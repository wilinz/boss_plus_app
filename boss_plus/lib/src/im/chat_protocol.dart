/// BOSS IM 协议(MQTT topic=`chat` 的 protobuf 信封)编解码。
///
/// 底层用官方 protobuf(`proto/chat.proto` → `gen/chat.pb.dart`,proto2),
/// 字段号/类型由反编译类 `ChatProtocol`(Techwolf)还原。详见 `docs/boss-im-protocol.md`。
///
/// 本文件是对生成类的**薄封装**:暴露 `ImMessage` 领域模型 + 收发编解码,
/// 使上层(`BossIm`)与 protobuf 细节解耦。
library;

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'gen/chat.pb.dart';

/// 信封消息类型(TechwolfChatProtocol.type)。
class ImType {
  static const int chat = 1; // 聊天消息
  static const int auth = 2; // 连接鉴权(presence)
  static const int request = 3; // 请求(suggest 等)
  static const int response = 4; // 请求响应
  static const int read = 6; // 已读回执
}

/// 正文类型(TechwolfMessageBody.type = mediaType / content_type)。文档 §10 全表。
class ContentType {
  static const int text = 1;
  static const int sound = 2;
  static const int image = 3;
  static const int action = 4;
  static const int jobCard = 8;
  static const int resume = 9;
  // …其余见文档 §10。
}

/// 一条聊天消息(type=1 的解析结果 / 发送输入)。
/// 职位卡片消息(content_type=8)的正文字段 —— 直接来自消息 protobuf(body.f10),
/// 与官方渲染同源(不需要另外拉 JobDetail)。字段号见抓包还原:
/// f1=岗位名 f3=薪资 f6=职类 f7=经验 f8=学历 f9=地点 f10=boss头衔
/// f11={f2=boss名, f3=头像url} f14=底部文案(由你发起的沟通) f15=标签(外地)。
class MsgJobCard {
  const MsgJobCard({
    this.title = '',
    this.salary = '',
    this.position = '',
    this.experience = '',
    this.degree = '',
    this.location = '',
    this.bossTitle = '',
    this.bossName = '',
    this.bossAvatar = '',
    this.footer = '',
    this.tag = '',
    this.jobId = 0,
    this.jumpUrl = '',
  });

  final String title;
  final String salary;
  final String position;
  final String experience;
  final String degree;
  final String location;
  final String bossTitle;
  final String bossName;
  final String bossAvatar;
  final String footer;
  final String tag;
  final int jobId;

  /// bosszp 深链(含 jid/uid/securityId),点击卡片进职位详情用。
  final String jumpUrl;

  /// 从 jumpUrl 里解出的 securityId(职位详情页需要)。
  String get securityId {
    final m = RegExp(r'securityId=([^&]+)').firstMatch(jumpUrl);
    return m != null ? Uri.decodeComponent(m.group(1)!) : '';
  }
}

class ImMessage {
  ImMessage({
    required this.fromUid,
    required this.toUid,
    required this.contentType,
    this.text,
    this.jobCard,
    this.pushText,
    this.msgId = 0,
    this.clientMsgId = 0,
    this.time = 0,
    this.fromName,
  });

  final int fromUid;
  final int toUid;
  final int contentType;

  /// content_type=1 时的文本正文。
  final String? text;

  /// content_type=8 时的职位卡片(从消息 protobuf 解出)。
  final MsgJobCard? jobCard;

  /// 推送摘要文案(body 无文本的系统/交换类消息用它显示,如「你已发起换电话请求」)。
  final String? pushText;

  /// 可显示的最佳文案:优先正文,退化到 pushText。
  String? get displayText => text ?? pushText;

  /// 服务器分配的消息 id(发送时为 0)。
  final int msgId;

  /// 客户端临时 id(= 发送时间戳 ms)。
  final int clientMsgId;
  final int time;
  final String? fromName;

  bool get isText => contentType == ContentType.text;

  @override
  String toString() =>
      'ImMessage(from=$fromUid→to=$toUid, type=$contentType, '
      'text=${text == null ? null : '"$text"'}, msgId=$msgId)';
}

/// 信封编解码。
class ChatProtocol {
  static const String versionChat = '1.3'; // 服务器回推
  static const String versionCtrl = '1.4'; // 客户端出站

  // ---- 编码:发文本消息(type=1) ----

  /// 构造发送文本的信封字节。字节级对齐真机实测(§8):显式写出 0 值字段,version="1.4"。
  static Uint8List encodeTextSend({
    required int fromUid,
    required String fromName,
    required int toUid,
    required String text,
    required int clientMsgId,
  }) {
    final cmid = Int64(clientMsgId);
    final msg = TechwolfMessage()
      ..from = (TechwolfUser()
        ..uid = Int64(fromUid)
        ..name = fromName
        ..source = 0)
      ..to = (TechwolfUser()
        ..uid = Int64(toUid)
        ..source = 0)
      ..type = 1
      ..mid = cmid
      ..time = cmid
      ..body = (TechwolfMessageBody()
        ..type = ContentType.text
        ..templateId = 1
        ..text = text)
      ..offline = false
      ..taskId = Int64.ZERO
      ..cmid = cmid
      ..status = 2
      ..unCount = 0
      ..bizType = 0
      ..quoteId = Int64.ZERO;
    final env = TechwolfChatProtocol()
      ..type = ImType.chat
      ..version = versionCtrl
      ..messages.add(msg);
    return env.writeToBuffer();
  }

  // ---- 编码:连接鉴权(type=2)----

  /// 连接后应用层鉴权信封(§2:presence + 设备指纹)。
  static Uint8List encodeAuth({
    required int uid,
    required int presenceType, // 实测 768
    required String appVersion,
    required String osVersion,
    required String modelVendor, // "Redmi||22021211RC"
    required String uniqid,
    required int appId, // 1003
    required int nowMs,
    required int sessionStartMs,
    required int lastMessageId,
    String os = 'Android',
    String network = 'WIFI',
    String channel = '5',
    double longitude = 0, // client_info f12(经度 double),实测官方带此字段
    double latitude = 0, // client_info f13(纬度 double)
  }) {
    final presence = TechwolfPresence()
      ..type = presenceType
      ..uid = Int64(uid)
      ..clientInfo = (TechwolfClientInfo()
        ..version = appVersion
        ..system = os
        ..systemVersion = osVersion
        ..model = modelVendor
        ..uniqid = uniqid
        ..network = network
        ..appId = appId
        ..platform = os
        ..channel = channel
        ..longitude = longitude
        ..latitude = latitude)
      ..clientTime = (TechwolfClientTime()
        ..startTime = Int64(nowMs)
        ..resumeTime = Int64(nowMs)
        ..locateTime = Int64(sessionStartMs))
      ..lastMessageId = Int64(lastMessageId)
      ..lastGroupMessageId = Int64.ZERO;
    final env = TechwolfChatProtocol()
      ..type = ImType.auth
      ..version = versionCtrl
      ..presence = presence;
    return env.writeToBuffer();
  }

  // ---- 编码:已读回执(type=6) ----

  /// 已读回执信封。[friendUid] 对方 uid,[msgId] 已读到的消息 id。
  static Uint8List encodeRead({
    required int friendUid,
    required int msgId,
    required int timeMs,
  }) {
    final read = TechwolfMessageRead()
      ..userId = Int64(friendUid)
      ..messageId = Int64(msgId)
      ..readTime = Int64(timeMs)
      ..sync = false
      ..userSource = 0
      ..ownerSource = 0;
    final env = TechwolfChatProtocol()
      ..type = ImType.read
      ..version = versionCtrl
      ..messageRead = read;
    return env.writeToBuffer();
  }

  // ---- 解码:入站信封 ----

  /// 解析入站信封,返回 (type, 携带的聊天消息列表)。只解 type=1 的聊天消息。
  static ({int type, List<ImMessage> messages}) decode(Uint8List data) {
    final env = TechwolfChatProtocol.fromBuffer(data);
    if (env.type != ImType.chat) {
      return (type: env.type, messages: const []);
    }
    final msgs = <ImMessage>[];
    for (final m in env.messages) {
      final body = m.hasBody() ? m.body : null;
      final ct = body?.type ?? 0;
      msgs.add(ImMessage(
        fromUid: m.from.uid.toInt(),
        toUid: m.to.uid.toInt(),
        fromName: m.from.hasName() ? m.from.name : null,
        contentType: ct,
        text: (ct == ContentType.text && (body?.hasText() ?? false))
            ? body!.text
            : null,
        jobCard: (ct == ContentType.jobCard && (body?.hasJobCard() ?? false))
            ? _jobCardFrom(body!.jobCard)
            : null,
        pushText: m.hasPushText() ? m.pushText : null,
        msgId: m.mid.toInt(),
        time: m.time.toInt(),
      ));
    }
    return (type: env.type, messages: msgs);
  }

  /// 生成的 TechwolfJobCard → 轻量 JobCard(UI 用)。
  static MsgJobCard _jobCardFrom(TechwolfJobCard j) => MsgJobCard(
        title: j.title,
        salary: j.salary,
        position: j.position,
        experience: j.experience,
        degree: j.degree,
        location: j.location,
        bossTitle: j.bossTitle,
        bossName: j.hasBoss() ? j.boss.name : '',
        bossAvatar: j.hasBoss() ? j.boss.avatar : '',
        footer: j.footer,
        tag: j.tag,
        jobId: j.jobId.toInt(),
        jumpUrl: j.jumpUrl,
      );
}
