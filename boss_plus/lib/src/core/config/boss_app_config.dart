import 'dart:convert';
import 'dart:math';

import 'device_profiles.dart';

/// BOSS 直聘 App 配置(设备指纹 + 版本)。
///
/// 负责两件事:
/// 1. 拼接 `User-Agent`:`NetType/{net} Screen/{w}X{h} BossZhipin/{ver} Android {sdk}`。
/// 2. 生成公共参数里的 `client_info`(设备/网络/机型/uniqid/oaid/did 等 JSON,
///    被打进加密的 `sp`),以及 `curidentity`/`v`/`uniqid` 等。
///
/// 参考 `docs/boss-request-signing.md`。字段无默认机型:必须显式或用
/// [BossAppConfig.forDevice] 由 deviceId 确定性派生真实机型(去特征化)。
class BossAppConfig {
  BossAppConfig({
    required this.uniqid,
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    this.versionName = '14.070',
    this.versionCode = '14070',
    this.appId = '1003',
    this.channel = '5',
    this.netType = 'WIFI',
    this.screenWidth = 1080,
    this.screenHeight = 2400,
    this.oaid = '',
    this.did = '',
    this.curIdentity = '0',
  });

  /// 设备唯一 id(公共参数 `uniqid` / client_info.uniqid)。
  final String uniqid;

  /// 机型代号,如 `22021211RC`(client_info.model 用 `厂商||机型`)。
  final String model;

  /// 厂商,如 `Redmi`。
  final String manufacturer;

  /// Android 版本,如 `13`。
  final String osVersion;

  /// App 版本名(UA / client_info.version_flag)。签名绑定 SECRET32→版本,勿乱改。
  final String versionName;

  final String versionCode;

  /// 业务 app_id,BOSS 固定 `1003`。
  final String appId;

  /// 渠道号。
  final String channel;

  /// 网络类型(UA 里的 NetType,如 WIFI/4G/5G)。
  final String netType;

  final int screenWidth;
  final int screenHeight;

  /// OAID(可空)。
  final String oaid;

  /// 数盟设备指纹 did(可空)。
  final String did;

  /// 当前身份:`0` 游客/未选,`1`/`2` 牛人/BOSS。
  final String curIdentity;

  /// UA:`NetType/WIFI Screen/1080X2400 BossZhipin/14.070 Android 13`。
  String get userAgent =>
      'NetType/$netType Screen/${screenWidth}X$screenHeight '
      'BossZhipin/$versionName Android $osVersion';

  /// 由 [deviceId] 确定性派生一套真实机型(同 id → 同机型,跨登录稳定)。
  factory BossAppConfig.forDevice({
    required String deviceId,
    String? uniqid,
    String versionName = '14.070',
  }) {
    final seed =
        deviceId.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
    final rng = Random(seed);
    final p = kRealDeviceProfiles[rng.nextInt(kRealDeviceProfiles.length)];
    return BossAppConfig(
      uniqid: uniqid ?? deviceId,
      manufacturer: p.$1,
      model: p.$2,
      osVersion: _varyOs(p.$3, rng),
      versionName: versionName,
    );
  }

  static String _varyOs(String base, Random r) {
    final n = int.tryParse(base);
    if (n == null) return base;
    final lo = (n - 1).clamp(9, 16);
    final hi = (n + 2).clamp(9, 16);
    return (lo + r.nextInt(hi - lo + 1)).toString();
  }

  /// 构建 `client_info` JSON(值会被打进加密 sp;字段对齐真机抓包)。
  Map<String, dynamic> buildClientInfo({
    bool background = false,
    int? locPerm,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return {
      'version': osVersion,
      'os': 'Android',
      'start_time': now,
      'resume_time': now,
      'channel': channel,
      'model': '$manufacturer||$model',
      'dzt': 0,
      'loc_per': locPerm ?? 1,
      'uniqid': uniqid,
      if (oaid.isNotEmpty) 'oaid': oaid,
      'oaid_honor': '00000000-0000-0000-0000-000000000000',
      if (did.isNotEmpty) 'did': did,
      'is_bg_req': background ? 1 : 0,
      'network': netType.toLowerCase(),
      'abi': 'arm64-v8a',
      'version_flag': versionName,
    };
  }

  /// 组装每个请求都会注入的公共参数(见 native `m.c`)。
  Map<String, String> commonParams() => {
        'curidentity': curIdentity,
        'v': versionName,
        'req_time': DateTime.now().millisecondsSinceEpoch.toString(),
        'uniqid': uniqid,
        'client_info': jsonEncode(buildClientInfo()),
      };

  factory BossAppConfig.fromJson(Map<String, dynamic> j) => BossAppConfig(
        uniqid: j['uniqid'] as String,
        model: j['model'] as String,
        manufacturer: j['manufacturer'] as String,
        osVersion: j['osVersion'] as String,
        versionName: j['versionName'] as String? ?? '14.070',
        versionCode: j['versionCode'] as String? ?? '14070',
        appId: j['appId'] as String? ?? '1003',
        channel: j['channel'] as String? ?? '5',
        netType: j['netType'] as String? ?? 'WIFI',
        screenWidth: (j['screenWidth'] as num?)?.toInt() ?? 1080,
        screenHeight: (j['screenHeight'] as num?)?.toInt() ?? 2400,
        oaid: j['oaid'] as String? ?? '',
        did: j['did'] as String? ?? '',
        curIdentity: j['curIdentity'] as String? ?? '0',
      );

  Map<String, dynamic> toJson() => {
        'uniqid': uniqid,
        'model': model,
        'manufacturer': manufacturer,
        'osVersion': osVersion,
        'versionName': versionName,
        'versionCode': versionCode,
        'appId': appId,
        'channel': channel,
        'netType': netType,
        'screenWidth': screenWidth,
        'screenHeight': screenHeight,
        'oaid': oaid,
        'did': did,
        'curIdentity': curIdentity,
      };

  /// 基于当前配置改写部分字段(编辑设备指纹用)。
  BossAppConfig copyWith({
    String? uniqid,
    String? model,
    String? manufacturer,
    String? osVersion,
    String? versionName,
    String? versionCode,
    String? channel,
    String? netType,
    int? screenWidth,
    int? screenHeight,
    String? oaid,
    String? did,
  }) =>
      BossAppConfig(
        uniqid: uniqid ?? this.uniqid,
        model: model ?? this.model,
        manufacturer: manufacturer ?? this.manufacturer,
        osVersion: osVersion ?? this.osVersion,
        versionName: versionName ?? this.versionName,
        versionCode: versionCode ?? this.versionCode,
        appId: appId,
        channel: channel ?? this.channel,
        netType: netType ?? this.netType,
        screenWidth: screenWidth ?? this.screenWidth,
        screenHeight: screenHeight ?? this.screenHeight,
        oaid: oaid ?? this.oaid,
        did: did ?? this.did,
        curIdentity: curIdentity,
      );
}
