//
//  Generated code. Do not modify.
//  source: chat.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// 外层信封。type 决定用哪个 body 字段。
class TechwolfChatProtocol extends $pb.GeneratedMessage {
  factory TechwolfChatProtocol({
    $core.int? type,
    $core.String? version,
    $core.Iterable<TechwolfMessage>? messages,
    TechwolfPresence? presence,
    TechwolfMessageRead? messageRead,
    $core.int? domain,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (version != null) {
      $result.version = version;
    }
    if (messages != null) {
      $result.messages.addAll(messages);
    }
    if (presence != null) {
      $result.presence = presence;
    }
    if (messageRead != null) {
      $result.messageRead = messageRead;
    }
    if (domain != null) {
      $result.domain = domain;
    }
    return $result;
  }
  TechwolfChatProtocol._() : super();
  factory TechwolfChatProtocol.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TechwolfChatProtocol.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TechwolfChatProtocol', package: const $pb.PackageName(_omitMessageNames ? '' : 'techwolf'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.O3)
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..pc<TechwolfMessage>(3, _omitFieldNames ? '' : 'messages', $pb.PbFieldType.PM, subBuilder: TechwolfMessage.create)
    ..aOM<TechwolfPresence>(4, _omitFieldNames ? '' : 'presence', subBuilder: TechwolfPresence.create)
    ..aOM<TechwolfMessageRead>(8, _omitFieldNames ? '' : 'messageRead', protoName: 'messageRead', subBuilder: TechwolfMessageRead.create)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'domain', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfChatProtocol clone() => TechwolfChatProtocol()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfChatProtocol copyWith(void Function(TechwolfChatProtocol) updates) => super.copyWith((message) => updates(message as TechwolfChatProtocol)) as TechwolfChatProtocol;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TechwolfChatProtocol create() => TechwolfChatProtocol._();
  TechwolfChatProtocol createEmptyInstance() => create();
  static $pb.PbList<TechwolfChatProtocol> createRepeated() => $pb.PbList<TechwolfChatProtocol>();
  @$core.pragma('dart2js:noInline')
  static TechwolfChatProtocol getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TechwolfChatProtocol>(create);
  static TechwolfChatProtocol? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get type => $_getIZ(0);
  @$pb.TagNumber(1)
  set type($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<TechwolfMessage> get messages => $_getList(2);

  @$pb.TagNumber(4)
  TechwolfPresence get presence => $_getN(3);
  @$pb.TagNumber(4)
  set presence(TechwolfPresence v) { $_setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasPresence() => $_has(3);
  @$pb.TagNumber(4)
  void clearPresence() => $_clearField(4);
  @$pb.TagNumber(4)
  TechwolfPresence ensurePresence() => $_ensure(3);

  @$pb.TagNumber(8)
  TechwolfMessageRead get messageRead => $_getN(4);
  @$pb.TagNumber(8)
  set messageRead(TechwolfMessageRead v) { $_setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasMessageRead() => $_has(4);
  @$pb.TagNumber(8)
  void clearMessageRead() => $_clearField(8);
  @$pb.TagNumber(8)
  TechwolfMessageRead ensureMessageRead() => $_ensure(4);

  @$pb.TagNumber(10)
  $core.int get domain => $_getIZ(5);
  @$pb.TagNumber(10)
  set domain($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(10)
  $core.bool hasDomain() => $_has(5);
  @$pb.TagNumber(10)
  void clearDomain() => $_clearField(10);
}

class TechwolfMessage extends $pb.GeneratedMessage {
  factory TechwolfMessage({
    TechwolfUser? from,
    TechwolfUser? to,
    $core.int? type,
    $fixnum.Int64? mid,
    $fixnum.Int64? time,
    TechwolfMessageBody? body,
    $core.bool? offline,
    $core.bool? received,
    $core.String? pushText,
    $fixnum.Int64? taskId,
    $fixnum.Int64? cmid,
    $core.int? status,
    $core.int? unCount,
    $core.String? pushSound,
    $core.int? flag,
    $core.List<$core.int>? encryptedBody,
    $core.String? bizId,
    $core.int? bizType,
    $core.String? securityId,
    $fixnum.Int64? quoteId,
  }) {
    final $result = create();
    if (from != null) {
      $result.from = from;
    }
    if (to != null) {
      $result.to = to;
    }
    if (type != null) {
      $result.type = type;
    }
    if (mid != null) {
      $result.mid = mid;
    }
    if (time != null) {
      $result.time = time;
    }
    if (body != null) {
      $result.body = body;
    }
    if (offline != null) {
      $result.offline = offline;
    }
    if (received != null) {
      $result.received = received;
    }
    if (pushText != null) {
      $result.pushText = pushText;
    }
    if (taskId != null) {
      $result.taskId = taskId;
    }
    if (cmid != null) {
      $result.cmid = cmid;
    }
    if (status != null) {
      $result.status = status;
    }
    if (unCount != null) {
      $result.unCount = unCount;
    }
    if (pushSound != null) {
      $result.pushSound = pushSound;
    }
    if (flag != null) {
      $result.flag = flag;
    }
    if (encryptedBody != null) {
      $result.encryptedBody = encryptedBody;
    }
    if (bizId != null) {
      $result.bizId = bizId;
    }
    if (bizType != null) {
      $result.bizType = bizType;
    }
    if (securityId != null) {
      $result.securityId = securityId;
    }
    if (quoteId != null) {
      $result.quoteId = quoteId;
    }
    return $result;
  }
  TechwolfMessage._() : super();
  factory TechwolfMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TechwolfMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TechwolfMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'techwolf'), createEmptyInstance: create)
    ..aOM<TechwolfUser>(1, _omitFieldNames ? '' : 'from', subBuilder: TechwolfUser.create)
    ..aOM<TechwolfUser>(2, _omitFieldNames ? '' : 'to', subBuilder: TechwolfUser.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'type', $pb.PbFieldType.O3)
    ..aInt64(4, _omitFieldNames ? '' : 'mid')
    ..aInt64(5, _omitFieldNames ? '' : 'time')
    ..aOM<TechwolfMessageBody>(6, _omitFieldNames ? '' : 'body', subBuilder: TechwolfMessageBody.create)
    ..aOB(7, _omitFieldNames ? '' : 'offline')
    ..aOB(8, _omitFieldNames ? '' : 'received')
    ..aOS(9, _omitFieldNames ? '' : 'pushText', protoName: 'pushText')
    ..aInt64(10, _omitFieldNames ? '' : 'taskId', protoName: 'taskId')
    ..aInt64(11, _omitFieldNames ? '' : 'cmid')
    ..a<$core.int>(12, _omitFieldNames ? '' : 'status', $pb.PbFieldType.O3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'unCount', $pb.PbFieldType.O3, protoName: 'unCount')
    ..aOS(14, _omitFieldNames ? '' : 'pushSound', protoName: 'pushSound')
    ..a<$core.int>(15, _omitFieldNames ? '' : 'flag', $pb.PbFieldType.O3)
    ..a<$core.List<$core.int>>(16, _omitFieldNames ? '' : 'encryptedBody', $pb.PbFieldType.OY, protoName: 'encryptedBody')
    ..aOS(17, _omitFieldNames ? '' : 'bizId', protoName: 'bizId')
    ..a<$core.int>(18, _omitFieldNames ? '' : 'bizType', $pb.PbFieldType.O3, protoName: 'bizType')
    ..aOS(19, _omitFieldNames ? '' : 'securityId', protoName: 'securityId')
    ..aInt64(20, _omitFieldNames ? '' : 'quoteId', protoName: 'quoteId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfMessage clone() => TechwolfMessage()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfMessage copyWith(void Function(TechwolfMessage) updates) => super.copyWith((message) => updates(message as TechwolfMessage)) as TechwolfMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TechwolfMessage create() => TechwolfMessage._();
  TechwolfMessage createEmptyInstance() => create();
  static $pb.PbList<TechwolfMessage> createRepeated() => $pb.PbList<TechwolfMessage>();
  @$core.pragma('dart2js:noInline')
  static TechwolfMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TechwolfMessage>(create);
  static TechwolfMessage? _defaultInstance;

  @$pb.TagNumber(1)
  TechwolfUser get from => $_getN(0);
  @$pb.TagNumber(1)
  set from(TechwolfUser v) { $_setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasFrom() => $_has(0);
  @$pb.TagNumber(1)
  void clearFrom() => $_clearField(1);
  @$pb.TagNumber(1)
  TechwolfUser ensureFrom() => $_ensure(0);

  @$pb.TagNumber(2)
  TechwolfUser get to => $_getN(1);
  @$pb.TagNumber(2)
  set to(TechwolfUser v) { $_setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTo() => $_has(1);
  @$pb.TagNumber(2)
  void clearTo() => $_clearField(2);
  @$pb.TagNumber(2)
  TechwolfUser ensureTo() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get type => $_getIZ(2);
  @$pb.TagNumber(3)
  set type($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get mid => $_getI64(3);
  @$pb.TagNumber(4)
  set mid($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMid() => $_has(3);
  @$pb.TagNumber(4)
  void clearMid() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get time => $_getI64(4);
  @$pb.TagNumber(5)
  set time($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearTime() => $_clearField(5);

  @$pb.TagNumber(6)
  TechwolfMessageBody get body => $_getN(5);
  @$pb.TagNumber(6)
  set body(TechwolfMessageBody v) { $_setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasBody() => $_has(5);
  @$pb.TagNumber(6)
  void clearBody() => $_clearField(6);
  @$pb.TagNumber(6)
  TechwolfMessageBody ensureBody() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.bool get offline => $_getBF(6);
  @$pb.TagNumber(7)
  set offline($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasOffline() => $_has(6);
  @$pb.TagNumber(7)
  void clearOffline() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get received => $_getBF(7);
  @$pb.TagNumber(8)
  set received($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasReceived() => $_has(7);
  @$pb.TagNumber(8)
  void clearReceived() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get pushText => $_getSZ(8);
  @$pb.TagNumber(9)
  set pushText($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasPushText() => $_has(8);
  @$pb.TagNumber(9)
  void clearPushText() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get taskId => $_getI64(9);
  @$pb.TagNumber(10)
  set taskId($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasTaskId() => $_has(9);
  @$pb.TagNumber(10)
  void clearTaskId() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get cmid => $_getI64(10);
  @$pb.TagNumber(11)
  set cmid($fixnum.Int64 v) { $_setInt64(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasCmid() => $_has(10);
  @$pb.TagNumber(11)
  void clearCmid() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get status => $_getIZ(11);
  @$pb.TagNumber(12)
  set status($core.int v) { $_setSignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasStatus() => $_has(11);
  @$pb.TagNumber(12)
  void clearStatus() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get unCount => $_getIZ(12);
  @$pb.TagNumber(13)
  set unCount($core.int v) { $_setSignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasUnCount() => $_has(12);
  @$pb.TagNumber(13)
  void clearUnCount() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get pushSound => $_getSZ(13);
  @$pb.TagNumber(14)
  set pushSound($core.String v) { $_setString(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasPushSound() => $_has(13);
  @$pb.TagNumber(14)
  void clearPushSound() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.int get flag => $_getIZ(14);
  @$pb.TagNumber(15)
  set flag($core.int v) { $_setSignedInt32(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasFlag() => $_has(14);
  @$pb.TagNumber(15)
  void clearFlag() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.List<$core.int> get encryptedBody => $_getN(15);
  @$pb.TagNumber(16)
  set encryptedBody($core.List<$core.int> v) { $_setBytes(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasEncryptedBody() => $_has(15);
  @$pb.TagNumber(16)
  void clearEncryptedBody() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get bizId => $_getSZ(16);
  @$pb.TagNumber(17)
  set bizId($core.String v) { $_setString(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasBizId() => $_has(16);
  @$pb.TagNumber(17)
  void clearBizId() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.int get bizType => $_getIZ(17);
  @$pb.TagNumber(18)
  set bizType($core.int v) { $_setSignedInt32(17, v); }
  @$pb.TagNumber(18)
  $core.bool hasBizType() => $_has(17);
  @$pb.TagNumber(18)
  void clearBizType() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get securityId => $_getSZ(18);
  @$pb.TagNumber(19)
  set securityId($core.String v) { $_setString(18, v); }
  @$pb.TagNumber(19)
  $core.bool hasSecurityId() => $_has(18);
  @$pb.TagNumber(19)
  void clearSecurityId() => $_clearField(19);

  @$pb.TagNumber(20)
  $fixnum.Int64 get quoteId => $_getI64(19);
  @$pb.TagNumber(20)
  set quoteId($fixnum.Int64 v) { $_setInt64(19, v); }
  @$pb.TagNumber(20)
  $core.bool hasQuoteId() => $_has(19);
  @$pb.TagNumber(20)
  void clearQuoteId() => $_clearField(20);
}

/// 正文。type = content_type(见 docs §10 全表)。文本走 text(f3);
/// 职位卡(type=8)走 jobCard(f10),字段号由抓包还原(docs §21)。
class TechwolfMessageBody extends $pb.GeneratedMessage {
  factory TechwolfMessageBody({
    $core.int? type,
    $core.int? templateId,
    $core.String? text,
    TechwolfJobCard? jobCard,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (templateId != null) {
      $result.templateId = templateId;
    }
    if (text != null) {
      $result.text = text;
    }
    if (jobCard != null) {
      $result.jobCard = jobCard;
    }
    return $result;
  }
  TechwolfMessageBody._() : super();
  factory TechwolfMessageBody.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TechwolfMessageBody.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TechwolfMessageBody', package: const $pb.PackageName(_omitMessageNames ? '' : 'techwolf'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.O3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'templateId', $pb.PbFieldType.O3, protoName: 'templateId')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..aOM<TechwolfJobCard>(10, _omitFieldNames ? '' : 'jobCard', protoName: 'jobCard', subBuilder: TechwolfJobCard.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfMessageBody clone() => TechwolfMessageBody()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfMessageBody copyWith(void Function(TechwolfMessageBody) updates) => super.copyWith((message) => updates(message as TechwolfMessageBody)) as TechwolfMessageBody;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TechwolfMessageBody create() => TechwolfMessageBody._();
  TechwolfMessageBody createEmptyInstance() => create();
  static $pb.PbList<TechwolfMessageBody> createRepeated() => $pb.PbList<TechwolfMessageBody>();
  @$core.pragma('dart2js:noInline')
  static TechwolfMessageBody getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TechwolfMessageBody>(create);
  static TechwolfMessageBody? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get type => $_getIZ(0);
  @$pb.TagNumber(1)
  set type($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get templateId => $_getIZ(1);
  @$pb.TagNumber(2)
  set templateId($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTemplateId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTemplateId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);

  @$pb.TagNumber(10)
  TechwolfJobCard get jobCard => $_getN(3);
  @$pb.TagNumber(10)
  set jobCard(TechwolfJobCard v) { $_setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasJobCard() => $_has(3);
  @$pb.TagNumber(10)
  void clearJobCard() => $_clearField(10);
  @$pb.TagNumber(10)
  TechwolfJobCard ensureJobCard() => $_ensure(3);
}

/// 职位卡片正文(body.f10)。官方聊天页顶部「由你发起的沟通」白卡即渲染此结构。
class TechwolfJobCard extends $pb.GeneratedMessage {
  factory TechwolfJobCard({
    $core.String? title,
    $core.String? brand,
    $core.String? salary,
    $core.String? jumpUrl,
    $fixnum.Int64? jobId,
    $core.String? position,
    $core.String? experience,
    $core.String? degree,
    $core.String? location,
    $core.String? bossTitle,
    TechwolfUser? boss,
    $core.String? footer,
    $core.String? tag,
    $fixnum.Int64? expectId,
  }) {
    final $result = create();
    if (title != null) {
      $result.title = title;
    }
    if (brand != null) {
      $result.brand = brand;
    }
    if (salary != null) {
      $result.salary = salary;
    }
    if (jumpUrl != null) {
      $result.jumpUrl = jumpUrl;
    }
    if (jobId != null) {
      $result.jobId = jobId;
    }
    if (position != null) {
      $result.position = position;
    }
    if (experience != null) {
      $result.experience = experience;
    }
    if (degree != null) {
      $result.degree = degree;
    }
    if (location != null) {
      $result.location = location;
    }
    if (bossTitle != null) {
      $result.bossTitle = bossTitle;
    }
    if (boss != null) {
      $result.boss = boss;
    }
    if (footer != null) {
      $result.footer = footer;
    }
    if (tag != null) {
      $result.tag = tag;
    }
    if (expectId != null) {
      $result.expectId = expectId;
    }
    return $result;
  }
  TechwolfJobCard._() : super();
  factory TechwolfJobCard.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TechwolfJobCard.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TechwolfJobCard', package: const $pb.PackageName(_omitMessageNames ? '' : 'techwolf'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'brand')
    ..aOS(3, _omitFieldNames ? '' : 'salary')
    ..aOS(4, _omitFieldNames ? '' : 'jumpUrl', protoName: 'jumpUrl')
    ..aInt64(5, _omitFieldNames ? '' : 'jobId', protoName: 'jobId')
    ..aOS(6, _omitFieldNames ? '' : 'position')
    ..aOS(7, _omitFieldNames ? '' : 'experience')
    ..aOS(8, _omitFieldNames ? '' : 'degree')
    ..aOS(9, _omitFieldNames ? '' : 'location')
    ..aOS(10, _omitFieldNames ? '' : 'bossTitle', protoName: 'bossTitle')
    ..aOM<TechwolfUser>(11, _omitFieldNames ? '' : 'boss', subBuilder: TechwolfUser.create)
    ..aOS(14, _omitFieldNames ? '' : 'footer')
    ..aOS(15, _omitFieldNames ? '' : 'tag')
    ..aInt64(19, _omitFieldNames ? '' : 'expectId', protoName: 'expectId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfJobCard clone() => TechwolfJobCard()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfJobCard copyWith(void Function(TechwolfJobCard) updates) => super.copyWith((message) => updates(message as TechwolfJobCard)) as TechwolfJobCard;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TechwolfJobCard create() => TechwolfJobCard._();
  TechwolfJobCard createEmptyInstance() => create();
  static $pb.PbList<TechwolfJobCard> createRepeated() => $pb.PbList<TechwolfJobCard>();
  @$core.pragma('dart2js:noInline')
  static TechwolfJobCard getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TechwolfJobCard>(create);
  static TechwolfJobCard? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get brand => $_getSZ(1);
  @$pb.TagNumber(2)
  set brand($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBrand() => $_has(1);
  @$pb.TagNumber(2)
  void clearBrand() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get salary => $_getSZ(2);
  @$pb.TagNumber(3)
  set salary($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSalary() => $_has(2);
  @$pb.TagNumber(3)
  void clearSalary() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get jumpUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set jumpUrl($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasJumpUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearJumpUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get jobId => $_getI64(4);
  @$pb.TagNumber(5)
  set jobId($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasJobId() => $_has(4);
  @$pb.TagNumber(5)
  void clearJobId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get position => $_getSZ(5);
  @$pb.TagNumber(6)
  set position($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPosition() => $_has(5);
  @$pb.TagNumber(6)
  void clearPosition() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get experience => $_getSZ(6);
  @$pb.TagNumber(7)
  set experience($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasExperience() => $_has(6);
  @$pb.TagNumber(7)
  void clearExperience() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get degree => $_getSZ(7);
  @$pb.TagNumber(8)
  set degree($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasDegree() => $_has(7);
  @$pb.TagNumber(8)
  void clearDegree() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get location => $_getSZ(8);
  @$pb.TagNumber(9)
  set location($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasLocation() => $_has(8);
  @$pb.TagNumber(9)
  void clearLocation() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get bossTitle => $_getSZ(9);
  @$pb.TagNumber(10)
  set bossTitle($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasBossTitle() => $_has(9);
  @$pb.TagNumber(10)
  void clearBossTitle() => $_clearField(10);

  @$pb.TagNumber(11)
  TechwolfUser get boss => $_getN(10);
  @$pb.TagNumber(11)
  set boss(TechwolfUser v) { $_setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasBoss() => $_has(10);
  @$pb.TagNumber(11)
  void clearBoss() => $_clearField(11);
  @$pb.TagNumber(11)
  TechwolfUser ensureBoss() => $_ensure(10);

  @$pb.TagNumber(14)
  $core.String get footer => $_getSZ(11);
  @$pb.TagNumber(14)
  set footer($core.String v) { $_setString(11, v); }
  @$pb.TagNumber(14)
  $core.bool hasFooter() => $_has(11);
  @$pb.TagNumber(14)
  void clearFooter() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get tag => $_getSZ(12);
  @$pb.TagNumber(15)
  set tag($core.String v) { $_setString(12, v); }
  @$pb.TagNumber(15)
  $core.bool hasTag() => $_has(12);
  @$pb.TagNumber(15)
  void clearTag() => $_clearField(15);

  @$pb.TagNumber(19)
  $fixnum.Int64 get expectId => $_getI64(13);
  @$pb.TagNumber(19)
  set expectId($fixnum.Int64 v) { $_setInt64(13, v); }
  @$pb.TagNumber(19)
  $core.bool hasExpectId() => $_has(13);
  @$pb.TagNumber(19)
  void clearExpectId() => $_clearField(19);
}

class TechwolfUser extends $pb.GeneratedMessage {
  factory TechwolfUser({
    $fixnum.Int64? uid,
    $core.String? name,
    $core.String? avatar,
    $core.String? company,
    $core.String? headImg,
    $core.int? certification,
    $core.int? source,
  }) {
    final $result = create();
    if (uid != null) {
      $result.uid = uid;
    }
    if (name != null) {
      $result.name = name;
    }
    if (avatar != null) {
      $result.avatar = avatar;
    }
    if (company != null) {
      $result.company = company;
    }
    if (headImg != null) {
      $result.headImg = headImg;
    }
    if (certification != null) {
      $result.certification = certification;
    }
    if (source != null) {
      $result.source = source;
    }
    return $result;
  }
  TechwolfUser._() : super();
  factory TechwolfUser.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TechwolfUser.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TechwolfUser', package: const $pb.PackageName(_omitMessageNames ? '' : 'techwolf'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'uid')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'avatar')
    ..aOS(4, _omitFieldNames ? '' : 'company')
    ..aOS(5, _omitFieldNames ? '' : 'headImg', protoName: 'headImg')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'certification', $pb.PbFieldType.O3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'source', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfUser clone() => TechwolfUser()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfUser copyWith(void Function(TechwolfUser) updates) => super.copyWith((message) => updates(message as TechwolfUser)) as TechwolfUser;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TechwolfUser create() => TechwolfUser._();
  TechwolfUser createEmptyInstance() => create();
  static $pb.PbList<TechwolfUser> createRepeated() => $pb.PbList<TechwolfUser>();
  @$core.pragma('dart2js:noInline')
  static TechwolfUser getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TechwolfUser>(create);
  static TechwolfUser? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get uid => $_getI64(0);
  @$pb.TagNumber(1)
  set uid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get avatar => $_getSZ(2);
  @$pb.TagNumber(3)
  set avatar($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAvatar() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatar() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get company => $_getSZ(3);
  @$pb.TagNumber(4)
  set company($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCompany() => $_has(3);
  @$pb.TagNumber(4)
  void clearCompany() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get headImg => $_getSZ(4);
  @$pb.TagNumber(5)
  set headImg($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasHeadImg() => $_has(4);
  @$pb.TagNumber(5)
  void clearHeadImg() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get certification => $_getIZ(5);
  @$pb.TagNumber(6)
  set certification($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasCertification() => $_has(5);
  @$pb.TagNumber(6)
  void clearCertification() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get source => $_getIZ(6);
  @$pb.TagNumber(7)
  set source($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasSource() => $_has(6);
  @$pb.TagNumber(7)
  void clearSource() => $_clearField(7);
}

/// type=2 鉴权/在线(信封 field 4)。
class TechwolfPresence extends $pb.GeneratedMessage {
  factory TechwolfPresence({
    $core.int? type,
    $fixnum.Int64? uid,
    TechwolfClientInfo? clientInfo,
    TechwolfClientTime? clientTime,
    $fixnum.Int64? lastMessageId,
    $fixnum.Int64? lastGroupMessageId,
    $fixnum.Int64? userId,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (uid != null) {
      $result.uid = uid;
    }
    if (clientInfo != null) {
      $result.clientInfo = clientInfo;
    }
    if (clientTime != null) {
      $result.clientTime = clientTime;
    }
    if (lastMessageId != null) {
      $result.lastMessageId = lastMessageId;
    }
    if (lastGroupMessageId != null) {
      $result.lastGroupMessageId = lastGroupMessageId;
    }
    if (userId != null) {
      $result.userId = userId;
    }
    return $result;
  }
  TechwolfPresence._() : super();
  factory TechwolfPresence.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TechwolfPresence.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TechwolfPresence', package: const $pb.PackageName(_omitMessageNames ? '' : 'techwolf'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.O3)
    ..aInt64(2, _omitFieldNames ? '' : 'uid')
    ..aOM<TechwolfClientInfo>(3, _omitFieldNames ? '' : 'clientInfo', protoName: 'clientInfo', subBuilder: TechwolfClientInfo.create)
    ..aOM<TechwolfClientTime>(4, _omitFieldNames ? '' : 'clientTime', protoName: 'clientTime', subBuilder: TechwolfClientTime.create)
    ..aInt64(5, _omitFieldNames ? '' : 'lastMessageId', protoName: 'lastMessageId')
    ..aInt64(6, _omitFieldNames ? '' : 'lastGroupMessageId', protoName: 'lastGroupMessageId')
    ..aInt64(7, _omitFieldNames ? '' : 'userId', protoName: 'userId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfPresence clone() => TechwolfPresence()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfPresence copyWith(void Function(TechwolfPresence) updates) => super.copyWith((message) => updates(message as TechwolfPresence)) as TechwolfPresence;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TechwolfPresence create() => TechwolfPresence._();
  TechwolfPresence createEmptyInstance() => create();
  static $pb.PbList<TechwolfPresence> createRepeated() => $pb.PbList<TechwolfPresence>();
  @$core.pragma('dart2js:noInline')
  static TechwolfPresence getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TechwolfPresence>(create);
  static TechwolfPresence? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get type => $_getIZ(0);
  @$pb.TagNumber(1)
  set type($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get uid => $_getI64(1);
  @$pb.TagNumber(2)
  set uid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUid() => $_has(1);
  @$pb.TagNumber(2)
  void clearUid() => $_clearField(2);

  @$pb.TagNumber(3)
  TechwolfClientInfo get clientInfo => $_getN(2);
  @$pb.TagNumber(3)
  set clientInfo(TechwolfClientInfo v) { $_setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasClientInfo() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientInfo() => $_clearField(3);
  @$pb.TagNumber(3)
  TechwolfClientInfo ensureClientInfo() => $_ensure(2);

  @$pb.TagNumber(4)
  TechwolfClientTime get clientTime => $_getN(3);
  @$pb.TagNumber(4)
  set clientTime(TechwolfClientTime v) { $_setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasClientTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearClientTime() => $_clearField(4);
  @$pb.TagNumber(4)
  TechwolfClientTime ensureClientTime() => $_ensure(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get lastMessageId => $_getI64(4);
  @$pb.TagNumber(5)
  set lastMessageId($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasLastMessageId() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastMessageId() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get lastGroupMessageId => $_getI64(5);
  @$pb.TagNumber(6)
  set lastGroupMessageId($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasLastGroupMessageId() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastGroupMessageId() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get userId => $_getI64(6);
  @$pb.TagNumber(7)
  set userId($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasUserId() => $_has(6);
  @$pb.TagNumber(7)
  void clearUserId() => $_clearField(7);
}

class TechwolfClientInfo extends $pb.GeneratedMessage {
  factory TechwolfClientInfo({
    $core.String? version,
    $core.String? system,
    $core.String? systemVersion,
    $core.String? model,
    $core.String? uniqid,
    $core.String? network,
    $core.int? appId,
    $core.String? platform,
    $core.String? channel,
    $core.String? ssid,
    $core.String? bssid,
    $core.double? longitude,
    $core.double? latitude,
  }) {
    final $result = create();
    if (version != null) {
      $result.version = version;
    }
    if (system != null) {
      $result.system = system;
    }
    if (systemVersion != null) {
      $result.systemVersion = systemVersion;
    }
    if (model != null) {
      $result.model = model;
    }
    if (uniqid != null) {
      $result.uniqid = uniqid;
    }
    if (network != null) {
      $result.network = network;
    }
    if (appId != null) {
      $result.appId = appId;
    }
    if (platform != null) {
      $result.platform = platform;
    }
    if (channel != null) {
      $result.channel = channel;
    }
    if (ssid != null) {
      $result.ssid = ssid;
    }
    if (bssid != null) {
      $result.bssid = bssid;
    }
    if (longitude != null) {
      $result.longitude = longitude;
    }
    if (latitude != null) {
      $result.latitude = latitude;
    }
    return $result;
  }
  TechwolfClientInfo._() : super();
  factory TechwolfClientInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TechwolfClientInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TechwolfClientInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'techwolf'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'version')
    ..aOS(2, _omitFieldNames ? '' : 'system')
    ..aOS(3, _omitFieldNames ? '' : 'systemVersion', protoName: 'systemVersion')
    ..aOS(4, _omitFieldNames ? '' : 'model')
    ..aOS(5, _omitFieldNames ? '' : 'uniqid')
    ..aOS(6, _omitFieldNames ? '' : 'network')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'appId', $pb.PbFieldType.O3, protoName: 'appId')
    ..aOS(8, _omitFieldNames ? '' : 'platform')
    ..aOS(9, _omitFieldNames ? '' : 'channel')
    ..aOS(10, _omitFieldNames ? '' : 'ssid')
    ..aOS(11, _omitFieldNames ? '' : 'bssid')
    ..a<$core.double>(12, _omitFieldNames ? '' : 'longitude', $pb.PbFieldType.OD)
    ..a<$core.double>(13, _omitFieldNames ? '' : 'latitude', $pb.PbFieldType.OD)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfClientInfo clone() => TechwolfClientInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfClientInfo copyWith(void Function(TechwolfClientInfo) updates) => super.copyWith((message) => updates(message as TechwolfClientInfo)) as TechwolfClientInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TechwolfClientInfo create() => TechwolfClientInfo._();
  TechwolfClientInfo createEmptyInstance() => create();
  static $pb.PbList<TechwolfClientInfo> createRepeated() => $pb.PbList<TechwolfClientInfo>();
  @$core.pragma('dart2js:noInline')
  static TechwolfClientInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TechwolfClientInfo>(create);
  static TechwolfClientInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get version => $_getSZ(0);
  @$pb.TagNumber(1)
  set version($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get system => $_getSZ(1);
  @$pb.TagNumber(2)
  set system($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSystem() => $_has(1);
  @$pb.TagNumber(2)
  void clearSystem() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get systemVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set systemVersion($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSystemVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearSystemVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get model => $_getSZ(3);
  @$pb.TagNumber(4)
  set model($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasModel() => $_has(3);
  @$pb.TagNumber(4)
  void clearModel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get uniqid => $_getSZ(4);
  @$pb.TagNumber(5)
  set uniqid($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasUniqid() => $_has(4);
  @$pb.TagNumber(5)
  void clearUniqid() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get network => $_getSZ(5);
  @$pb.TagNumber(6)
  set network($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasNetwork() => $_has(5);
  @$pb.TagNumber(6)
  void clearNetwork() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get appId => $_getIZ(6);
  @$pb.TagNumber(7)
  set appId($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasAppId() => $_has(6);
  @$pb.TagNumber(7)
  void clearAppId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get platform => $_getSZ(7);
  @$pb.TagNumber(8)
  set platform($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasPlatform() => $_has(7);
  @$pb.TagNumber(8)
  void clearPlatform() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get channel => $_getSZ(8);
  @$pb.TagNumber(9)
  set channel($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasChannel() => $_has(8);
  @$pb.TagNumber(9)
  void clearChannel() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get ssid => $_getSZ(9);
  @$pb.TagNumber(10)
  set ssid($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasSsid() => $_has(9);
  @$pb.TagNumber(10)
  void clearSsid() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get bssid => $_getSZ(10);
  @$pb.TagNumber(11)
  set bssid($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasBssid() => $_has(10);
  @$pb.TagNumber(11)
  void clearBssid() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get longitude => $_getN(11);
  @$pb.TagNumber(12)
  set longitude($core.double v) { $_setDouble(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasLongitude() => $_has(11);
  @$pb.TagNumber(12)
  void clearLongitude() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get latitude => $_getN(12);
  @$pb.TagNumber(13)
  set latitude($core.double v) { $_setDouble(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasLatitude() => $_has(12);
  @$pb.TagNumber(13)
  void clearLatitude() => $_clearField(13);
}

class TechwolfClientTime extends $pb.GeneratedMessage {
  factory TechwolfClientTime({
    $fixnum.Int64? startTime,
    $fixnum.Int64? resumeTime,
    $fixnum.Int64? locateTime,
  }) {
    final $result = create();
    if (startTime != null) {
      $result.startTime = startTime;
    }
    if (resumeTime != null) {
      $result.resumeTime = resumeTime;
    }
    if (locateTime != null) {
      $result.locateTime = locateTime;
    }
    return $result;
  }
  TechwolfClientTime._() : super();
  factory TechwolfClientTime.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TechwolfClientTime.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TechwolfClientTime', package: const $pb.PackageName(_omitMessageNames ? '' : 'techwolf'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'startTime', protoName: 'startTime')
    ..aInt64(2, _omitFieldNames ? '' : 'resumeTime', protoName: 'resumeTime')
    ..aInt64(3, _omitFieldNames ? '' : 'locateTime', protoName: 'locateTime')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfClientTime clone() => TechwolfClientTime()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfClientTime copyWith(void Function(TechwolfClientTime) updates) => super.copyWith((message) => updates(message as TechwolfClientTime)) as TechwolfClientTime;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TechwolfClientTime create() => TechwolfClientTime._();
  TechwolfClientTime createEmptyInstance() => create();
  static $pb.PbList<TechwolfClientTime> createRepeated() => $pb.PbList<TechwolfClientTime>();
  @$core.pragma('dart2js:noInline')
  static TechwolfClientTime getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TechwolfClientTime>(create);
  static TechwolfClientTime? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get startTime => $_getI64(0);
  @$pb.TagNumber(1)
  set startTime($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasStartTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartTime() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get resumeTime => $_getI64(1);
  @$pb.TagNumber(2)
  set resumeTime($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasResumeTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearResumeTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get locateTime => $_getI64(2);
  @$pb.TagNumber(3)
  set locateTime($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLocateTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocateTime() => $_clearField(3);
}

/// type=6 已读回执(信封 field 8)。
class TechwolfMessageRead extends $pb.GeneratedMessage {
  factory TechwolfMessageRead({
    $fixnum.Int64? userId,
    $fixnum.Int64? messageId,
    $fixnum.Int64? readTime,
    $core.bool? sync,
    $core.int? userSource,
    $core.int? ownerSource,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (messageId != null) {
      $result.messageId = messageId;
    }
    if (readTime != null) {
      $result.readTime = readTime;
    }
    if (sync != null) {
      $result.sync = sync;
    }
    if (userSource != null) {
      $result.userSource = userSource;
    }
    if (ownerSource != null) {
      $result.ownerSource = ownerSource;
    }
    return $result;
  }
  TechwolfMessageRead._() : super();
  factory TechwolfMessageRead.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TechwolfMessageRead.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TechwolfMessageRead', package: const $pb.PackageName(_omitMessageNames ? '' : 'techwolf'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId', protoName: 'userId')
    ..aInt64(2, _omitFieldNames ? '' : 'messageId', protoName: 'messageId')
    ..aInt64(3, _omitFieldNames ? '' : 'readTime', protoName: 'readTime')
    ..aOB(4, _omitFieldNames ? '' : 'sync')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'userSource', $pb.PbFieldType.O3, protoName: 'userSource')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'ownerSource', $pb.PbFieldType.O3, protoName: 'ownerSource')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfMessageRead clone() => TechwolfMessageRead()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TechwolfMessageRead copyWith(void Function(TechwolfMessageRead) updates) => super.copyWith((message) => updates(message as TechwolfMessageRead)) as TechwolfMessageRead;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TechwolfMessageRead create() => TechwolfMessageRead._();
  TechwolfMessageRead createEmptyInstance() => create();
  static $pb.PbList<TechwolfMessageRead> createRepeated() => $pb.PbList<TechwolfMessageRead>();
  @$core.pragma('dart2js:noInline')
  static TechwolfMessageRead getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TechwolfMessageRead>(create);
  static TechwolfMessageRead? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get messageId => $_getI64(1);
  @$pb.TagNumber(2)
  set messageId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get readTime => $_getI64(2);
  @$pb.TagNumber(3)
  set readTime($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasReadTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearReadTime() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get sync => $_getBF(3);
  @$pb.TagNumber(4)
  set sync($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSync() => $_has(3);
  @$pb.TagNumber(4)
  void clearSync() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get userSource => $_getIZ(4);
  @$pb.TagNumber(5)
  set userSource($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasUserSource() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserSource() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get ownerSource => $_getIZ(5);
  @$pb.TagNumber(6)
  set ownerSource($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasOwnerSource() => $_has(5);
  @$pb.TagNumber(6)
  void clearOwnerSource() => $_clearField(6);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
