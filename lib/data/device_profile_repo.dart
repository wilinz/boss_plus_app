import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

/// 一条真实设备指纹样本(厂商 / 机型代号 / 系统版本 / 权重)。
class DeviceProfile {
  const DeviceProfile(this.manufacturer, this.model, this.osVersion, this.weight);

  final String manufacturer;
  final String model;
  final String osVersion;

  /// 机型流行度权重(越大越常见);加权随机时命中概率更高,更好地融入真实分布。
  final int weight;
}

/// 内嵌的真实设备库(`assets/device_profiles.json`,1388 台,导出自 keep_plus)。
///
/// 取代此前写死的 10 条 `kRealDeviceProfiles`:按权重随机挑一台,派生更真实、更分散
/// 的设备指纹。首次使用前需 [load](在 `main` 里 await)。
class DeviceProfileRepo {
  DeviceProfileRepo._();
  static final DeviceProfileRepo instance = DeviceProfileRepo._();

  static const _assetPath = 'assets/device_profiles.json';

  List<DeviceProfile> _profiles = const [];
  int _totalWeight = 0;

  bool get isLoaded => _profiles.isNotEmpty;
  int get count => _profiles.length;

  /// 从 asset 载入设备库(幂等)。解析失败则保持空,调用方回退到引擎内置样本。
  Future<void> load() async {
    if (isLoaded) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _profiles = [
        for (final e in list)
          DeviceProfile(
            e['m'] as String,
            e['d'] as String,
            e['o'] as String,
            (e['w'] as num?)?.toInt() ?? 1,
          ),
      ];
      _totalWeight = _profiles.fold(0, (a, p) => a + (p.weight > 0 ? p.weight : 1));
    } catch (_) {
      _profiles = const [];
      _totalWeight = 0;
    }
  }

  /// 按权重随机挑一台。[rng] 可注入(确定性派生用);未加载返回 null。
  DeviceProfile? pickWeighted([Random? rng]) {
    if (!isLoaded) return null;
    final r = rng ?? Random();
    var t = r.nextInt(_totalWeight);
    for (final p in _profiles) {
      t -= p.weight > 0 ? p.weight : 1;
      if (t < 0) return p;
    }
    return _profiles.last;
  }
}
