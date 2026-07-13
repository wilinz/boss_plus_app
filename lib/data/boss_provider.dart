import 'dart:io';

import 'package:boss_plus/boss_plus.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import 'package:path/path.dart' as p;

import 'device_config_store.dart';

/// 多账号 Boss 客户端持有者(懒加载):设备指纹与会话都**按用户名(登录手机号)分桶**。
///
/// 当前绑定用户名 [_activeUser] 决定用哪套设备指纹(见 [DeviceConfigStore])和哪个
/// 会话文件(`boss_session_<key>.json`)。绑定关系持久化到 `boss_active_user.json`,
/// 重启后自动恢复上次登录的号。旧单文件 `boss_session.json` 首次运行迁移进默认桶。
class BossProvider {
  BossProvider._();
  static final BossProvider instance = BossProvider._();

  static const _legacySession = 'boss_session.json';
  static const _activeUserFile = 'boss_active_user.json';
  static const _defaultKey = '__default__';

  Boss? _boss;
  String? _activeUser;
  bool _restored = false;
  String? _dirPath;

  /// 当前绑定的用户名(登录手机号)。null = 默认桶。
  String? get activeUser => _activeUser;

  Future<String> get _dir async =>
      _dirPath ??= (await getApplicationDocumentsDirectory()).path;

  /// 用户名 → 文件名安全 key(手机号是数字,默认桶用常量;其余非法字符转 `_`)。
  String _key(String? u) => (u == null || u.isEmpty)
      ? _defaultKey
      : u.replaceAll(RegExp(r'[^0-9A-Za-z_]'), '_');

  String _sessionFile(String? u) => 'boss_session_${_key(u)}.json';

  /// 恢复上次绑定的用户名(幂等),并把旧单会话文件迁移进默认桶。
  Future<void> _ensureRestored() async {
    if (_restored) return;
    _restored = true;
    final dir = await _dir;
    // 迁移旧单会话 → 默认桶(仅当默认桶还没有会话)。
    final legacy = File(p.join(dir, _legacySession));
    final defaultSession = File(p.join(dir, _sessionFile(null)));
    if (await legacy.exists() && !await defaultSession.exists()) {
      await legacy.copy(defaultSession.path);
    }
    final saved = await FileSessionJar(p.join(dir, _activeUserFile)).load();
    final u = saved?['user'] as String?;
    _activeUser = (u != null && u.isNotEmpty) ? u : null;
  }

  Future<Boss> get() async {
    await _ensureRestored();
    if (_boss != null) return _boss!;
    final dir = await _dir;
    final appConfig = await DeviceConfigStore.instance.get(username: _activeUser);
    _boss = await Boss.newInstance(
      appConfig: appConfig,
      cookieJar: CookieJar(),
      sessionJar: FileSessionJar(p.join(dir, _sessionFile(_activeUser))),
    );
    return _boss!;
  }

  /// 绑定当前用户名(手机号):变化时持久化绑定并丢弃客户端,下次 [get] 用该用户的
  /// 设备指纹 + 会话重建。
  Future<void> setActiveUser(String? username) async {
    await _ensureRestored();
    final u = (username == null || username.trim().isEmpty) ? null : username.trim();
    if (u != _activeUser) {
      _activeUser = u;
      await FileSessionJar(p.join(await _dir, _activeUserFile))
          .save({'user': _activeUser ?? ''});
      reset();
    }
  }

  /// 丢弃当前客户端,使下次 [get] 用最新的设备指纹/会话重建。
  void reset() => _boss = null;

  /// 删除某用户名(手机号)的会话文件(删除账号时调用)。
  Future<void> deleteSession(String? username) async {
    final f = File(p.join(await _dir, _sessionFile(username)));
    if (await f.exists()) await f.delete();
  }
}
