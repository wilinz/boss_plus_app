import 'dart:convert';

/// 极验(Geetest gt3 slide)初始化参数,来自 BOSS `man/machine` 响应。
///
/// App 拿到 [gt]/[challenge] 后,用极验官方 JS(WebView 内)拉起滑块;
/// [success]==1 表示走极验二次验证,==0 表示服务端判定无需验证(bypass)。
///
/// 真机响应结构(已实证):
/// ```json
/// {"code":0,"zpData":{
///     "startCaptcha":"{\"success\":1,\"challenge\":\"...\",\"gt\":\"...\"}",
///     "captchaType":1, "isMachine":true }}
/// ```
/// 注意 gt/challenge/success **嵌在 `zpData.startCaptcha` 这个 JSON 字符串里**。
class GeetestRegister {
  const GeetestRegister({
    required this.gt,
    required this.challenge,
    required this.success,
    this.isMachine = true,
    this.newCaptcha = true,
  });

  final String gt;
  final String challenge;
  final bool success;

  /// 服务端判定是否为机器(true 需人机验证)。
  final bool isMachine;
  final bool newCaptcha;

  /// 需要拉起滑块:success==1(极验初始化成功)。
  bool get needVerify => success && gt.isNotEmpty && challenge.isNotEmpty;

  factory GeetestRegister.fromJson(Map<String, dynamic> j) {
    final zp = j['zpData'] is Map
        ? Map<String, dynamic>.from(j['zpData'] as Map)
        : j;
    int asInt(dynamic v) =>
        v is num ? v.toInt() : (v is bool ? (v ? 1 : 0) : int.tryParse('$v') ?? 0);

    // 优先解析嵌套的 startCaptcha(JSON 字符串或已是 Map)
    Map<String, dynamic> cap = {};
    final sc = zp['startCaptcha'];
    if (sc is String && sc.trim().isNotEmpty) {
      try {
        cap = Map<String, dynamic>.from(jsonDecode(sc) as Map);
      } catch (_) {}
    } else if (sc is Map) {
      cap = Map<String, dynamic>.from(sc);
    }
    // 回退:有些接口 gt/challenge 直接在 zpData
    final src = cap.isNotEmpty ? cap : zp;

    return GeetestRegister(
      gt: (src['gt'] ?? src['geetest_gt'] ?? '').toString(),
      challenge:
          (src['challenge'] ?? src['geetest_challenge'] ?? '').toString(),
      success: asInt(src['success'] ?? src['geetest_success'] ?? 0) == 1,
      isMachine: (zp['isMachine'] ?? true) == true,
      newCaptcha: (src['new_captcha'] ?? src['newCaptcha'] ?? true) == true,
    );
  }

  @override
  String toString() =>
      'GeetestRegister(gt=$gt, challenge=$challenge, success=$success, isMachine=$isMachine)';
}

/// 用户滑块通过后,极验官方 JS `getValidate()` 返回的三元组。
///
/// 由 WebView 回传;再随 BOSS `smsCode`/`codeLogin` 上送(参数名以真机抓包为准,
/// 见 [toBossParams])。
class GeetestResult {
  const GeetestResult({
    required this.challenge,
    required this.validate,
    required this.seccode,
  });

  final String challenge;
  final String validate;
  final String seccode;

  factory GeetestResult.fromJson(Map<String, dynamic> j) => GeetestResult(
        challenge:
            (j['geetest_challenge'] ?? j['challenge'] ?? '').toString(),
        validate: (j['geetest_validate'] ?? j['validate'] ?? '').toString(),
        seccode: (j['geetest_seccode'] ?? j['seccode'] ?? '').toString(),
      );

  /// 组装成 BOSS 登录接口需要的参数(challenge/validate/seccode)。
  /// 真机 smsCode 用 `challenge`;validate/seccode 参数名待真机校准(此处给常见名)。
  Map<String, String> toBossParams() => {
        'challenge': challenge,
        'validate': validate,
        'seccode': seccode,
      };

  @override
  String toString() => 'GeetestResult(challenge=$challenge, validate=$validate)';
}
