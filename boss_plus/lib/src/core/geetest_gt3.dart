import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';

/// 极验 gt3(slide 7.9.x)`w` 参数的**纯 Dart** 实现。
///
/// 移植自公开逆向研究(crowod/GeetestV3 等),常量与算法为 gt3 全系稳定值:
/// - RSA:固定公钥 [_modulus] / e=0x10001,PKCS#1 v1.5,加密 16 位随机 AES key。
/// - AES:128-CBC,iv=`0000000000000000`,PKCS7;明文是含轨迹的 JSON。
/// - `w` 封装(web 版,可对极验 demo 端到端验证):`bytesToString(aes) + hex(rsa)`。
///   session key 在 step1 用 RSA 上送、precheck 复用免 RSA(见 registerW/precheckW)。
///   (BOSS android SDK 用 base64(aes+rsa),但其指纹包结构不可恢复,故走可验证的 web 路径。)
///
/// 确定性变换([bytesToString]/[funF]/[calAa])有对应的 Python 参考测试向量,
/// 见 `test/geetest_gt3_test.dart`,可脱离活验证码校验移植正确性。
class GeetestGt3 {
  GeetestGt3({Random? rand}) : _rand = rand ?? Random.secure();

  final Random _rand;

  /// 会话 AES key(16 位),step1 用 RSA 上送后服务端记住,precheck 复用免 RSA。
  late final String _sessionKey = _secKey();

  static String _hex(Uint8List b) =>
      b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

  /// web 编码 `w`:`bytesToString(aes(payload, sessionKey))` [+ `hex(rsa(sessionKey))`]。
  String _webEncode(Map<String, dynamic> payload, {required bool withRsa}) {
    final enc = bytesToString(aesEncrypt(jsonEncode(payload), _sessionKey));
    return withRsa ? enc + _hex(rsaEncrypt(_sessionKey)) : enc;
  }

  /// step1 注册 `w`(带 RSA,确立会话 key),换取 c/s。
  String registerW(String gt, String challenge) => _webEncode({
        'gt': gt,
        'challenge': challenge,
        'offline': false,
        'new_captcha': true,
        'product': 'embed',
        'width': '100%',
        'https': true,
        'type': 'slide3',
      }, withRsa: true);

  /// precheck `w`(复用会话 key,不带 RSA),behavior 由 GeetestGt3Behavior.calA 生成。
  String precheckW(Map<String, dynamic> behavior) =>
      _webEncode(behavior, withRsa: false);

  // 极验固定 RSA 公钥(gt3 全系通用),模数 1024bit。
  static const _modulus =
      '00C1E3934D1614465B33053E7F48EE4EC87B14B95EF88947713D25EECBFF7E74C7977D0'
      '2DC1D9451F79DD5D1C10C29ACB6A9B4D6FB7D0A0279B6719E1772565F09AF627715919'
      '221AEF91899CAE08C0D686D748B20A3603BE2318CA6BC2B59706592A9219D0BF05C9F65'
      '023A21D2330807252AE0066D59CEEFA5F2748EA80BAB81';
  static final _pubExp = BigInt.from(0x10001);

  // bytes_to_string 用的自定义 base64 字母表与位置换掩码。
  static const _bts =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789()';
  static const _mJEi = 7274496, _mJFj = 9483264, _mJGF = 19220, _mJHv = 235;

  // fun_e / fun_n 编码表。
  static const _funETab = <List<int>>[
    [1, 0], [2, 0], [1, -1], [1, 1], [0, 1], [0, -1], [3, 0], [2, -1], [2, 1],
  ];
  static const _funEStr = 'stuvwxyz~';
  static const _funNStr =
      '()*,-./0123456789:?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqr';

  // ---------------------------------------------------------------------------
  // 确定性变换(可用测试向量校验)
  // ---------------------------------------------------------------------------

  /// gt3 自定义 base64(把 AES 密文字节编码成字符串;网页 `w` 用,Android 不用但保留)。
  static String bytesToString(List<int> array) {
    String o(int t) => (t < 0 || t >= _bts.length) ? '.' : _bts[t];
    int e(int t, int mask) {
      var n = 0;
      for (var r = 24; r >= 0; r--) {
        if (1 == (mask >> r & 1)) n = (n << 1) + (t >> r & 1);
      }
      return n;
    }

    var n = '', tail = '';
    for (var a = 0; a < array.length; a += 3) {
      if (a + 2 < array.length) {
        final u = (array[a] << 16) + (array[a + 1] << 8) + array[a + 2];
        n += o(e(u, _mJEi)) + o(e(u, _mJFj)) + o(e(u, _mJGF)) + o(e(u, _mJHv));
      } else {
        final c = array.length % 3;
        if (c == 2) {
          final u = (array[a] << 16) + (array[a + 1] << 8);
          n += o(e(u, _mJEi)) + o(e(u, _mJFj)) + o(e(u, _mJGF));
          tail = '.';
        } else if (c == 1) {
          final u = array[a] << 16;
          n += o(e(u, _mJEi)) + o(e(u, _mJFj));
          tail = '..';
        }
      }
    }
    return n + tail;
  }

  /// 轨迹差分:相邻点求 [dx,dy,dt],dx=dy=0 时把 dt 累加到下一个非零点。
  static List<List<int>> funT(List<List<num>> t) {
    final out = <List<int>>[];
    var o = 0, e = 0, n = 0;
    for (var s = 0; s < t.length - 1; s++) {
      e = (t[s + 1][0] - t[s][0]).round();
      n = (t[s + 1][1] - t[s][1]).round();
      final r = (t[s + 1][2] - t[s][2]).round();
      if (e != 0 || n != 0 || r != 0) {
        if (e == 0 && n == 0) {
          o += r;
        } else {
          out.add([e, n, r + o]);
          o = 0;
        }
      }
    }
    if (o != 0) out.add([e, n, o]);
    return out;
  }

  static String _funE(List<int> t) {
    for (var n = 0; n < _funETab.length; n++) {
      if (t[0] == _funETab[n][0] && t[1] == _funETab[n][1]) return _funEStr[n];
    }
    return '';
  }

  static String _funN(int t) {
    final n = _funNStr.length;
    final i = t.abs();
    var o = i ~/ n;
    if (o >= n) o = n - 1;
    final r = o != 0 ? _funNStr[o] : '';
    var s = '';
    if (t < 0) s += '!';
    if (r.isNotEmpty) s += r'$';
    return s + r + _funNStr[i % n];
  }

  /// 把轨迹编码成 `dx!!dy!!dt` 三段字符串(cal_aa 的输入 t)。
  static String funF(List<List<num>> t) {
    final r = <String>[], i = <String>[], o = <String>[];
    for (final tt in funT(t)) {
      final ee = _funE(tt);
      if (ee.isNotEmpty) {
        i.add(ee);
      } else {
        r.add(_funN(tt[0]));
        i.add(_funN(tt[1]));
      }
      o.add(_funN(tt[2]));
    }
    return '${r.join()}!!${i.join()}!!${o.join()}';
  }

  /// 用 c(数组)与 s(hex 串)把噪声字符插入轨迹串,得到 `aa`。
  static String calAa(String t, List<int> c, String s) {
    var o = t;
    final sa = c[0], a = c[2], u = c[4];
    for (var i = 0; i + 2 <= s.length; i += 2) {
      final cc = int.parse(s.substring(i, i + 2), radix: 16);
      final ch = String.fromCharCode(cc);
      final l = (sa * cc * cc + a * cc + u) % t.length;
      o = o.substring(0, l) + ch + o.substring(l);
    }
    return o;
  }

  // ---------------------------------------------------------------------------
  // 带随机 / 加密的部分
  // ---------------------------------------------------------------------------

  /// userresponse:由滑动距离 [value] 与 [challenge](含末尾 2 字符)推出。
  String calUserresponse(num value, String challenge) {
    final n0 = challenge.substring(32);
    final r = <int>[];
    for (final ch in n0.codeUnits) {
      r.add(ch > 57 ? ch - 87 : ch - 48);
    }
    final nn = 36 * r[0] + r[1];
    var h = value.round() + nn;
    final head = challenge.substring(0, 32);
    final u = <List<String>>[[], [], [], [], []];
    final seen = <String>{};
    var idx = 0;
    for (var i = 0; i < head.length; i++) {
      final ch = head[i];
      if (seen.contains(ch)) continue;
      seen.add(ch);
      u[idx].add(ch);
      idx++;
      if (idx == 5) idx = 0;
    }
    var d = 4;
    var p = '';
    final g = [1, 2, 5, 10, 50];
    while (h > 0) {
      if (h - g[d] >= 0) {
        final f = (_rand.nextDouble() * u[d].length).floor();
        p += u[d][f];
        h -= g[d];
      } else {
        u.removeAt(d);
        g.removeAt(d);
        d--;
      }
    }
    return p;
  }

  Map<String, dynamic> _getEp(String gt, String challenge, {String v = '7.9.3'}) {
    final f = crypto.md5.convert(utf8.encode(gt + challenge)).toString();
    final a = DateTime.now().millisecondsSinceEpoch;
    int rnd(int lo, int hi) => lo + _rand.nextInt(hi - lo + 1);
    final ff = a + rnd(2, 8);
    final b = a + rnd(50, 80);
    final l = a + rnd(3, 9);
    final m = l + rnd(30, 50);
    final nn = m + rnd(1, 5);
    final o = nn + rnd(10, 50);
    final p = o + rnd(70, 90);
    final rr = p + rnd(10, 100);
    final s = rr + rnd(1, 2);
    return {
      'v': v,
      'f': f,
      'me': true,
      'te': false,
      'tm': {
        'a': a, 'b': b, 'c': b, 'd': 0, 'e': 0, 'f': ff, 'g': ff, 'h': ff,
        'i': ff, 'j': ff, 'k': 0, 'l': l, 'm': m, 'n': nn, 'o': o, 'p': p,
        'q': p, 'r': DateTime.now().millisecondsSinceEpoch, 's': s, 't': s,
        'u': s,
      },
    };
  }

  /// 生成 16 位随机 AES key(8 字节随机 → hex)。
  String _secKey() {
    const hex = '0123456789abcdef';
    return List.generate(16, (_) => hex[_rand.nextInt(16)]).join();
  }

  /// AES-128-CBC / PKCS7 加密,key 为 16 位 ascii,iv 固定 16 个 '0'。
  static Uint8List aesEncrypt(String text, String key) {
    final cipher = PaddedBlockCipherImpl(
        PKCS7Padding(), CBCBlockCipher(AESEngine()));
    cipher.init(
        true,
        PaddedBlockCipherParameters(
            ParametersWithIV(
                KeyParameter(Uint8List.fromList(utf8.encode(key))),
                Uint8List.fromList(utf8.encode('0000000000000000'))),
            null));
    return cipher.process(Uint8List.fromList(utf8.encode(text)));
  }

  /// RSA/PKCS1 v1.5 加密 [text](16 位 key 的 ascii 字节)→ 128 字节。
  static Uint8List rsaEncrypt(String text) {
    final n = BigInt.parse(_modulus, radix: 16);
    final engine = PKCS1Encoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(RSAPublicKey(n, _pubExp)));
    return engine.process(Uint8List.fromList(utf8.encode(text)));
  }

  /// 组装最终 `w`(BOSS/Android:`base64(aesBytes + rsaBytes)`,MIME 换行)。
  ///
  /// - [distance] 滑动像素距离(userresponse 用)
  /// - [trace] 拖动轨迹 `[x, y, tMillis]`(相对起点),末点时间即 passtime
  /// - [c]/[s] 来自 get.php 配置
  String buildW({
    required String gt,
    required String challenge,
    required num distance,
    required List<List<num>> trace,
    required List<int> c,
    required String s,
  }) {
    final passtime = trace.isEmpty ? 0 : trace.last[2];
    final aa = calAa(funF(trace), c, s);
    final rp = crypto.md5
        .convert(utf8.encode('$gt${challenge.substring(0, 32)}$passtime'))
        .toString();
    final payload = <String, dynamic>{
      'lang': 'zh-cn',
      'userresponse': calUserresponse(distance, challenge),
      'passtime': passtime,
      'imgload': 100 + _rand.nextInt(701),
      'aa': aa,
      'ep': _getEp(gt, challenge),
      'rp': rp,
    };
    return _webEncode(payload, withRsa: true);
  }
}
