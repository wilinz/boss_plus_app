/// 牛人个人信息 + 求职期望(来自 `/api/zpgeek/cvapp/geek/baseinfo/query` 的 geekDetail)。
class GeekInfo {
  GeekInfo({
    required this.name,
    required this.avatar,
    required this.userId,
    required this.encryptGeekId,
    required this.ageDesc,
    required this.applyStatus,
    required this.hometown,
    required this.workEduDesc,
    required this.expect,
    required this.raw,
  });

  final String name;
  final String avatar;
  final int userId;
  final String encryptGeekId;
  final String ageDesc;
  final String applyStatus;
  final String hometown;
  final String workEduDesc;

  /// 求职期望(joblist 用),可能为空(未设置期望)。
  final GeekExpect? expect;

  final Map<String, dynamic> raw;

  factory GeekInfo.fromBaseInfo(dynamic data) {
    final zp = data is Map ? data['zpData'] : null;
    final gd = zp is Map ? zp['geekDetail'] : null;
    final g = gd is Map ? Map<String, dynamic>.from(gd) : <String, dynamic>{};
    final ui = g['userInfo'] is Map
        ? Map<String, dynamic>.from(g['userInfo'] as Map)
        : <String, dynamic>{};

    // 求职期望:学生用 geekStuCombineExpect,社招用 expectPositionList[0]
    GeekExpect? expect;
    final stu = g['geekStuCombineExpect'];
    if (stu is Map && (stu['encryptExpectId']?.toString().isNotEmpty ?? false)) {
      expect = GeekExpect.fromStuCombine(Map<String, dynamic>.from(stu));
    } else {
      final list = g['expectPositionList'];
      if (list is List && list.isNotEmpty && list.first is Map) {
        expect = GeekExpect.fromExpectItem(
            Map<String, dynamic>.from(list.first as Map));
      }
    }

    return GeekInfo(
      name: (ui['name'] ?? g['name'] ?? '').toString(),
      avatar: (ui['large'] ?? ui['tiny'] ?? '').toString(),
      userId: (ui['userId'] as num?)?.toInt() ?? 0,
      encryptGeekId: (ui['encryptGeekId'] ?? '').toString(),
      ageDesc: (g['ageDesc'] ?? '').toString(),
      applyStatus: (g['applyStatusContent'] ?? '').toString(),
      hometown: (ui['hometownName'] ?? '').toString(),
      workEduDesc: (g['workEduDesc'] ?? '').toString(),
      expect: expect,
      raw: g,
    );
  }
}

/// 求职期望(joblist 所需的 encryptExpectId / expectId / 城市)。
class GeekExpect {
  GeekExpect({
    required this.encryptExpectId,
    required this.expectId,
    required this.cityCode,
    required this.cityName,
    required this.positionName,
  });

  /// joblist 直接用的加密期望 id(学生态已含 `stuc_` 前缀)。
  final String encryptExpectId;
  final int expectId;
  final int cityCode;
  final String cityName;
  final String positionName;

  factory GeekExpect.fromStuCombine(Map<String, dynamic> m) => GeekExpect(
        encryptExpectId: (m['encryptExpectId'] ?? '').toString(),
        expectId: (m['expectId'] as num?)?.toInt() ?? -2,
        cityCode: (m['location'] as num?)?.toInt() ?? 0,
        cityName: (m['locationName'] ?? '').toString(),
        positionName: (m['positionName'] ?? '').toString(),
      );

  /// 社招期望项:joblist 的 encryptExpectId 需加 `stuc_`? 社招通常直接用原值。
  factory GeekExpect.fromExpectItem(Map<String, dynamic> m) {
    final loc = m['locationList'];
    final firstLoc = loc is List && loc.isNotEmpty && loc.first is Map
        ? Map<String, dynamic>.from(loc.first as Map)
        : const {};
    return GeekExpect(
      encryptExpectId: (m['encryptExpectId'] ?? '').toString(),
      expectId: (m['expectId'] as num?)?.toInt() ?? -1,
      cityCode: (m['location'] as num?)?.toInt() ??
          (firstLoc['code'] as num?)?.toInt() ??
          0,
      cityName:
          (m['locationName'] ?? firstLoc['name'] ?? '').toString(),
      positionName: (m['positionName'] ?? '').toString(),
    );
  }
}
