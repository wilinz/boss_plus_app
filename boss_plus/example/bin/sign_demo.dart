import 'package:boss_plus/boss_plus.dart';

/// 离线演示:给定参数 → 打印 sp / sig,并解密自校验(不联网)。
void main() {
  final signer = YzwgSigner(); // 默认 SECRET32(官方 14.070 实测)

  final params = {
    'client_info': '{"version":"13","os":"Android","model":"Redmi||22021211RC"}',
    'req_time': DateTime.now().millisecondsSinceEpoch.toString(),
    'uniqid': '55395b57-feb0-49bc-bce2-c54fa7be5a7d',
    'v': '14.070',
    'curidentity': '0',
  };

  // 未登录(免 token):key = SECRET32
  final r1 = signer.sign(apiPath: '/api/zpCommon/userConfig', params: params);
  print('=== 未登录 (key=SECRET32) ===');
  print('strD = ${r1.strD}');
  print('sp   = ${r1.sp}');
  print('sig  = ${r1.sig}');
  print('解密回 strD 一致? ${signer.decode(r1.sp) == r1.strD}');

  // 登录后:key = SECRET32 + secretKey
  const secretKey = 'ba45619f1c8b9569645c2206fbfaab4a';
  final r2 = signer.sign(
    apiPath: '/api/zpgeek/app/f1/chat/recommend/query',
    params: params,
    secretKey: secretKey,
  );
  print('\n=== 登录后 (key=SECRET32+secretKey) ===');
  print('sp  = ${r2.sp}');
  print('sig = ${r2.sig}');
  print('解密回 strD 一致? ${signer.decode(r2.sp, secretKey: secretKey) == r2.strD}');
}
