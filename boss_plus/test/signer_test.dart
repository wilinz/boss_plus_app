import 'dart:convert';
import 'dart:typed_data';

import 'package:boss_plus/src/core/crypto/yzwg_signer.dart';
import 'package:boss_plus/src/core/crypto/lz4_block.dart';
import 'package:test/test.dart';

void main() {
  final signer = YzwgSigner(); // 默认 SECRET32 = 官方 14.070 实测值

  test('RC4 matches reference vector', () {
    // RC4("Key","Plaintext") = BBF316E8D940AF0AD3
    final out = YzwgSigner.rc4(ascii.encode('Key'), ascii.encode('Plaintext'));
    expect(out, [0xBB, 0xF3, 0x16, 0xE8, 0xD9, 0x40, 0xAF, 0x0A, 0xD3]);
  });

  test('MD5 hex', () {
    expect(YzwgSigner.md5Hex(ascii.encode('abc')),
        '900150983cd24fb0d6963f7d28e17f72');
  });

  test('LZ4 literal-only round trip', () {
    final src = Uint8List.fromList(
        ascii.encode('client_info=%7B%22version%22%3A%2213%22%7D&v=14.070'));
    final comp = Lz4Block.compressBlock(src);
    final back = Lz4Block.decompressBlock(comp);
    expect(back, src);
  });

  test('decode real captured sp (SECRET32 key) -> strD', () {
    // 真机 Frida 抓到的一次请求(免 token 接口 → key=SECRET32),sp 截断也能解出前缀。
    const sp =
        'zwp_NCTRJTSwi3DeyMDkHJuGvU0MAYbyceqJ44s9CxuyL65jv20XaVYg1XpFLNVaF7'
        'LolNJtanuLr-ARNMh36qI3RFO3xe8JyDZtt-TQVeh_TOtTgNw-LeFjEs8hx0tJoj7v'
        '9ncKmYZWKNui4my5EMB';
    // 取前 120 个 base64 字符(4 的倍数,避开截断的末尾组),部分解码即可验证前缀。
    final strD = signer.decode(sp.substring(0, 120)); // 无 secretKey
    expect(strD, startsWith('client_info=%7B%22version%22%3A%2213%22'));
  });

  test('sign() self round-trip: decode(sp) == strD', () {
    final params = {
      'client_info': '{"version":"13","os":"Android"}',
      'req_time': '1783186014239',
      'uniqid': '55395b57-feb0-49bc-bce2-c54fa7be5a7d',
      'v': '14.070',
      'app_id': '1003',
    };
    final r = signer.sign(apiPath: '/api/zpCommon/userConfig', params: params);
    expect(signer.decode(r.sp), r.strD);
    expect(r.sig, startsWith('V3.0'));
    // sig 可离线复算校验
    final expectSig =
        'V3.0${YzwgSigner.md5Hex(ascii.encode('/api/zpCommon/userConfig'
            '${r.strD}${YzwgSigner.kDefaultSecret32}'))}';
    expect(r.sig, expectSig);
  });

  test('encodePassword matches real device account (byte-exact)', () {
    // 真机: phone 19944719875 → account "vGkWQnyJd2aIvEU=" (base64(RC4(phone,SECRET32)))
    expect(signer.encodePassword('19944719875'), 'vGkWQnyJd2aIvEU=');
    expect(signer.decodePassword('vGkWQnyJd2aIvEU='), '19944719875');
  });

  test('logged-in key = SECRET32 + secretKey (64B)', () {
    final params = {'v': '14.070', 'app_id': '1003'};
    const secretKey = 'ba45619f1c8b9569645c2206fbfaab4a';
    final r = signer.sign(
        apiPath: '/api/zpgeek/app/f1/query',
        params: params,
        secretKey: secretKey);
    expect(signer.decode(r.sp, secretKey: secretKey), r.strD);
  });
}
