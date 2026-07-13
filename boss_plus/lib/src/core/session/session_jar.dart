import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// 会话持久化接口(单账号:只存 token/secretKey 等,不做多用户管理)。
abstract class SessionJar {
  Future<void> save(Map<String, dynamic> session);

  Future<Map<String, dynamic>?> load();

  Future<void> clear();
}

/// 内存实现(测试/一次性 CLI 用)。
class MemorySessionJar implements SessionJar {
  Map<String, dynamic>? _data;

  @override
  Future<void> save(Map<String, dynamic> session) async => _data = session;

  @override
  Future<Map<String, dynamic>?> load() async => _data;

  @override
  Future<void> clear() async => _data = null;
}

/// 文件实现:把会话写到单个 JSON 文件。
class FileSessionJar implements SessionJar {
  FileSessionJar(this.path);

  final String path;

  @override
  Future<void> save(Map<String, dynamic> session) async {
    final f = File(path);
    await Directory(p.dirname(path)).create(recursive: true);
    await f.writeAsString(jsonEncode(session));
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    final f = File(path);
    if (!await f.exists()) return null;
    final txt = await f.readAsString();
    if (txt.trim().isEmpty) return null;
    return jsonDecode(txt) as Map<String, dynamic>;
  }

  @override
  Future<void> clear() async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
