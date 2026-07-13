import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:boss_plus/boss_plus.dart';

/// BOSS 直聘命令行(单账号)。
///
/// 子命令:
///   sign   离线计算 sp/sig(不联网)
///   login  短信验证码登录(smsCode → codeLogin),会话存本地文件
///   get    已登录态发一个 GET 业务请求
///   post   已登录态发一个 POST 业务请求
Future<void> main(List<String> args) async {
  final runner = CommandRunner<void>('boss_cli', 'BOSS 直聘协议命令行(boss_plus 引擎)')
    ..addCommand(SignCommand())
    ..addCommand(LoginCommand())
    ..addCommand(RequestCommand('get'))
    ..addCommand(RequestCommand('post'))
    ..addCommand(UploadResumeCommand());
  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(64);
  }
}

const _defaultSession = '.boss_session.json';

Future<Boss> _openClient({String? deviceId, String? sessionPath}) async {
  final cfg = BossAppConfig.forDevice(
      deviceId: deviceId ?? 'cli-default-device-0001');
  final jar = FileSessionJar(sessionPath ?? _defaultSession);
  return Boss.newInstance(appConfig: cfg, sessionJar: jar);
}

/// boss_cli sign --path /api/... --param k=v --param ... [--secret-key SK]
class SignCommand extends Command<void> {
  SignCommand() {
    argParser
      ..addOption('path', abbr: 'p', help: 'API 路径(从 /api/ 起)', mandatory: true)
      ..addMultiOption('param', abbr: 'd', help: '业务参数 k=v(可多次)')
      ..addOption('secret-key', help: '会话 secretKey(登录后;免 token 接口留空)')
      ..addOption('secret32', help: '覆盖内置 SECRET32');
  }

  @override
  String get name => 'sign';
  @override
  String get description => '离线计算 sp/sig(不联网)';

  @override
  void run() {
    final a = argResults!;
    final signer = YzwgSigner(secret32: a['secret32'] as String?);
    final params = <String, String>{};
    for (final kv in a['param'] as List<String>) {
      final i = kv.indexOf('=');
      if (i < 0) throw UsageException('参数需 k=v: $kv', usage);
      params[kv.substring(0, i)] = kv.substring(i + 1);
    }
    final r = signer.sign(
      apiPath: a['path'] as String,
      params: params,
      secretKey: a['secret-key'] as String?,
    );
    print(const JsonEncoder.withIndent('  ')
        .convert({'strD': r.strD, 'sp': r.sp, 'sig': r.sig}));
  }
}

/// boss_cli login --mobile 199... [--code 1234] [--device-id ...]
class LoginCommand extends Command<void> {
  LoginCommand() {
    argParser
      ..addOption('mobile', abbr: 'm', help: '手机号', mandatory: true)
      ..addOption('code', abbr: 'c', help: '短信验证码(留空则先发码并交互输入)')
      ..addOption('device-id', help: '设备 id(派生机型指纹)')
      ..addOption('session', help: '会话文件路径', defaultsTo: _defaultSession);
  }

  @override
  String get name => 'login';
  @override
  String get description => '短信验证码登录,会话存本地';

  @override
  Future<void> run() async {
    final a = argResults!;
    final mobile = a['mobile'] as String;
    final boss = await _openClient(
        deviceId: a['device-id'] as String?, sessionPath: a['session'] as String?);

    var code = a['code'] as String?;
    if (code == null || code.isEmpty) {
      // 极验:CLI 无法拖滑块。先探测是否需要验证。
      final reg = await boss.manMachine(mobile: mobile);
      if (reg.needVerify) {
        stderr.writeln('该账号登录需极验滑块验证(gt=${reg.gt}),CLI 无法手动拖动。'
            '请改用 App 端登录,或用 --code 直接传入已获取的验证码。');
        exit(2);
      }
      final resp = await boss.sendSmsCode(mobile: mobile);
      final ok = (resp['code'] as num?)?.toInt() == 0;
      stdout.writeln('验证码已${ok ? "发送" : "请求失败: ${resp['message'] ?? resp}"}。'
          '请输入收到的验证码: ');
      code = stdin.readLineSync()?.trim();
      if (code == null || code.isEmpty) {
        stderr.writeln('未输入验证码');
        exit(1);
      }
    }
    final r = await boss.loginWithSms(mobile: mobile, code: code);
    stdout.writeln('登录: code=${r.code} msg=${r.message} '
        '会话=${r.hasSession ? "已建立(已保存)" : "未建立"}');
    if (!r.hasSession) exit(1);
  }
}

/// boss_cli upload-resume --file /path/to/简历.pdf
class UploadResumeCommand extends Command<void> {
  UploadResumeCommand() {
    argParser
      ..addOption('file', abbr: 'f', help: '本地简历文件(pdf/doc/docx)', mandatory: true)
      ..addOption('device-id', help: '设备 id')
      ..addOption('session', help: '会话文件', defaultsTo: _defaultSession);
  }

  @override
  String get name => 'upload-resume';
  @override
  String get description => '上传附件简历(multipart → /api/zpupload/uploadResumeFile)';

  @override
  Future<void> run() async {
    final a = argResults!;
    final path = a['file'] as String;
    if (!File(path).existsSync()) {
      stderr.writeln('文件不存在: $path');
      exit(1);
    }
    final boss = await _openClient(
        deviceId: a['device-id'] as String?, sessionPath: a['session'] as String?);
    final resp = await boss.uploadResumeFile(path);
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(resp));
    if ((resp['code'] as num?)?.toInt() != 0) exit(1);
  }
}

/// boss_cli get|post --path /api/... [--param k=v] [--no-token]
class RequestCommand extends Command<void> {
  RequestCommand(this._method) {
    argParser
      ..addOption('path', abbr: 'p', help: 'API 路径', mandatory: true)
      ..addMultiOption('param',
          abbr: 'd', help: '业务参数 k=v', splitCommas: false)
      ..addFlag('no-token', help: '免 token 接口', defaultsTo: false)
      ..addOption('device-id', help: '设备 id')
      ..addOption('session', help: '会话文件', defaultsTo: _defaultSession);
  }

  final String _method;

  @override
  String get name => _method;
  @override
  String get description => '已登录态发一个 ${_method.toUpperCase()} 业务请求';

  @override
  Future<void> run() async {
    final a = argResults!;
    final boss = await _openClient(
        deviceId: a['device-id'] as String?, sessionPath: a['session'] as String?);
    final params = <String, String>{};
    for (final kv in a['param'] as List<String>) {
      final i = kv.indexOf('=');
      if (i < 0) throw UsageException('参数需 k=v: $kv', usage);
      params[kv.substring(0, i)] = kv.substring(i + 1);
    }
    final noToken = a['no-token'] as bool;
    final path = a['path'] as String;
    final resp = _method == 'get'
        ? await boss.getApi(path, params: params, noToken: noToken)
        : await boss.postApi(path, data: params, noToken: noToken);
    stdout.writeln('HTTP ${resp.statusCode}');
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(resp.data));
  }
}
