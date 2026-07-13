import 'dart:async';

import 'package:boss_plus/boss_plus.dart';
import 'package:get/get.dart';

import '../data/boss_provider.dart';
import 'chat_store.dart';

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

  /// 入站消息统一入口:广播给订阅者 + 计未读。
  void _onMessage(ImMessage m) {
    _incoming.add(m);
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
      // 载入本地聊天存储(会话/消息/未读),恢复未读红点。
      if (myUid != 0) {
        await ChatStore.instance.init(myUid);
        _lastRead
          ..clear()
          ..addAll(ChatStore.instance.lastRead);
      }
      final im = BossIm(
        uid: myUid,
        userName: myName,
        appConfig: boss.appConfig,
        secretKey: boss.auth.secretKey ?? '',
        onDisconnected: _onDisconnected,
      );
      im.messages.listen(_onMessage);
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
    _im?.disconnect();
    _incoming.close();
    super.onClose();
  }
}
