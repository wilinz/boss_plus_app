import 'dart:convert';

import 'package:boss_plus/src/core/geetest_gt3.dart';
import 'package:test/test.dart';

/// 校验 gt3 确定性变换的 Dart 移植与 Python 参考(crowod/GeetestV3)一致。
/// 向量由参考实现的 decrypt.py 纯函数以固定输入生成。
void main() {
  test('bytesToString 与参考一致', () {
    const arr = [0, 1, 2, 3, 4, 5, 250, 251, 252, 253, 254, 255, 16, 32, 48, 64, 128, 200, 7];
    expect(GeetestGt3.bytesToString(arr), 'AAECDBBB6()89)7)AUCIgIA0HA..');
  });

  final trace = <List<num>>[
    [0, 0, 100], [5, 0, 120], [12, 1, 150], [20, 0, 180],
    [33, -1, 210], [50, 1, 260], [68, 0, 300], [68, 0, 360],
  ];

  test('funF 与参考一致', () {
    expect(GeetestGt3.funF(trace), '.016:?(!!()!)!)*!)(!!AKKKdUn');
  });

  test('calAa 与参考一致', () {
    const c = [12, 58, 98, 36, 43, 95, 62, 15, 12];
    const s = '682a5143';
    expect(GeetestGt3.calAa(GeetestGt3.funF(trace), c, s),
        '.016:?(!!()!)!)**!)(!!AKKCQKdUhn');
  });

  test('aesEncrypt 长度为块整数倍且可 base64', () {
    final out = GeetestGt3.aesEncrypt('{"hello":"world"}', '0123456789abcdef');
    expect(out.length % 16, 0);
    expect(() => base64.encode(out), returnsNormally);
  });

  test('rsaEncrypt 输出 128 字节', () {
    expect(GeetestGt3.rsaEncrypt('0123456789abcdef').length, 128);
  });
}
