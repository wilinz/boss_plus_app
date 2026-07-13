import 'dart:math';

import 'package:dio/dio.dart';

import '../core/config/boss_app_config.dart';

/// BOSS 固定/动态请求头拦截器(见 native `net.bosszhipin.base.e`)。
///
/// 为发往 `*.zhipin.com` 的请求注入:
/// - `User-Agent`(机型指纹)
/// - `traceId`(每请求一个 UUID)
/// - `zp-accept-encoding:1` / `zp-accept-encrypting:1` / `zp-accept-compressing:3`
/// - `t2`(登录态 token,由 [BossAuthState] 提供;未登录不加)
class BossHeaderInterceptor extends Interceptor {
  BossHeaderInterceptor({required this.appConfig, required this.auth});

  BossAppConfig appConfig;
  final BossAuthState auth;

  bool _isBossHost(Uri uri) => uri.host.endsWith('zhipin.com');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isBossHost(options.uri)) {
      final h = options.headers;
      h.putIfAbsent('User-Agent', () => appConfig.userAgent);
      h.putIfAbsent('traceId', () => 'A-${_uuid()}');
      h.putIfAbsent('zp-accept-encoding', () => '1');
      h.putIfAbsent('zp-accept-encrypting', () => '1');
      h.putIfAbsent('zp-accept-compressing', () => '3');
      final t2 = auth.token2;
      if (t2 != null && t2.isNotEmpty) {
        h.putIfAbsent('t2', () => t2);
      }
    }
    super.onRequest(options, handler);
  }

  static final _rnd = Random.secure();

  static String _uuid() {
    final b = List<int>.generate(16, (_) => _rnd.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String hx(int n) => b[n].toRadixString(16).padLeft(2, '0');
    final s = List.generate(16, hx).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}'
        '-${s.substring(16, 20)}-${s.substring(20)}';
  }
}

/// 登录态(单账号):持有会话 `token2`(→ `t2` 头)与 `secretKey`(→ 签名密钥)。
class BossAuthState {
  String? token2;
  String? secretKey;

  bool get loggedIn => (secretKey != null && secretKey!.isNotEmpty);

  void clear() {
    token2 = null;
    secretKey = null;
  }
}
