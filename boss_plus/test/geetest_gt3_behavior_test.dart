import 'package:boss_plus/src/core/geetest_gt3_behavior.dart';
import 'package:test/test.dart';

/// 校验 precheck 行为包的位打包函数与 Python 参考(function.py)一致。
void main() {
  final ee = <List<dynamic>>[
    ['move', 303, 418, 1000, 'pointermove'],
    ['move', 300, 419, 1030, 'pointermove'],
    ['move', 295, 423, 1070, 'pointermove'],
    ['move', 290, 432, 1120, 'pointermove'],
    ['move', 285, 440, 1180, 'pointermove'],
    ['down', 280, 455, 1250, 'pointerdown'],
    ['focus', 1300],
    ['up', 280, 455, 1360, 'pointerup'],
  ];

  test('calNHelp2', () {
    expect([0, 5, -5, 40000, -40000, 123.6].map(GeetestGt3Behavior.calNHelp2),
        [0, 5, -5, 32767, -32767, 124]);
  });

  test('help_ / hash_', () {
    expect(GeetestGt3Behavior.help_('A0z~'), [65, 48, 122, 126]);
    expect(GeetestGt3Behavior.hash_('hello'), '5d41402abc4b2a76b9719d911017c592');
  });

  test('calNFunD', () {
    expect(GeetestGt3Behavior.calNFunD(['move', 'move', 'down', 'up']),
        '10000000000001001000000000010010');
  });

  test('calNFunP flag0/flag1', () {
    expect(GeetestGt3Behavior.calNFunP([5, -3, 0, 127, -200, 4], false),
        '100000000000011000000001010001010011000001111111110010000100');
    expect(GeetestGt3Behavior.calNFunP([5, -3, 0, 127, -200, 4], true),
        '10000000000001100000000101000101001100000111111111001000010001010');
  });

  test('calNHelp3 → calN → calTt 全链一致', () {
    final h3 = GeetestGt3Behavior.calNHelp3(ee);
    final caln = GeetestGt3Behavior.calN(h3.r);
    expect(caln, 'M(O,.*M(MBB90OMd8-Ed81(-P)4ebMA/()j((G1AS8((');
    const c = [12, 58, 98, 36, 43, 95, 62, 15, 12];
    const s = '682a5143';
    expect(GeetestGt3Behavior.calTt(caln, c, s),
        'M(O,.*M(MBB90OMd8-EhdC81(-P)*4ebMAQ/()j((G1AS8((');
  });
}
