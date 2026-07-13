/// BOSS IM 客户端(纯 Dart):MQTT + protobuf 收发聊天消息。
///
/// 依据 `docs/boss-im-protocol.md`:
/// - Broker `ssl://chat.zhipin.com:443`(标准 MQTT over TLS)
/// - username = `{uid}-1-{PROTO_VER}-{appVer}`(如 `756381816-1-1.3-14.070`),无 CONNECT payload
/// - 连上后发 type=2 应用层鉴权信封(§2)完成登录
/// - 收发聊天走 topic `chat`,payload 为 `ChatProtocol` protobuf 信封
///
/// 传输层兼容性说明:官方为自研 MQTT 客户端(`pf0.j`/`com.twl.mms`,自定义帧
/// `MMSMessage`),但语义(username/topic/QoS/protobuf payload)均为标准 MQTT。
/// 本实现用标准 `mqtt_client`;与真机 broker 的 wire 级兼容需联网实测验证。
library;

import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io' show SecurityContext, X509Certificate;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show md5;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart' show Uint8Buffer;

import '../core/config/boss_app_config.dart';
import '../utils/log.dart';
import 'chat_protocol.dart';
import 'mqtt_client_cert.dart';

/// IM 连接配置。
class BossImConfig {
  const BossImConfig({
    this.host = 'chat.zhipin.com',
    this.port = 443,
    this.keepAliveSeconds = 60,
    this.topic = 'chat',
  });

  final String host;
  final int port;
  final int keepAliveSeconds;
  final String topic;
}

/// BOSS IM 客户端:连接鉴权 + 收发文本消息。
class BossIm {
  BossIm({
    required this.uid,
    required this.userName,
    required this.appConfig,
    required this.secretKey,
    this.identity = 0,
    this.sendPresence = true,
    this.longitude = 0,
    this.latitude = 0,
    this.config = const BossImConfig(),
    this.onDisconnected,
  });

  /// 连接被断开时回调(broker unsolicited 断连 / 主动 disconnect 均触发)。
  /// 上层据此复位状态并按需重连(注意 §16:同账号单连接,官方 App 在线会互踢)。
  final void Function()? onDisconnected;

  /// 当前用户 uid(登录后从会话拿到)。
  final int uid;

  /// 用户显示名(发送消息 from.name 用)。
  final String userName;

  /// 登录会话密钥(与 HTTP 签名同源,用于派生 MQTT password)。
  final String secretKey;

  /// 身份位(MQTT username 第二段):geek=0 / boss=1。实测 geek 用 0。
  final int identity;

  /// 是否连接后发 type=2 presence 鉴权(需发,否则 broker 不推消息/断连)。
  final bool sendPresence;

  /// 设备经纬度(client_info f12/f13 double,实测官方带此字段)。
  final double longitude;
  final double latitude;

  final BossAppConfig appConfig;
  final BossImConfig config;

  MqttServerClient? _client;
  final int _sessionStart = DateTime.now().millisecondsSinceEpoch;

  final _incoming = StreamController<ImMessage>.broadcast();

  /// 入站聊天消息流(已解出的 type=1 文本/卡片等)。
  Stream<ImMessage> get messages => _incoming.stream;

  bool get connected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  /// MQTT username:`{uid}-{identity}-1.4-{appVer}`(真机实测 = `756381816-0-1.4-14.070`)。
  String get mqttUsername => '$uid-$identity-1.4-${appConfig.versionName}';

  /// MQTT clientId = md5(设备 uniqid) 的中间 16 位。
  /// 实测:md5("55395b57-...-c54fa7be5a7d")[8:24] = 810714beab4111f6。
  /// broker 按 clientId 关联该设备的消息队列 → 必须与设备指纹一致才能收到推送。
  String get mqttClientId => _md5Hex(appConfig.uniqid).substring(8, 24);

  /// MQTT password = md5(secretKey + ts) 中间 16 位 + ts(实测 `ConnectController.getPassword`)。
  String _mqttPassword() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return _md5Hex(secretKey + ts).substring(8, 24) + ts;
  }

  static String _md5Hex(String s) => md5.convert(utf8.encode(s)).toString();

  /// 连接 broker(TLS)→ MQTT CONNECT → 订阅 topic → 发 type=2 鉴权。
  Future<void> connect() async {
    final clientId = mqttClientId;
    // 双向 TLS(mTLS):Android 上 chat.zhipin.com 强制客户端出示证书(不带 → bad_certificate)。
    // 用官方 RSA 客户端证书(client.p12);EC 版(ecc_client.p12)在 Android BoringSSL 上会
    // 触发 certificate_unknown,故改用 RSA。服务器证书 BOSS 自签,用 onBadCertificate 放行。
    final ctx = SecurityContext(withTrustedRoots: true)
      ..useCertificateChainBytes(utf8.encode(mqttClientCertPem))
      ..usePrivateKeyBytes(utf8.encode(mqttClientKeyPem));
    final c = MqttServerClient.withPort(config.host, clientId, config.port)
      ..secure = true
      ..securityContext = ctx
      ..keepAlivePeriod = 360 // 真机实测 keepAlive=360
      ..logging(on: false)
      ..setProtocolV31() // 真机实测 mqttVersion=3(MQTT 3.1 / MQIsdp),非 3.1.1
      // 服务器证书是 BOSS 自签(subject==issuer, CN=*.zhipin.com),非公共 CA。
      ..onBadCertificate = _acceptBossCert;

    // 真机实测 CONNECT:clientId=md5(username)[8:24]、username=`{uid}-0-1.4-{ver}`、
    // password=md5(secretKey+ts)[8:24]+ts。
    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(mqttUsername, _mqttPassword())
        .withWillQos(MqttQos.atMostOnce)
        .startClean();
    c.connectionMessage = connMsg;

    c.onConnected = () => bossLog('IM 已连接 $clientId', tag: 'im');
    c.onDisconnected = () {
      bossLog(
          'IM 断开 reason=${c.connectionStatus?.disconnectionOrigin} '
          'returnCode=${c.connectionStatus?.returnCode}',
          tag: 'im');
      onDisconnected?.call();
    };
    c.onSubscribed = (t) => bossLog('IM 已订阅 $t', tag: 'im');
    // BOSS broker 回的 SUBACK 缺 qosGrants(空)。mqtt_client 10.11.x 已对空 qosGrants
    // 做短路保护,但仅当 onSubscribeFail != null 时才安全:未设时 confirmSubscription
    // 会在日志分支求值 `qosGrants.first` 触发空列表崩溃。故此回调必须注册。
    c.onSubscribeFail =
        (t) => bossLog('IM 订阅 SUBACK 无 qosGrants(BOSS 特性,忽略) $t', tag: 'im');
    c.updates?.listen(_onUpdates);

    _client = c;
    await c.connect();

    if (c.connectionStatus?.state != MqttConnectionState.connected) {
      throw StateError('IM 连接失败: ${c.connectionStatus}');
    }

    // 官方 App 连上后**立即 subscribe("chat", QoS=1)**(逆向 sf0.b.i():connect→subscribe;
    // 配置 qf0.f 默认 topic=IButtonKey.CHAT="chat"、qos=1)。这是 broker 开始投递 type=1
    // 实时消息的前提——之前误信「官方从不 subscribe」(frida 抓包假象)去掉了它,导致 RECV=0。
    // 空 qosGrants 崩溃已由上面的 onSubscribeFail 规避;入站 PUBLISH 无关订阅记录,照常经
    // c.updates 投递(mqtt_client publishMessageReceived 不按订阅过滤)。
    c.subscribe(config.topic, MqttQos.atLeastOnce);

    // 订阅后再发 type=2 presence 鉴权(官方每次连上都发,broker 要求结构完整的 type=2)。
    if (sendPresence) _sendAuth();
  }

  /// 发送一条文本消息给 [toUid]。
  ///
  /// 返回本条的 clientMsgId(= 发送时间戳);服务器会经 type=1 回推确认,
  /// 回推消息通过 [messages] 流返回。
  int sendText({required int toUid, required String text}) {
    final clientMsgId = DateTime.now().millisecondsSinceEpoch;
    final env = ChatProtocol.encodeTextSend(
      fromUid: uid,
      fromName: userName,
      toUid: toUid,
      text: text,
      clientMsgId: clientMsgId,
    );
    _publish(env);
    bossLog('发送文本 → $toUid: "$text" (cmid=$clientMsgId)', tag: 'im');
    return clientMsgId;
  }

  /// 发送已读回执。
  void sendRead({required int friendUid, required int msgId}) {
    final env = ChatProtocol.encodeRead(
      friendUid: friendUid,
      msgId: msgId,
      timeMs: DateTime.now().millisecondsSinceEpoch,
    );
    _publish(env);
  }

  Future<void> disconnect() async {
    _client?.disconnect();
    await _incoming.close();
  }

  // ---- 内部 ----

  /// 证书 pinning:接受 BOSS 自签服务器证书。
  ///
  /// 服务器按协商套件回不同自签证书:
  /// - RSA 套件:`O=BOSS, CN=*.zhipin.com`
  /// - ECC 套件(带 EC 客户端证书时走这条):`O=zhipin, CN=Zhipin BossHi Inc.`(= ecc_server.crt)
  /// 两者都是 kanzhun/BOSS 自签,统一按关键字放行。
  static bool _acceptBossCert(Object cert) {
    if (cert is! X509Certificate) return false;
    final s = '${cert.subject} ${cert.issuer}'.toLowerCase();
    return s.contains('zhipin') || s.contains('boss') || s.contains('kanzhun');
  }

  void _sendAuth() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final env = ChatProtocol.encodeAuth(
      uid: uid,
      presenceType: 768,
      appVersion: appConfig.versionName,
      osVersion: appConfig.osVersion,
      modelVendor: '${appConfig.manufacturer}||${appConfig.model}',
      uniqid: appConfig.uniqid,
      appId: int.tryParse(appConfig.appId) ?? 1003,
      nowMs: now,
      sessionStartMs: _sessionStart,
      lastMessageId: 0,
      longitude: longitude,
      latitude: latitude,
    );
    _publish(env);
    bossLog('已发鉴权 type=2 uid=$uid', tag: 'im');
  }

  void _publish(Uint8List payload) {
    final buf = Uint8Buffer()..addAll(payload);
    _client?.publishMessage(config.topic, MqttQos.atLeastOnce, buf);
  }

  void _onUpdates(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final e in events) {
      final msg = e.payload;
      if (msg is! MqttPublishMessage) continue;
      final data = Uint8List.fromList(msg.payload.message); // Uint8Buffer → Uint8List
      try {
        final decoded = ChatProtocol.decode(data);
        for (final m in decoded.messages) {
          _incoming.add(m);
          // 自动回已读(可选:仅对方发来的消息)
          if (m.fromUid != uid && m.msgId != 0) {
            sendRead(friendUid: m.fromUid, msgId: m.msgId);
          }
        }
      } catch (err) {
        bossLog('入站解析失败: $err', tag: 'im');
      }
    }
  }
}
