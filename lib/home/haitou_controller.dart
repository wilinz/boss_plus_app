import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/boss_provider.dart';
import 'ai_filter.dart';
import 'home_controller.dart';

/// BOSS 活跃描述 → 陈旧度档位(越小越活跃);-1=无法识别。
///
/// 只有描述文字可依据,故按 BOSS 的活跃话术有序分级(先近后远,先匹配者优先):
/// 0在线 1刚刚 2今日 3几日内 4本周 5本月/近1月 6数月 7半年内 8半年前 9一年内 10一年前+。
/// 关键:先判「日/周/半年」再判「月/年」,避免「本月活跃」被含「月」子串误判为久未活跃。
int activeRank(String desc) {
  final d = desc.trim();
  if (d.isEmpty) return -1;
  if (d.contains('在线')) return 0;
  if (d.contains('刚刚')) return 1;
  if (d.contains('今日') || d.contains('今天')) return 2;
  if (d.contains('日')) return 3; // N日内 / 近日
  if (d.contains('周')) return 4; // 本周 / N周内
  if (d.contains('半年')) return d.contains('前') ? 8 : 7; // 前=久,内=较近
  if (d.contains('月')) {
    // 本月/近1月=本月档(5);近2~3月=数月档(6)。「内」偏近、「前」偏久同档处理。
    final n = _monthsIn(d);
    return n <= 1 ? 5 : 6;
  }
  if (d.contains('年')) return d.contains('前') ? 10 : 9;
  return -1; // 话术无法识别 → 交由调用方按「未知放行」处理
}

/// 从含「月」的活跃描述里解析月数。支持「本月/N月/N个月/中文数字个月」;
/// 无法确定月数(如「数月」)保守按 2 处理(归入数月档,不误放进本月档)。
int _monthsIn(String d) {
  if (d.contains('本月')) return 1;
  final m = RegExp(r'(\d+)\s*个?\s*月').firstMatch(d); // 2月 / 2个月
  if (m != null) return int.parse(m.group(1)!);
  final c = RegExp(r'([一二两三四五六七八九十])\s*个?\s*月').firstMatch(d); // 两个月 / 一月
  if (c != null) {
    return const {
          '一': 1, '两': 2, '二': 2, '三': 3, '四': 4, '五': 5,
          '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
        }[c.group(1)] ??
        2;
  }
  return 2; // 有「月」但无数字(数月/几月)→ 保守归数月档
}

/// 服务端提示是否为「今日已达上限」——要等到明天,休息重试没意义,必须停。
///
/// 实测话术:「您今天已与150位BOSS沟通,休息一下,明天再来吧～」「今日沟通已达上限」。
/// 注意它同样含「休息」,所以必须**先于**临时限流(操作过于频繁)判断,否则会被误当成
/// 可恢复的限流而空等重试。
bool isDailyCapMessage(String msg) =>
    msg.contains('上限') ||
    msg.contains('明天') ||
    msg.contains('今天已') ||
    msg.contains('今日已');

/// 海投:循环对推荐职位「发起沟通」,跳过已沟通,可配间隔,显示进度。
///
/// 复用首页 [HomeController] 的职位列表与分页(列表拉完自动 loadMore),对每个职位
/// 走官方流程 detail → `startChat`。已沟通职位(本地持久化集合,按 encryptJobId 记)直接跳过。
/// 限流处理:「每日上限」直接停;「操作过于频繁」等临时限流则退回该职位、休息后重投
/// (按次数退避),投满 [targetCount] 才收工。所有 BOSS 请求(含被过滤职位的详情、翻页)
/// 都限速,避免连打接口把限流打出来。
class HaitouController extends GetxController {
  /// 常驻单例:脱离页面存在,切到别的页面/tab 也继续跑。
  static HaitouController get to => Get.isRegistered<HaitouController>()
      ? Get.find<HaitouController>()
      : Get.put(HaitouController(), permanent: true);

  /// 懒取首页控制器(职位列表来源),避免构造时它还没注册。
  HomeController get home => Get.find<HomeController>();

  final running = false.obs;
  final done = 0.obs; // 成功发起沟通
  final skipped = 0.obs; // 跳过(已沟通)
  final filtered = 0.obs; // 被关键词过滤掉
  final failed = 0.obs; // 失败
  final current = ''.obs; // 当前处理的职位

  // 关键词过滤:命中「排除」直接跳过;设了「仅含」则职位名须至少含一个才发。
  // 逗号/空格/顿号分隔,匹配职位名+公司+标签(忽略大小写)。
  final excludeCtrl = TextEditingController();
  final includeCtrl = TextEditingController();
  // 职位详情正文关键词(独立于上面的列表关键词):在拉取详情后匹配 jobDesc 等正文。
  final detailExcludeCtrl = TextEditingController();
  final detailIncludeCtrl = TextEditingController();
  final salaryCtrl = TextEditingController(); // 最低月薪(K)输入框
  static const _kExclude = 'haitou_exclude_kw';
  static const _kInclude = 'haitou_include_kw';
  static const _kDetailExclude = 'haitou_detail_exclude_kw';
  static const _kDetailInclude = 'haitou_detail_include_kw';

  // 额外过滤:最低月薪(K)、公司最低规模(人数)、仅活跃公司。0 = 不限。
  final minSalary = 0.obs; // 最低月薪(K),职位低于此值即跳过
  final minScale = 0.obs; // 公司最低规模(人数下限),小于此值即跳过
  final activeOnly = false.obs; // true=仅沟通近期活跃的 BOSS
  final activeWithin = 5.obs; // 近期活跃截止档位(见 _activeRank):2=今日 4=本周 5=本月
  static const _kMinSalary = 'haitou_min_salary';
  static const _kMinScale = 'haitou_min_scale';
  static const _kActiveWithin = 'haitou_active_within';

  /// 「近期活跃」可调档位(截止档位 maxRank,见 [_activeRank])。
  static const activeWithinOptions = <({String label, int maxRank})>[
    (label: '今日内', maxRank: 2),
    (label: '本周内', maxRank: 4),
    (label: '本月内', maxRank: 5),
  ];

  // AI 过滤:用 OpenAI 兼容接口按简历判断职位是否值得投递(仅列表卡信息,批量省 token)。
  final aiEnabled = false.obs;
  final aiBaseUrlCtrl = TextEditingController();
  final aiKeyCtrl = TextEditingController();
  final aiModelCtrl = TextEditingController();
  final resumeCtrl = TextEditingController();
  final aiBatchSize = 10.obs; // 每次批量判定的职位数
  final aiJudging = false.obs; // 正在调 AI
  final resumeFilling = false.obs; // 正在自动填充/AI 摘要简历
  static const _kAiEnabled = 'haitou_ai_enabled';
  static const _kAiBaseUrl = 'haitou_ai_baseurl';
  static const _kAiKey = 'haitou_ai_key';
  static const _kAiModel = 'haitou_ai_model';
  static const _kAiResume = 'haitou_ai_resume';
  static const _kAiBatch = 'haitou_ai_batch';
  // AI 判定结果缓存(jobKey → 是否匹配),避免重复判同一职位。
  final _aiVerdicts = <String, bool>{};
  static const _kActiveOnly = 'haitou_active_only';

  /// 公司规模档位(下限人数),UI 从中选。
  static const scaleOptions = <({String label, int min})>[
    (label: '不限', min: 0),
    (label: '≥20人', min: 20),
    (label: '≥100人', min: 100),
    (label: '≥500人', min: 500),
    (label: '≥1000人', min: 1000),
    (label: '≥10000人', min: 10000),
  ];
  // 沟通间隔:每次在 [minInterval, maxInterval] 秒内随机取值(避免固定节奏被风控)。
  final minInterval = 8.obs;
  final maxInterval = 15.obs;

  /// 目标沟通数,达到即停(0=不限)。平台每日上限约 150。
  final targetCount = 150.obs;
  /// 触发「操作过于频繁」后的基础休息时长(秒);连续触发按倍数退避。
  final restSeconds = 300.obs;
  /// 连续限流最多休息这么多次,仍不行才停(防止无意义死循环)。
  static const _maxRestRounds = 10;
  static const _kTargetCount = 'haitou_target_count';
  static const _kRestSeconds = 'haitou_rest_seconds';
  final logs = <String>[].obs;

  final _rand = Random();
  final _contacted = <String>{};
  SharedPreferences? _prefs;
  static const _prefsKey = 'haitou_contacted';

  int _cursor = 0; // 处理到 home.jobs 的下标

  @override
  void onInit() {
    super.onInit();
    _loadContacted();
  }

  Future<void> _loadContacted() async {
    _prefs = await SharedPreferences.getInstance();
    _contacted.addAll(_prefs?.getStringList(_prefsKey) ?? const []);
    excludeCtrl.text = _prefs?.getString(_kExclude) ??
        '开车,司机,销售,保安,外卖,配送,服务员,普工,直播';
    includeCtrl.text = _prefs?.getString(_kInclude) ?? '逆向,安全,爬虫,风控';
    detailExcludeCtrl.text = _prefs?.getString(_kDetailExclude) ?? '';
    detailIncludeCtrl.text = _prefs?.getString(_kDetailInclude) ?? '';
    minSalary.value = _prefs?.getInt(_kMinSalary) ?? 0;
    minScale.value = _prefs?.getInt(_kMinScale) ?? 0;
    activeOnly.value = _prefs?.getBool(_kActiveOnly) ?? false;
    activeWithin.value = _prefs?.getInt(_kActiveWithin) ?? 5;
    targetCount.value = _prefs?.getInt(_kTargetCount) ?? 150;
    restSeconds.value = _prefs?.getInt(_kRestSeconds) ?? 300;
    salaryCtrl.text = minSalary.value == 0 ? '' : '${minSalary.value}';
    aiEnabled.value = _prefs?.getBool(_kAiEnabled) ?? false;
    aiBaseUrlCtrl.text =
        _prefs?.getString(_kAiBaseUrl) ?? 'https://api.openai.com/v1';
    aiKeyCtrl.text = _prefs?.getString(_kAiKey) ?? '';
    aiModelCtrl.text = _prefs?.getString(_kAiModel) ?? 'gpt-5-nano';
    resumeCtrl.text = _prefs?.getString(_kAiResume) ?? '';
    aiBatchSize.value = _prefs?.getInt(_kAiBatch) ?? 10;
  }

  void _saveKeywords() {
    // 薪资输入框 → minSalary(非法/空按不限)。
    minSalary.value = int.tryParse(salaryCtrl.text.trim()) ?? 0;
    _prefs?.setString(_kExclude, excludeCtrl.text);
    _prefs?.setString(_kInclude, includeCtrl.text);
    _prefs?.setString(_kDetailExclude, detailExcludeCtrl.text);
    _prefs?.setString(_kDetailInclude, detailIncludeCtrl.text);
    _prefs?.setInt(_kMinSalary, minSalary.value);
    _prefs?.setInt(_kMinScale, minScale.value);
    _prefs?.setBool(_kActiveOnly, activeOnly.value);
    _prefs?.setInt(_kActiveWithin, activeWithin.value);
    _prefs?.setInt(_kTargetCount, targetCount.value);
    _prefs?.setInt(_kRestSeconds, restSeconds.value);
    _prefs?.setBool(_kAiEnabled, aiEnabled.value);
    _prefs?.setString(_kAiBaseUrl, aiBaseUrlCtrl.text.trim());
    _prefs?.setString(_kAiKey, aiKeyCtrl.text.trim());
    _prefs?.setString(_kAiModel, aiModelCtrl.text.trim());
    _prefs?.setString(_kAiResume, resumeCtrl.text);
    _prefs?.setInt(_kAiBatch, aiBatchSize.value);
  }

  /// 解析月薪下限(K)。无法识别(面议/空/日薪按月折算失败)返回 null=不拦。
  int? _parseMinSalaryK(String s) {
    if (s.isEmpty || s.contains('面议')) return null;
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(s);
    if (m == null) return null;
    var lo = double.parse(m.group(1)!);
    if (s.contains('万')) {
      lo *= 10; // 1.5万 → 15K
    } else if (s.contains('元') && s.contains('天')) {
      lo = lo * 21 / 1000; // 日薪按 21 天折算成月薪(K)
    } else if (s.contains('元') && !s.contains('K') && !s.contains('k')) {
      lo /= 1000; // 纯「元/月」→ K
    }
    return lo.round();
  }

  /// 解析公司规模下限人数(取字符串中第一个数字)。无法识别返回 null=不拦。
  int? _parseScaleMin(String s) {
    if (s.isEmpty) return null;
    final m = RegExp(r'(\d+)').firstMatch(s);
    return m == null ? null : int.parse(m.group(1)!);
  }

  /// 活跃描述是否在用户设定的「近期活跃」范围内。无法识别→放行(不误杀)。
  bool _isRecentActive(String desc) {
    final r = activeRank(desc);
    if (r < 0) return true;
    return r <= activeWithin.value;
  }

  /// 拆关键词(逗号/顿号/空格分隔,小写)。
  List<String> _kw(String s) => s
      .toLowerCase()
      .split(RegExp(r'[,，、\s]+'))
      .where((e) => e.isNotEmpty)
      .toList();

  String _jobKey(dynamic j) =>
      j.encryptJobId.isNotEmpty ? j.encryptJobId : j.securityId;

  /// 从当前职位起,向后凑一批未判定的职位一次性交给 AI(省请求/token),缓存结果。
  Future<void> _aiJudgeAhead(dynamic current) async {
    // 收集批次:当前职位 + 后续未判定的(跳过已沟通),上限 aiBatchSize。
    final batch = <dynamic>[current];
    for (var i = _cursor;
        i < home.jobs.length && batch.length < aiBatchSize.value;
        i++) {
      final j = home.jobs[i];
      final k = _jobKey(j);
      if (k.isEmpty || _aiVerdicts.containsKey(k) || _contacted.contains(k)) {
        continue;
      }
      batch.add(j);
    }
    aiJudging.value = true;
    try {
      final verdicts = await aiJudgeJobs(
        baseUrl: aiBaseUrlCtrl.text.trim(),
        apiKey: aiKeyCtrl.text.trim(),
        model: aiModelCtrl.text.trim(),
        resume: resumeCtrl.text.trim(),
        jobs: [
          for (final j in batch)
            (
              title: j.jobName as String,
              company: j.brandName as String,
              salary: j.salaryDesc as String,
              labels: (j.jobLabels as List).join(' '),
            ),
        ],
      );
      var ok = 0;
      for (var i = 0; i < batch.length; i++) {
        final m = verdicts[i] ?? true; // 缺失默认匹配,不误杀
        _aiVerdicts[_jobKey(batch[i])] = m;
        if (m) ok++;
      }
      _log('🤖 AI 判定 ${batch.length} 个 → 匹配 $ok');
    } catch (e) {
      // AI 失败不阻断:整批放行。
      for (final j in batch) {
        _aiVerdicts[_jobKey(j)] = true;
      }
      _log('⚠ AI 调用失败,本批放行: $e');
    } finally {
      aiJudging.value = false;
    }
  }

  /// 拉完整简历 → 有 AI 配置则让 AI 摘要成求职画像,否则用原始拼接文本,填入简历框。
  Future<void> autoFillResume() async {
    if (resumeFilling.value) return;
    resumeFilling.value = true;
    try {
      final boss = await BossProvider.instance.get();
      final info = await boss.queryGeekBaseInfo();
      final g = info.raw;
      String s(dynamic v) => (v ?? '').toString().trim();
      List list(dynamic v) => v is List ? v : const [];
      final parts = <String>[];
      final desc = s(g['userDescription'] ?? g['userDesc'] ?? g['geekDesc']);
      if (desc.isNotEmpty) parts.add('【个人优势】$desc');
      final exp = list(g['expectPositionList']);
      if (exp.isNotEmpty && exp.first is Map) {
        final e = exp.first as Map;
        parts.add('【求职期望】${s(e['positionName'] ?? e['position'])} · '
            '${s(e['locationName'] ?? e['cityName'])} · ${s(e['salaryDesc'] ?? e['salary'])}');
      }
      for (final w in list(g['workExperienceList']).take(5)) {
        if (w is! Map) continue;
        parts.add('【工作】${s(w['company'])} ${s(w['positionName'])} '
            '${s(w['workContent'] ?? w['responsibility'])}');
      }
      for (final pr in list(g['projectExperienceList']).take(5)) {
        if (pr is! Map) continue;
        parts.add('【项目】${s(pr['name'])} ${s(pr['description'] ?? pr['content'])}');
      }
      for (final ed in list(g['eduExperienceList']).take(3)) {
        if (ed is! Map) continue;
        parts.add('【教育】${s(ed['school'])} ${s(ed['major'])} ${s(ed['degreeName'])}');
      }
      final full = parts.join('\n');
      if (full.isEmpty) {
        _log('⚠ 未取到简历内容');
        return;
      }

      final baseUrl = aiBaseUrlCtrl.text.trim();
      final key = aiKeyCtrl.text.trim();
      if (baseUrl.isNotEmpty && key.isNotEmpty) {
        // 有 AI 配置:让 AI 把完整简历摘要成岗位匹配画像。
        try {
          resumeCtrl.text = await aiSummarizeResume(
            baseUrl: baseUrl,
            apiKey: key,
            model: aiModelCtrl.text.trim(),
            fullResume: full,
          );
          _log('🤖 已用 AI 生成求职画像');
        } catch (e) {
          resumeCtrl.text = full; // AI 失败退回原始文本
          _log('⚠ AI 摘要失败,用原始简历: $e');
        }
      } else {
        resumeCtrl.text = full;
      }
      _saveKeywords();
    } catch (e) {
      _log('⚠ 简历自动填充失败: $e');
    } finally {
      resumeFilling.value = false;
    }
  }

  @override
  void onClose() {
    excludeCtrl.dispose();
    includeCtrl.dispose();
    detailExcludeCtrl.dispose();
    detailIncludeCtrl.dispose();
    salaryCtrl.dispose();
    aiBaseUrlCtrl.dispose();
    aiKeyCtrl.dispose();
    aiModelCtrl.dispose();
    resumeCtrl.dispose();
    super.onClose();
  }

  Future<void> _saveContacted() async =>
      _prefs?.setStringList(_prefsKey, _contacted.toList());

  void _log(String s) {
    final t = DateTime.now();
    logs.insert(0,
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}  $s');
    if (logs.length > 200) logs.removeRange(200, logs.length);
  }

  void stop() => running.value = false;

  /// 可中断等待(每秒检查 [running],stop 后立即退出)。
  Future<void> _sleep(int seconds) async {
    for (var i = 0; i < seconds && running.value; i++) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// 已请求过 BOSS 接口(详情/翻页)但没发起沟通时的轻量间隔。
  ///
  /// 被过滤的职位此前直接 `continue`,详情接口会被连续快打 → 触发「操作过于频繁」。
  /// 取沟通间隔的 1/3(下限 2s)给这些请求限速。
  Future<void> _paceRequest() async {
    final lo = (minInterval.value / 3).ceil().clamp(2, 10);
    final hi = (maxInterval.value / 3).ceil().clamp(lo, 15);
    await _sleep(lo + _rand.nextInt(hi - lo + 1));
  }

  Future<void> start() async {
    if (running.value) return;
    _saveKeywords();
    _aiVerdicts.clear();
    running.value = true;
    _log('▶ 开始海投(间隔 ${minInterval.value}~${maxInterval.value}s 随机)');
    try {
      await _run();
    } catch (e) {
      _log('⚠ 异常停止: $e');
    } finally {
      running.value = false;
      current.value = '';
      _log('⏹ 停止 — 成功 ${done.value} · 跳过 ${skipped.value} · 过滤 ${filtered.value} · 失败 ${failed.value}');
    }
  }

  Future<void> _run() async {
    final boss = await BossProvider.instance.get();
    var consecutiveFail = 0;
    var restRounds = 0; // 连续触发限流的次数(用于退避与兜底停止)
    while (running.value) {
      // 达到目标即停(平台每日上限约 150)。
      if (targetCount.value > 0 && done.value >= targetCount.value) {
        _log('🎯 已投满 ${done.value} 个,达到目标');
        break;
      }
      // 列表拉完了 → 翻页;无更多则结束。
      if (_cursor >= home.jobs.length) {
        if (home.hasMore.value) {
          current.value = '加载更多职位…';
          await home.loadMore();
          await _paceRequest(); // 翻页也是 BOSS 请求,别紧接着再打详情
          if (_cursor >= home.jobs.length) {
            _log('没有更多职位了');
            break;
          }
        } else {
          _log('已到推荐列表末尾');
          break;
        }
      }
      if (!running.value) break;

      final job = home.jobs[_cursor];
      _cursor++;
      final key =
          job.encryptJobId.isNotEmpty ? job.encryptJobId : job.securityId;
      if (key.isEmpty) continue;

      // 跳过已沟通(不占用间隔,快速略过)。
      if (_contacted.contains(key)) {
        skipped.value++;
        current.value = '跳过 ${job.jobName}';
        continue;
      }

      // 关键词过滤(职位名+公司+标签)。
      final hay =
          '${job.jobName} ${job.brandName} ${job.jobLabels.join(' ')}'
              .toLowerCase();
      final ex = _kw(excludeCtrl.text);
      final inc = _kw(includeCtrl.text);
      if (ex.any(hay.contains)) {
        filtered.value++;
        _log('🚫 过滤(排除词): ${job.jobName}');
        continue;
      }
      if (inc.isNotEmpty && !inc.any(hay.contains)) {
        filtered.value++;
        _log('🚫 过滤(不含关键词): ${job.jobName}');
        continue;
      }

      // 薪资过滤:职位月薪下限 < 设定值即跳过(解析失败不拦)。
      if (minSalary.value > 0) {
        final k = _parseMinSalaryK(job.salaryDesc);
        if (k != null && k < minSalary.value) {
          filtered.value++;
          _log('🚫 过滤(薪资 ${job.salaryDesc} < ${minSalary.value}K): ${job.jobName}');
          continue;
        }
      }

      // 公司规模过滤:规模下限 < 设定人数即跳过(解析失败不拦)。
      if (minScale.value > 0) {
        final n = _parseScaleMin(job.brandScale);
        if (n != null && n < minScale.value) {
          filtered.value++;
          _log('🚫 过滤(规模 ${job.brandScale} < ${minScale.value}人): ${job.jobName}');
          continue;
        }
      }

      // 活跃过滤:在线直接放行;否则看活跃描述,非近期活跃即跳过。
      // (列表无活跃字段时留待详情兜底判断。)
      if (activeOnly.value &&
          !job.bossOnline &&
          job.activeTimeDesc.isNotEmpty &&
          !_isRecentActive(job.activeTimeDesc)) {
        filtered.value++;
        _log('🚫 过滤(不活跃 ${job.activeTimeDesc}): ${job.jobName}');
        continue;
      }

      // AI 过滤:按简历批量判定是否值得投递(基于列表卡信息,免拉详情、省 token)。
      if (aiEnabled.value && resumeCtrl.text.trim().isNotEmpty) {
        if (!_aiVerdicts.containsKey(key)) await _aiJudgeAhead(job);
        if (_aiVerdicts[key] == false) {
          filtered.value++;
          _log('🤖 AI 过滤(不匹配): ${job.jobName}');
          continue;
        }
      }

      current.value = '${job.jobName} @ ${job.brandName}';
      var greeted = false;
      try {
        final d = await boss.queryJobDetail(
            securityId: job.securityId, lid: home.lid.value);
        // 列表无活跃度字段时,用详情里的 BOSS 活跃度兜底判断。
        if (activeOnly.value &&
            job.activeTimeDesc.isEmpty &&
            !_isRecentActive(d.bossActiveDesc)) {
          filtered.value++;
          _log('🚫 过滤(不活跃 ${d.bossActiveDesc}): ${job.jobName}');
          await _paceRequest();
          continue;
        }
        // 详情正文关键词过滤:用独立的一组关键词,匹配职位描述/标签/行业/公司全名。
        final dEx = _kw(detailExcludeCtrl.text);
        final dInc = _kw(detailIncludeCtrl.text);
        if (dEx.isNotEmpty || dInc.isNotEmpty) {
          final detailHay = ('${d.jobDesc} ${d.positionName} '
                  '${d.bossLabels.join(' ')} ${d.industryName} ${d.comName}')
              .toLowerCase();
          if (dEx.any(detailHay.contains)) {
            filtered.value++;
            _log('🚫 过滤(详情含排除词): ${job.jobName}');
            await _paceRequest();
            continue;
          }
          if (dInc.isNotEmpty && !dInc.any(detailHay.contains)) {
            filtered.value++;
            _log('🚫 过滤(详情不含关键词): ${job.jobName}');
            await _paceRequest();
            continue;
          }
        }
        final resp = await boss.startChat(
          securityId: job.securityId,
          jobId: d.jobId,
          expectId: d.expectId,
          lid: home.lid.value,
        );
        final code = (resp['code'] as num?)?.toInt();
        final msg = (resp['message'] ?? '').toString();
        if (code == 0) {
          done.value++;
          greeted = true;
          _contacted.add(key);
          await _saveContacted();
          _log('✅ ${job.jobName} @ ${job.brandName}');
          consecutiveFail = 0;
          restRounds = 0;
        } else if (isDailyCapMessage(msg)) {
          // 每日沟通上限:要等到明天,休息重试没意义,直接收工。
          _log('🏁 今日已达平台上限,收工:$msg');
          break;
        } else if (msg.contains('频繁') ||
            msg.contains('限制') ||
            msg.contains('太快') ||
            msg.contains('过快') ||
            msg.contains('稍后')) {
          // 临时限流:退回这个职位,休息后重投,不中断整轮海投。
          _cursor--;
          restRounds++;
          if (restRounds > _maxRestRounds) {
            _log('🛑 连续限流 $restRounds 次仍未恢复,停止');
            break;
          }
          final wait = restSeconds.value * (restRounds > 3 ? 3 : restRounds);
          _log('😴 触发限流(第 $restRounds 次),休息 ${wait}s 后继续:$msg');
          await _sleep(wait);
          continue;
        } else if (msg.contains('已') &&
            (msg.contains('沟通') || msg.contains('聊'))) {
          // 已沟通过 → 记录并跳过(不等间隔)。
          skipped.value++;
          _contacted.add(key);
          await _saveContacted();
          _log('⏭ 已沟通过 ${job.jobName}');
          continue;
        } else {
          failed.value++;
          _log('❌ ${job.jobName} — $msg (code=$code)');
          if (++consecutiveFail >= 5) {
            _log('🛑 连续失败过多,已停止');
            break;
          }
        }
      } catch (e) {
        failed.value++;
        _log('❌ ${job.jobName} — $e');
        if (++consecutiveFail >= 5) {
          _log('🛑 连续异常过多,已停止');
          break;
        }
      }

      // 仅在真正发起沟通后等待随机间隔(跳过/异常不空耗)。
      if (greeted) {
        final lo = minInterval.value;
        final hi = maxInterval.value < lo ? lo : maxInterval.value;
        final iv = lo + _rand.nextInt(hi - lo + 1);
        _log('⏳ 等待 ${iv}s');
        await _sleep(iv);
      }
    }
  }
}
