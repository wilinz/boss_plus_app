import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/material.dart';

import '../chat/chat_page.dart';
import '../data/boss_provider.dart';

/// 职位详情页:传入职位卡的 securityId + 列表 lid,拉取并展示完整详情。
class JobDetailPage extends StatefulWidget {
  const JobDetailPage({
    super.key,
    required this.securityId,
    required this.lid,
    required this.title,
  });

  final String securityId;
  final String lid;
  final String title;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  JobDetail? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await BossProvider.instance.get();
      final d = await b.queryJobDetail(
          securityId: widget.securityId, lid: widget.lid);
      if (mounted) setState(() => _detail = d);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  bool _starting = false;

  Future<void> _startChat(JobDetail d) async {
    setState(() => _starting = true);
    try {
      final b = await BossProvider.instance.get();
      final resp = await b.startChat(
        securityId: widget.securityId,
        jobId: d.jobId,
        expectId: d.expectId,
        lid: widget.lid,
      );
      if (!mounted) return;
      // 权威来源:startChat 响应的 relation(= 官方 GeekCreateFriendResponse.relation),
      // 含真实 friendId、friend 专属 securityId、name。用它打开会话页 —— 否则用职位页的
      // d.bossUid(可能 0)+ 职位 securityId(拉历史拉不到)会导致 peerUid=0、开场白被误过滤。
      final zp = resp['zpData'];
      final relation =
          (zp is Map && zp['relation'] is Map) ? zp['relation'] as Map : const {};
      final friendId =
          (relation['friendId'] as num?)?.toInt() ?? d.bossUid;
      final friendSecurityId =
          (relation['securityId'] as String?) ?? widget.securityId;
      final friendName = (relation['name'] as String?)?.trim();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatPage(
          peerUid: friendId,
          peerName: (friendName == null || friendName.isEmpty)
              ? (d.bossName.isEmpty ? 'Boss' : d.bossName)
              : friendName,
          peerSubtitle:
              d.comName.isEmpty ? '招聘者' : '${d.comName} · 招聘者',
          peerAvatar: d.bossAvatar,
          friendSource: (relation['friendSource'] as num?)?.toInt() ?? 0,
          securityId: friendSecurityId,
          jobCard: ChatJobCard(
            jobTitle: d.positionName,
            salary: d.salaryDesc,
            company: d.comName,
            stage: d.stageName,
            location: d.locationDesc.isEmpty ? d.address : d.locationDesc,
            experience: d.experienceName,
            degree: d.degreeName,
            bossName: d.bossName,
            bossTitle: d.bossTitle,
            bossAvatar: d.bossAvatar,
          ),
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('发起沟通失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _error != null
          ? Center(child: Text('加载失败: $_error'))
          : d == null
              ? const Center(child: CircularProgressIndicator())
              : _content(d),
      bottomNavigationBar: d == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  icon: _starting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.chat),
                  label: const Text('立即沟通'),
                  onPressed: _starting ? null : () => _startChat(d),
                ),
              ),
            ),
    );
  }

  Widget _content(JobDetail d) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 职位标题 + 薪资
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(d.positionName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Text(d.salaryDesc,
                style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFFF7B33),
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (d.locationDesc.isNotEmpty) _chip(d.locationDesc),
            if (d.experienceName.isNotEmpty) _chip(d.experienceName),
            if (d.degreeName.isNotEmpty) _chip(d.degreeName),
          ],
        ),
        const Divider(height: 32),

        // Boss
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  d.bossAvatar.isNotEmpty ? NetworkImage(d.bossAvatar) : null,
              child: d.bossAvatar.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.bossName}  ·  ${d.bossTitle}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    [d.brandName, ...d.bossLabels].where((s) => s.isNotEmpty).join('  ·  '),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 32),

        // 职位描述
        const Text('职位描述',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(d.jobDesc,
            style: const TextStyle(height: 1.6, fontSize: 14)),
        const Divider(height: 32),

        // 工作地址
        if (d.address.isNotEmpty) ...[
          const Text('工作地址',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(child: Text(d.address)),
          ]),
          const Divider(height: 32),
        ],

        // 公司
        const Text('公司信息',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            if (d.brandLogo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(d.brandLogo,
                    width: 44, height: 44, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.business, size: 44)),
              )
            else
              const Icon(Icons.business, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.brandName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(d.brandDesc,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  if (d.comName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(d.comName,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _chip(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(s, style: const TextStyle(fontSize: 13)),
      );
}
