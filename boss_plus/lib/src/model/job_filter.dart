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

  JobFilter copyWith({
    int? sortType,
    int? cityCode,
    String? cityName,
    Object? salary = _keep,
    Object? experience = _keep,
    Object? degree = _keep,
  }) =>
      JobFilter(
        sortType: sortType ?? this.sortType,
        cityCode: cityCode ?? this.cityCode,
        cityName: cityName ?? this.cityName,
        salary: identical(salary, _keep) ? this.salary : salary as String?,
        experience:
            identical(experience, _keep) ? this.experience : experience as String?,
        degree: identical(degree, _keep) ? this.degree : degree as String?,
      );

  /// 构建 joblist 的 `filterParams` JSON 串。
  String buildFilterParams(int defaultCityCode) {
    final fp = <String, dynamic>{
      'cityCode': '${cityCode ?? defaultCityCode}',
      'switchCity': '0',
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
