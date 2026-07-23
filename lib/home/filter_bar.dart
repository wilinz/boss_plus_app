import 'package:boss_plus/boss_plus.dart';
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
    final expLabel =
        kExperienceOptions.firstWhere((o) => o.code == filter.experience).label;
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
          _item(context, expLabel == '不限' ? '经验' : expLabel,
              filter.experience != null, () => _pickExperience(context)),
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

  void _pickExperience(BuildContext context) => _sheet(
        context,
        '工作经验',
        kExperienceOptions
            .map((o) => (
                  label: o.label,
                  selected: filter.experience == o.code,
                  onTap: () => onChanged(filter.copyWith(experience: o.code)),
                ))
            .toList(),
      );

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
