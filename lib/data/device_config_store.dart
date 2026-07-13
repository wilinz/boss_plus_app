import 'dart:math';

import 'package:boss_plus/boss_plus.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:path/path.dart' as p;

import 'device_profile_repo.dart';

/// 设备指纹(`BossAppConfig`)的持久化持有者:**按用户名(登录手机号)分桶**。
///
/// 每个手机号一套设备指纹,首次用到时随机派生真实机型并整份存盘,之后复用;换号
/// 各自独立。未指定用户名(登录前)用 [_defaultKey] 桶。存盘为
/// `boss_devices.json`(`{_v,profiles:{key:cfg}}`);旧单文件 `boss_device.json`
/// 首次运行自动迁移进 [_defaultKey]。
class DeviceConfigStore {
  DeviceConfigStore._();
  static final DeviceConfigStore instance = DeviceConfigStore._();

  static const _fileName = 'boss_devices.json';
  static const _legacyFile = 'boss_device.json';
  static const _defaultKey = '__default__';

  final Map<String, BossAppConfig> _cache = {};
  bool _loaded = false;
  String? _dirPath;

  Future<String> get _dir async =>
      _dirPath ??= (await getApplicationDocumentsDirectory()).path;

  String _key(String? username) =>
      (username != null && username.trim().isNotEmpty)
          ? username.trim()
          : _defaultKey;

  /// 载入分桶存储(幂等);无新文件时从旧单文件迁移。
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final dir = await _dir;
    final saved = await FileSessionJar(p.join(dir, _fileName)).load();
    if (saved != null && saved['profiles'] is Map) {
      final m = (saved['profiles'] as Map).cast<String, dynamic>();
      m.forEach((k, v) =>
          _cache[k] = BossAppConfig.fromJson((v as Map).cast<String, dynamic>()));
    } else {
      // 迁移旧单文件(整份配置 / 仅 deviceId)→ 默认桶。
      final old = await FileSessionJar(p.join(dir, _legacyFile)).load();
      if (old != null && old['model'] != null) {
        _cache[_defaultKey] = BossAppConfig.fromJson(old);
      } else if (old != null &&
          (old['deviceId'] as String?)?.isNotEmpty == true) {
        _cache[_defaultKey] =
            BossAppConfig.forDevice(deviceId: old['deviceId'] as String);
      }
      if (_cache.isNotEmpty) await _flush();
    }
    _loaded = true;
  }

  Future<void> _flush() async {
    final dir = await _dir;
    await FileSessionJar(p.join(dir, _fileName)).save({
      '_v': 2,
      'profiles': {for (final e in _cache.entries) e.key: e.value.toJson()},
    });
  }

  /// 取某用户名(手机号)的设备指纹:已存则复用,否则随机派生一台并落盘。
  Future<BossAppConfig> get({String? username}) async {
    await _ensureLoaded();
    final k = _key(username);
    final existing = _cache[k];
    if (existing != null) return existing;
    final cfg = randomDevice();
    _cache[k] = cfg;
    await _flush();
    return cfg;
  }

  /// 覆盖保存某用户名(手机号)编辑后的设备指纹。
  Future<void> save(BossAppConfig cfg, {String? username}) async {
    await _ensureLoaded();
    _cache[_key(username)] = cfg;
    await _flush();
  }

  /// 删除某用户名(手机号)的设备指纹桶(删除账号时调用)。
  Future<void> remove(String? username) async {
    await _ensureLoaded();
    if (_cache.remove(_key(username)) != null) await _flush();
  }

  /// 随机派生一台真实机型:优先从内嵌设备库(1388 台)按权重挑一台,
  /// 未加载时回退到引擎内置的少量样本。uniqid、网络类型、屏幕分辨率始终新随机 ——
  /// 每个用户由此得到唯一且持久的设备指纹。
  static BossAppConfig randomDevice() {
    final id = randomDeviceId();
    final base = BossAppConfig.forDevice(deviceId: id);
    final prof = DeviceProfileRepo.instance.pickWeighted();
    final (w, h) = randomScreen();
    return base.copyWith(
      manufacturer: prof?.manufacturer,
      model: prof?.model,
      osVersion: prof?.osVersion,
      netType: randomNetType(),
      screenWidth: w,
      screenHeight: h,
    );
  }

  /// 随机屏幕分辨率(加权:1080p 主流,少量 2K 旗舰 / 低端)。
  static (int, int) randomScreen() {
    const weighted = [
      ((1080, 2400), 34),
      ((1080, 2340), 18),
      ((1080, 2412), 12),
      ((1080, 2160), 8),
      ((1220, 2712), 8), // 小米旗舰
      ((1264, 2780), 5),
      ((1440, 3200), 5), // 2K 旗舰
      ((1200, 2670), 4),
      ((720, 1600), 4), // 低端
      ((900, 2000), 2),
    ];
    final total = weighted.fold<int>(0, (a, e) => a + e.$2);
    var t = Random().nextInt(total);
    for (final (wh, w) in weighted) {
      t -= w;
      if (t < 0) return wh;
    }
    return (1080, 2400);
  }

  /// 随机网络类型(加权:WiFi 最常见,其次 5G / 4G,少量 3G)。
  static String randomNetType() {
    const weighted = [
      ('WIFI', 55),
      ('5G', 25),
      ('4G', 18),
      ('3G', 2),
    ];
    final total = weighted.fold<int>(0, (a, e) => a + e.$2);
    var t = Random().nextInt(total);
    for (final (net, w) in weighted) {
      t -= w;
      if (t < 0) return net;
    }
    return 'WIFI';
  }

  static String randomDeviceId() {
    final r = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(32, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
