import 'dart:convert';

import 'package:boss_plus/boss_plus.dart';
import 'package:test/test.dart';

void main() {
  const expectCity = 101280100; // 期望城市:广州

  Map<String, dynamic> fp(JobFilter f) =>
      jsonDecode(f.buildFilterParams(expectCity)) as Map<String, dynamic>;

  group('JobFilter.buildFilterParams: switchCity 随是否换城变化', () {
    test('未选城市 → 用期望城市,switchCity=0', () {
      final m = fp(const JobFilter());
      expect(m['cityCode'], '$expectCity');
      expect(m['switchCity'], '0');
    });

    test('选中与期望相同的城市 → 仍算没换城,switchCity=0', () {
      final m = fp(const JobFilter(cityCode: expectCity));
      expect(m['cityCode'], '$expectCity');
      expect(m['switchCity'], '0');
    });

    test('选中其它城市(深圳)→ switchCity=1,服务端才真正按该城市过滤', () {
      final m = fp(const JobFilter(cityCode: 101280600));
      expect(m['cityCode'], '101280600');
      expect(m['switchCity'], '1'); // 回归:恒为 0 时城市过滤失效
    });

    test('选「全国(不限)」→ 也是显式换城,switchCity=1', () {
      final m = fp(const JobFilter(cityCode: 100010000));
      expect(m['cityCode'], '100010000');
      expect(m['switchCity'], '1');
    });

    test('其它筛选项照常带上', () {
      final m = fp(const JobFilter(
          cityCode: 101010100, salary: '405', experience: '104', degree: '203'));
      expect(m['switchCity'], '1');
      expect(m['salary'], '405');
      expect(m['experience'], '[104]');
      expect(m['degree'], '[203]');
    });
  });
}
