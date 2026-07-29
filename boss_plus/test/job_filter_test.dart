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

    test('显式选中与期望相同的城市 → 也算选了城市,switchCity=1', () {
      final m = fp(const JobFilter(cityCode: expectCity));
      expect(m['cityCode'], '$expectCity');
      expect(m['switchCity'], '1'); // 只看是否显式选城,不与期望城市比较
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

    test('选中期望城市 + 推荐排序 → 实发最新排序(否则服务端忽略城市过滤)', () {
      const f = JobFilter(sortType: 0, cityCode: expectCity);
      expect(f.effectiveSortType(expectCity), 1);
    });

    test('其它情况保持用户所选排序', () {
      // 非期望城市:推荐排序本就生效,不改
      expect(const JobFilter(sortType: 0, cityCode: 101280600)
          .effectiveSortType(expectCity), 0);
      // 没选城市:不改
      expect(const JobFilter(sortType: 0).effectiveSortType(expectCity), 0);
      // 用户本就选了最新:不变
      expect(const JobFilter(sortType: 1, cityCode: expectCity)
          .effectiveSortType(expectCity), 1);
    });

    test('copyWith 传 null 可清空城市(回到全国),不传则保持', () {
      const picked = JobFilter(cityCode: 101280600, cityName: '深圳');
      // 清空 → 回到「没选城市」
      final cleared = picked.copyWith(cityCode: null, cityName: null);
      expect(cleared.cityCode, isNull);
      expect(cleared.cityName, isNull);
      expect(fp(cleared)['switchCity'], '0');
      expect(fp(cleared)['cityCode'], '$expectCity'); // 回落期望城市
      // 只改排序时城市保持不变
      final resorted = picked.copyWith(sortType: 1);
      expect(resorted.cityCode, 101280600);
      expect(resorted.cityName, '深圳');
    });

    test('其它筛选项照常带上', () {
      final m = fp(const JobFilter(
          cityCode: 101010100, salary: '405', experience: ['104'], degree: '203'));
      expect(m['switchCity'], '1');
      expect(m['salary'], '405');
      expect(m['experience'], '104');
      expect(m['degree'], '203');
    });

    test('经验多选:发数组「或」匹配;空则不带 experience', () {
      // 在校生 + 应届生
      expect(fp(const JobFilter(experience: ['108', '102']))['experience'],
          '108,102');
      // 空 = 不限,不带该字段
      expect(fp(const JobFilter()).containsKey('experience'), isFalse);
      // copyWith 传空列表可清空
      const picked = JobFilter(experience: ['104']);
      expect(fp(picked.copyWith(experience: const []))
          .containsKey('experience'), isFalse);
    });
  });
}
