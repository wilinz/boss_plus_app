import 'package:dio/dio.dart';

import '../core/config/boss_app_config.dart';
import '../core/crypto/yzwg_signer.dart';
import 'boss_header_interceptor.dart';

/// BOSS 签名/加密拦截器(复现 native `net.bosszhipin.base.m`)。
///
/// 对每个发往 `*.zhipin.com` 的请求:
/// 1. 收集参数 = 调用方业务参数(GET 的 query / POST 的 form data)+ 公共参数
///    (`curidentity`/`v`/`req_time`/`uniqid`/`client_info`)。
/// 2. `strD` = 排序规范化;`sp` = 加密参数包;`sig` = 签名。
/// 3. 出站请求只带 `{sp, sig, app_id}`(GET → query,POST → x-www-form-urlencoded body),
///    业务参数已加密进 `sp`。
///
/// secretKey:登录后走 [BossAuthState.secretKey];未登录或 `extra['bossNoToken']==true`
/// 的免 token 接口传空。须排在 header 拦截器之后。
class BossSignInterceptor extends Interceptor {
  BossSignInterceptor({
    required this.appConfig,
    required this.auth,
    required this.signer,
  });

  BossAppConfig appConfig;
  final BossAuthState auth;
  final YzwgSigner signer;

  bool _isBossHost(Uri uri) => uri.host.endsWith('zhipin.com');

  /// 从 URL 取从 `/api/` 起的路径(见 native `config.m.f`)。
  String _apiPath(Uri uri) {
    final full = uri.path;
    final idx = full.indexOf('/api/');
    return idx < 0 ? full : full.substring(idx);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra['bossRaw'] == true || !_isBossHost(options.uri)) {
      handler.next(options);
      return;
    }
    try {
      final method = options.method.toUpperCase();

      // 业务参数
      final params = <String, String>{};
      options.uri.queryParameters.forEach((k, v) => params[k] = v);
      final data = options.data;
      final isMultipart = data is FormData;
      if (data is Map) {
        data.forEach((k, v) => params['$k'] = '$v');
      } else if (isMultipart) {
        // multipart:文本字段参与签名,二进制文件不参与
        for (final f in data.fields) {
          params[f.key] = f.value;
        }
      }
      // 公共参数(不覆盖调用方同名参数)
      appConfig.commonParams().forEach((k, v) => params.putIfAbsent(k, () => v));

      final noToken = options.extra['bossNoToken'] == true;
      final secretKey = noToken ? null : auth.secretKey;

      final r = signer.sign(
        apiPath: _apiPath(options.uri),
        params: params,
        secretKey: secretKey,
      );

      final outbound = {
        'sp': r.sp,
        'sig': r.sig,
        'app_id': appConfig.appId,
      };

      if (method == 'GET' || method == 'DELETE' || method == 'HEAD') {
        options.queryParameters = outbound;
        options.data = null;
      } else if (isMultipart) {
        // multipart 上传:sp/sig 放 query,保留 FormData 文件体
        options.queryParameters = outbound;
      } else {
        // POST/PUT:x-www-form-urlencoded
        options.queryParameters = {};
        options.data = outbound;
        options.contentType = Headers.formUrlEncodedContentType;
      }

      handler.next(options);
    } catch (e) {
      handler.reject(DioException(requestOptions: options, error: e), true);
    }
  }
}
