import 'dart:convert';

/// 职位筛选条件(推荐列表 joblist 的 sortType + filterParams)。
class JobFilter {
  const JobFilter({
    this.sortType = 0,
    this.cityCode,
    this.cityName,
    this.salary,
    this.experience = const [],
    this.degree,
  });

  /// 排序:见 [kSortOptions](0=推荐,1=最新)。
  final int sortType;

  /// 城市 code(覆盖期望城市);null 用期望默认城市。
  final int? cityCode;
  final String? cityName;

  /// 薪资 code(见 [kSalaryOptions]);null=不限。
  final String? salary;

  /// 经验 code(见 [kExperienceOptions]),**可多选**;空 = 不限。
  /// filterParams 里发数组 `[108,102]`,服务端做「或」匹配。
  final List<String> experience;

  /// 学历 code(见 [kDegreeOptions]);null=不限。
  final String? degree;

  /// [cityCode]/[cityName] 传 `null` 表示**清空城市筛选**(回到「全国」),不传则保持原值。
  JobFilter copyWith({
    int? sortType,
    Object? cityCode = _keep,
    Object? cityName = _keep,
    Object? salary = _keep,
    List<String>? experience,
    Object? degree = _keep,
  }) =>
      JobFilter(
        sortType: sortType ?? this.sortType,
        cityCode: identical(cityCode, _keep) ? this.cityCode : cityCode as int?,
        cityName:
            identical(cityName, _keep) ? this.cityName : cityName as String?,
        salary: identical(salary, _keep) ? this.salary : salary as String?,
        experience: experience ?? this.experience,
        degree: identical(degree, _keep) ? this.degree : degree as String?,
      );

  /// 实际发给 joblist 的 `sortType`。
  ///
  /// 实测:「推荐」(0)排序下,服务端把「筛选城市 == 求职期望城市」当作没筛选,回退成
  /// 全国推荐流(命中 0/30);换「最新」(1)才会真正按该城市过滤(26/30)。选非期望
  /// 城市时两种排序都正常。故仅在这一组合下自动改用 1,其余保持用户所选排序。
  int effectiveSortType(int defaultCityCode) =>
      (sortType == 0 && cityCode != null && cityCode == defaultCityCode)
          ? 1
          : sortType;

  /// 构建 joblist 的 `filterParams` JSON 串。
  ///
  /// `switchCity` 表示「用户是否显式选了城市」:只要选了城市就发 `1`(不论是否与求职
  /// 期望城市相同);没选、回落到期望城市才发 `0`。恒发 `0` 会让服务端认为用户没切
  /// 城市,**忽略 cityCode 覆盖**按期望城市返回 —— 即城市过滤失效。
  String buildFilterParams(int defaultCityCode) {
    final fp = <String, dynamic>{
      'cityCode': '${cityCode ?? defaultCityCode}',
      'switchCity': cityCode != null ? '1' : '0',
    };
    // 经验/学历是**逗号分隔的裸串**(如 "108,102"),不能加方括号 —— 带 `[]`
    // 服务端不认,过滤直接失效(实测:"108,102"→全在校/应届,"[108,102]"→无效)。
    if (salary != null) fp['salary'] = salary;
    if (experience.isNotEmpty) fp['experience'] = experience.join(',');
    if (degree != null) fp['degree'] = degree;
    return jsonEncode(fp);
  }

  static const Object _keep = Object();
}

/// 排序选项。
const List<({int value, String label})> kSortOptions = [
  (value: 0, label: '推荐'),
  (value: 1, label: '最新'),
];

/// 薪资区间(code 来自官方 filter/data,单选)。
const List<({String? code, String label})> kSalaryOptions = [
  (code: null, label: '不限'),
  (code: '429', label: '8K以下'),
  (code: '430', label: '8-12K'),
  (code: '431', label: '12-16K'),
  (code: '432', label: '16-20K'),
  (code: '433', label: '20-25K'),
  (code: '434', label: '25K以上'),
];

/// 经验筛选项(可多选)。code 来自官方 filter/data:108=在校生、102=应届生
/// (注意:不是直觉的反过来)。用于 filterParams.experience(逗号分隔)。
const List<({String code, String label})> kExperienceOptions = [
  (code: '108', label: '在校生'),
  (code: '102', label: '应届生'),
  (code: '103', label: '1年以内'),
  (code: '104', label: '1-3年'),
  (code: '105', label: '3-5年'),
  (code: '106', label: '5-10年'),
  (code: '107', label: '10年以上'),
];

/// 学历(code 来自真机职位数据:203=本科)。
const List<({String? code, String label})> kDegreeOptions = [
  (code: null, label: '不限'),
  (code: '209', label: '初中及以下'),
  (code: '206', label: '高中'),
  (code: '208', label: '中专/中技'),
  (code: '202', label: '大专'),
  (code: '203', label: '本科'),
  (code: '204', label: '硕士'),
  (code: '205', label: '博士'),
];
