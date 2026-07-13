/// 推荐职位卡(`/api/zpgeek/app/geek/recommend/joblist` 的 jobList 项)。
class JobCard {
  JobCard({
    required this.jobName,
    required this.salaryDesc,
    required this.brandName,
    required this.brandLogo,
    required this.brandScale,
    required this.brandStage,
    required this.bossName,
    required this.bossTitle,
    required this.bossAvatar,
    required this.cityName,
    required this.areaDistrict,
    required this.jobLabels,
    required this.encryptJobId,
    required this.securityId,
    required this.raw,
  });

  final String jobName;
  final String salaryDesc;
  final String brandName;
  final String brandLogo;
  final String brandScale;
  final String brandStage;
  final String bossName;
  final String bossTitle;
  final String bossAvatar;
  final String cityName;
  final String areaDistrict;
  final List<String> jobLabels;
  final String encryptJobId;
  final String securityId;
  final Map<String, dynamic> raw;

  /// 公司描述:规模 · 阶段(过滤空值)。
  String get brandDesc =>
      [brandStage, brandScale].where((s) => s.isNotEmpty).join(' · ');

  /// BOSS 活跃度描述(如「刚刚活跃」「3日内活跃」「本月活跃」),列表未返回则为空。
  /// 字段名据反编译的 ServerJobCardBean 确认为 activeTimeDesc,activeInfo 兜底。
  String get activeTimeDesc =>
      (raw['activeTimeDesc'] ?? raw['activeInfo'] ?? '').toString();

  /// BOSS 是否当前在线(ServerJobCardBean.online)。
  bool get bossOnline => raw['online'] == true;

  /// 地点:城市 区域。
  String get locationDesc =>
      [cityName, areaDistrict].where((s) => s.isNotEmpty).join(' ');

  factory JobCard.fromJson(Map<String, dynamic> j) => JobCard(
        jobName: (j['jobName'] ?? '').toString(),
        salaryDesc: (j['salaryDesc'] ?? '').toString(),
        brandName: (j['brandName'] ?? '').toString(),
        brandLogo: (j['brandLogo'] ?? '').toString(),
        brandScale: (j['brandScaleName'] ?? '').toString(),
        brandStage: (j['brandStageName'] ?? '').toString(),
        bossName: (j['bossName'] ?? '').toString(),
        bossTitle: (j['bossTitle'] ?? '').toString(),
        bossAvatar: (j['bossAvatar'] ?? '').toString(),
        cityName: (j['cityName'] ?? '').toString(),
        areaDistrict: (j['areaDistrict'] ?? '').toString(),
        jobLabels: (j['jobLabels'] is List)
            ? (j['jobLabels'] as List).map((e) => e.toString()).toList()
            : const [],
        encryptJobId: (j['encryptJobId'] ?? '').toString(),
        securityId: (j['securityId'] ?? '').toString(),
        raw: j,
      );
}

/// 一页职位列表结果。
class JobListPage {
  JobListPage({required this.jobs, required this.hasMore, required this.lid});

  final List<JobCard> jobs;
  final bool hasMore;
  final String lid;

  factory JobListPage.fromResponse(dynamic data) {
    final zp = data is Map ? data['zpData'] : null;
    final z = zp is Map ? zp : const {};
    final list = z['jobList'];
    final jobs = (list is List)
        ? list
            .whereType<Map>()
            .map((e) => JobCard.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <JobCard>[];
    return JobListPage(
      jobs: jobs,
      hasMore: z['hasMore'] == true,
      lid: (z['lid'] ?? '').toString(),
    );
  }
}
