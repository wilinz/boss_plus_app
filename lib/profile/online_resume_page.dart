import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/boss_provider.dart';

/// 在线简历原生预览:渲染 geekDetail 结构化数据(自我介绍 / 工作 / 项目 / 教育 / 期望)。
/// 官方在线简历是纯原生 UI(非 PDF / 非 WebView)。数据来自 baseinfo/query 的 geekDetail。
class OnlineResumeController extends GetxController {
  final loading = true.obs;
  final error = ''.obs;
  final geek = Rxn<GeekInfo>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = '';
    try {
      final b = await BossProvider.instance.get();
      geek.value = await b.queryGeekBaseInfo();
    } catch (e) {
      error.value = '$e';
    } finally {
      loading.value = false;
    }
  }

  /// 保存个人优势(简历编辑):`baseinfo/update` 的 `userDescription` 字段
  /// (= 官方 AdvantageEditFragment)。成功后刷新简历。返回提示文案。
  Future<String> saveAdvantage(String text) async {
    try {
      final b = await BossProvider.instance.get();
      final resp = await b.updateBaseInfo({'userDescription': text});
      if (resp['code'] == 0) {
        await load();
        return '保存成功';
      }
      return (resp['message'] as String?) ?? '保存失败';
    } catch (e) {
      return '保存失败: $e';
    }
  }

  /// 保存求职状态:`baseinfo/update` 的 `applyStatus` 字段(= 官方 GeekWorkStatusDialog)。
  /// [code] 取自官方 jobType 配置(0=随时到岗/3=月内/2=考虑机会/1=暂不考虑)。
  Future<String> saveApplyStatus(int code) async {
    try {
      final b = await BossProvider.instance.get();
      final resp = await b.updateBaseInfo({'applyStatus': code});
      if (resp['code'] == 0) {
        await load();
        return '保存成功';
      }
      return (resp['message'] as String?) ?? '保存失败';
    } catch (e) {
      return '保存失败: $e';
    }
  }

  /// 新增/编辑项目经历(projexp/save)。成功后刷新。返回提示文案。
  Future<String> saveProject(Map<String, String> fields) async {
    try {
      final b = await BossProvider.instance.get();
      final resp = await b.saveProjectExp(fields);
      if (resp['code'] == 0) {
        await load();
        return '保存成功';
      }
      return (resp['message'] as String?) ?? '保存失败';
    } catch (e) {
      return '保存失败: $e';
    }
  }

  /// 删除项目经历(projexp/delete)。成功后刷新。返回提示文案。
  Future<String> deleteProject(int projectId) async {
    try {
      final b = await BossProvider.instance.get();
      final resp = await b.deleteProjectExp(projectId);
      if (resp['code'] == 0) {
        await load();
        return '已删除';
      }
      return (resp['message'] as String?) ?? '删除失败';
    } catch (e) {
      return '删除失败: $e';
    }
  }
}

class OnlineResumePage extends StatefulWidget {
  const OnlineResumePage({super.key});

  @override
  State<OnlineResumePage> createState() => _OnlineResumePageState();
}

class _OnlineResumePageState extends State<OnlineResumePage> {
  static const _tag = 'online_resume';
  late final OnlineResumeController c;

  static const _teal = Color(0xFF12B7A0);
  static const _bg = Color(0xFFF2F3F5);

  @override
  void initState() {
    super.initState();
    // 每次进页用全新控制器(onInit 触发 load),避免复用上次的旧缓存。
    Get.delete<OnlineResumeController>(tag: _tag);
    c = Get.put(OnlineResumeController(), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<OnlineResumeController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('在线简历'), actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: c.load),
      ]),
      body: Obx(() {
        if (c.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final g = c.geek.value;
        if (g == null) {
          return Center(
              child: Text('加载失败: ${c.error.value}',
                  style: const TextStyle(color: Colors.grey)));
        }
        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _header(g),
              const SizedBox(height: 12),
              ..._sections(context, c, g.raw),
            ],
          ),
        );
      }),
    );
  }

  Widget _card(String title, Widget child, {VoidCallback? onEdit}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                if (onEdit != null)
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined,
                          size: 18, color: Colors.black38),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  Widget _header(GeekInfo g) {
    // 官方副标题:"26年应届生｜23岁｜本科"
    final fresh = _s(g.raw, ['graduateTag', 'freshGraduateDesc']);
    final degree = _s(g.raw, ['degreeCategory', 'degreeName']);
    final parts = [
      if (fresh.isNotEmpty) fresh,
      if (g.ageDesc.isNotEmpty) g.ageDesc,
      if (degree.isNotEmpty) degree,
    ];
    final isStudent = (g.raw['freshGraduate'] == true) ||
        _s(g.raw, ['geekAffiliation']).contains('学生');
    final phone = _s(g.raw, ['phone', 'encryptPhone']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFCED4DA),
            backgroundImage:
                g.avatar.isNotEmpty ? NetworkImage(g.avatar) : null,
            child: g.avatar.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(g.name.isEmpty ? '牛人' : g.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                    if (isStudent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: _teal,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('学生',
                            style: TextStyle(
                                color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                if (parts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(parts.join(' ｜ '),
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54)),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.phone_outlined,
                        size: 15, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(phone,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black45)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sections(
      BuildContext context, OnlineResumeController c, Map<String, dynamic> gd) {
    final out = <Widget>[];

    // 个人优势(= userDescription):始终显示,可编辑(简历编辑入口)
    final desc = _s(gd, ['userDescription', 'userDesc', 'geekDesc']);
    out.add(_card(
      '个人优势',
      Text(desc.isEmpty ? '点击右上角编辑,填写你的个人优势' : desc,
          style: desc.isEmpty ? _hint : _body),
      onEdit: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AdvantageEditPage(initial: desc, controller: c))),
    ));

    // 求职状态(applyStatus):始终显示,可编辑(底部选择器)
    final statusText = _s(gd, ['applyStatusContent', 'applyStatusDesc']);
    final curStatus = (gd['applyStatus'] as num?)?.toInt();
    // freshGraduate(graduate)语义见官方 qx.a.a:0=职场人(在职/离职)、3=在校生(在校/离校)、
    // 2=在校生找实习、1=应届生。非 0 即在校/应届身份,用「在校/离校」前缀。
    final grad = (gd['freshGraduate'] as num?)?.toInt() ?? 0;
    final isStu = grad != 0 || _s(gd, ['geekAffiliation']).contains('学生');
    out.add(_card(
      '求职状态',
      Text(statusText.isEmpty ? '点击右上角编辑,设置求职状态' : statusText,
          style: statusText.isEmpty ? _hint : _body),
      onEdit: () => _editApplyStatus(context, c, isStu, curStatus),
    ));

    // 求职期望(职位 · 城市 · 行业)
    final expect = _firstMap(gd, ['geekStuCombineExpect']) ??
        _firstOfList(gd, ['expectPositionList']);
    if (expect != null) {
      final pos = _s(expect, ['positionName', 'position']);
      final city = _s(expect, ['locationName', 'cityName', 'city']);
      final salary = _s(expect, ['salaryDesc', 'salary']);
      final line = [pos, city, salary].where((s) => s.isNotEmpty).join(' · ');
      if (line.isNotEmpty) out.add(_card('求职期望', Text(line, style: _body)));
    }

    // 工作/实习经历(ServerWorkBean)
    out.addAll(_expList(gd, ['workExperienceList'], '工作/实习经历', (m) {
      final title = _s(m, ['company', 'formattedCompany']);
      final sub = _s(m, ['positionName', 'positionTitle']);
      final time = _timeRange(m);
      final detail = _s(m, ['workContent', 'responsibility', 'workEmphasis']);
      return (title, sub, time, detail);
    }));

    // 项目经历(ServerProjectBean):可新增/编辑/删除(projexp/save|delete)
    out.addAll(_projectSection(context, c, gd));

    // 教育经历(ServerEduBean: school / major / degreeName / eduDescription / dates)
    out.addAll(_expList(gd, ['eduExperienceList'], '教育经历', (m) {
      final title = _s(m, ['school']);
      final sub = [_s(m, ['major']), _s(m, ['degreeName'])]
          .where((s) => s.isNotEmpty)
          .join(' · ');
      final time = _timeRange(m);
      final detail = _s(m, ['eduDescription', 'courseDesc', 'briefIntroduce']);
      return (title, sub, time, detail);
    }));

    // 校园/社团经历(ServerClubBean: name / roleName / description / dates)
    out.addAll(_expList(gd, ['clubExpList'], '校园/社团经历', (m) {
      final title = _s(m, ['name']);
      final sub = _s(m, ['roleName']);
      final time = _timeRange(m);
      final detail = _s(m, ['description']);
      return (title, sub, time, detail);
    }));

    // 培训经历
    out.addAll(_expList(gd, ['trainingExpList'], '培训经历', (m) {
      final title = _s(m, ['name', 'trainingName', 'organization']);
      final sub = _s(m, ['courseName', 'course', 'roleName']);
      final time = _timeRange(m);
      final detail = _s(m, ['description', 'content']);
      return (title, sub, time, detail);
    }));

    // 所获荣誉(官方显示为标签 chips)
    final honors = _labels(gd, ['honorList']);
    if (honors.isNotEmpty) {
      out.add(_card('所获荣誉',
          Wrap(spacing: 8, runSpacing: 8, children: [for (final h in honors) _chip(h)])));
    }

    // 资格证书
    out.addAll(_expList(gd, ['certificationList'], '资格证书', (m) {
      final title = _s(m, ['name', 'certName', 'title']);
      final time = _s(m, ['date', 'getDate', 'time']);
      final detail = _s(m, ['description', 'content']);
      return (title, '', time, detail);
    }));

    // 志愿经历
    out.addAll(_expList(gd, ['volunteerList'], '志愿经历', (m) {
      final title = _s(m, ['name', 'organization']);
      final sub = _s(m, ['roleName', 'role']);
      final time = _timeRange(m);
      final detail = _s(m, ['description', 'content']);
      return (title, sub, time, detail);
    }));

    // 技能标签
    final skills = _labels(gd, ['geekSkillLabelList', 'professionalSkill']);
    if (skills.isNotEmpty) {
      out.add(_card(
        '专业技能',
        Wrap(spacing: 8, runSpacing: 8, children: [for (final s in skills) _chip(s)]),
      ));
    }

    // 性格标签
    final chars = _labels(gd, ['geekCharacterLabelList']);
    if (chars.isNotEmpty) {
      out.add(_card(
        '性格特点',
        Wrap(spacing: 8, runSpacing: 8, children: [for (final s in chars) _chip(s)]),
      ));
    }

    if (out.isEmpty) {
      out.add(_card('在线简历',
          const Text('暂无结构化内容', style: TextStyle(color: Colors.grey))));
    }
    return out;
  }

  static const _body =
      TextStyle(fontSize: 14, color: Colors.black87, height: 1.5);
  static const _hint = TextStyle(fontSize: 14, color: Colors.black38);

  /// 项目经历区块:条目可点编辑 + 底部「新增」(= 官方 ProjectExperienceActivity)。
  List<Widget> _projectSection(
      BuildContext context, OnlineResumeController c, Map<String, dynamic> gd) {
    final raw = gd['projectExperienceList'];
    final items = raw is List ? raw.whereType<Map>().toList() : const <Map>[];
    void openEdit(Map? item) => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProjectExpEditPage(
            controller: c,
            initial: item == null ? null : Map<String, dynamic>.from(item),
          ),
        ));
    return [
      _card(
        '项目经历',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final m in items)
              InkWell(
                onTap: () => openEdit(m),
                child: _expItem((
                  _s(m, ['name']),
                  _s(m, ['roleName']),
                  _rangeYm(m),
                  _s(m, ['projectDescription', 'performance']),
                )),
              ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('还没有项目经历', style: _hint),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => openEdit(null),
                icon: const Icon(Icons.add, size: 18, color: _teal),
                label: const Text('新增项目经历',
                    style: TextStyle(color: _teal)),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// `"yyyyMM"` → `"yyyy.MM"`;`-1`/空 → 至今/空(= 官方 n70.a.c)。
  static String _fmtYm(String v) {
    if (v.isEmpty) return '';
    if (v == '-1') return '至今';
    if (v.length >= 6) return '${v.substring(0, 4)}.${v.substring(4, 6)}';
    if (v.length >= 4) return v.substring(0, 4);
    return v;
  }

  static String _rangeYm(Map m) {
    final s = _fmtYm(_s(m, ['startDate']));
    final e = _fmtYm(_s(m, ['endDate']));
    if (s.isEmpty && e.isEmpty) return '';
    return '$s - ${e.isEmpty ? '至今' : e}';
  }

  /// 求职状态选项(码来自官方 y.A() 的 jobType 配置;在校/在职前缀按 freshGraduate 区分)。
  static List<(int, String)> _applyStatusOptions(bool student) {
    final onJob = student ? '在校' : '在职';
    final off = student ? '离校' : '离职';
    return [
      (0, '$off-随时到岗'),
      (3, '$onJob-月内到岗'),
      (2, '$onJob-考虑机会'),
      (1, '$onJob-暂不考虑'),
    ];
  }

  Future<void> _editApplyStatus(BuildContext context, OnlineResumeController c,
      bool student, int? current) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('求职状态',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            for (final (code, label) in _applyStatusOptions(student))
              ListTile(
                title: Text(label),
                trailing: code == current
                    ? const Icon(Icons.check, color: _teal)
                    : null,
                onTap: () => Navigator.of(ctx).pop(code),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || picked == current) return;
    final msg = await c.saveApplyStatus(picked);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  List<Widget> _expList(Map<String, dynamic> gd, List<String> keys,
      String title, (String, String, String, String) Function(Map) map) {
    List? list;
    for (final k in keys) {
      if (gd[k] is List && (gd[k] as List).isNotEmpty) {
        list = gd[k] as List;
        break;
      }
    }
    if (list == null) return const [];
    return [
      _card(
        title,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in list)
              if (item is Map) _expItem(map(item)),
          ],
        ),
      ),
    ];
  }

  Widget _expItem((String, String, String, String) e) {
    final (title, sub, time, detail) = e;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title.isEmpty ? '—' : title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              if (time.trim() != '-')
                Text(time,
                    style: const TextStyle(fontSize: 12, color: Colors.black38)),
            ],
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 13, color: _teal)),
          ],
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(detail, style: _body),
          ],
        ],
      ),
    );
  }

  static String _timeRange(Map m) {
    final s = _s(m, ['startDate', 'startYearMonth', 'startTime']);
    final e = _s(m, ['endDate', 'endYearMonth', 'endTime']);
    if (s.isEmpty && e.isEmpty) return '';
    return '$s - ${e.isEmpty ? '至今' : e}';
  }

  static List<String> _labels(Map gd, List<String> keys) {
    for (final k in keys) {
      final v = gd[k];
      if (v is List && v.isNotEmpty) {
        return v
            .map((e) => e is Map
                ? _s(e, ['name', 'labelName', 'skillName', 'text'])
                : e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      if (v is String && v.isNotEmpty) {
        return v.split(RegExp(r'[,，、]')).where((s) => s.isNotEmpty).toList();
      }
    }
    return const [];
  }

  Widget _chip(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(6)),
        child: Text(s, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      );

  // ---- 取值助手(字段名多候选)----
  static String _s(Map m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '';
  }

  static Map<String, dynamic>? _firstMap(Map gd, List<String> keys) {
    for (final k in keys) {
      if (gd[k] is Map) return Map<String, dynamic>.from(gd[k] as Map);
    }
    return null;
  }

  static Map<String, dynamic>? _firstOfList(Map gd, List<String> keys) {
    for (final k in keys) {
      if (gd[k] is List &&
          (gd[k] as List).isNotEmpty &&
          (gd[k] as List).first is Map) {
        return Map<String, dynamic>.from((gd[k] as List).first as Map);
      }
    }
    return null;
  }
}

/// 个人优势编辑页(简历编辑):多行文本 → `updateBaseInfo({userDescription})`。
/// 保存成功后回到在线简历并刷新(controller.load 已在 saveAdvantage 内触发)。
class AdvantageEditPage extends StatefulWidget {
  const AdvantageEditPage(
      {super.key, required this.initial, required this.controller});

  final String initial;
  final OnlineResumeController controller;

  @override
  State<AdvantageEditPage> createState() => _AdvantageEditPageState();
}

class _AdvantageEditPageState extends State<AdvantageEditPage> {
  static const _teal = Color(0xFF12B7A0);
  static const int _maxLen = 2000;

  late final TextEditingController _tc =
      TextEditingController(text: widget.initial);
  bool _saving = false;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final msg = await widget.controller.saveAdvantage(_tc.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
    if (msg == '保存成功') Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人优势'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: _teal))
                : const Text('保存',
                    style: TextStyle(
                        color: _teal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _tc,
          maxLength: _maxLen,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: '介绍你的核心优势、技能亮点、职业规划…',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }
}

/// 项目经历编辑页(新增/编辑):`projexp/save`,删除 `projexp/delete`。
/// 日期为 `"yyyyMM"`(年+月轮选),结束可选「至今」(=`-1`)。字段对齐官方 ServerProjectBean。
class ProjectExpEditPage extends StatefulWidget {
  const ProjectExpEditPage(
      {super.key, required this.controller, this.initial});

  final OnlineResumeController controller;
  final Map<String, dynamic>? initial;

  @override
  State<ProjectExpEditPage> createState() => _ProjectExpEditPageState();
}

class _ProjectExpEditPageState extends State<ProjectExpEditPage> {
  static const _teal = Color(0xFF12B7A0);

  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _url;
  late final TextEditingController _desc;
  late final TextEditingController _perf;
  String _startYm = '';
  String _endYm = ''; // "yyyyMM" 或 "-1"(至今)
  bool _busy = false;

  int get _projectId =>
      (widget.initial?['projectId'] as num?)?.toInt() ?? 0;
  bool get _isEditing => _projectId > 0;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    String s(String k) => (m?[k] ?? '').toString();
    _name = TextEditingController(text: s('name'));
    _role = TextEditingController(text: s('roleName'));
    _url = TextEditingController(text: s('url'));
    _desc = TextEditingController(text: s('projectDescription'));
    _perf = TextEditingController(text: s('performance'));
    _startYm = s('startDate');
    _endYm = s('endDate');
  }

  @override
  void dispose() {
    for (final c in [_name, _role, _url, _desc, _perf]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmt(String v) {
    if (v.isEmpty) return '选择时间';
    if (v == '-1') return '至今';
    if (v.length >= 6) return '${v.substring(0, 4)}.${v.substring(4, 6)}';
    if (v.length >= 4) return v.substring(0, 4);
    return v;
  }

  Future<void> _pickYm({required bool isEnd}) async {
    final now = DateTime.now();
    final years = [for (var y = now.year; y >= 1970; y--) y];
    final cur = isEnd ? _endYm : _startYm;
    var selYear = (cur.length >= 4 && cur != '-1')
        ? int.tryParse(cur.substring(0, 4)) ?? now.year
        : now.year;
    var selMonth = (cur.length >= 6 && cur != '-1')
        ? int.tryParse(cur.substring(4, 6)) ?? now.month
        : now.month;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 320,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消',
                          style: TextStyle(color: Colors.black45))),
                  if (isEnd)
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, '-1'),
                        child: const Text('至今',
                            style: TextStyle(color: _teal))),
                  TextButton(
                      // 官方日期为 8 位 yyyyMMdd(日固定 01,见真机 baseinfo/query)
                      onPressed: () => Navigator.pop(ctx,
                          '$selYear${selMonth.toString().padLeft(2, '0')}01'),
                      child: const Text('确定',
                          style: TextStyle(
                              color: _teal, fontWeight: FontWeight.w600))),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 40,
                        controller: FixedExtentScrollController(
                            initialItem: years.indexOf(selYear)),
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) => selYear = years[i],
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: years.length,
                          builder: (_, i) =>
                              Center(child: Text('${years[i]}年')),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 40,
                        controller: FixedExtentScrollController(
                            initialItem: selMonth - 1),
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) => selMonth = i + 1,
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 12,
                          builder: (_, i) =>
                              Center(child: Text('${i + 1}月')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isEnd) {
        _endYm = picked;
      } else {
        _startYm = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _toast('请填写项目名称');
      return;
    }
    if (_startYm.isEmpty) {
      _toast('请选择开始时间');
      return;
    }
    setState(() => _busy = true);
    final msg = await widget.controller.saveProject({
      'projectId': '$_projectId',
      'name': _name.text.trim(),
      'roleName': _role.text.trim(),
      'url': _url.text.trim(),
      'projectDescription': _desc.text.trim(),
      'performance': _perf.text.trim(),
      'startDate': _startYm,
      'endDate': _endYm.isEmpty ? '-1' : _endYm,
    });
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(msg);
    if (msg == '保存成功') Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除项目经历'),
        content: const Text('确定删除这条项目经历吗?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    final msg = await widget.controller.deleteProject(_projectId);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(msg);
    if (msg == '已删除') Navigator.of(context).pop(true);
  }

  void _toast(String s) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑项目经历' : '新增项目经历'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _teal))
                : const Text('保存',
                    style: TextStyle(
                        color: _teal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('项目名称', _name, hint: '必填'),
          _field('担任角色', _role),
          Row(children: [
            Expanded(child: _dateTile('开始时间', _startYm, () => _pickYm(isEnd: false))),
            const SizedBox(width: 12),
            Expanded(child: _dateTile('结束时间', _endYm, () => _pickYm(isEnd: true))),
          ]),
          _field('项目描述', _desc, maxLines: 4),
          _field('项目业绩', _perf, maxLines: 4),
          _field('项目链接', _url, keyboard: TextInputType.url),
          if (_isEditing) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('删除该项目经历',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {String? hint, int maxLines = 1, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            maxLines: maxLines,
            keyboardType: keyboard,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            child: InputDecorator(
              decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder()),
              child: Text(_fmt(value),
                  style: TextStyle(
                      color: value.isEmpty ? Colors.black38 : Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }
}
