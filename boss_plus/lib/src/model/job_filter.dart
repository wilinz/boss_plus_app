import 'dart:convert';

/// 职位筛选条件(推荐列表 joblist 的 sortType + filterParams)。
class JobFilter {
  const JobFilter({
    this.sortType = 0,
    this.cityCode,
    this.cityName,
    this.salary,
    this.experience,
    this.degree,
  });

  /// 排序:见 [kSortOptions](0=推荐,1=最新)。
  final int sortType;

  /// 城市 code(覆盖期望城市);null 用期望默认城市。
  final int? cityCode;
  final String? cityName;

  /// 薪资 code(见 [kSalaryOptions]);null=不限。
  final String? salary;

  /// 经验 code(见 [kExperienceOptions]);null=不限。
  final String? experience;

  /// 学历 code(见 [kDegreeOptions]);null=不限。
  final String? degree;

  /// [cityCode]/[cityName] 传 `null` 表示**清空城市筛选**(回到「全国」),不传则保持原值。
  JobFilter copyWith({
    int? sortType,
    Object? cityCode = _keep,
    Object? cityName = _keep,
    Object? salary = _keep,
    Object? experience = _keep,
    Object? degree = _keep,
  }) =>
      JobFilter(
        sortType: sortType ?? this.sortType,
        cityCode: identical(cityCode, _keep) ? this.cityCode : cityCode as int?,
        cityName:
            identical(cityName, _keep) ? this.cityName : cityName as String?,
        salary: identical(salary, _keep) ? this.salary : salary as String?,
        experience:
            identical(experience, _keep) ? this.experience : experience as String?,
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
    if (salary != null) fp['salary'] = salary;
    if (experience != null) fp['experience'] = '[$experience]';
    if (degree != null) fp['degree'] = '[$degree]';
    return jsonEncode(fp);
  }

  static const Object _keep = Object();
}

/// 排序选项。
const List<({int value, String label})> kSortOptions = [
  (value: 0, label: '推荐'),
  (value: 1, label: '最新'),
];

/// 城市选项(code 为 BOSS 城市编码)。
const List<({int code, String name})> kCityOptions = [
  (code: 101280100, name: '广州'),
  (code: 101280600, name: '深圳'),
  (code: 101010100, name: '北京'),
  (code: 101020100, name: '上海'),
  (code: 101210100, name: '杭州'),
  (code: 101270100, name: '成都'),
  (code: 101200100, name: '武汉'),
  (code: 101190100, name: '南京'),
];

/// 薪资区间(code 为 BOSS 薪资筛选编码)。
const List<({String? code, String label})> kSalaryOptions = [
  (code: null, label: '不限'),
  (code: '404', label: '5-10K'),
  (code: '405', label: '10-20K'),
  (code: '406', label: '20-50K'),
  (code: '407', label: '50K以上'),
];

/// 经验(code 来自真机职位数据)。
const List<({String? code, String label})> kExperienceOptions = [
  (code: null, label: '不限'),
  (code: '108', label: '应届生'),
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
