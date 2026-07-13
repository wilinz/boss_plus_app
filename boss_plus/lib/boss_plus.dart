/// BOSS 直聘请求协议引擎(纯 Dart)。
///
/// - `sp`/`sig` 加密签名:[YzwgSigner](RC4 + MD5 + LZ4 + BZPBlock + base64url)
/// - Dio 拦截器链:设备头 → 签名加密 → 响应解密
/// - 客户端门面:[Boss]
library;

export 'src/core/boss.dart';
export 'src/core/base_client.dart';
export 'src/core/config/boss_app_config.dart';
export 'src/core/config/device_profiles.dart';
export 'src/core/crypto/yzwg_signer.dart';
export 'src/core/crypto/lz4_block.dart';
export 'src/core/session/session_jar.dart';
export 'src/http/boss_header_interceptor.dart';
export 'src/http/boss_sign_interceptor.dart';
export 'src/http/response_decrypt_interceptor.dart';
export 'src/im/boss_im.dart';
export 'src/im/chat_protocol.dart';
export 'src/im/gen/chat.pb.dart';
export 'src/model/login_result.dart';
export 'src/model/geetest.dart';
export 'src/core/geetest_gt3.dart';
export 'src/core/geetest_gt3_solver.dart';
export 'src/model/geek_info.dart';
export 'src/model/job_card.dart';
export 'src/model/job_detail.dart';
export 'src/model/job_filter.dart';
export 'src/utils/log.dart';
