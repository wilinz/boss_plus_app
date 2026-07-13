import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'haitou_controller.dart';

/// 海投面板:配置沟通间隔、启动/停止、显示进度与日志。
class HaitouPage extends StatelessWidget {
  const HaitouPage({super.key});

  static const _teal = Color(0xFF12B7A0);

  @override
  Widget build(BuildContext context) {
    // 常驻单例:即使离开本页,海投任务仍在后台继续(可切到别的页面操作)。
    final c = HaitouController.to;
    return Scaffold(
      appBar: AppBar(title: const Text('海投')),
      body: Obx(() {
        final total =
            c.done.value + c.skipped.value + c.filtered.value + c.failed.value;
        return SingleChildScrollView(
          child: Column(
          children: [
            // ---- 进度卡 ----
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _stat('已沟通', c.done.value, _teal),
                        _stat('跳过', c.skipped.value, Colors.orange),
                        _stat('过滤', c.filtered.value, Colors.purple),
                        _stat('失败', c.failed.value, Colors.red),
                        _stat('累计', total, Colors.blueGrey),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: c.running.value ? null : 0,
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.running.value
                          ? (c.current.value.isEmpty ? '运行中…' : c.current.value)
                          : '未运行',
                      style: const TextStyle(color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // ---- 间隔设置(随机区间) ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('随机间隔'),
                  Expanded(
                    child: RangeSlider(
                      min: 5,
                      max: 120,
                      divisions: 115,
                      labels: RangeLabels('${c.minInterval.value}s',
                          '${c.maxInterval.value}s'),
                      values: RangeValues(c.minInterval.value.toDouble(),
                          c.maxInterval.value.toDouble()),
                      onChanged: c.running.value
                          ? null
                          : (v) {
                              c.minInterval.value = v.start.round();
                              c.maxInterval.value = v.end.round();
                            },
                    ),
                  ),
                  SizedBox(
                      width: 68,
                      child: Text(
                          '${c.minInterval.value}~${c.maxInterval.value}s',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
            // ---- 关键词过滤 ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: TextField(
                controller: c.excludeCtrl,
                enabled: !c.running.value,
                decoration: const InputDecoration(
                  labelText: '排除关键词(命中即跳过)',
                  hintText: '司机,销售,保安,外卖…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: c.includeCtrl,
                enabled: !c.running.value,
                decoration: const InputDecoration(
                  labelText: '仅含关键词(留空=不限)',
                  hintText: 'Android,逆向,安全,开发…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // ---- 详情正文关键词(独立于上面的列表关键词)----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: c.detailExcludeCtrl,
                enabled: !c.running.value,
                decoration: const InputDecoration(
                  labelText: '详情排除关键词(正文命中即跳过)',
                  hintText: '外包,驻场,加班…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: c.detailIncludeCtrl,
                enabled: !c.running.value,
                decoration: const InputDecoration(
                  labelText: '详情仅含关键词(留空=不限)',
                  hintText: 'so,frida,unidbg…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // ---- 薪资 / 公司规模 / 活跃度 ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // 最低月薪
                  Expanded(
                    child: TextField(
                      controller: c.salaryCtrl,
                      enabled: !c.running.value,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '最低月薪(K)',
                        hintText: '留空=不限',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 公司规模
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: c.minScale.value,
                      decoration: const InputDecoration(
                        labelText: '公司规模',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final o in HaitouController.scaleOptions)
                          DropdownMenuItem(value: o.min, child: Text(o.label)),
                      ],
                      onChanged: c.running.value
                          ? null
                          : (v) => c.minScale.value = v ?? 0,
                    ),
                  ),
                ],
              ),
            ),
            // 仅活跃公司
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CheckboxListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('仅沟通近期活跃的 BOSS',
                    style: TextStyle(fontSize: 14)),
                value: c.activeOnly.value,
                onChanged: c.running.value
                    ? null
                    : (v) => c.activeOnly.value = v ?? false,
              ),
            ),
            // ---- AI 过滤(OpenAI 兼容)----
            _aiSection(c),
            const SizedBox(height: 4),
            // ---- 启动/停止 ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: c.running.value ? Colors.red : _teal),
                  icon: Icon(c.running.value ? Icons.stop : Icons.send),
                  label: Text(c.running.value ? '停止' : '开始海投'),
                  onPressed: c.running.value ? c.stop : c.start,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('已沟通的职位会自动跳过;触发平台限流会自动停止。',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
            const Divider(height: 16),
            // ---- 日志 ----
            SizedBox(
              height: 320,
              child: c.logs.isEmpty
                  ? const Center(
                      child: Text('日志', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: c.logs.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(c.logs[i],
                            style: const TextStyle(
                                fontSize: 12.5, height: 1.3)),
                      ),
                    ),
            ),
          ],
          ),
        );
      }),
    );
  }

  Widget _aiSection(HaitouController c) {
    InputDecoration dec(String label, [String? hint]) => InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
        );
    return Obx(() => Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: c.aiEnabled.value,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: _teal),
                const SizedBox(width: 8),
                const Text('AI 过滤(按简历判断是否匹配)',
                    style: TextStyle(fontSize: 14)),
                const Spacer(),
                Switch(
                  value: c.aiEnabled.value,
                  onChanged:
                      c.running.value ? null : (v) => c.aiEnabled.value = v,
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            children: [
              TextField(
                  controller: c.aiBaseUrlCtrl,
                  enabled: !c.running.value,
                  decoration: dec('Base URL', 'https://api.openai.com/v1')),
              const SizedBox(height: 8),
              TextField(
                  controller: c.aiKeyCtrl,
                  enabled: !c.running.value,
                  obscureText: true,
                  decoration: dec('API Key', 'sk-…')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                        controller: c.aiModelCtrl,
                        enabled: !c.running.value,
                        decoration: dec('模型', 'gpt-5-nano')),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<int>(
                      initialValue: c.aiBatchSize.value,
                      decoration: dec('每批数量'),
                      items: [
                        for (final n in const [5, 10, 15, 20, 30])
                          DropdownMenuItem(value: n, child: Text('$n')),
                      ],
                      onChanged: c.running.value
                          ? null
                          : (v) => c.aiBatchSize.value = v ?? 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: c.resumeCtrl,
                enabled: !c.running.value,
                maxLines: 4,
                minLines: 2,
                decoration: dec('简历/求职描述(AI 判断依据)', '技能、经验、期望…'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: c.resumeFilling.value
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(c.resumeFilling.value
                      ? '生成中…'
                      : 'AI 从我的简历生成画像'),
                  onPressed: c.running.value || c.resumeFilling.value
                      ? null
                      : c.autoFillResume,
                ),
              ),
              const Text('填了 Base URL/Key 时,点上方按钮会用 AI 把完整简历摘要成求职画像;'
                  '匹配时仅把职位名/公司/薪资/标签批量发给 AI,省 token。',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ));
  }

  Widget _stat(String label, int n, Color color) => Expanded(
        child: Column(
          children: [
            Text('$n',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      );
}
