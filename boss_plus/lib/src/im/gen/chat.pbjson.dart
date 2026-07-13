//
//  Generated code. Do not modify.
//  source: chat.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use techwolfChatProtocolDescriptor instead')
const TechwolfChatProtocol$json = {
  '1': 'TechwolfChatProtocol',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'messages', '3': 3, '4': 3, '5': 11, '6': '.techwolf.TechwolfMessage', '10': 'messages'},
    {'1': 'presence', '3': 4, '4': 1, '5': 11, '6': '.techwolf.TechwolfPresence', '10': 'presence'},
    {'1': 'messageRead', '3': 8, '4': 1, '5': 11, '6': '.techwolf.TechwolfMessageRead', '10': 'messageRead'},
    {'1': 'domain', '3': 10, '4': 1, '5': 5, '10': 'domain'},
  ],
};

/// Descriptor for `TechwolfChatProtocol`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List techwolfChatProtocolDescriptor = $convert.base64Decode(
    'ChRUZWNod29sZkNoYXRQcm90b2NvbBISCgR0eXBlGAEgASgFUgR0eXBlEhgKB3ZlcnNpb24YAi'
    'ABKAlSB3ZlcnNpb24SNQoIbWVzc2FnZXMYAyADKAsyGS50ZWNod29sZi5UZWNod29sZk1lc3Nh'
    'Z2VSCG1lc3NhZ2VzEjYKCHByZXNlbmNlGAQgASgLMhoudGVjaHdvbGYuVGVjaHdvbGZQcmVzZW'
    '5jZVIIcHJlc2VuY2USPwoLbWVzc2FnZVJlYWQYCCABKAsyHS50ZWNod29sZi5UZWNod29sZk1l'
    'c3NhZ2VSZWFkUgttZXNzYWdlUmVhZBIWCgZkb21haW4YCiABKAVSBmRvbWFpbg==');

@$core.Deprecated('Use techwolfMessageDescriptor instead')
const TechwolfMessage$json = {
  '1': 'TechwolfMessage',
  '2': [
    {'1': 'from', '3': 1, '4': 1, '5': 11, '6': '.techwolf.TechwolfUser', '10': 'from'},
    {'1': 'to', '3': 2, '4': 1, '5': 11, '6': '.techwolf.TechwolfUser', '10': 'to'},
    {'1': 'type', '3': 3, '4': 1, '5': 5, '10': 'type'},
    {'1': 'mid', '3': 4, '4': 1, '5': 3, '10': 'mid'},
    {'1': 'time', '3': 5, '4': 1, '5': 3, '10': 'time'},
    {'1': 'body', '3': 6, '4': 1, '5': 11, '6': '.techwolf.TechwolfMessageBody', '10': 'body'},
    {'1': 'offline', '3': 7, '4': 1, '5': 8, '10': 'offline'},
    {'1': 'received', '3': 8, '4': 1, '5': 8, '10': 'received'},
    {'1': 'pushText', '3': 9, '4': 1, '5': 9, '10': 'pushText'},
    {'1': 'taskId', '3': 10, '4': 1, '5': 3, '10': 'taskId'},
    {'1': 'cmid', '3': 11, '4': 1, '5': 3, '10': 'cmid'},
    {'1': 'status', '3': 12, '4': 1, '5': 5, '10': 'status'},
    {'1': 'unCount', '3': 13, '4': 1, '5': 5, '10': 'unCount'},
    {'1': 'pushSound', '3': 14, '4': 1, '5': 9, '10': 'pushSound'},
    {'1': 'flag', '3': 15, '4': 1, '5': 5, '10': 'flag'},
    {'1': 'encryptedBody', '3': 16, '4': 1, '5': 12, '10': 'encryptedBody'},
    {'1': 'bizId', '3': 17, '4': 1, '5': 9, '10': 'bizId'},
    {'1': 'bizType', '3': 18, '4': 1, '5': 5, '10': 'bizType'},
    {'1': 'securityId', '3': 19, '4': 1, '5': 9, '10': 'securityId'},
    {'1': 'quoteId', '3': 20, '4': 1, '5': 3, '10': 'quoteId'},
  ],
};

/// Descriptor for `TechwolfMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List techwolfMessageDescriptor = $convert.base64Decode(
    'Cg9UZWNod29sZk1lc3NhZ2USKgoEZnJvbRgBIAEoCzIWLnRlY2h3b2xmLlRlY2h3b2xmVXNlcl'
    'IEZnJvbRImCgJ0bxgCIAEoCzIWLnRlY2h3b2xmLlRlY2h3b2xmVXNlclICdG8SEgoEdHlwZRgD'
    'IAEoBVIEdHlwZRIQCgNtaWQYBCABKANSA21pZBISCgR0aW1lGAUgASgDUgR0aW1lEjEKBGJvZH'
    'kYBiABKAsyHS50ZWNod29sZi5UZWNod29sZk1lc3NhZ2VCb2R5UgRib2R5EhgKB29mZmxpbmUY'
    'ByABKAhSB29mZmxpbmUSGgoIcmVjZWl2ZWQYCCABKAhSCHJlY2VpdmVkEhoKCHB1c2hUZXh0GA'
    'kgASgJUghwdXNoVGV4dBIWCgZ0YXNrSWQYCiABKANSBnRhc2tJZBISCgRjbWlkGAsgASgDUgRj'
    'bWlkEhYKBnN0YXR1cxgMIAEoBVIGc3RhdHVzEhgKB3VuQ291bnQYDSABKAVSB3VuQ291bnQSHA'
    'oJcHVzaFNvdW5kGA4gASgJUglwdXNoU291bmQSEgoEZmxhZxgPIAEoBVIEZmxhZxIkCg1lbmNy'
    'eXB0ZWRCb2R5GBAgASgMUg1lbmNyeXB0ZWRCb2R5EhQKBWJpeklkGBEgASgJUgViaXpJZBIYCg'
    'diaXpUeXBlGBIgASgFUgdiaXpUeXBlEh4KCnNlY3VyaXR5SWQYEyABKAlSCnNlY3VyaXR5SWQS'
    'GAoHcXVvdGVJZBgUIAEoA1IHcXVvdGVJZA==');

@$core.Deprecated('Use techwolfMessageBodyDescriptor instead')
const TechwolfMessageBody$json = {
  '1': 'TechwolfMessageBody',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'templateId', '3': 2, '4': 1, '5': 5, '10': 'templateId'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
    {'1': 'jobCard', '3': 10, '4': 1, '5': 11, '6': '.techwolf.TechwolfJobCard', '10': 'jobCard'},
  ],
};

/// Descriptor for `TechwolfMessageBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List techwolfMessageBodyDescriptor = $convert.base64Decode(
    'ChNUZWNod29sZk1lc3NhZ2VCb2R5EhIKBHR5cGUYASABKAVSBHR5cGUSHgoKdGVtcGxhdGVJZB'
    'gCIAEoBVIKdGVtcGxhdGVJZBISCgR0ZXh0GAMgASgJUgR0ZXh0EjMKB2pvYkNhcmQYCiABKAsy'
    'GS50ZWNod29sZi5UZWNod29sZkpvYkNhcmRSB2pvYkNhcmQ=');

@$core.Deprecated('Use techwolfJobCardDescriptor instead')
const TechwolfJobCard$json = {
  '1': 'TechwolfJobCard',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'brand', '3': 2, '4': 1, '5': 9, '10': 'brand'},
    {'1': 'salary', '3': 3, '4': 1, '5': 9, '10': 'salary'},
    {'1': 'jumpUrl', '3': 4, '4': 1, '5': 9, '10': 'jumpUrl'},
    {'1': 'jobId', '3': 5, '4': 1, '5': 3, '10': 'jobId'},
    {'1': 'position', '3': 6, '4': 1, '5': 9, '10': 'position'},
    {'1': 'experience', '3': 7, '4': 1, '5': 9, '10': 'experience'},
    {'1': 'degree', '3': 8, '4': 1, '5': 9, '10': 'degree'},
    {'1': 'location', '3': 9, '4': 1, '5': 9, '10': 'location'},
    {'1': 'bossTitle', '3': 10, '4': 1, '5': 9, '10': 'bossTitle'},
    {'1': 'boss', '3': 11, '4': 1, '5': 11, '6': '.techwolf.TechwolfUser', '10': 'boss'},
    {'1': 'footer', '3': 14, '4': 1, '5': 9, '10': 'footer'},
    {'1': 'tag', '3': 15, '4': 1, '5': 9, '10': 'tag'},
    {'1': 'expectId', '3': 19, '4': 1, '5': 3, '10': 'expectId'},
  ],
};

/// Descriptor for `TechwolfJobCard`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List techwolfJobCardDescriptor = $convert.base64Decode(
    'Cg9UZWNod29sZkpvYkNhcmQSFAoFdGl0bGUYASABKAlSBXRpdGxlEhQKBWJyYW5kGAIgASgJUg'
    'VicmFuZBIWCgZzYWxhcnkYAyABKAlSBnNhbGFyeRIYCgdqdW1wVXJsGAQgASgJUgdqdW1wVXJs'
    'EhQKBWpvYklkGAUgASgDUgVqb2JJZBIaCghwb3NpdGlvbhgGIAEoCVIIcG9zaXRpb24SHgoKZX'
    'hwZXJpZW5jZRgHIAEoCVIKZXhwZXJpZW5jZRIWCgZkZWdyZWUYCCABKAlSBmRlZ3JlZRIaCghs'
    'b2NhdGlvbhgJIAEoCVIIbG9jYXRpb24SHAoJYm9zc1RpdGxlGAogASgJUglib3NzVGl0bGUSKg'
    'oEYm9zcxgLIAEoCzIWLnRlY2h3b2xmLlRlY2h3b2xmVXNlclIEYm9zcxIWCgZmb290ZXIYDiAB'
    'KAlSBmZvb3RlchIQCgN0YWcYDyABKAlSA3RhZxIaCghleHBlY3RJZBgTIAEoA1IIZXhwZWN0SW'
    'Q=');

@$core.Deprecated('Use techwolfUserDescriptor instead')
const TechwolfUser$json = {
  '1': 'TechwolfUser',
  '2': [
    {'1': 'uid', '3': 1, '4': 1, '5': 3, '10': 'uid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'avatar', '3': 3, '4': 1, '5': 9, '10': 'avatar'},
    {'1': 'company', '3': 4, '4': 1, '5': 9, '10': 'company'},
    {'1': 'headImg', '3': 5, '4': 1, '5': 9, '10': 'headImg'},
    {'1': 'certification', '3': 6, '4': 1, '5': 5, '10': 'certification'},
    {'1': 'source', '3': 7, '4': 1, '5': 5, '10': 'source'},
  ],
};

/// Descriptor for `TechwolfUser`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List techwolfUserDescriptor = $convert.base64Decode(
    'CgxUZWNod29sZlVzZXISEAoDdWlkGAEgASgDUgN1aWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIWCg'
    'ZhdmF0YXIYAyABKAlSBmF2YXRhchIYCgdjb21wYW55GAQgASgJUgdjb21wYW55EhgKB2hlYWRJ'
    'bWcYBSABKAlSB2hlYWRJbWcSJAoNY2VydGlmaWNhdGlvbhgGIAEoBVINY2VydGlmaWNhdGlvbh'
    'IWCgZzb3VyY2UYByABKAVSBnNvdXJjZQ==');

@$core.Deprecated('Use techwolfPresenceDescriptor instead')
const TechwolfPresence$json = {
  '1': 'TechwolfPresence',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'uid', '3': 2, '4': 1, '5': 3, '10': 'uid'},
    {'1': 'clientInfo', '3': 3, '4': 1, '5': 11, '6': '.techwolf.TechwolfClientInfo', '10': 'clientInfo'},
    {'1': 'clientTime', '3': 4, '4': 1, '5': 11, '6': '.techwolf.TechwolfClientTime', '10': 'clientTime'},
    {'1': 'lastMessageId', '3': 5, '4': 1, '5': 3, '10': 'lastMessageId'},
    {'1': 'lastGroupMessageId', '3': 6, '4': 1, '5': 3, '10': 'lastGroupMessageId'},
    {'1': 'userId', '3': 7, '4': 1, '5': 3, '10': 'userId'},
  ],
};

/// Descriptor for `TechwolfPresence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List techwolfPresenceDescriptor = $convert.base64Decode(
    'ChBUZWNod29sZlByZXNlbmNlEhIKBHR5cGUYASABKAVSBHR5cGUSEAoDdWlkGAIgASgDUgN1aW'
    'QSPAoKY2xpZW50SW5mbxgDIAEoCzIcLnRlY2h3b2xmLlRlY2h3b2xmQ2xpZW50SW5mb1IKY2xp'
    'ZW50SW5mbxI8CgpjbGllbnRUaW1lGAQgASgLMhwudGVjaHdvbGYuVGVjaHdvbGZDbGllbnRUaW'
    '1lUgpjbGllbnRUaW1lEiQKDWxhc3RNZXNzYWdlSWQYBSABKANSDWxhc3RNZXNzYWdlSWQSLgoS'
    'bGFzdEdyb3VwTWVzc2FnZUlkGAYgASgDUhJsYXN0R3JvdXBNZXNzYWdlSWQSFgoGdXNlcklkGA'
    'cgASgDUgZ1c2VySWQ=');

@$core.Deprecated('Use techwolfClientInfoDescriptor instead')
const TechwolfClientInfo$json = {
  '1': 'TechwolfClientInfo',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 9, '10': 'version'},
    {'1': 'system', '3': 2, '4': 1, '5': 9, '10': 'system'},
    {'1': 'systemVersion', '3': 3, '4': 1, '5': 9, '10': 'systemVersion'},
    {'1': 'model', '3': 4, '4': 1, '5': 9, '10': 'model'},
    {'1': 'uniqid', '3': 5, '4': 1, '5': 9, '10': 'uniqid'},
    {'1': 'network', '3': 6, '4': 1, '5': 9, '10': 'network'},
    {'1': 'appId', '3': 7, '4': 1, '5': 5, '10': 'appId'},
    {'1': 'platform', '3': 8, '4': 1, '5': 9, '10': 'platform'},
    {'1': 'channel', '3': 9, '4': 1, '5': 9, '10': 'channel'},
    {'1': 'ssid', '3': 10, '4': 1, '5': 9, '10': 'ssid'},
    {'1': 'bssid', '3': 11, '4': 1, '5': 9, '10': 'bssid'},
    {'1': 'longitude', '3': 12, '4': 1, '5': 1, '10': 'longitude'},
    {'1': 'latitude', '3': 13, '4': 1, '5': 1, '10': 'latitude'},
  ],
};

/// Descriptor for `TechwolfClientInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List techwolfClientInfoDescriptor = $convert.base64Decode(
    'ChJUZWNod29sZkNsaWVudEluZm8SGAoHdmVyc2lvbhgBIAEoCVIHdmVyc2lvbhIWCgZzeXN0ZW'
    '0YAiABKAlSBnN5c3RlbRIkCg1zeXN0ZW1WZXJzaW9uGAMgASgJUg1zeXN0ZW1WZXJzaW9uEhQK'
    'BW1vZGVsGAQgASgJUgVtb2RlbBIWCgZ1bmlxaWQYBSABKAlSBnVuaXFpZBIYCgduZXR3b3JrGA'
    'YgASgJUgduZXR3b3JrEhQKBWFwcElkGAcgASgFUgVhcHBJZBIaCghwbGF0Zm9ybRgIIAEoCVII'
    'cGxhdGZvcm0SGAoHY2hhbm5lbBgJIAEoCVIHY2hhbm5lbBISCgRzc2lkGAogASgJUgRzc2lkEh'
    'QKBWJzc2lkGAsgASgJUgVic3NpZBIcCglsb25naXR1ZGUYDCABKAFSCWxvbmdpdHVkZRIaCghs'
    'YXRpdHVkZRgNIAEoAVIIbGF0aXR1ZGU=');

@$core.Deprecated('Use techwolfClientTimeDescriptor instead')
const TechwolfClientTime$json = {
  '1': 'TechwolfClientTime',
  '2': [
    {'1': 'startTime', '3': 1, '4': 1, '5': 3, '10': 'startTime'},
    {'1': 'resumeTime', '3': 2, '4': 1, '5': 3, '10': 'resumeTime'},
    {'1': 'locateTime', '3': 3, '4': 1, '5': 3, '10': 'locateTime'},
  ],
};

/// Descriptor for `TechwolfClientTime`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List techwolfClientTimeDescriptor = $convert.base64Decode(
    'ChJUZWNod29sZkNsaWVudFRpbWUSHAoJc3RhcnRUaW1lGAEgASgDUglzdGFydFRpbWUSHgoKcm'
    'VzdW1lVGltZRgCIAEoA1IKcmVzdW1lVGltZRIeCgpsb2NhdGVUaW1lGAMgASgDUgpsb2NhdGVU'
    'aW1l');

@$core.Deprecated('Use techwolfMessageReadDescriptor instead')
const TechwolfMessageRead$json = {
  '1': 'TechwolfMessageRead',
  '2': [
    {'1': 'userId', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'messageId', '3': 2, '4': 1, '5': 3, '10': 'messageId'},
    {'1': 'readTime', '3': 3, '4': 1, '5': 3, '10': 'readTime'},
    {'1': 'sync', '3': 4, '4': 1, '5': 8, '10': 'sync'},
    {'1': 'userSource', '3': 5, '4': 1, '5': 5, '10': 'userSource'},
    {'1': 'ownerSource', '3': 6, '4': 1, '5': 5, '10': 'ownerSource'},
  ],
};

/// Descriptor for `TechwolfMessageRead`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List techwolfMessageReadDescriptor = $convert.base64Decode(
    'ChNUZWNod29sZk1lc3NhZ2VSZWFkEhYKBnVzZXJJZBgBIAEoA1IGdXNlcklkEhwKCW1lc3NhZ2'
    'VJZBgCIAEoA1IJbWVzc2FnZUlkEhoKCHJlYWRUaW1lGAMgASgDUghyZWFkVGltZRISCgRzeW5j'
    'GAQgASgIUgRzeW5jEh4KCnVzZXJTb3VyY2UYBSABKAVSCnVzZXJTb3VyY2USIAoLb3duZXJTb3'
    'VyY2UYBiABKAVSC293bmVyU291cmNl');

