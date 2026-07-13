import 'dart:convert';
import 'dart:async';

import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../data/boss_provider.dart';
import 'chat_store.dart';
import 'im_service.dart';

/// 单会话聊天控制器:HTTP 拉历史 + 订阅全局 [ImService] 的实时消息流。
///
/// 不自建连接 —— 全 App 共享 [ImService] 的唯一 MQTT 连接(同 clientId 多连接会互踢)。
/// 收发协议见 `docs/boss-im-protocol.md`。
class ChatController extends GetxController {
  ChatController({
    required this.peerUid,
    required this.peerName,
    this.friendSource = 0,
    this.securityId = '',
  });

  /// 对方(boss)uid 与显示名。
  final int peerUid;
  final String peerName;
  final int friendSource;
  final String securityId;

  final messages = <ImMessage>[].obs;
  final connecting = true.obs;
  final error = ''.obs;

  final ImService _im = ImService.to;
  StreamSubscription<ImMessage>? _sub;

  /// 实时连接状态直接取全局 IM 服务的。
  RxBool get connected => _im.connected;
  int get _myUid => _im.myUid;
  String get _myName => _im.myName;

  /// 最近一条消息的服务器 id(交换/发简历接口的 mid 参数用)。无则 0。
  int get latestMsgId {
    for (final m in messages.reversed) {
      if (m.msgId != 0) return m.msgId;
    }
    return 0;
  }

  /// 已见消息去重(clientMsgId 或 msgId)。
  final _seen = <int>{};

  @override
  void onInit() {
    super.onInit();
    // 标记会话活跃 + 清零未读红点。会改动全局 unread(通知已构建的徽章 Obx),
    // 推迟到帧后,避免「setState during build」(onInit 在 ChatPage.build 内同步执行)。
    WidgetsBinding.instance.addPostFrameCallback((_) => _im.openChat(peerUid));
    // 先上屏本地缓存(秒开、离线可见),HTTP 拉到后按 key 合并去重。
    final cached = ChatStore.instance.messages(peerUid);
    if (cached.isNotEmpty) {
      cached.sort((a, b) => a.time.compareTo(b.time));
      messages.assignAll(cached);
      for (final m in cached) {
        _seen.add(m.msgId != 0 ? m.msgId : m.clientMsgId);
      }
      connecting.value = false;
    }
    _bootstrap();
  }

  /// 缓存当前会话可展示消息到本地(截断在 ChatStore 内)。
  void _persist() => ChatStore.instance.saveMessages(
      peerUid, messages.where((m) => m.displayText != null).toList());

  void _bootstrap() {
    // 1) 先订阅实时消息(避免错过刚发起沟通的开场白 type=1 回推)。
    _sub = _im.incoming.listen(_onIncoming);
    // 2) 确保连接(复用全局单例;已连秒返回,不阻塞 UI)。
    _im.ensureConnected().catchError((e) {
      error.value = '实时连接失败(历史仍可见): $e';
    });
    // connecting 只表示首屏历史是否加载中,不再被连接/重试阻塞。
    // 3) 后台拉历史(空则重试,刚发起沟通有延迟)。
    _loadHistory();
  }

  /// HTTP 拉历史,解码去重上屏;空时重试(刚发起沟通服务器代发开场白有延迟)。
  Future<void> _loadHistory() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final boss = await BossProvider.instance.get();
        final page = await boss.chatHistory(
          friendId: peerUid,
          friendSource: friendSource,
          securityId: securityId,
          count: 30,
        );
        final history = <ImMessage>[];
        for (final b64 in page.messages) {
          try {
            for (final m in ChatProtocol.decode(base64.decode(b64)).messages) {
              // 文本 + 职位卡 + 系统/交换类(有 pushText 的)都上屏。
              if (m.displayText != null || m.jobCard != null) history.add(m);
            }
          } catch (_) {}
        }
        if (history.isNotEmpty) {
          // 按稳定 key 去重合并(ImMessage 无值相等,不能靠 Set 对象身份 —— 否则重拉
          // 历史会把已上屏的消息整体翻倍)。key = msgId>0 ? msgId : clientMsgId>0 ?
          // -clientMsgId : content 兜底。历史与实时同一条会被合成一条。
          final byKey = <Object, ImMessage>{};
          for (final m in [...messages, ...history]) {
            final k = m.msgId != 0
                ? 'm${m.msgId}'
                : m.clientMsgId != 0
                    ? 'c${m.clientMsgId}'
                    : 't${m.time}_${m.displayText ?? ''}';
            byKey[k] = m; // 后写覆盖:history 覆盖 messages(取服务器版本)
            _seen.add(m.msgId != 0 ? m.msgId : m.clientMsgId);
          }
          final merged = byKey.values.toList()
            ..sort((a, b) => a.time.compareTo(b.time));
          messages.assignAll(merged);
          connecting.value = false;
          _persist();
          _im.markRead(peerUid, latestMsgId); // 看到历史 = 已读到最新
          return;
        }
      } catch (e) {
        bossLog('拉历史失败(attempt $attempt): $e', tag: 'im');
      }
      // 首次 fetch 后即收起 loading —— 空会话(系统号/无历史)不再干等 3 次重试的
      // 「加载中」;后续重试/实时推送到达再填内容(打招呼开场白走 MQTT/下次 fetch)。
      connecting.value = false;
      await Future.delayed(const Duration(seconds: 1));
    }
    connecting.value = false; // 3 次仍空,停掉 loading(靠实时推送)。
  }

  /// 刷新会话(重新拉历史并合并)。用于交换/发简历等操作成功后同步新消息 ——
  /// 这类操作消息**不经 MQTT 实时推**(实测),官方 onSuccess 也是刷新(r2())而非等推送。
  Future<void> reloadHistory() => _loadHistory();

  void _onIncoming(ImMessage m) {
    // 只收当前会话相关(我与对方之间)的消息。
    final relevant = (m.fromUid == peerUid && m.toUid == _myUid) ||
        (m.fromUid == _myUid && m.toUid == peerUid);
    if (!relevant || (m.displayText == null && m.jobCard == null)) return;
    // 去重:服务器回推自己发的消息 / 历史与推送重叠。
    final key = m.msgId != 0 ? m.msgId : m.clientMsgId;
    if (key != 0 && !_seen.add(key)) return;
    connecting.value = false; // 有消息了,收起 loading。
    messages.add(m);
    messages.sort((a, b) => a.time.compareTo(b.time));
    _persist();
  }

  /// 发送文本。本地即时上屏;服务器会经 type=1 回推确认(去重靠 clientMsgId)。
  void send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final cmid = _im.sendText(toUid: peerUid, text: t);
    if (cmid == null) {
      error.value = '未连接,无法发送';
      return;
    }
    _seen.add(cmid); // 标记,避免服务器回推重复上屏。
    messages.add(ImMessage(
      fromUid: _myUid,
      toUid: peerUid,
      contentType: ContentType.text,
      text: t,
      clientMsgId: cmid,
      time: DateTime.now().millisecondsSinceEpoch,
      fromName: _myName,
    ));
    _persist();
  }

  bool isMine(ImMessage m) => m.fromUid == _myUid;

  @override
  void onClose() {
    // 退出会话:取消活跃标记(之后该会话的新消息重新计未读)。
    _im.closeChat(peerUid);
    // 只取消本会话订阅;不断开全局共享连接。
    _sub?.cancel();
    super.onClose();
  }
}
