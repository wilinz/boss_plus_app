import 'dart:convert';

import 'package:dio/dio.dart';

import 'geetest_gt3.dart';
import 'geetest_gt3_behavior.dart';

/// gt3 滑块图包 + 刷新后的 challenge。
class GeetestGt3Challenge {
  GeetestGt3Challenge({
    required this.bgUrl,
    required this.sliceUrl,
    required this.fullBgUrl,
    required this.challenge,
    required this.ypos,
    required this.xpos,
    required this.height,
  });

  /// 带缺口的背景图。
  final String bgUrl;

  /// 拼图块(PNG,透明底)。
  final String sliceUrl;

  /// 完整背景(无缺口),仅自动解法对比用。
  final String fullBgUrl;

  /// is_next 刷新后的 challenge(提交 ajax 用)。
  final String challenge;

  final int ypos;
  final int xpos;
  final int height;
}

/// 极验 gt3 滑块**纯 Dart** 求解流程(无 WebView)。
///
/// 流程(对齐 BOSS 真机抓包,`client_type=android`/`product=embed`):
/// 1. `gettype.php` 确认类型;
/// 2. `get.php`(config)→ 取 `c`/`s`;
/// 3. `get.php?is_next`(embed)→ 取 `bg`/`slice`/`fullbg` 图与刷新 challenge;
/// 4. 手动拖动得到距离+轨迹 → [GeetestGt3.buildW] 造 `w`;
/// 5. `ajax.php`(`client_type=web_mobile`)提交 → 拿 `validate`。
///
/// 注:register 阶段的短 `w`、precheck POST ajax、以及 ep/pt 细节可能需按真机
/// 微调(macOS 无法联调),见 boss-geetest-gt3-selfimpl 记录。
class GeetestGt3Solver {
  GeetestGt3Solver({required this.gt, required this.challenge, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              responseType: ResponseType.plain,
              headers: {
                'Referer': 'https://static.geetest.com/',
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 '
                        '(KHTML, like Gecko) Chrome/108.0.0.0 Mobile Safari/537.36',
              },
            ));

  static const _api = 'https://apiv6.geetest.com';

  final String gt;
  String challenge;
  final Dio _dio;

  final GeetestGt3 _cipher = GeetestGt3();
  List<int> c = const [];
  String s = '';

  int get _ts => DateTime.now().millisecondsSinceEpoch;

  /// 解析 JSONP:`geetest_123({...})` 或 `({...})` → Map。
  Map<String, dynamic> _jsonp(dynamic body) {
    final text = body is String ? body : body.toString();
    final m = RegExp(r'\((\{.*\})\)', dotAll: true).firstMatch(text);
    final raw = m != null ? m.group(1)! : text;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  /// 拉配置与图包。
  Future<GeetestGt3Challenge> load() async {
    // 1. gettype
    await _dio.get('$_api/gettype.php',
        queryParameters: {'gt': gt, 't': '$_ts'});

    // 2. get.php 注册(带 RSA 的 register w,确立会话 key)→ c, s
    final cfg = _jsonp((await _dio.get('$_api/get.php', queryParameters: {
      'gt': gt,
      'challenge': challenge,
      'client_type': 'android',
      'lang': 'zh-cn',
      'pt': '0',
      'w': _cipher.registerW(gt, challenge),
    }))
        .data);
    final data = cfg['data'] is Map
        ? Map<String, dynamic>.from(cfg['data'] as Map)
        : cfg;
    c = (data['c'] as List).map((e) => (e as num).toInt()).toList();
    s = data['s'].toString();

    // 3. ajax.php precheck(行为包,复用会话 key)→ result:slide,激活 challenge
    await _dio.get('$_api/ajax.php', queryParameters: {
      'gt': gt,
      'challenge': challenge,
      'client_type': 'android',
      'lang': 'zh-cn',
      'pt': '0',
      'w': _cipher.precheckW(GeetestGt3Behavior.calA(c, s, gt, challenge)),
    });

    // 4. get.php?is_next → 图包 + 刷新 challenge
    final img = _jsonp((await _dio.get('$_api/get.php', queryParameters: {
      'is_next': 'true',
      'mobile': 'true',
      'product': 'embed',
      'width': '100%',
      'https': 'true',
      'gt': gt,
      'challenge': challenge,
      'lang': 'zh-CN',
      'type': 'slide3',
      'api_server': 'apiv6.geetest.com',
      'callback': 'geetest_$_ts',
    }))
        .data);
    challenge = (img['challenge'] ?? challenge).toString();

    final servers = (img['static_servers'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const ['static.geetest.com/'];
    String url(String? p) {
      if (p == null || p.isEmpty) return '';
      final host = servers.first.replaceAll(RegExp(r'/+$'), '');
      return 'https://$host/$p';
    }

    return GeetestGt3Challenge(
      bgUrl: url(img['bg'] as String?),
      sliceUrl: url(img['slice'] as String?),
      fullBgUrl: url(img['fullbg'] as String?),
      challenge: challenge,
      ypos: (img['ypos'] as num?)?.toInt() ?? 0,
      xpos: (img['xpos'] as num?)?.toInt() ?? 0,
      height: (img['height'] as num?)?.toInt() ?? 160,
    );
  }

  /// 提交拖动结果,成功返回 `validate`(失败返回 null)。
  ///
  /// - [distance] 缺口像素距离(图坐标)
  /// - [trace] 拖动轨迹 `[x, y, tMillis]`(相对起点)
  Future<String?> submit(num distance, List<List<num>> trace) async {
    final w = _cipher.buildW(
      gt: gt,
      challenge: challenge,
      distance: distance,
      trace: trace,
      c: c,
      s: s,
    );
    final rawResp = (await _dio.get('$_api/ajax.php', queryParameters: {
      'gt': gt,
      'challenge': challenge,
      'lang': 'zh-cn',
      'client_type': 'web_mobile',
      'w': w,
      'callback': 'geetest_$_ts',
    }))
        .data;
    // ignore: avoid_print
    assert(() {
      print('[gt3] ajax raw: $rawResp');
      return true;
    }());
    final res = _jsonp(rawResp);
    final ok = res['success'] == 1 || res['result'] == 'success';
    final validate = res['validate']?.toString();
    return (ok && validate != null && validate.isNotEmpty) ? validate : null;
  }
}
