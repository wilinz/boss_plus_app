# boss_plus_app

BOSS 直聘(zhipin.com)请求协议客户端。纯 Dart 引擎 + 命令行,**单账号、无服务端**。
架构对齐 `keep_plus_app`(引擎包 + CLI),协议逆向依据见仓库根 `docs/`。

## 结构

```
boss_plus_app/
├── boss_plus/          # 纯 Dart 协议引擎(可被 App/CLI 复用)
│   ├── lib/src/core/crypto/    # yzwg_signer(RC4+MD5+LZ4+BZPBlock) / lz4_block
│   ├── lib/src/core/config/    # BossAppConfig 设备指纹 / client_info
│   ├── lib/src/core/session/   # SessionJar(内存/文件)
│   ├── lib/src/http/           # 拦截器:header → sign → response-decrypt
│   ├── lib/src/core/boss.dart  # Boss 客户端门面(登录/请求)
│   └── test/                   # 签名单测(含真机 sp 回放)
└── cli/                # 命令行:sign / login / get / post
```

## 协议一句话

每个发往 `*.zhipin.com` 的请求由拦截器自动补齐:
- **Header**:`User-Agent`、`traceId`、`zp-accept-encoding/encrypting/compressing`、`t2`(登录后)
- **参数**:业务参数 + 公共参数(`client_info`/`req_time`/`uniqid`/`v`/`curidentity`)→
  排序成 `strD` → 出站只带 `sp`(加密参数包)、`sig`(签名)、`app_id=1003`

算法(纯 Dart 复现 `libyzwg.so`,已与真机逐字节核对):
```
sp  = base64url( RC4( "BZPBlock"+头 + LZ4(strD), key ) )
sig = "V3.0" + MD5( apiPath + strD + SECRET32 + secretKey )
key = SECRET32              (未登录/免token接口)
    = SECRET32 + secretKey  (登录后)
```
`SECRET32` = per-build 常量(绑定签名证书),内置官方 14.070 实测值。

## 用法

### 离线签名(不联网)
```bash
cd cli && dart pub get
dart run bin/boss_cli.dart sign -p /api/zpCommon/userConfig -d v=14.070 -d uniqid=abc
# 登录态签名:再加 --secret-key <会话密钥>
```

### 登录(短信验证码)
```bash
dart run bin/boss_cli.dart login -m 19900000000        # 自动发码并交互输入
dart run bin/boss_cli.dart login -m 19900000000 -c 1234 # 直接给码
# 会话(token2/secretKey)存到 .boss_session.json
```

### 已登录发请求
```bash
dart run bin/boss_cli.dart get  -p /api/zpCommon/userConfig
dart run bin/boss_cli.dart post -p /api/zpCommon/toggle/all -d key=value
# 免 token 接口加 --no-token
```

### 引擎内嵌(Dart/Flutter)
```dart
final boss = await Boss.newInstance(
  appConfig: BossAppConfig.forDevice(deviceId: 'my-device'),
  sessionJar: FileSessionJar('.boss_session.json'),
);
await boss.sendSmsCode(mobile: '199...');
await boss.loginWithSms(mobile: '199...', code: '1234');
final r = await boss.getApi('/api/zpCommon/userConfig');
```

## 测试
```bash
cd boss_plus && dart test    # RC4/MD5/LZ4 向量 + 真机 sp 回放 + 往返自洽
```

## 注意
- `SECRET32` 与 App 版本/签名证书绑定;换版本需重新 dump(Frida hook `rc4_ksa` 或读 so `base+0x544470`)。
- 仅供协议研究/自动化学习。
