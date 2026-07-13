import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;

import 'geetest_gt3.dart';

/// gt3 precheck「行为/指纹包」(`cal_a`)的确定性位打包辅助函数,纯 Dart 移植。
///
/// 对应参考实现 function.py。确定性部分有测试向量(见 geetest_gt3_behavior_test.dart)。
class GeetestGt3Behavior {
  static const _eventH = {
    'move': 0, 'down': 1, 'up': 2, 'scroll': 3,
    'focus': 4, 'blur': 5, 'unload': 6, 'unknown': 7,
  };

  /// 二进制串:等价 python `bin(n).lstrip('0b').zfill(width)`。
  static String _bin(int n, int width) {
    final s = n == 0 ? '' : n.toRadixString(2);
    return s.padLeft(width, '0');
  }

  static String hash_(String e) =>
      crypto.md5.convert(utf8.encode(e)).toString();

  static List<int> help_(String e) => e.codeUnits;

  static int calNHelp2(num e) {
    const t = 32767;
    if (t < e) {
      e = t;
    } else if (e < -t) {
      e = -t;
    }
    return e.round();
  }

  /// 过滤事件流,只保留主指针类型的 move/down/up。
  static List<List<dynamic>> calNHelp1(List<List<dynamic>> e) {
    var t = '';
    var n = 0;
    while (t.isEmpty && n < e.length) {
      t = e[n].length > 4 ? e[n][4].toString() : '';
      n++;
    }
    if (t.isEmpty) return e;
    var r = '';
    for (final i in const ['mouse', 'touch', 'pointer', 'MSPointer']) {
      if (t.indexOf(i) == 0) r = i;
    }
    final s = List<List<dynamic>>.from(e);
    const a = ['move', 'down', 'up'];
    for (var c = s.length - 1; c >= 0; c--) {
      final u = s[c];
      if (a.contains(u[0])) {
        if (u.length >= 5 && (u[4] as String).indexOf(r) != 0) s.removeAt(c);
      }
    }
    return s;
  }

  /// 事件流 → (第一个有效事件 fp, 最后一个 lp, 差分序列 r_)。
  static ({List<dynamic>? fp, List<dynamic>? lp, List<dynamic> r}) calNHelp3(
      List<List<dynamic>> e) {
    var t = 0, n = 0, i = 0;
    final r = <dynamic>[];
    List<dynamic>? a, s;
    final c = calNHelp1(e);
    final u = c.length;
    const o = ['down', 'move', 'up', 'scroll'];
    const o2 = ['blur', 'focus', 'unload'];
    final start = u < 300 ? 0 : u - 300;
    for (var idx = start; idx < u; idx++) {
      final l = c[idx];
      final hh = l[0];
      if (o.contains(hh)) {
        a ??= l;
        s = l;
        i = i != 0 ? (l[3] as num).toInt() - i : i;
        r.add([
          hh,
          [(l[1] as num) - t, (l[2] as num) - n],
          calNHelp2(i),
        ]);
        t = (l[1] as num).toInt();
        n = (l[2] as num).toInt();
        i = (l[3] as num).toInt();
      } else if (o2.contains(hh)) {
        i = i != 0 ? (l[1] as num).toInt() - i : i;
        r.add([hh, calNHelp2(i)]);
        i = (l[1] as num).toInt();
      }
    }
    return (fp: a, lp: s, r: r);
  }

  static String calNFunD(List<String> e) {
    final tt = <int>[];
    final n = e.length;
    var r = 0;
    while (r < n) {
      final o = e[r];
      var i = 0;
      while (true) {
        if (i >= 16) break;
        final a = r + i + 1;
        if (a >= n) break;
        if (e[a] != o) break;
        i++;
      }
      r = r + 1 + i;
      final s = _eventH[o]!;
      if (i != 0) {
        tt.add(8 | s);
        tt.add(i - 1);
      } else {
        tt.add(s);
      }
    }
    final c = _bin(32768 | n, 16);
    final sb = StringBuffer(c);
    for (final v in tt) {
      sb.write(_bin(v, 4));
    }
    return sb.toString();
  }

  static String calNFunP(List<int> e, bool flag) {
    const t = 32767;
    var n = <int>[];
    for (var i in e) {
      if (i > t) {
        i = t;
      } else if (i < -t) {
        i = -t;
      }
      n.add(i);
    }
    e = n;
    var len = e.length;
    var r = 0;
    final o = <int>[];
    while (r < len) {
      var i = 1;
      final a = e[r];
      final s = a.abs();
      while (true) {
        if (len <= r + i) break;
        if (e[r + i] != a) break;
        if (s >= 127 || i >= 127) break;
        i++;
      }
      if (i > 1) {
        o.add((a < 0 ? 49152 : 32768) | i << 7 | s);
      } else {
        o.add(a);
      }
      r += i;
    }
    e = o;
    final rr = <String>[];
    final oo = <String>[];
    for (final i in e) {
      final tt = i != 0 ? (log(i.abs() + 1) / log(16)).ceil() : 0;
      final w = tt == 0 ? 1 : tt;
      rr.add(_bin(w - 1, 2));
      oo.add(_bin(i.abs(), 4 * w));
    }
    final iStr = rr.join();
    final aStr = oo.join();
    if (!flag) {
      return _bin(32768 | e.length, 16) + iStr + aStr;
    }
    final nn = <String>[];
    for (final idx in e) {
      if (idx != 0 && idx >> 15 != 1) nn.add(idx < 0 ? '1' : '0');
    }
    return _bin(32768 | e.length, 16) + iStr + aStr + nn.join();
  }

  static String calN(List<dynamic> e) {
    final t = <String>[];
    final n = <int>[];
    final o = <int>[];
    final r = <int>[];
    for (final s in e) {
      final c = (s as List).length;
      t.add(s[0] as String);
      n.add((c == 2 ? s[1] : s[2]) as int);
      if (c == 3) {
        r.add((s[1] as List)[0] as int);
        o.add((s[1] as List)[1] as int);
      }
    }
    var u = calNFunD(t) +
        calNFunP(n, false) +
        calNFunP(r, true) +
        calNFunP(o, true);
    if (u.length % 6 != 0) u += _bin(0, 6 - u.length % 6);
    const s =
        '()*,-./0123456789:?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~';
    final sb = StringBuffer();
    for (var r0 = 0; r0 < u.length ~/ 6; r0++) {
      sb.write(s[int.parse(u.substring(6 * r0, 6 * (r0 + 1)), radix: 2)]);
    }
    return sb.toString();
  }

  /// cal_tt 与 [GeetestGt3.calAa] 同算法(c[0],c[2],c[4] + s hex 插入噪声)。
  static String calTt(String t, List<int> c, String s) =>
      GeetestGt3.calAa(t, c, s);

  // AC(GPU 采样)固定指纹哈希,由 Python 参考预算,避免 double 字符串格式差异。
  static const _acHash = 'd348eea9ee98a7c9267199e355ccba3a';

  /// precheck 行为/指纹包(`cal_a`),提交给 ajax.php 换 `result:slide`。
  static Map<String, dynamic> calA(
      List<int> c, String s, String gt, String challenge,
      {Random? rand}) {
    final r = rand ?? Random();
    final ms = DateTime.now().millisecondsSinceEpoch;
    // 复制事件模板并填入递增时间戳。
    final ee = _eeTmpl.map((e) => List<dynamic>.from(e)).toList();
    var tt = ms;
    for (var i = 0; i < ee.length; i++) {
      if (ee[i].length >= 3) {
        ee[i][3] = tt;
      } else {
        ee[i][1] = tt;
      }
      tt += 2 + r.nextInt(29); // random(2,30)
    }
    final h3 = calNHelp3(ee);
    final n = calN(h3.r);
    final tsStr = '$ms';
    final oStr = _oTmpl.replaceAll(
        RegExp(r'data\d{4}\d+magic'), 'data${tsStr}magic');
    final t1233 = _t1233Tmpl.replaceAll(RegExp(r'\d{8}\d+'), tsStr);
    final passtime = 100 + r.nextInt(201); // random(100,300)
    final a = <String, dynamic>{
      'lang': 'zh-cn',
      'type': 'fullpage',
      'tt': calTt(n, c, s),
      'light': 'SPAN_0',
      's': hash_(GeetestGt3.bytesToString(help_(_rTmpl))),
      'h': hash_(GeetestGt3.bytesToString(help_(oStr))),
      'hh': hash_(oStr),
      'hi': hash_(t1233),
      'ep': calEp(h3.fp, h3.lp, gt, challenge, rand: r),
      'captcha_token': 'bboy',
      'passtime': passtime,
    };
    a['rp'] = hash_('$gt$challenge$passtime');
    return a;
  }

  static Map<String, dynamic> calEp(
      List<dynamic>? fp, List<dynamic>? lp, String gt, String challenge,
      {Random? rand}) {
    final r = rand ?? Random();
    final a = DateTime.now().millisecondsSinceEpoch;
    int rnd(int lo, int hi) => lo + r.nextInt(hi - lo + 1);
    final f = a + rnd(2, 8);
    final b = a + rnd(50, 80);
    final l = a + rnd(3, 9);
    final m = l + rnd(30, 50);
    final n = m + rnd(1, 5);
    final o = n + rnd(10, 50);
    final p = o + rnd(70, 90);
    final rr = p + rnd(10, 100);
    final sv = rr + rnd(1, 2);
    return {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'v': '8.7.9',
      'ip': '192.168.1.104,218.249.50.58',
      'f': hash_('$gt$challenge'),
      'de': false,
      'te': false,
      'me': true,
      'ven': 'Intel Open Source Technology Center',
      'ren': 'Mesa DRI Intel(R) UHD Graphics 620 (Kabylake GT2) ',
      'ac': _acHash,
      'pu': false,
      'ph': false,
      'ni': false,
      'se': false,
      'fp': fp,
      'lp': lp,
      'em': {'cp': 0, 'ek': '11', 'nt': 0, 'ph': 0, 'sc': 0, 'si': 0, 'wd': 0},
      'tm': {
        'a': a, 'b': b, 'c': b, 'd': 0, 'e': 0, 'f': f, 'g': f, 'h': f,
        'i': f, 'j': f, 'k': 0, 'l': l, 'm': m, 'n': n, 'o': o, 'p': p,
        'q': p, 'r': DateTime.now().millisecondsSinceEpoch, 's': sv, 't': sv,
        'u': sv,
      },
      'by': 0,
    };
  }

  static const _rTmpl = 'M(*((1((M((';

  static const _oTmpl =
      '6322magic data7608magic dataCSS1Compatmagic data1magic data-1magic data-1magic data-1magic data-1magic data-1magic data-1magic data-1magic data-1magic data-1magic data2magic data3magic data-1magic data-1magic data-1magic data-1magic data-1magic data-1magic data-1magic data-1magic data-1magic data-1magic data1magic data-1magic data-1magic data-1magic data10magic data44magic data0magic data0magic data737magic data784magic data1687magic data888magic datazh-CNmagic datazh-CN,zhmagic data-1magic data1.5magic data24magic dataMozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36magic data1magic data1magic data1706magic data960magic data1707magic data960magic data1magic data1magic data1magic data-1magic dataLinux x86_64magic data0magic data-8magic data0a93728bbc5be4241e024b729f6c5e5dmagic data3f4cf59bdc7d0da206835d0e495e258amagic datainternal-pdf-viewer,mhjfbmdgcfjbbpaeojofohoefgiehjaimagic data0magic data-1magic data0magic data8magic dataArial,BitstreamVeraSansMono,Courier,CourierNew,Helvetica,Monaco,Times,TimesNewRoman,Wingdings,Wingdings2,Wingdings3magic data1563801637024magic data-1,-1,9,4,11,0,17,0,50,2,10,10,30,95,95,98,99,99,99,-1magic data-1magic data-1magic data12magic data-1magic data-1magic data-1magic data5magic datafalsemagic datafalse';

  static const _t1233Tmpl =
      '6322!!7608!!CSS1Compat!!1!!-1!!-1!!-1!!-1!!-1!!-1!!-1!!-1!!-1!!2!!3!!-1!!-1!!-1!!-1!!-1!!-1!!-1!!-1!!-1!!-1!!1!!-1!!-1!!-1!!10!!44!!0!!0!!737!!784!!1687!!888!!zh-CN!!zh-CN,zh!!-1!!1.5!!24!!Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36!!1!!1!!1706!!960!!1707!!960!!1!!1!!1!!-1!!Linux x86_64!!0!!-8!!0a93728bbc5be4241e024b729f6c5e5d!!3f4cf59bdc7d0da206835d0e495e258a!!internal-pdf-viewer,mhjfbmdgcfjbbpaeojofohoefgiehjai!!0!!-1!!0!!8!!Arial,BitstreamVeraSansMono,Courier,CourierNew,Helvetica,Monaco,Times,TimesNewRoman,Wingdings,Wingdings2,Wingdings3!!1563801637024!!-1,-1,9,4,11,0,17,0,50,2,10,10,30,95,95,98,99,99,99,-1!!-1!!-1!!12!!-1!!-1!!-1!!5!!false!!false';

  static final List<List<dynamic>> _eeTmpl = [
    ['move', 303, 418, 1563888260111, 'pointermove'],
    ['move', 302, 419, 1563888260129, 'pointermove'],
    ['move', 302, 418, 1563888260130, 'mousemove'],
    ['move', 301, 419, 1563888260157, 'pointermove'],
    ['move', 301, 418, 1563888260158, 'mousemove'],
    ['move', 301, 419, 1563888260162, 'pointermove'],
    ['move', 301, 419, 1563888260218, 'pointermove'],
    ['move', 301, 419, 1563888260258, 'pointermove'],
    ['move', 300, 419, 1563888260259, 'mousemove'],
    ['move', 300, 419, 1563888260293, 'pointermove'],
    ['move', 300, 420, 1563888260300, 'pointermove'],
    ['move', 299, 420, 1563888260642, 'pointermove'],
    ['move', 299, 421, 1563888260650, 'pointermove'],
    ['move', 298, 421, 1563888260663, 'pointermove'],
    ['move', 297, 421, 1563888260676, 'pointermove'],
    ['move', 296, 423, 1563888260685, 'pointermove'],
    ['move', 295, 423, 1563888260696, 'pointermove'],
    ['move', 294, 425, 1563888260709, 'pointermove'],
    ['move', 294, 424, 1563888260710, 'mousemove'],
    ['move', 293, 427, 1563888260719, 'pointermove'],
    ['move', 292, 427, 1563888260730, 'pointermove'],
    ['move', 291, 430, 1563888260746, 'pointermove'],
    ['move', 291, 431, 1563888260752, 'pointermove'],
    ['move', 290, 432, 1563888260763, 'pointermove'],
    ['move', 289, 434, 1563888260777, 'pointermove'],
    ['move', 289, 435, 1563888260785, 'pointermove'],
    ['move', 287, 440, 1563888260797, 'pointermove'],
    ['move', 287, 440, 1563888260798, 'mousemove'],
    ['move', 287, 441, 1563888260809, 'pointermove'],
    ['move', 287, 441, 1563888260810, 'mousemove'],
    ['move', 286, 443, 1563888260819, 'pointermove'],
    ['move', 284, 449, 1563888260831, 'pointermove'],
    ['move', 284, 448, 1563888260832, 'mousemove'],
    ['move', 283, 450, 1563888260844, 'pointermove'],
    ['move', 281, 453, 1563888260853, 'pointermove'],
    ['move', 280, 453, 1563888260854, 'mousemove'],
    ['move', 280, 454, 1563888260865, 'pointermove'],
    ['move', 279, 455, 1563888260877, 'pointermove'],
    ['move', 279, 455, 1563888260887, 'pointermove'],
    ['down', 279, 455, 1563888261343, 'pointerdown'],
    ['focus', 1563888261344],
    ['up', 279, 455, 1563888261450, 'pointerup'],
  ];
}
