import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../account/account_list_page.dart';
import '../data/account_store.dart';
import '../data/boss_provider.dart';
import 'online_resume_page.dart';
import 'resume_page.dart';

/// 个人主页 tab:展示牛人基本资料(头像/姓名/年龄/家乡/学历经历/求职期望)。
class ProfileController extends GetxController {
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
      final g = await b.queryGeekBaseInfo();
      geek.value = g;
      // 回填当前账号的昵称/头像,供多账号列表展示。
      AccountStore.instance.updateProfile(BossProvider.instance.activeUser,
          name: g.name, avatar: g.avatar);
    } catch (e) {
      error.value = '$e';
    } finally {
      loading.value = false;
    }
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.onLogout});

  final VoidCallback? onLogout;

  static const _teal = Color(0xFF12B7A0);
  static const _bg = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProfileController());
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: c.load,
          ),
          if (onLogout != null)
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
        if (c.error.value.isNotEmpty && c.geek.value == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('加载失败: ${c.error.value}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: c.load, child: const Text('重试')),
              ],
            ),
          );
        }
        final g = c.geek.value;
        if (g == null) return const SizedBox.shrink();
        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _header(g),
              const SizedBox(height: 12),
              _accountEntry(context),
              const SizedBox(height: 12),
              _resumeEntries(context),
              const SizedBox(height: 12),
              _infoSection(g),
              const SizedBox(height: 12),
              _expectSection(g),
            ],
          ),
        );
      }),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  Widget _header(GeekInfo g) {
    final sub = [g.ageDesc, g.applyStatus, g.hometown]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return _card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFCED4DA),
            backgroundImage:
                g.avatar.isNotEmpty ? NetworkImage(g.avatar) : null,
            child: g.avatar.isEmpty
                ? const Icon(Icons.person, size: 34, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name.isEmpty ? '牛人' : g.name,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(sub,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
                const SizedBox(height: 4),
                Text('UID ${g.userId}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 多账号入口:显示当前手机号,点击进账号列表切换/管理。
  Widget _accountEntry(BuildContext context) {
    final cur = BossProvider.instance.activeUser;
    return _card(
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AccountListPage())),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.switch_account_outlined, color: _teal),
              const SizedBox(width: 12),
              const Text('多账号',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const Spacer(),
              Text(cur ?? '默认账号',
                  style: const TextStyle(fontSize: 13, color: Colors.black38)),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  // 简历入口:在线简历 / 附件简历 两个并行项。
  Widget _resumeEntries(BuildContext context) => _card(
        child: Column(
          children: [
            _resumeRow(context, Icons.article_outlined, '在线简历', '结构化内容',
                () => const OnlineResumePage()),
            const Divider(height: 20),
            _resumeRow(context, Icons.picture_as_pdf_outlined, '附件简历', 'PDF 预览',
                () => const AttachmentResumePage()),
          ],
        ),
      );

  Widget _resumeRow(BuildContext context, IconData icon, String title,
          String hint, Widget Function() page) =>
      InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => page())),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: _teal),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const Spacer(),
              Text(hint,
                  style: const TextStyle(fontSize: 13, color: Colors.black38)),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      );

  Widget _infoSection(GeekInfo g) {
    final rows = <(String, String)>[
      ('求职状态', g.applyStatus),
      ('家乡', g.hometown),
      ('教育/经历', g.workEduDesc),
    ].where((r) => r.$2.isNotEmpty).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('基本信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final r in rows) _kv(r.$1, r.$2),
        ],
      ),
    );
  }

  Widget _expectSection(GeekInfo g) {
    final e = g.expect;
    if (e == null) return const SizedBox.shrink();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('求职期望',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.work_outline, size: 18, color: _teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [e.positionName, e.cityName]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 76,
                child: Text(k,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black45))),
            Expanded(
                child: Text(v,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black87))),
          ],
        ),
      );
}
