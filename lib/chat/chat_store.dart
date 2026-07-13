import 'dart:convert';
import 'dart:io';

import 'package:boss_plus/boss_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

/// 聊天本地存储:按账号(uid)持久化会话列表、每会话最近消息、未读数。
///
/// 单 JSON 文件(`chat_store_<uid>.json`),内存持有全量、变更即写盘。数据量小
/// (仅文字/系统消息预览,每会话截断到最近 60 条),够用且零额外依赖(复用 path_provider)。
class ChatStore {
  ChatStore._();
  static final ChatStore instance = ChatStore._();

  File? _file;
  Map<String, dynamic> _data = {
    'conversations': <dynamic>[],
    'messages': <String, dynamic>{},
    'lastRead': <String, dynamic>{}, // peer -> 已读到的最大 msgId(未读水位)
  };

  /// 绑定账号并载入本地数据(登录/连接后调用)。
  Future<void> init(int uid) async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File(p.join(dir.path, 'chat_store_$uid.json'));
    if (await _file!.exists()) {
      try {
        final m = jsonDecode(await _file!.readAsString());
        if (m is Map<String, dynamic>) _data = m;
      } catch (_) {}
    }
  }

  Future<void> _flush() async {
    final f = _file;
    if (f == null) return;
    try {
      await f.writeAsString(jsonEncode(_data));
    } catch (_) {}
  }

  // ---- 会话列表 ----
  List<Map<String, dynamic>> get conversations =>
      ((_data['conversations'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  Future<void> saveConversations(List<Map<String, dynamic>> convs) async {
    _data['conversations'] = convs;
    await _flush();
  }

  // ---- 已读水位(peer -> 已读到的最大 msgId) ----
  Map<int, int> get lastRead {
    final m = (_data['lastRead'] as Map?) ?? const {};
    final out = <int, int>{};
    m.forEach((k, v) {
      final id = int.tryParse('$k');
      if (id != null) out[id] = (v as num?)?.toInt() ?? 0;
    });
    return out;
  }

  Future<void> saveLastRead(Map<int, int> lastRead) async {
    _data['lastRead'] = lastRead.map((k, v) => MapEntry('$k', v));
    await _flush();
  }

  // ---- 每会话消息 ----
  List<ImMessage> messages(int friendId) {
    final m = (_data['messages'] as Map?)?['$friendId'];
    if (m is! List) return const [];
    return m.whereType<Map>().map((e) => msgFromJson(e)).toList();
  }

  Future<void> saveMessages(int friendId, List<ImMessage> msgs) async {
    final capped =
        msgs.length > 60 ? msgs.sublist(msgs.length - 60) : msgs;
    final all = Map<String, dynamic>.from((_data['messages'] as Map?) ?? {});
    all['$friendId'] = capped.map(msgToJson).toList();
    _data['messages'] = all;
    await _flush();
  }

  // ---- ImMessage <-> JSON(只存展示所需字段;jobCard 等复杂体不缓存,靠 HTTP 补) ----
  static Map<String, dynamic> msgToJson(ImMessage m) => {
        'f': m.fromUid,
        't': m.toUid,
        'ct': m.contentType,
        'txt': m.text,
        'push': m.pushText,
        'mid': m.msgId,
        'cmid': m.clientMsgId,
        'ts': m.time,
        'fn': m.fromName,
      };

  static ImMessage msgFromJson(Map m) => ImMessage(
        fromUid: (m['f'] as num?)?.toInt() ?? 0,
        toUid: (m['t'] as num?)?.toInt() ?? 0,
        contentType: (m['ct'] as num?)?.toInt() ?? ContentType.text,
        text: m['txt'] as String?,
        pushText: m['push'] as String?,
        msgId: (m['mid'] as num?)?.toInt() ?? 0,
        clientMsgId: (m['cmid'] as num?)?.toInt() ?? 0,
        time: (m['ts'] as num?)?.toInt() ?? 0,
        fromName: m['fn'] as String?,
      );
}
