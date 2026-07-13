/// 职位详情(`/api/zpgeek/jobapp/geek/job/querydetail` 的 zpData)。
class JobDetail {
  JobDetail({
    required this.positionName,
    required this.salaryDesc,
    required this.experienceName,
    required this.degreeName,
    required this.address,
    required this.locationDesc,
    required this.jobDesc,
    required this.bossName,
    required this.bossTitle,
    required this.bossAvatar,
    required this.bossActiveDesc,
    required this.bossLabels,
    required this.brandName,
    required this.comName,
    required this.industryName,
    required this.scaleName,
    required this.stageName,
    required this.brandLogo,
    required this.raw,
  });

  final String positionName;
  final String salaryDesc;
  final String experienceName;
  final String degreeName;
  final String address;
  final String locationDesc;
  final String jobDesc;

  final String bossName;
  final String bossTitle;
  final String bossAvatar;
  final String bossActiveDesc;
  final List<String> bossLabels;

  final String brandName;
  final String comName;
  final String industryName;
  final String scaleName;
  final String stageName;
  final String brandLogo;

  final Map<String, dynamic> raw;

  Map<String, dynamic> _sub(String k) =>
      raw[k] is Map ? Map<String, dynamic>.from(raw[k] as Map) : const {};

  /// 对方(boss)uid —— 发起沟通 / 打开会话用。
  /// 实测字段是 `bossBaseInfo.bossId`(= 聊天 friendId,深链 userId 也是它),
  /// 不是 `userId` / 顶层 `bossId`(那两个不存在,之前解析恒为 0 → peerUid=0 bug)。
  int get bossUid =>
      (_sub('bossBaseInfo')['bossId'] as num?)?.toInt() ??
      (_sub('bossBaseInfo')['userId'] as num?)?.toInt() ??
      (raw['bossId'] as num?)?.toInt() ??
      0;

  /// 职位 id(发起沟通参数)。
  String get jobId =>
      (_sub('jobBaseInfo')['jobId'] ?? _sub('jobBaseInfo')['encryptId'] ?? '')
          .toString();

  /// 期望 id(发起沟通参数)。
  String get expectId =>
      (raw['expectId'] ?? _sub('jobBaseInfo')['expectId'] ?? '').toString();

  /// 公司一行描述:行业 · 阶段 · 规模。
  String get brandDesc => [industryName, stageName, scaleName]
      .where((s) => s.isNotEmpty)
      .join(' · ');

  factory JobDetail.fromResponse(dynamic data) {
    final zp = data is Map ? data['zpData'] : null;
    final z = zp is Map ? zp : const {};
    Map<String, dynamic> sub(String k) =>
        z[k] is Map ? Map<String, dynamic>.from(z[k] as Map) : {};
    final job = sub('jobBaseInfo');
    final boss = sub('bossBaseInfo');
    final brand = sub('brandComInfo');
    List<String> strList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];

    return JobDetail(
      positionName: (job['positionName'] ?? job['jobName'] ?? '').toString(),
      salaryDesc: (job['salaryDesc'] ?? '').toString(),
      experienceName: (job['experienceName'] ?? '').toString(),
      degreeName: (job['degreeName'] ?? '').toString(),
      address: (job['address'] ?? '').toString(),
      locationDesc: (job['locationDesc'] ?? '').toString(),
      jobDesc: (job['jobDesc'] ?? '').toString(),
      bossName: (boss['name'] ?? '').toString(),
      bossTitle: (boss['title'] ?? '').toString(),
      bossAvatar: (boss['largeAvatar'] ?? boss['tinyAvatar'] ?? '').toString(),
      bossActiveDesc: (boss['activeTimeDesc'] ?? '').toString(),
      bossLabels: strList(boss['bossBehaviorLabels']),
      brandName: (brand['brandName'] ?? boss['brandName'] ?? '').toString(),
      comName: (brand['comName'] ?? '').toString(),
      industryName: (brand['industryName'] ?? '').toString(),
      scaleName: (brand['scaleName'] ?? '').toString(),
      stageName: (brand['stageName'] ?? '').toString(),
      brandLogo: (brand['logo'] ?? '').toString(),
      raw: Map<String, dynamic>.from(z),
    );
  }
}
