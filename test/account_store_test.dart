import 'dart:convert';
import 'dart:io';

import 'package:boss_plus_app/data/account_store.dart';
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

  test('account registry: add(dedup) / updateProfile / remove / persist',
      () async {
    final tmp = await Directory.systemTemp.createTemp('acct');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    final store = AccountStore.instance;

    await store.add('13800000001');
    await store.add('13800000001'); // 去重
    await store.add('13800000002');
    expect(store.accounts.map((a) => a.mobile),
        ['13800000001', '13800000002']);

    await store.updateProfile('13800000001', name: '小明', avatar: 'http://a');
    final a1 = store.accounts.firstWhere((a) => a.mobile == '13800000001');
    expect(a1.name, '小明');
    expect(a1.avatar, 'http://a');

    // 落盘含两个账号 + 资料。
    final file = File(p.join(tmp.path, 'boss_accounts.json'));
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final saved = (json['accounts'] as List).cast<Map<String, dynamic>>();
    expect(saved.length, 2);
    expect(saved.first['name'], '小明');

    await store.remove('13800000001');
    expect(store.accounts.map((a) => a.mobile), ['13800000002']);

    await tmp.delete(recursive: true);
  });
}
