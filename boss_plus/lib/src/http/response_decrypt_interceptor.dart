import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/crypto/yzwg_signer.dart';
import '../core/crypto/lz4_block.dart';
import 'boss_header_interceptor.dart';

/// 响应解密拦截器。
///
/// BOSS 响应在 `zp-encrypting:1` 时体是**纯 RC4 密文**(见 native `nativeDecodeContent`,
/// 实测解出 `{"code":...}`);`zp-compressing:1`(或 3)时为 gzip。
///
/// 为拿到原始字节(避免 Dio 的 JSON transformer 先对密文 `jsonDecode` 报错),
/// 本拦截器在 `onRequest` 把发往 `*.zhipin.com` 的响应类型改为 `bytes`,在 `onResponse`
/// 里按响应头解压/解密,最后 `jsonDecode` 回 Map/List。
class BossResponseDecryptInterceptor extends Interceptor {
  BossResponseDecryptInterceptor({required this.auth, required this.signer});

  final BossAuthState auth;
  final YzwgSigner signer;

  bool _isBossHost(Uri uri) => uri.host.endsWith('zhipin.com');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isBossHost(options.uri)) {
      options.responseType = ResponseType.bytes;
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 原始二进制下载(如 PDF)不解密/不转字符串,保留字节。
    if (response.requestOptions.extra['bossRaw'] == true) {
      super.onResponse(response, handler);
      return;
    }
    final data = response.data;
    if (data is List<int>) {
      response.data = _process(response, data);
    } else if (data is String) {
      response.data = _processString(data);
    }
    super.onResponse(response, handler);
  }

  /// 部分端点(如附件上传)响应体是 **base64url(加密字节)** 文本,而非二进制。
  /// 已是 JSON 文本则直接解析;否则 base64url 解码后按加密体解密。
  dynamic _processString(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('{') || t.startsWith('[')) {
      try {
        return jsonDecode(t);
      } catch (_) {
        return t;
      }
    }
    List<int> bytes;
    try {
      bytes = _b64urlDecode(t);
    } catch (_) {
      return t;
    }
    for (final key in {auth.secretKey, null}) {
      final plain = _decodeBody(bytes, key);
      if (plain != null) {
        try {
          return jsonDecode(plain);
        } catch (_) {
          return plain;
        }
      }
    }
    return t;
  }

  /// URL 安全 base64(`-_~` ↔ `+/=`)解码(见 signer `_base64UrlDecode`)。
  Uint8List _b64urlDecode(String s) {
    var t = s
        .replaceAll('-', '+')
        .replaceAll('_', '/')
        .replaceAll('~', '=')
        .replaceAll('=', '');
    final rem = t.length % 4;
    if (rem == 1) {
      t = t.substring(0, t.length - 1);
    } else if (rem != 0) {
      t = t.padRight(t.length + (4 - rem), '=');
    }
    return base64.decode(t);
  }

  dynamic _process(Response response, List<int> body) {
    final h = response.headers;
    final encrypting = h.value('zp-encrypting');

    // 加密响应:RC4 解密 + (可能)BZPBlock/LZ4 或 gzip 解压 → JSON。
    // 先按登录态 key(SECRET32+secretKey),失败再退 SECRET32。
    if (encrypting == '1') {
      for (final key in {auth.secretKey, null}) {
        final plain = _decodeBody(body, key);
        if (plain != null) {
          try {
            return jsonDecode(plain);
          } catch (_) {
            return plain;
          }
        }
      }
    }
    // 未加密 / 解密失败:按文本处理(可能是 base64url 加密文本,如附件上传)
    return _processString(utf8.decode(body, allowMalformed: true));
  }

  /// RC4(key) → 若 `BZPBlock` 头则跳 24B + LZ4;若 gzip magic 则 gunzip → utf8。
  /// 只有结果像 JSON({ 或 [ 开头)才认为解密成功。
  String? _decodeBody(List<int> cipher, String? key) {
    var bytes = signer.rc4Bytes(cipher, secretKey: key) as List<int>;
    if (bytes.length >= 8 &&
        utf8.decode(bytes.sublist(0, 8), allowMalformed: true) == 'BZPBlock') {
      bytes = Lz4Block.decompressBlock(
          Uint8List.fromList(bytes.sublist(24)));
    } else if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      try {
        bytes = gzip.decode(bytes);
      } catch (_) {
        return null;
      }
    }
    final s = utf8.decode(bytes, allowMalformed: true).trimLeft();
    return (s.startsWith('{') || s.startsWith('[')) ? s : null;
  }
}
