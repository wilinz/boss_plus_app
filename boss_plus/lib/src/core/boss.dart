import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

import 'base_client.dart';
import 'config/boss_app_config.dart';
import 'crypto/yzwg_signer.dart';
import 'session/session_jar.dart';
import '../http/boss_header_interceptor.dart';
import '../http/boss_sign_interceptor.dart';
import '../http/response_decrypt_interceptor.dart';
import '../model/login_result.dart';
import '../model/geetest.dart';
import '../model/geek_info.dart';
import '../model/job_card.dart';
import '../model/job_detail.dart';
import '../model/job_filter.dart';
import '../utils/log.dart';

/// BOSS 直聘(zhipin.com)客户端(单账号)。
///
/// 复现 App 的请求链路,拦截器顺序对齐 native:
///   设备头(header) → 签名/加密(sign) → 响应解密(decrypt)。
/// 参数加密进 `sp`、签名 `sig`、公共参数注入,全部由拦截器自动完成;
/// 上层只按业务语义传 query/form 参数即可。
///
/// 逆向依据见 `docs/boss-request-signing.md` 与 `docs/libyzwg-native-analysis.md`。
class Boss extends BaseClient {
  static const String _apiBase = 'https://api5.zhipin.com';

  @override
  String get baseUrl => _apiBase;

  late BossAppConfig _appConfig;
  final BossAuthState _auth = BossAuthState();
  late YzwgSigner _signer;
  SessionJar? _sessionJar;

  Boss._();

  BossAppConfig get appConfig => _appConfig;
  BossAuthState get auth => _auth;
  bool get loggedIn => _auth.loggedIn;

  static Future<Boss> newInstance({
    required BossAppConfig appConfig,
    CookieJar? cookieJar,
    SessionJar? sessionJar,
    String? secret32,
    Dio? dio,
  }) async {
    final boss = Boss._();
    await boss._init(
      appConfig: appConfig,
      cookieJar: cookieJar ?? CookieJar(),
      sessionJar: sessionJar,
      secret32: secret32,
      dio: dio,
    );
    return boss;
  }

  CookieJar? _cookieJar;

  /// 取指定 URL 的 cookie(供 WebView 注入登录态 —— H5 页面靠 cookie 认登录)。
  Future<List<Cookie>> cookiesForUrl(String url) async {
    final jar = _cookieJar;
    if (jar == null) return const [];
    try {
      return await jar.loadForRequest(Uri.parse(url));
    } catch (_) {
      return const [];
    }
  }

  Future<void> _init({
    required BossAppConfig appConfig,
    required CookieJar cookieJar,
    SessionJar? sessionJar,
    String? secret32,
    Dio? dio,
  }) async {
    _appConfig = appConfig;
    _sessionJar = sessionJar;
    _cookieJar = cookieJar;
    _signer = YzwgSigner(secret32: secret32);

    await super.initDio(
      cookieJar: cookieJar,
      userAgent: appConfig.userAgent,
      dio: dio,
    );

    this.dio.interceptors.addAll([
      BossHeaderInterceptor(appConfig: appConfig, auth: _auth),
      BossSignInterceptor(appConfig: appConfig, auth: _auth, signer: _signer),
      BossResponseDecryptInterceptor(auth: _auth, signer: _signer),
    ]);

    await restoreSession();
  }

  // ---------------- 登录流程(/api/zppassport/*) ----------------
  //
  // 抓包时间线:
  //   user/judge          账号判断(手机号加密成 account)
  //   man/machine         极验初始化 → 返回 {gt, challenge, success}
  //   phone/smsCode       带 geetest challenge(+validate/seccode)→ 发短信
  //   user/codeLogin      account + code → 拿 token2/secretKey
  //
  // 关键编码(已 byte-exact 逆向,见 docs):
  //   account = base64( RC4(phone, SECRET32) ) = signer.encodePassword(phone)
  //
  // ⚠️ TODO(待真机登录抓取校准):smsCode/codeLogin 中 geetest 的
  //   validate/seccode 参数名、以及是否需要 `regionCode` 等,目前用常见名占位。

  /// 手机号 → 加密形态(登录参数 `phone`/`account` 的值)。
  String encodeAccount(String mobile) => _signer.encodePassword(mobile);

  /// 账号判断:`POST /api/zppassport/user/judge`(免 token)。
  /// 真机参数:`phone`(加密)+`regionCode`。
  Future<Map<String, dynamic>> userJudge({required String mobile}) async {
    final resp = await dio.post(
      '/api/zppassport/user/judge',
      data: {'phone': encodeAccount(mobile), 'regionCode': '+86'},
      options: Options(extra: const {'bossNoToken': true}),
    );
    return _asMap(resp.data);
  }

  /// 极验初始化:`POST /api/zppassport/man/machine`(免 token)。
  /// 真机参数:`phone`(加密)+`type=3`(**无 regionCode**)。
  /// 返回 zpData.startCaptcha 里的 {gt, challenge, success};success=1 需拉起滑块。
  Future<GeetestRegister> manMachine({required String mobile}) async {
    final resp = await dio.post(
      '/api/zppassport/man/machine',
      data: {'phone': encodeAccount(mobile), 'type': '3'},
      options: Options(extra: const {'bossNoToken': true}),
    );
    return GeetestRegister.fromJson(_asMap(resp.data));
  }

  /// 发送短信验证码:`GET /api/zppassport/phone/smsCode`(免 token)。
  ///
  /// 真机参数:`phone`(加密)+`regionCode`+`type=3`+`voice=0`+ geetest 三件套
  /// (`challenge`/`validate`/`seccode`)。[geetest] 为用户手动过滑块后极验返回值。
  Future<Map<String, dynamic>> sendSmsCode({
    required String mobile,
    GeetestResult? geetest,
  }) async {
    final params = <String, String>{
      'phone': encodeAccount(mobile),
      'regionCode': '+86',
      'type': '3',
      'voice': '0',
      if (geetest != null) ...geetest.toBossParams(),
    };
    final resp = await dio.get(
      '/api/zppassport/phone/smsCode',
      queryParameters: params,
      options: Options(extra: const {'bossNoToken': true}),
    );
    return _asMap(resp.data);
  }

  /// 验证码登录:`POST /api/zppassport/user/codeLogin`(免 token)。
  ///
  /// 真机参数:`account`(加密手机号)+`phoneCode`(短信验证码)+`regionCode`+
  /// `identityType=-1`+`isWxLogin=false`。
  /// 成功后从响应提取 `token2`/`secretKey`,写入登录态并持久化。
  Future<BossLoginResult> loginWithSms({
    required String mobile,
    required String code,
  }) async {
    final resp = await dio.post(
      '/api/zppassport/user/codeLogin',
      data: {
        'account': encodeAccount(mobile),
        'regionCode': '+86',
        'phoneCode': code,
        'identityType': '-1',
        'isWxLogin': 'false',
      },
      options: Options(extra: const {'bossNoToken': true}),
    );
    final result = BossLoginResult.fromResponse(resp.data);
    if (result.ok && result.hasSession) {
      _auth.token2 = result.token2;
      _auth.secretKey = result.secretKey;
      await _saveSession();
      bossLog('登录成功 secretKey=${bossClip(result.secretKey, max: 12)}…',
          tag: 'boss.login');
    } else {
      bossLog('登录未获得会话: $result', tag: 'boss.login');
    }
    return result;
  }

  /// 用已有会话直接恢复登录态(跳过登录)。
  void setSession({required String token2, required String secretKey}) {
    _auth.token2 = token2;
    _auth.secretKey = secretKey;
  }

  /// 退出登录。
  void logout() {
    _auth.clear();
    _sessionJar?.clear();
  }

  // ---------------- 牛人业务 ----------------

  /// 拉取牛人个人信息 + 求职期望:`GET /api/zpgeek/cvapp/geek/baseinfo/query`。
  Future<GeekInfo> queryGeekBaseInfo() async {
    final resp = await dio.get('/api/zpgeek/cvapp/geek/baseinfo/query');
    return GeekInfo.fromBaseInfo(resp.data);
  }

  /// 简历列表:`GET /api/zpgeek/cvapp/geek/resume/querylist`(HAR 实测)。
  /// 返回 `zpData.resumeList`(= `ServerResumeBean`,每条自带 previewUrl 可直接 WebView 预览)。
  Future<List<Map<String, dynamic>>> resumeList() async {
    final resp = await dio.get('/api/zpgeek/cvapp/geek/resume/querylist');
    final data = resp.data;
    final zp = data is Map ? data['zpData'] : null;
    final list = zp is Map ? zp['resumeList'] : null;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// 下载简历 PDF 字节(附件简历原生预览用)。[url] 为简历 previewUrl 深链里的内层
  /// 地址(preview4geek,返回 application/pdf)。走本 dio(带 t2 认证),原生渲染不经 WebView。
  Future<List<int>> downloadBytes(String url) async {
    final resp = await dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        extra: const {'bossRaw': true}, // 跳签名/解密,自带 encryptParam;保留 PDF 字节
      ),
    );
    return resp.data ?? const [];
  }

  /// 更新牛人基本信息(简历编辑):`POST /api/zpgeek/cvapp/geek/baseinfo/update`(HAR 实测)。
  /// [fields] 为要更新的字段键值(如 {name, ...});服务器按传入字段增量更新。
  Future<Map<String, dynamic>> updateBaseInfo(
      Map<String, dynamic> fields) async {
    final resp = await dio.post(
      '/api/zpgeek/cvapp/geek/baseinfo/update',
      data: fields,
    );
    return _asMap(resp.data);
  }

  /// 上传附件简历文件:`POST /api/zpupload/uploadResumeFile`(multipart,= 官方 `FileUploadRequest`)。
  /// [filePath] 本地文件路径。返回 `zpData {originId, path}`(= `UploadResumeResponse`)。
  Future<Map<String, dynamic>> uploadResumeFile(String filePath) async {
    final name = filePath.split('/').last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: name),
      'fileName': name,
      'fileType': '1', // 官方 FileUploadRequest.fileType(默认 1),缺失服务端报「参数值错误」
    });
    final resp = await dio.post('/api/zpupload/uploadResumeFile', data: form);
    return _asMap(resp.data);
  }

  /// 新增/编辑项目经历:`POST /api/zpgeek/cvapp/geek/projexp/save`(= 官方 `GeekUpdateProjectExpRequest`)。
  /// [fields] 键:`projectId`(0=新增)、`name`、`roleName`、`url`、`projectDescription`、
  /// `performance`、`startDate`/`endDate`(字符串 `"yyyyMM"`,`endDate="-1"`=至今)。
  /// 服务端要求 `entrance`/`riskTipType`,此处补默认值。
  Future<Map<String, dynamic>> saveProjectExp(
      Map<String, String> fields) async {
    final resp = await dio.post(
      '/api/zpgeek/cvapp/geek/projexp/save',
      data: {'entrance': '1', 'riskTipType': '1', ...fields},
    );
    return _asMap(resp.data);
  }

  /// 删除项目经历:`POST /api/zpgeek/cvapp/geek/projexp/delete`(= 官方 `GeekDeleteProjectExpRequest`)。
  Future<Map<String, dynamic>> deleteProjectExp(int projectId) async {
    final resp = await dio.post(
      '/api/zpgeek/cvapp/geek/projexp/delete',
      data: {'projectId': '$projectId'},
    );
    return _asMap(resp.data);
  }

  /// 拉取推荐职位列表:`GET /api/zpgeek/app/geek/recommend/joblist`。
  ///
  /// [expect] 来自 [queryGeekBaseInfo] 的 `GeekInfo.expect`(含 encryptExpectId/城市)。
  /// [filter] 排序/城市/薪资/经验/学历 筛选(见 [JobFilter]);默认不筛选。
  /// 未设置求职期望时 [expect] 为 null,无法拉取(返回空页)。
  Future<JobListPage> fetchRecommendJobs({
    required GeekExpect expect,
    int page = 1,
    int pageSize = 15,
    JobFilter filter = const JobFilter(),
  }) async {
    if (expect.encryptExpectId.isEmpty) {
      return JobListPage(jobs: const [], hasMore: false, lid: '');
    }
    final resp = await dio.get(
      '/api/zpgeek/app/geek/recommend/joblist',
      queryParameters: {
        'encryptExpectId': expect.encryptExpectId,
        'expectId': '${expect.expectId}',
        'sortType': '${filter.sortType}',
        'page': '$page',
        'pageSize': '$pageSize',
        'jobType': '0',
        'topicType': '0',
        'filterParams': filter.buildFilterParams(expect.cityCode),
      },
    );
    final pageData = JobListPage.fromResponse(resp.data);
    bossLog('joblist page=$page → ${pageData.jobs.length} 条 hasMore=${pageData.hasMore}',
        tag: 'boss.job');
    return pageData;
  }

  /// 职位详情:`GET /api/zpgeek/jobapp/geek/job/querydetail`。
  ///
  /// [securityId] 取自职位卡 `JobCard.securityId`,[lid] 取自 `JobListPage.lid`。
  Future<JobDetail> queryJobDetail({
    required String securityId,
    String lid = '',
  }) async {
    final resp = await dio.get(
      '/api/zpgeek/jobapp/geek/job/querydetail',
      queryParameters: {
        'securityId': securityId,
        'jobType': '0',
        'lid': lid,
        'needRelatedJob': 'true',
        'page': '1',
        'requestSource': '0',
        'sourceType': '0',
        'wayType': '0',
      },
    );
    return JobDetail.fromResponse(resp.data);
  }

  // ---------------- IM / 沟通 ----------------

  /// 发起沟通:`GET /api/zpgeek/app/friend/add`(HAR 实测)。
  ///
  /// 在职位详情页点「立即沟通」时调用,服务器会代发开场白 [greeting],
  /// 之后经 IM(MQTT type=1)回推。返回解密后的响应 JSON。
  Future<Map<String, dynamic>> startChat({
    required String securityId,
    required String jobId,
    required String expectId,
    String lid = '',
    String greeting = '',
    String jobAddressId = '',
  }) async {
    final resp = await dio.get(
      '/api/zpgeek/app/friend/add',
      queryParameters: {
        'securityId': securityId,
        'jobId': jobId,
        'expectId': expectId,
        'lid': lid,
        if (greeting.isNotEmpty) 'greeting': greeting,
        if (jobAddressId.isNotEmpty) 'jobAddressId': jobAddressId,
      },
    );
    final data = resp.data;
    return data is Map ? Map<String, dynamic>.from(data) : {'raw': data};
  }

  /// 交换联系方式 / 发简历:`POST /api/zpchat/exchange/request`(= 官方 `ExchangeChatRequest`,HAR 实测)。
  ///
  /// [type]:"1"=换电话 / "2"=换微信 / "3"=发简历 / "6"=电话+微信(官方 `ExchangeChatRequest.EXCHANGE_*`)。
  /// 注意参数名是 **`type`(字符串)**,不是 exchangeType;之前误用 `blueCollarRequest`(蓝领端点)
  /// 被服务器拒「用户权限限制」。[mid]=最近消息 id;[scene]=场景(0=默认);[resumeId]=发简历用。
  static const String exchangePhone = '1';
  static const String exchangeWechat = '2';
  static const String exchangeResume = '3';

  Future<Map<String, dynamic>> exchangeContact({
    required String securityId,
    required String type,
    int mid = 0,
    int scene = 0,
    String resumeId = '',
  }) async {
    final resp = await dio.post(
      '/api/zpchat/exchange/request',
      data: {
        'securityId': securityId,
        'type': type,
        'mid': mid,
        'scene': scene,
        if (resumeId.isNotEmpty) 'resumeId': resumeId,
      },
    );
    final data = resp.data;
    return data is Map ? Map<String, dynamic>.from(data) : {'raw': data};
  }

  /// 拉取与某个 boss 的聊天历史:`GET /api/zpchat/message/historyMsg`。
  ///
  /// 历史消息是纯 HTTP 拉取(不依赖本地库/MQTT)。响应 `zpData.messages` 是一组
  /// base64 字符串,每条 base64 解出即 `TechwolfChatProtocol` 信封(与实时收发同结构),
  /// 用 `ChatProtocol.decode` 解析。分页用 [maxMsgId](上一批的 minMsgId)。
  ///
  /// 返回 (messages: base64 列表, hasMore, minMsgId)。
  Future<({List<String> messages, bool hasMore, int minMsgId})> chatHistory({
    required int friendId,
    int friendSource = 0,
    int maxMsgId = 0,
    int count = 20,
    String securityId = '',
  }) async {
    final resp = await dio.get(
      '/api/zpchat/message/historyMsg',
      queryParameters: {
        'friendId': friendId,
        'friendSource': friendSource,
        'maxMsgId': maxMsgId,
        'count': count,
        if (securityId.isNotEmpty) 'securityId': securityId,
      },
    );
    final zp = _zpData(resp.data);
    final list = zp['messages'];
    final messages = <String>[
      if (list is List)
        for (final m in list)
          if (m is String) m,
    ];
    return (
      messages: messages,
      hasMore: zp['hasMore'] == true,
      minMsgId: (zp['minMsgId'] as num?)?.toInt() ?? 0,
    );
  }

  /// 会话列表 id(第一段):`POST /api/zprelation/friend/getFriendIdListV1`。
  ///
  /// 返回三类联系人的 id(含 waterLevel 版本水位):
  /// - `zp`: 普通 boss 好友(getBaseInfo 的 friendIds)
  /// - `dz`: 直招/代招(dzFriendIds)
  /// - `peer`: 同行(peerFriendIds)
  /// 详情需再调 [contactBaseInfo]。[scene]/[waterLevel] 用于增量。
  Future<({List<int> zp, List<int> dz, List<int> peer})> contactFriendIds({
    int scene = 0,
    int waterLevel = 0,
  }) async {
    final resp = await dio.post(
      '/api/zprelation/friend/getFriendIdListV1',
      data: {'scene': scene, 'waterLevel': waterLevel},
    );
    final m = _asMap(resp.data);
    if (m['code'] != 0) {
      bossLog('friendIds code=${m['code']} msg=${m['message']}',
          tag: 'boss.friend');
    }
    final zpData = _zpData(resp.data);
    List<int> pick(String key) {
      final out = <int>[];
      final list = zpData[key];
      if (list is List) {
        for (final e in list) {
          final id = (e is Map) ? e['friendId'] : e;
          if (id is num) out.add(id.toInt());
        }
      }
      return out;
    }

    return (
      zp: pick('zpFriendIdList'),
      dz: pick('dzFriendIdList'),
      peer: pick('peerFriendIdList'),
    );
  }

  /// 会话列表详情(第二段):`POST /api/zprelation/friend/getBaseInfo`。
  ///
  /// 按 id 批量拉联系人详情(名字/公司/岗位/头像/securityId 等)。三类 id 分开传。
  /// 返回 `baseInfoList` 原始 map 列表(字段见 `ServerAddFriendBean`:
  /// name/company/jobName/friendId/securityId/positionName/salaryDesc…)。
  Future<List<Map<String, dynamic>>> contactBaseInfo({
    List<int> friendIds = const [],
    List<int> dzFriendIds = const [],
    List<int> peerFriendIds = const [],
  }) async {
    // 好友多时一次全发会撑爆 sp 触发「无效的签名」(native 也是分批,见
    // FixContactAll*TaskRun 的 MAX_PAGE_SIZE 切片)。这里每桶按 [_baseInfoBatch]
    // 分批请求再合并,对上层透明。
    const batch = 20;
    List<List<int>> chunk(List<int> ids) => [
          for (var i = 0; i < ids.length; i += batch)
            ids.sublist(i, i + batch > ids.length ? ids.length : i + batch),
        ];

    final out = <Map<String, dynamic>>[];
    for (final c in chunk(friendIds)) {
      out.addAll(await _baseInfoBatch(friendIds: c));
    }
    for (final c in chunk(dzFriendIds)) {
      out.addAll(await _baseInfoBatch(dzFriendIds: c));
    }
    for (final c in chunk(peerFriendIds)) {
      out.addAll(await _baseInfoBatch(peerFriendIds: c));
    }
    return out;
  }

  /// 单批 getBaseInfo(≤20 个 id/桶)。
  Future<List<Map<String, dynamic>>> _baseInfoBatch({
    List<int> friendIds = const [],
    List<int> dzFriendIds = const [],
    List<int> peerFriendIds = const [],
  }) async {
    String csv(List<int> ids) => ids.join(',');
    final resp = await dio.post(
      '/api/zprelation/friend/getBaseInfo',
      data: {
        if (friendIds.isNotEmpty) 'friendIds': csv(friendIds),
        if (dzFriendIds.isNotEmpty) 'dzFriendIds': csv(dzFriendIds),
        if (peerFriendIds.isNotEmpty) 'peerFriendIds': csv(peerFriendIds),
      },
    );
    final bm = _asMap(resp.data);
    final zpData = _zpData(resp.data);
    if (bm['code'] != 0) {
      bossLog(
          'baseInfo code=${bm['code']} msg=${bm['message']} '
          'req(zp=${friendIds.length},dz=${dzFriendIds.length},peer=${peerFriendIds.length})',
          tag: 'boss.friend');
    }
    final list = zpData['baseInfoList'];
    return <Map<String, dynamic>>[
      if (list is List)
        for (final e in list)
          if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  /// 从 `{code,message,zpData:{...}}` 里取 zpData。
  Map<String, dynamic> _zpData(dynamic data) {
    final map = data is Map ? Map<String, dynamic>.from(data) : const {};
    final zp = map['zpData'];
    return zp is Map ? Map<String, dynamic>.from(zp) : <String, dynamic>{};
  }

  // ---------------- 业务请求(通用) ----------------

  /// 通用 GET(参数自动签名加密)。[noToken] 用于免 token 白名单接口。
  Future<Response> getApi(
    String path, {
    Map<String, String>? params,
    bool noToken = false,
  }) =>
      dio.get(path,
          queryParameters: params,
          options: Options(extra: {'bossNoToken': noToken}));

  /// 通用 POST(参数自动签名加密)。
  Future<Response> postApi(
    String path, {
    Map<String, dynamic>? data,
    bool noToken = false,
  }) =>
      dio.post(path,
          data: data ?? const {},
          options: Options(extra: {'bossNoToken': noToken}));

  // ---------------- 会话持久化 ----------------

  Future<void> _saveSession() async {
    if (_sessionJar == null) return;
    await _sessionJar!.save({
      'token2': _auth.token2,
      'secretKey': _auth.secretKey,
      'appConfig': _appConfig.toJson(),
    });
  }

  Future<void> restoreSession() async {
    if (_sessionJar == null) return;
    final s = await _sessionJar!.load();
    if (s == null) return;
    final sk = s['secretKey'] as String?;
    final t2 = s['token2'] as String?;
    if (sk != null && sk.isNotEmpty) {
      _auth.secretKey = sk;
      _auth.token2 = t2;
      bossLog('恢复会话', tag: 'boss.login');
    }
  }

  static Map<String, dynamic> _asMap(dynamic d) =>
      d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
}
