import 'dart:math';

import 'package:boss_plus_app/data/device_profile_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads embedded device library and picks from it', () async {
    final repo = DeviceProfileRepo.instance;
    await repo.load();

    expect(repo.isLoaded, isTrue);
    expect(repo.count, 1388);

    // 确定性挑选:同一随机源产出稳定结果。
    final p = repo.pickWeighted(Random(42));
    expect(p, isNotNull);
    expect(p!.manufacturer, isNotEmpty);
    expect(p.model, isNotEmpty);
    expect(p.osVersion, isNotEmpty);

    // 加权分布合理:高权重厂商(vivo/Xiaomi)应在大量抽样中占多数。
    final counts = <String, int>{};
    final r = Random(1);
    for (var i = 0; i < 5000; i++) {
      final d = repo.pickWeighted(r)!;
      counts[d.manufacturer] = (counts[d.manufacturer] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    expect(['vivo', 'Xiaomi'].contains(top.key), isTrue,
        reason: 'top manufacturer was ${top.key}');
  });
}
