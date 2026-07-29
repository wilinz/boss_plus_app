import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

/// 职位筛选栏:排序 / 城市 / 薪资 / 经验 / 学历,点开底部选择。
class JobFilterBar extends StatelessWidget {
  const JobFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final JobFilter filter;
  final ValueChanged<JobFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final sortLabel =
        kSortOptions.firstWhere((o) => o.value == filter.sortType).label;
    // 没选城市时服务端返回的是全国推荐流(不是求职期望城市),所以标签就显示「全国」,
    // 不要拿期望城市名冒充,否则与实际结果不符。
    final cityLabel = filter.cityName ?? '全国';
    final salaryLabel =
        kSalaryOptions.firstWhere((o) => o.code == filter.salary).label;
    // 经验可多选:空=「经验」,选 1 个显示其名,多个显示「经验(N)」。
    final expLabel = switch (filter.experience.length) {
      0 => '经验',
      1 => kExperienceOptions
          .firstWhere((o) => o.code == filter.experience.first,
              orElse: () => (code: '', label: '经验'))
          .label,
      final n => '经验($n)',
    };
    final degLabel =
        kDegreeOptions.firstWhere((o) => o.code == filter.degree).label;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _item(context, sortLabel, filter.sortType != 0, () => _pickSort(context)),
          _item(context, cityLabel, filter.cityCode != null,
              () => _pickCity(context)),
          _item(context, salaryLabel == '不限' ? '薪资' : salaryLabel,
              filter.salary != null, () => _pickSalary(context)),
          _item(context, expLabel, filter.experience.isNotEmpty,
              () => _pickExperience(context)),
          _item(context, degLabel == '不限' ? '学历' : degLabel,
              filter.degree != null, () => _pickDegree(context)),
        ],
      ),
    );
  }

  Widget _item(
      BuildContext context, String label, bool active, VoidCallback onTap) {
    final color = active ? const Color(0xFF00A6A7) : Colors.black87;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
              color: active ? const Color(0xFF00A6A7) : Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          visualDensity: VisualDensity.compact,
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 13)),
            Icon(Icons.arrow_drop_down, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _sheet(
    BuildContext context,
    String title,
    List<({String label, bool selected, VoidCallback onTap})> options,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            // 选项多时(如城市列表)可滚动,避免 Column 溢出。
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in options)
                    ListTile(
                      title: Text(o.label),
                      trailing: o.selected
                          ? const Icon(Icons.check, color: Color(0xFF00A6A7))
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        o.onTap();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickSort(BuildContext context) => _sheet(
        context,
        '排序',
        kSortOptions
            .map((o) => (
                  label: o.label,
                  selected: filter.sortType == o.value,
                  onTap: () => onChanged(filter.copyWith(sortType: o.value)),
                ))
            .toList(),
      );

  void _pickCity(BuildContext context) => _sheet(
        context,
        '选择城市',
        [
          // 「全国」= 清空城市筛选。不能传 100010000 之类的「全国码」——实测返回 0 条。
          (
            label: '全国(不限)',
            selected: filter.cityCode == null,
            onTap: () =>
                onChanged(filter.copyWith(cityCode: null, cityName: null)),
          ),
          ...kCityOptions.map((o) => (
                label: o.name,
                selected: filter.cityCode == o.code,
                onTap: () => onChanged(
                    filter.copyWith(cityCode: o.code, cityName: o.name)),
              )),
        ],
      );

  void _pickSalary(BuildContext context) => _sheet(
        context,
        '薪资范围',
        kSalaryOptions
            .map((o) => (
                  label: o.label,
                  selected: filter.salary == o.code,
                  onTap: () => onChanged(filter.copyWith(salary: o.code)),
                ))
            .toList(),
      );

  void _pickExperience(BuildContext context) => _multiSheet(
        context,
        '工作经验(可多选)',
        kExperienceOptions.map((o) => (code: o.code, label: o.label)).toList(),
        filter.experience.toSet(),
        (codes) => onChanged(filter.copyWith(experience: codes.toList())),
      );

  /// 多选底部弹窗:勾选/清空只改临时集合,**关闭时**才一次性回调(避免边选边重载列表)。
  Future<void> _multiSheet(
    BuildContext context,
    String title,
    List<({String code, String label})> options,
    Set<String> initial,
    ValueChanged<Set<String>> onApply,
  ) async {
    final picked = {...initial};
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                child: Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: picked.isEmpty
                          ? null
                          : () => setSheet(picked.clear),
                      child: const Text('清空'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final o in options)
                      CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(o.label),
                        value: picked.contains(o.code),
                        onChanged: (v) => setSheet(() => v == true
                            ? picked.add(o.code)
                            : picked.remove(o.code)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('完成'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // 关闭后:选择有变化才应用(触发一次列表重载)。
    if (!setEquals(picked, initial)) onApply(picked);
  }

  void _pickDegree(BuildContext context) => _sheet(
        context,
        '学历要求',
        kDegreeOptions
            .map((o) => (
                  label: o.label,
                  selected: filter.degree == o.code,
                  onTap: () => onChanged(filter.copyWith(degree: o.code)),
                ))
            .toList(),
      );
}
