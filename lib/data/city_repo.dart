import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 一个市级城市(BOSS 城市编码 + 名称 + 拼音,用于筛选/搜索)。
class City {
  const City(this.code, this.name, this.pinyin, this.firstChar, this.hot);

  final int code;
  final String name;
  final String pinyin;
  final String firstChar;
  final bool hot;
}

/// 内嵌的全量市级城市库(`assets/cities.json`,373 城,提取自官方 app 内置 city.json,
/// 城市码与官方一致)。取代此前写死的 8 个城市。首次使用前需 [load]。
class CityRepo {
  CityRepo._();
  static final CityRepo instance = CityRepo._();

  static const _assetPath = 'assets/cities.json';

  List<City> _all = const [];
  List<City> _hot = const [];

  bool get isLoaded => _all.isNotEmpty;
  List<City> get all => _all;
  List<City> get hot => _hot;

  Future<void> load() async {
    if (isLoaded) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _all = [
        for (final e in list)
          City(
            (e['c'] as num).toInt(),
            e['n'] as String,
            (e['p'] as String?) ?? '',
            (e['f'] as String?) ?? '',
            e['h'] == 1,
          ),
      ];
      _hot = _all.where((c) => c.hot).toList();
    } catch (_) {
      _all = const [];
      _hot = const [];
    }
  }

  /// 名称/拼音/首字母模糊搜索(不区分大小写)。空 query 返回全部。
  List<City> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where((c) =>
            c.name.contains(query.trim()) ||
            c.pinyin.startsWith(q) ||
            c.firstChar == q)
        .toList();
  }
}
