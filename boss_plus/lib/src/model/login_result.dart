/// 登录结果(codeLogin 响应归一化)。
///
/// 响应体经 [BossResponseDecryptInterceptor] 解密为 JSON,常见结构
/// `{"code":0,"message":"Success","zpData":{...}}`。会话所需的 `token2`/`secretKey`
/// 从 zpData 里按常见字段名提取(不同版本字段名可能不同,见 [BossLoginResult.fromResponse])。
class BossLoginResult {
  BossLoginResult({
    required this.code,
    required this.message,
    required this.token2,
    required this.secretKey,
    required this.raw,
  });

  final int code;
  final String message;
  final String? token2;
  final String? secretKey;
  final Map<String, dynamic> raw;

  bool get ok => code == 0;
  bool get hasSession =>
      (secretKey != null && secretKey!.isNotEmpty);

  factory BossLoginResult.fromResponse(dynamic data) {
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final zp = map['zpData'];
    final zpData = zp is Map ? Map<String, dynamic>.from(zp) : const {};

    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = zpData[k] ?? map[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    return BossLoginResult(
      code: (map['code'] as num?)?.toInt() ?? -1,
      message: map['message']?.toString() ?? '',
      token2: pick(['token2', 't2', 'token']),
      secretKey: pick(['secretKey', 'sk', 'secret_key']),
      raw: map,
    );
  }

  @override
  String toString() =>
      'BossLoginResult(code=$code, msg=$message, token2=${token2 != null}, '
      'secretKey=${secretKey != null})';
}
