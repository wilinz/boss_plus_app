import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/account_store.dart';
import '../data/boss_provider.dart';
import '../login/login_controller.dart';

/// 多账号列表:展示已登录过的账号,点击切换,可添加/删除。
///
/// 账号数据来自 [AccountStore](手机号 + 昵称/头像);切换/添加/删除都走
/// [LoginController],它负责重建各页(IM、职位、消息)并刷新登录态。
class AccountListPage extends StatefulWidget {
  const AccountListPage({super.key});

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  static const _teal = Color(0xFF12B7A0);
  final _login = Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    AccountStore.instance.load();
  }

  Future<void> _switch(String? mobile) async {
    if (mobile == BossProvider.instance.activeUser) return;
    await _login.switchAccount(mobile);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _add() async {
    _login.beginAddAccount();
    if (mounted) Navigator.of(context).pop(); // 回到根,显示登录表单
  }

  Future<void> _confirmRemove(Account a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账号'),
        content: Text('删除 ${a.mobile} 的本地会话与设备指纹?下次需重新登录。'),
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
    final wasActive = BossProvider.instance.activeUser == a.mobile;
    await _login.removeAccount(a.mobile);
    // 删的是当前账号 → LoginController 已切换/回登录,关掉本页。
    if (wasActive && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账号切换')),
      body: Obx(() {
        final active = BossProvider.instance.activeUser;
        final list = AccountStore.instance.accounts.toList();
        // 老安装的默认桶(无手机号)若正登录,补一条只读的「默认账号」。
        final showDefault = active == null && _login.loggedIn.value;
        return ListView(
          children: [
            if (showDefault)
              _tile(
                const Account(mobile: '', name: '默认账号'),
                isActive: true,
                removable: false,
              ),
            for (final a in list) _tile(a, isActive: a.mobile == active),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add, color: _teal),
              title: const Text('添加账号'),
              onTap: _add,
            ),
          ],
        );
      }),
    );
  }

  Widget _tile(Account a, {required bool isActive, bool removable = true}) {
    final title = a.name.isNotEmpty ? a.name : (a.mobile.isEmpty ? '默认账号' : a.mobile);
    final sub = a.name.isNotEmpty && a.mobile.isNotEmpty ? a.mobile : null;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFCED4DA),
        backgroundImage: a.avatar.isNotEmpty ? NetworkImage(a.avatar) : null,
        child: a.avatar.isEmpty
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(title),
      subtitle: sub != null ? Text(sub) : null,
      trailing: isActive
          ? const Icon(Icons.check_circle, color: _teal)
          : (removable
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.black38),
                  tooltip: '删除',
                  onPressed: () => _confirmRemove(a),
                )
              : null),
      onTap: isActive ? null : () => _switch(a.mobile.isEmpty ? null : a.mobile),
    );
  }
}
