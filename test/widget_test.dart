import 'package:flutter_test/flutter_test.dart';

import 'package:boss_plus_app/main.dart';

void main() {
  testWidgets('login page renders', (tester) async {
    await tester.pumpWidget(const BossPlusApp());
    await tester.pump();
    // 登录页应出现「获取验证码」按钮
    expect(find.text('获取验证码'), findsOneWidget);
  });
}
