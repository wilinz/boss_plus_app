import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'filter_bar.dart';
import 'haitou_controller.dart';
import 'haitou_page.dart';
import 'home_controller.dart';
import 'job_detail_page.dart';

/// 首页:顶部个人信息卡 + 推荐职位列表。
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HomeController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('BOSS 直聘 · 推荐'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: c.refreshAll,
          ),
          // 海投:运行中图标高亮(任务在后台持续,切到别的页面也不停)。
          Obx(() {
            final running = HaitouController.to.running.value;
            return IconButton(
              icon: Icon(running ? Icons.campaign : Icons.campaign_outlined,
                  color: running ? const Color(0xFF12B7A0) : null),
              tooltip: running ? '海投进行中' : '海投',
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const HaitouPage())),
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出登录',
            onPressed: onLogout,
          ),
        ],
      ),
      body: Obx(() {
        if (c.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: c.refreshAll,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                c.loadMore();
              }
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (c.geek.value != null) _profileCard(c.geek.value!),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('推荐职位',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('${c.jobs.length}',
                      style: const TextStyle(color: Colors.grey)),
                ]),
                const SizedBox(height: 8),
                // 筛选栏:排序 / 城市 / 薪资 / 经验 / 学历
                JobFilterBar(
                  filter: c.filter.value,
                  defaultCityName: c.geek.value?.expect?.cityName ?? '',
                  onChanged: c.applyFilter,
                ),
                const SizedBox(height: 8),
                if (c.error.value.isNotEmpty && c.jobs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                        child: Text(c.error.value,
                            style: const TextStyle(color: Colors.grey))),
                  ),
                ...c.jobs.map((j) => _jobCard(context, j, c.lid.value)),
                if (c.loadingMore.value)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!c.hasMore.value && c.jobs.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: Text('没有更多了',
                            style: TextStyle(color: Colors.grey))),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _profileCard(GeekInfo g) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  g.avatar.isNotEmpty ? NetworkImage(g.avatar) : null,
              child: g.avatar.isEmpty ? const Icon(Icons.person, size: 32) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name.isEmpty ? '牛人' : g.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    [g.ageDesc, g.applyStatus, g.hometown]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (g.expect != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '期望:${g.expect!.positionName} · ${g.expect!.cityName}',
                      style: const TextStyle(
                          color: Color(0xFF00A6A7),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text('UID ${g.userId}',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobCard(BuildContext context, JobCard j, String lid) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => JobDetailPage(
            securityId: j.securityId,
            lid: lid,
            title: j.jobName,
          ),
        )),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(j.jobName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Text(j.salaryDesc,
                    style: const TextStyle(
                        color: Color(0xFFFF7B33),
                        fontWeight: FontWeight.bold)),
              ],
            ),
            if (j.locationDesc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(j.locationDesc,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
            if (j.jobLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: j.jobLabels
                    .take(6)
                    .map((l) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(l,
                              style: const TextStyle(fontSize: 12)),
                        ))
                    .toList(),
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      j.bossAvatar.isNotEmpty ? NetworkImage(j.bossAvatar) : null,
                  child: j.bossAvatar.isEmpty
                      ? const Icon(Icons.person, size: 14)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      '${j.bossName}${j.bossTitle.isNotEmpty ? "·${j.bossTitle}" : ""}',
                      j.brandName,
                      j.brandDesc,
                    ].where((s) => s.isNotEmpty).join('  |  '),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
