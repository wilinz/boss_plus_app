import 'dart:async';
import 'dart:convert';

import 'package:boss_plus/boss_plus.dart';
import 'package:get/get.dart';

import '../data/boss_provider.dart';
import 'chat_store.dart';

/// 一条会话的元数据(从消息流派生:最后一条内容/时间/是否我发/最新 msgId)。
/// 名片(名字/公司/头像)不在这里,由 [ContactListController] 用 getBaseInfo 补。
class ImConversation {
  ImConversation(this.peer);
  final int peer;
  String lastText = '';
  int lastTime = 0;
  bool lastMine = false;
  int lastMsgId = 0;
  String peerName = ''; // 消息里带的对方名(getBaseInfo 缺时兜底)

  Map<String, dynamic> toJson() => {
        'txt': lastText,
        't': lastTime,
        'mine': lastMine,
        'mid': lastMsgId,
        'n': peerName,
      };

  factory ImConversation.fromJson(int peer, Map m) {
    final c = ImConversation(peer);
    c.lastText = (m['txt'] ?? '').toString();
    c.lastTime = (m['t'] as num?)?.toInt() ?? 0;
    c.lastMine = m['mine'] == true;
    c.lastMsgId = (m['mid'] as num?)?.toInt() ?? 0;
    c.peerName = (m['n'] ?? '').toString();
    return c;
  }
}

/// 全局唯一的 IM 连接(GetX 单例)。
///
/// 关键:MQTT clientId = md5(uniqid) 对本设备是**固定**的,同 clientId 的多个连接
/// 会互踢。所以整个 App 只能有**一个** [BossIm] 连接,所有会话共享 —— 每个会话各自
/// 建连会导致「打开新会话就重连」的死循环。本服务持有这唯一连接,ChatController
/// 只订阅其消息流、调用其发送,不再自行连接。
class ImService extends GetxService {
  static ImService get to => Get.find<ImService>();

  BossIm? _im;
  Future<void>? _connecting;

  final connected = false.obs;
  final error = ''.obs;

  int myUid = 0;
  String myName = '我';
  String myAvatar = '';

  /// 全量入站消息流(未按会话过滤;各 ChatController 自行筛选)。
  final _incoming = StreamController<ImMessage>.broadcast();
  Stream<ImMessage> get incoming => _incoming.stream;

  /// 每个会话(peer uid)的未读数(per-tile 红点用)。派生自「已读水位」+ 实时增量。
  final unread = <int, int>{}.obs;

  /// 未读总数(消息 tab 红点用),随 [unread] 同步更新。
  final unreadTotal = 0.obs;

  /// 会话表(peer -> 会话元数据),由消息流(存量同步 + 实时)派生。
  /// 会话列表页监听此表:最后一条/时间/未读都来自这里,不再逐个 chatHistory。
  final conversations = <int, ImConversation>{}.obs;

  int _syncMaxMsgId = 0;
  bool _pulling = false;
  StreamSubscription? _controlSub;
  Timer? _persistTimer;

  /// 已读水位:peer -> 已读到的最大 msgId(比它新的对方消息才算未读),持久化。
  final _lastRead = <int, int>{};

  /// 当前打开的会话 peer(其消息不计未读)。0 = 无。
  int _activePeer = 0;

  void _recomputeTotal() {
    var s = 0;
    for (final v in unread.values) {
      s += v;
    }
    unreadTotal.value = s;
  }

  void _setUnread(int peer, int n) {
    if (n <= 0) {
      unread.remove(peer);
    } else {
      unread[peer] = n;
    }
    unread.refresh();
    _recomputeTotal();
  }

  Future<void> _persistLastRead() =>
      ChatStore.instance.saveLastRead(Map.of(_lastRead));

  /// 用一段会话历史计算某会话未读(会话列表 _fillLastMessages 调用)。
  /// 首次见到某会话:把当前最新记为已读(避免历史全标红)。
  void applyHistory(int peer, List<ImMessage> msgs) {
    var latest = 0;
    var newer = 0;
    final wm = _lastRead[peer];
    for (final m in msgs) {
      if (m.fromUid != peer || m.msgId <= 0) continue; // 只数对方的、有 id 的
      if (m.msgId > latest) latest = m.msgId;
      if (wm != null && m.msgId > wm) newer++;
    }
    if (latest == 0) return;
    if (wm == null) {
      // 首次:标记已读到最新,未读 0。
      _lastRead[peer] = latest;
      _persistLastRead();
      _setUnread(peer, 0);
      return;
    }
    _setUnread(peer, peer == _activePeer ? 0 : newer);
    if (peer == _activePeer) markRead(peer, latest);
  }

  /// 标记某会话已读到 [uptoMsgId](进入会话/在会话内收到消息时)。
  void markRead(int peer, int uptoMsgId) {
    final cur = _lastRead[peer] ?? 0;
    if (uptoMsgId > cur) {
      _lastRead[peer] = uptoMsgId;
      _persistLastRead();
    }
    if ((unread[peer] ?? 0) != 0) _setUnread(peer, 0);
  }

  /// 打开某会话:标记活跃并立即清红点(水位在历史加载后由 [markRead] 推进)。
  void openChat(int peer) {
    _activePeer = peer;
    if ((unread[peer] ?? 0) != 0) _setUnread(peer, 0);
  }

  /// 关闭会话。
  void closeChat(int peer) {
    if (_activePeer == peer) _activePeer = 0;
  }

  /// 入站消息统一入口:广播给订阅者 + 会话表派生 + 计未读。
  void _onMessage(ImMessage m) {
    _incoming.add(m);
    // 会话表:任何有内容的消息(含我发的、系统卡片)都用于更新会话预览/时间/置顶。
    _ingestForList(m);
    final hasContent = m.displayText != null || m.jobCard != null;
    if (!hasContent || m.fromUid == myUid || m.fromUid == 0) return;
    final peer = m.fromUid;
    if (peer == _activePeer) {
      // 正在看这个会话 → 直接标记已读,不计未读。
      if (m.msgId > 0) markRead(peer, m.msgId);
      return;
    }
    // 未读 +1(有 msgId 则同时约束水位不倒退)。
    _setUnread(peer, (unread[peer] ?? 0) + 1);
  }

  /// 任意消息类型 → 会话列表预览文字(与官方一致:文本直接显示,其它给类型摘要)。
  static String? _previewOf(ImMessage m) {
    final t = m.displayText;
    if (t != null && t.isNotEmpty) return t;
    return switch (m.contentType) {
      ContentType.image => '[图片]',
      ContentType.sound => '[语音]',
      ContentType.jobCard => '[职位]',
      _ => m.jobCard != null ? '[职位]' : null, // 无内容(纯控制)不建会话
    };
  }

  /// 把一条消息并入会话表(存量同步 + 实时都走这里)。取"更新的一条"作为会话预览。
  void _ingestForList(ImMessage m) {
    final preview = _previewOf(m);
    if (preview == null) return;
    final peer = m.fromUid == myUid ? m.toUid : m.fromUid;
    if (peer == 0 || peer == myUid) return;
    final c = conversations[peer] ?? ImConversation(peer);
    final t = m.time > 0 ? m.time : c.lastTime;
    // 更新条件:时间更新,或(同/无时间但)msgId 更大,或首次。
    final isNewer = c.lastTime == 0 ||
        t > c.lastTime ||
        (t >= c.lastTime && m.msgId > c.lastMsgId);
    if (isNewer) {
      c.lastText = preview;
      c.lastTime = t;
      c.lastMine = m.fromUid == myUid;
      if (m.msgId > 0) c.lastMsgId = m.msgId;
      if (!c.lastMine && (m.fromName?.isNotEmpty ?? false)) {
        c.peerName = m.fromName!;
      }
    }
    conversations[peer] = c;
    conversations.refresh();
    if (m.msgId > _syncMaxMsgId) _syncMaxMsgId = m.msgId;
    _schedulePersist();
  }

  /// 已回填过最后一条的 peer(避免重复打 HTTP)。
  final _backfilled = <int>{};

  /// 存量兜底:broker 的 `/message/pull` 补推没来时(实测冷启常不推),用 HTTP 单聊历史
  /// 给「还没有最后一条」的会话各拉一页最新消息,并入会话表。
  ///
  /// [peerSource] = peer -> friendSource(getBaseInfo 的桶)。之后的实时消息仍由
  /// [_onMessage] 覆盖,所以这里只兜底一次。
  Future<void> backfillLastMessages(
    Map<int, int> peerSource, {
    int concurrency = 5,
  }) async {
    final todo = <int>[
      for (final e in peerSource.entries)
        if ((conversations[e.key]?.lastText ?? '').isEmpty &&
            _backfilled.add(e.key))
          e.key,
    ];
    if (todo.isEmpty) return;
    final boss = await BossProvider.instance.get();
    var next = 0;
    Future<void> worker() async {
      while (true) {
        final i = next++;
        if (i >= todo.length) return;
        final peer = todo[i];
        try {
          // count>1:接口按页返回,让 _ingestForList 自己挑最新的一条。
          final h = await boss.chatHistory(
            friendId: peer,
            friendSource: peerSource[peer] ?? 0,
            maxMsgId: 0,
            count: 5,
          );
          for (final b64 in h.messages) {
            for (final msg in ChatProtocol.decode(base64.decode(b64)).messages) {
              _ingestForList(msg);
            }
          }
        } catch (_) {
          _backfilled.remove(peer); // 失败允许下次重试
        }
      }
    }

    await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
    bossLog('会话最后一条回填完成 ${todo.length} 个', tag: 'im');
    _flushPersist();
  }

  /// 会话同步:presence 的 PULL 位触发 broker 下推首批 + type=4 `/message/pull` 控制包
  /// (`{hasMore,lastId,secretId}`)。此处收到控制包后用 HTTP `Boss.pullHistory` 逐页
  /// 拉全存量(直到 hasMore=false),每条并入会话表。
  Future<void> _onControl(({String query, Map<String, String> results}) c) async {
    if (c.query != '/message/pull') return;
    final r = c.results;
    final hasMore = r['hasMore'] == 'true' || r['hasMore'] == '1';
    final lastId = int.tryParse(r['lastId'] ?? '') ?? 0;
    final secretId = r['secretId'] ?? '';
    if (!hasMore || secretId.isEmpty || _pulling) return;
    _pulling = true;
    try {
      final boss = await BossProvider.instance.get();
      var lid = lastId, sid = secretId, guard = 0;
      while (guard++ < 100) {
        final page = await boss.pullHistory(lastId: lid, secretId: sid);
        for (final b64 in page.messages) {
          try {
            for (final msg in ChatProtocol.decode(base64.decode(b64)).messages) {
              _ingestForList(msg);
            }
          } catch (_) {}
        }
        if (!page.hasMore || page.secretId.isEmpty) break;
        lid = page.lastId;
        sid = page.secretId;
      }
      bossLog('会话同步续拉完成 会话数=${conversations.length}', tag: 'im');
    } catch (e) {
      bossLog('会话同步续拉失败: $e', tag: 'im');
    } finally {
      _pulling = false;
      _flushPersist();
    }
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 800), _flushPersist);
  }

  void _flushPersist() {
    _persistTimer?.cancel();
    final meta = conversations.map((k, v) => MapEntry(k, v.toJson()));
    ChatStore.instance.saveConvMeta(meta);
    ChatStore.instance.saveSyncMaxMsgId(_syncMaxMsgId);
  }

  /// 确保已连接(幂等)。
  /// 关键:已连接则直接返回,**绝不**再建第二个连接 —— 同 clientId 的两个 MQTT 连接
  /// 会被 broker 单方面互踢(§16 之前误判为"官方 App 互踢",实为本 App 自己重复建连
  /// 自踢)。连接进行中共享同一 Future;断开后 _im/connected 复位,才允许重连。
  Future<void> ensureConnected() {
    if (connected.value && _im != null) return Future.value();
    return _connecting ??= _connect();
  }

  Future<void> _connect() async {
    // 双重保险:进入实际建连前再查一次,避免 await 边界上的竞态重复建连。
    if (connected.value && _im != null) return;
    try {
      final boss = await BossProvider.instance.get();
      try {
        final geek = await boss.queryGeekBaseInfo();
        myUid = geek.userId;
        myName = geek.name;
        myAvatar = geek.avatar;
      } catch (e) {
        bossLog('拉个人信息失败: $e', tag: 'im');
      }
      // 载入本地聊天存储(会话/消息/未读),恢复未读红点与会话表(离线可见、秒开)。
      if (myUid != 0) {
        await ChatStore.instance.init(myUid);
        _lastRead
          ..clear()
          ..addAll(ChatStore.instance.lastRead);
        conversations.clear();
        ChatStore.instance.convMeta.forEach((peer, m) {
          conversations[peer] = ImConversation.fromJson(peer, m);
        });
        conversations.refresh();
        _syncMaxMsgId = ChatStore.instance.syncMaxMsgId;
      }
      final im = BossIm(
        uid: myUid,
        userName: myName,
        appConfig: boss.appConfig,
        secretKey: boss.auth.secretKey ?? '',
        onDisconnected: _onDisconnected,
      );
      im.messages.listen(_onMessage);
      // 会话同步控制包(type=4 /message/pull)→ HTTP 逐页续拉存量。
      _controlSub?.cancel();
      _controlSub = im.controls.listen(_onControl);
      // 全量补推:presence lastMessageId=0 → broker 下推全部存量(dedup 幂等)。
      // 若要增量,改为 im.syncFromMsgId = _syncMaxMsgId。
      im.syncFromMsgId = 0;
      await im.connect();
      _im = im;
      connected.value = true;
    } catch (e, st) {
      error.value = '$e';
      bossLog('IM 连接失败: $e\n$st', tag: 'im');
      rethrow;
    } finally {
      // 成功/失败都清空,使 ensureConnected 可再次触发重连;dedupe 只需在连接进行中生效。
      _connecting = null;
    }
  }

  /// broker 断连回调:复位状态。下一次 ensureConnected()(打开会话/UI 触发)即重连。
  void _onDisconnected() {
    connected.value = false;
    _controlSub?.cancel();
    _controlSub = null;
    _flushPersist();
    _im = null;
  }

  /// 发送文本,返回 clientMsgId(失败返回 null)。
  int? sendText({required int toUid, required String text}) {
    final im = _im;
    if (im == null || !connected.value) return null;
    return im.sendText(toUid: toUid, text: text);
  }

  @override
  void onClose() {
    _persistTimer?.cancel();
    _flushPersist();
    _controlSub?.cancel();
    _im?.disconnect();
    _incoming.close();
    super.onClose();
  }
}
