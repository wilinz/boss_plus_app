import 'dart:convert';
import 'dart:io';

import 'package:boss_plus_app/data/boss_provider.dart';
import 'package:boss_plus_app/data/device_profile_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.dir);
  final String dir;
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('session bucketed by username: migrate, isolate, remember active',
      () async {
    final tmp = await Directory.systemTemp.createTemp('bossprov');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    await DeviceProfileRepo.instance.load();
    File f(String n) => File(p.join(tmp.path, n));

    // 旧单会话文件(已登录)存在 → 应迁移进默认桶并保持登录态。
    await f('boss_session.json')
        .writeAsString(jsonEncode({'secretKey': 'legacy-sk', 'token2': 't'}));

    final prov = BossProvider.instance;
    final b0 = await prov.get();
    expect(b0.loggedIn, isTrue, reason: '默认桶应继承旧会话');
    expect(await f('boss_session___default__.json').exists(), isTrue);
    expect(prov.activeUser, isNull);

    // 切到手机号 A:新桶、无会话 → 未登录;绑定被持久化。
    await prov.setActiveUser('13800000001');
    final bA = await prov.get();
    expect(bA.loggedIn, isFalse, reason: 'A 号还没登录');
    final active = jsonDecode(
        await f('boss_active_user.json').readAsString()) as Map<String, dynamic>;
    expect(active['user'], '13800000001');

    // 给 A 号写入会话 → 重建后 A 已登录,默认桶不受影响。
    prov.reset();
    await f('boss_session_13800000001.json')
        .writeAsString(jsonEncode({'secretKey': 'A-sk', 'token2': 't'}));
    final bA2 = await prov.get();
    expect(bA2.loggedIn, isTrue);

    // 切回默认桶:仍是旧会话(隔离成立)。
    await prov.setActiveUser(null);
    final bDef = await prov.get();
    expect(bDef.loggedIn, isTrue);

    await tmp.delete(recursive: true);
  });
}
