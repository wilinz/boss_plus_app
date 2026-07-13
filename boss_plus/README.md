# boss_plus

BOSS 直聘(zhipin.com)请求协议引擎(纯 Dart)。复现 `keep_plus` 架构:加密/签名 + Dio 拦截器链。

## 核心:YzwgSigner

纯 Dart 复现 `libyzwg.so`(逆向见仓库 `docs/libyzwg-native-analysis.md`):

```dart
final signer = YzwgSigner();               // 默认 SECRET32(官方 14.070 实测)
final r = signer.sign(
  apiPath: '/api/zpCommon/userConfig',
  params: {'v': '14.070', 'uniqid': 'abc'},
  secretKey: null,                          // 登录后传会话密钥
);
r.sp;  r.sig;                               // → 放进 query/body
signer.decode(r.sp);                        // 解密自校验 → strD
```

- `sp  = base64url( RC4( BZPBlock头 + LZ4(strD), key ) )`
- `sig = "V3.0" + MD5( apiPath + strD + SECRET32 + secretKey )`
- RC4/MD5 标准算法;LZ4 用「纯 literal 块」(服务端可解,免实现压缩器);base64 URL 变体 `+→- /→_ =→~`。

## Boss 客户端

```dart
final boss = await Boss.newInstance(
  appConfig: BossAppConfig.forDevice(deviceId: 'dev-1'),
  sessionJar: FileSessionJar('.boss_session.json'),
);
await boss.loginWithSms(mobile: '199...', code: '1234');
await boss.getApi('/api/zpCommon/userConfig');
```

拦截器链:`BossHeaderInterceptor`(设备头/t2) → `BossSignInterceptor`(公共参数+sp+sig) →
`BossResponseDecryptInterceptor`(RC4 响应解密)。

## 测试
```bash
dart test
```
覆盖:RC4/MD5 标准向量、LZ4 往返、**真机抓包 sp 解密回 strD**、sign 往返自洽、登录态 64B key。
