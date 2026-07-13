import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/boss_provider.dart';
import '../main_shell.dart';
import 'device_config_page.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(LoginController());
    return Obx(() {
      // 已登录 → 直接进首页(个人信息 + 职位列表)。按当前账号 key,切换账号时
      // 换 key 触发 MainShell 重建(重连该账号的 IM、重拉各页数据)。
      if (c.loggedIn.value) {
        return MainShell(
          key: ValueKey(c.activeAccount.value ?? '__default__'),
          onLogout: c.logout,
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('BOSS 直聘 · 登录'),
          actions: [
            IconButton(
              tooltip: '设备指纹',
              icon: const Icon(Icons.smartphone_outlined),
              onPressed: () async {
                // 编辑归属:优先当前输入的手机号,否则上次绑定的号(默认桶)。
                final typed = c.mobile.value.trim();
                final target = typed.isNotEmpty
                    ? typed
                    : BossProvider.instance.activeUser;
                final changed =
                    await Get.to(() => DeviceConfigPage(username: target));
                if (changed == true) c.onDeviceChanged(target);
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: _loginForm(context, c),
        ),
      );
    });
  }

  Widget _loginForm(BuildContext context, LoginController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Text('登录 / 注册',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('首次验证通过即注册 BOSS 直聘账号',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        TextField(
          keyboardType: TextInputType.phone,
          maxLength: 11,
          decoration: const InputDecoration(
            prefixText: '+86  ',
            labelText: '手机号',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          onChanged: (v) => c.mobile.value = v.trim(),
        ),
        const SizedBox(height: 12),
        TextField(
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (v) => c.code.value = v.trim(),
          decoration: InputDecoration(
            labelText: '验证码',
            border: const OutlineInputBorder(),
            counterText: '',
            // 尾部内嵌「获取验证码」按钮,替代外挂的大按钮。
            suffixIcon: Obx(() => TextButton(
                  onPressed:
                      c.busy.value ? null : () => c.requestSms(context),
                  child: Text(c.smsSent.value ? '重新获取' : '获取验证码'),
                )),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
        const SizedBox(height: 20),
        Obx(() => FilledButton(
              onPressed: c.busy.value ? null : c.login,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: c.busy.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('登录'),
            )),
        const SizedBox(height: 16),
        Obx(() => Text(c.message.value,
            style: TextStyle(
                color: c.message.value.contains('成功')
                    ? Colors.green
                    : Colors.redAccent))),
        const Spacer(),
        const Text('登录必弹极验滑块验证码,请手动完成验证。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

}
