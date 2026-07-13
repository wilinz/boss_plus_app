import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'lz4_block.dart';

/// BOSS 直聘请求签名/加密引擎(纯 Dart 复现 `libyzwg.so`)。
///
/// 逆向来源:`docs/libyzwg-native-analysis.md`(Ghidra 静态 + Frida 运行时逐字节确认)。
///
/// 两个产物:
/// - `sp`  = `base64url( RC4( BZPBlock头 + LZ4(strD), key ) )`
/// - `sig` = `"V3.0" + MD5( apiPath + strD + SECRET32 + secretKey )`
///
/// 其中:
/// - `strD` = 参数按 key 升序、value URL 编码后拼 `k=v&k=v`(见 [buildSortedParams])。
/// - `key`(RC4)= 未登录/免 token 接口用 [secret32];已登录普通接口用 `secret32 + secretKey`。
/// - `secret32` 为 per-build 常量(绑定签名证书),官方 14.070 实测见 [kDefaultSecret32]。
class YzwgSigner {
  YzwgSigner({String? secret32}) : secret32 = secret32 ?? kDefaultSecret32;

  /// 官方 14.070 build 实测 SECRET32(32 位十六进制 ASCII 串,绑定签名证书)。
  /// 换 build/换签名需重新 dump(Frida hook `rc4_ksa` 或读 `libyzwg` base+0x544470)。
  static const String kDefaultSecret32 = 'a308f3628b3f39f7d35cdebeb6920e21';

  /// 签名版本前缀,native 常量 `"V3.0"`。
  static const String kSigVersion = 'V3.0';

  /// BZPBlock 信封魔数。
  static final Uint8List _magic = Uint8List.fromList(ascii.encode('BZPBlock'));

  final String secret32;

  /// 计算某次请求的 `sp` 与 `sig`。
  ///
  /// [apiPath] = URL 中从 `/api/` 开始的路径(见 native `config.m.f`)。
  /// [params]  = 全部请求参数(业务参数 + 公共参数)。
  /// [secretKey] = 会话密钥(登录后由服务端下发);免 token 接口传 null/空。
  SignResult sign({
    required String apiPath,
    required Map<String, String> params,
    String? secretKey,
  }) {
    final strD = buildSortedParams(params);
    final sk = secretKey ?? '';
    final rc4Key = ascii.encode(sk.isEmpty ? secret32 : (secret32 + sk));

    final sp = _encode(utf8.encode(strD), rc4Key);
    final sig = kSigVersion +
        md5Hex(utf8.encode(apiPath + strD + secret32 + sk));
    return SignResult(sp: sp, sig: sig, strD: strD);
  }

  /// `sp` 编码:LZ4(明文) → BZPBlock 头 → RC4 → base64url。
  String _encode(List<int> plain, List<int> rc4Key) {
    final comp = Lz4Block.compressBlock(Uint8List.fromList(plain));
    final olen = plain.length;
    final clen = comp.length;

    final head = BytesBuilder()
      ..add(_magic)
      ..add(_u32le(0))
      ..add(_u32le(clen))
      ..add(_u32le(olen))
      ..add(_u32le(olen ^ clen));
    final envelope = (head..add(comp)).toBytes();

    final cipher = rc4(rc4Key, envelope);
    return _base64Url(cipher);
  }

  /// 自解 `sp`(RC4 对称 + 跳 BZPBlock 头 + LZ4 解压),用于自测/调试。
  String decode(String spOrBody, {String? secretKey}) {
    final cipher = _base64UrlDecode(spOrBody);
    final plain = rc4(_rc4KeyFor(secretKey), cipher);
    final payload = Uint8List.sublistView(Uint8List.fromList(plain), 24);
    final out = Lz4Block.decompressBlock(payload);
    return utf8.decode(out, allowMalformed: true);
  }

  /// 解密服务端**响应体**(`zp-encrypting:1`)。
  ///
  /// 实测(Frida `nativeDecodeContent` + 本次真机):响应 = **纯 RC4(密文)**,
  /// 无 BZPBlock/LZ4 外壳,直接是 JSON 明文字节。key 规则同请求。
  String decryptResponse(List<int> cipher, {String? secretKey}) =>
      utf8.decode(rc4(_rc4KeyFor(secretKey), cipher), allowMalformed: true);

  /// 用会话 key 对字节做 RC4(对称,响应解密用)。
  Uint8List rc4Bytes(List<int> data, {String? secretKey}) =>
      rc4(_rc4KeyFor(secretKey), data);

  /// 敏感字段编码(手机号/密码 → 登录参数 `account`)。
  ///
  /// 复现 native `nativeEncodePassword`(逆向已确认,byte-exact):
  /// **`account = base64( RC4(明文, SECRET32) )`**(标准 base64,固定用 SECRET32,与会话无关)。
  String encodePassword(String plain) =>
      base64.encode(rc4(ascii.encode(secret32), utf8.encode(plain)));

  /// [encodePassword] 的逆:`RC4( base64_decode(s), SECRET32 )`。
  String decodePassword(String encoded) =>
      utf8.decode(rc4(ascii.encode(secret32), base64.decode(encoded)),
          allowMalformed: true);

  List<int> _rc4KeyFor(String? secretKey) {
    final sk = secretKey ?? '';
    return ascii.encode(sk.isEmpty ? secret32 : (secret32 + sk));
  }

  // ---- 工具 ----

  /// 参数规范化:按 key 升序 → `key=URLEncode(value)` → `&` 连接(见 native `m.d`)。
  static String buildSortedParams(Map<String, String> params) {
    final keys = params.keys.where((k) => k.isNotEmpty).toList()..sort();
    final buf = StringBuffer();
    var first = true;
    for (final k in keys) {
      if (!first) buf.write('&');
      first = false;
      buf.write(k);
      buf.write('=');
      final v = params[k]!;
      if (v.isNotEmpty) buf.write(Uri.encodeQueryComponent(v));
    }
    return buf.toString();
  }

  static String md5Hex(List<int> data) =>
      crypto.md5.convert(data).toString();

  /// 标准 RC4(加解密同一函数)。
  static Uint8List rc4(List<int> key, List<int> data) {
    final s = List<int>.generate(256, (i) => i);
    var j = 0;
    for (var i = 0; i < 256; i++) {
      j = (j + s[i] + key[i % key.length]) & 0xff;
      final t = s[i];
      s[i] = s[j];
      s[j] = t;
    }
    final out = Uint8List(data.length);
    var a = 0, b = 0;
    for (var n = 0; n < data.length; n++) {
      a = (a + 1) & 0xff;
      b = (b + s[a]) & 0xff;
      final t = s[a];
      s[a] = s[b];
      s[b] = t;
      out[n] = data[n] ^ s[(s[a] + s[b]) & 0xff];
    }
    return out;
  }

  static Uint8List _u32le(int v) =>
      Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little);

  /// 标准 base64 → URL 安全变体:`+→-  /→_  =→~`(见 native `base64_to_urlsafe`)。
  static String _base64Url(List<int> bytes) => base64
      .encode(bytes)
      .replaceAll('+', '-')
      .replaceAll('/', '_')
      .replaceAll('=', '~');

  static Uint8List _base64UrlDecode(String s) {
    var t = s.replaceAll('-', '+').replaceAll('_', '/').replaceAll('~', '=');
    // 规范化补齐:真实 sp 已是 4 的倍数(此处无副作用);对截断的调试串则丢弃
    // 悬空字符或补 `=`,保证 base64 合法。
    t = t.replaceAll('=', '');
    final rem = t.length % 4;
    if (rem == 1) {
      t = t.substring(0, t.length - 1);
    } else if (rem != 0) {
      t = t.padRight(t.length + (4 - rem), '=');
    }
    return base64.decode(t);
  }
}

/// [YzwgSigner.sign] 的结果。
class SignResult {
  const SignResult({required this.sp, required this.sig, required this.strD});

  /// 加密后的参数包(放进 query/body 的 `sp`)。
  final String sp;

  /// 请求签名(`V3.0` + md5),放进 query/body 的 `sig`。
  final String sig;

  /// 规范化后的参数串(调试用)。
  final String strD;
}
