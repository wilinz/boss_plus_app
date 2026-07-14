import 'package:boss_plus_app/home/haitou_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activeRank: BOSS 活跃描述分级', () {
    test('由近到远单调递增', () {
      expect(activeRank('在线'), 0);
      expect(activeRank('刚刚活跃'), 1);
      expect(activeRank('今日活跃'), 2);
      expect(activeRank('今天活跃'), 2);
      expect(activeRank('3日内活跃'), 3);
      expect(activeRank('本周活跃'), 4);
      expect(activeRank('本月活跃'), 5); // 关键:不再被含「月」误判为久未活跃
      expect(activeRank('近1月活跃'), 5);
      expect(activeRank('一个月内活跃'), 5);
      // 关键回归:两个月/2个月内活跃应归「数月档」(6),不能被当成本月档而放行
      expect(activeRank('两个月内活跃'), 6);
      expect(activeRank('2个月内活跃'), 6);
      expect(activeRank('近2月活跃'), 6);
      expect(activeRank('近3月活跃'), 6);
      expect(activeRank('数月前活跃'), 6);
      expect(activeRank('半年内活跃'), 7);
      expect(activeRank('半年前活跃'), 8);
      expect(activeRank('1年内活跃'), 9);
      expect(activeRank('1年前活跃'), 10);
      expect(activeRank(''), -1); // 未知
      expect(activeRank('神秘话术'), -1); // 无法识别
    });

    test('阈值语义:本月档(maxRank=5)放行本月及更近,过滤更久', () {
      const month = 5; // 本月内
      bool pass(String d) {
        final r = activeRank(d);
        return r < 0 || r <= month;
      }

      // 放行
      for (final d in ['在线', '刚刚活跃', '今日活跃', '3日内活跃', '本周活跃', '本月活跃', '近1月活跃']) {
        expect(pass(d), isTrue, reason: '$d 应放行');
      }
      // 过滤(含两个月/2个月:本月档放行不了它们)
      for (final d in ['两个月内活跃', '2个月内活跃', '近3月活跃', '半年内活跃', '半年前活跃', '1年前活跃']) {
        expect(pass(d), isFalse, reason: '$d 应过滤');
      }
    });

    test('阈值语义:今日档(maxRank=2)只放行今日及更近', () {
      const today = 2;
      bool pass(String d) => activeRank(d) <= today && activeRank(d) >= 0;
      expect(pass('今日活跃'), isTrue);
      expect(pass('刚刚活跃'), isTrue);
      expect(pass('本周活跃'), isFalse);
      expect(pass('本月活跃'), isFalse);
    });
  });
}
