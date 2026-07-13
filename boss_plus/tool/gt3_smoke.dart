import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:boss_plus/boss_plus.dart';

/// 对极验 demo 端到端验证纯 Dart gt3 流程(registerW→precheck→is_next→submit)。
/// 运行:dart run tool/gt3_smoke.dart
Future<void> main() async {
  final dio = Dio(BaseOptions(responseType: ResponseType.plain, headers: {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 12) Mobile Safari/537.36',
    'Referer': 'https://static.geetest.com/',
  }));
  final reg = jsonDecode((await dio.get(
          'https://www.geetest.com/demo/gt/register-slide',
          queryParameters: {'t': DateTime.now().millisecondsSinceEpoch}))
      .data as String) as Map<String, dynamic>;
  print('register gt=${reg['gt']} challenge=${reg['challenge']}');

  final solver = GeetestGt3Solver(
      gt: reg['gt'] as String, challenge: reg['challenge'] as String);
  final ch = await solver.load();
  print('LOAD ok → bg=${ch.bgUrl.isNotEmpty} slice=${ch.sliceUrl.isNotEmpty} '
      'newChallenge=${ch.challenge.substring(0, 8)}… ypos=${ch.ypos}');

  // 距离瞎给(demo 无 CV);只验证最终 w 被接受(success 结构而非格式错)。
  final trace = <List<num>>[
    for (var i = 0; i <= 100; i += 5) [i, i % 3 - 1, i * 6],
  ];
  final validate = await solver.submit(100, trace);
  print('SUBMIT validate=$validate  (distance=100 猜测,success 结构=通过)');
}
