import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// Dio 客户端基类(与 keep_plus 的 BaseClient 同构):统一 Dio 初始化、cookie、默认头。
abstract class BaseClient {
  late Dio dio;
  late CookieJar cookieJar;

  String get baseUrl;

  Future<void> initDio({
    required CookieJar cookieJar,
    required String userAgent,
    Dio? dio,
  }) async {
    dio ??= Dio(BaseOptions(baseUrl: baseUrl));
    dio.options = dio.options.copyWith(
      headers: {
        'User-Agent': userAgent,
        'Accept-Encoding': 'gzip',
      },
      validateStatus: (s) => s != null,
      followRedirects: false,
    );
    this.cookieJar = cookieJar;
    dio.interceptors.add(CookieManager(cookieJar));
    this.dio = dio;
  }

  void addInterceptor(Interceptor interceptor) => dio.interceptors.add(interceptor);
}
