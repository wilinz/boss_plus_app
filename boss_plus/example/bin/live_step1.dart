import 'package:boss_plus/boss_plus.dart';
Future<void> main() async {
  bossLogEnabled = true;
  final boss = await Boss.newInstance(
    appConfig: BossAppConfig.forDevice(deviceId: 'live-test-0001'),
    sessionJar: FileSessionJar('/tmp/boss_live_session.json'),
  );
  const mobile = '19900000000'; // 占位号,运行前改成你自己的手机号
  print('UA = ${boss.appConfig.userAgent}');
  try {
    final j = await boss.userJudge(mobile: mobile);
    print('judge → code=${j['code']} msg=${j['message']} '
        'zpData=${bossClip(j['zpData'])}');
  } catch (e) { print('judge EXC: $e'); }
  try {
    final sent = await boss.sendSmsCode(mobile: mobile);
    print('sendSmsCode → $sent');
  } catch (e) { print('sms EXC: $e'); }
}
