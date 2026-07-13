import 'dart:convert';
import 'dart:io';

import 'package:boss_plus_app/data/device_config_store.dart';
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

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('devcfg');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    await DeviceProfileRepo.instance.load();
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('per-username bucketing: distinct, stable, persisted', () async {
    final store = DeviceConfigStore.instance;

    final a1 = await store.get(username: '13800000001');
    final a2 = await store.get(username: '13800000001');
    final b1 = await store.get(username: '13800000002');

    // 同一手机号复用同一台设备,换号各自独立。
    expect(a1.uniqid, a2.uniqid, reason: '同号应稳定复用');
    expect(a1.uniqid, isNot(b1.uniqid), reason: '不同号应各自独立');

    // 落盘为分桶结构,含两个 key。
    final file = File(p.join(tmp.path, 'boss_devices.json'));
    expect(await file.exists(), isTrue);
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final profiles = (json['profiles'] as Map).cast<String, dynamic>();
    expect(profiles.keys, containsAll(['13800000001', '13800000002']));

    // 编辑保存只影响对应桶。
    final edited = a1.copyWith(model: 'EDITED-MODEL');
    await store.save(edited, username: '13800000001');
    final a3 = await store.get(username: '13800000001');
    expect(a3.model, 'EDITED-MODEL');
    final b2 = await store.get(username: '13800000002');
    expect(b2.model, b1.model, reason: '另一桶不受影响');
  });
}
