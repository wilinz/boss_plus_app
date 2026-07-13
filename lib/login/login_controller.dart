import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../chat/contact_list_page.dart';
import '../chat/im_service.dart';
import '../data/account_store.dart';
import '../data/boss_provider.dart';
import '../data/device_config_store.dart';
import '../home/home_controller.dart';
import 'geetest_slider_native.dart';

/// 登录页状态机(GetX)。
///
/// 流程:输入手机号 → [requestSms](man/machine → 若需验证则弹极验滑块 → smsCode)
/// → 输入验证码 → [login](codeLogin)。BOSS 登录**必弹极验**,滑块由用户手动完成。
class LoginController extends GetxController {
  final mobile = ''.obs;
  final code = ''.obs;

  final busy = false.obs;
  final smsSent = false.obs;
  final message = ''.obs;
  final loggedIn = false.obs;

  /// 当前绑定的手机号(null/'' = 默认桶);变化时驱动 [MainShell] 换 key 重建。
  final activeAccount = RxnString();

  /// 取(必要时重建)客户端。绑定用户名由 [requestSms]/[login] 在操作时显式完成 ——
  /// 启动 [_restore] 不改绑定,以恢复上次登录的号。
  Future<Boss> _client() => BossProvider.instance.get();

  bool get mobileValid => RegExp(r'^\d{11}$').hasMatch(mobile.value);

  @override
  void onInit() {
    super.onInit();
    // _restore → get() 内部会恢复上次绑定的号并加载其会话,刷新登录态。
    _restore();
  }

  Future<void> _restore() async {
    final b = await _client();
    activeAccount.value = BossProvider.instance.activeUser;
    loggedIn.value = b.loggedIn;
  }

  /// 切换到已注册的账号(手机号)。目标有会话则保持登录并重建各页;否则回登录表单。
  Future<void> switchAccount(String? mobile) async {
    await BossProvider.instance.setActiveUser(mobile);
    _resetPageControllers();
    final b = await _client();
    activeAccount.value = BossProvider.instance.activeUser;
    smsSent.value = false;
    code.value = '';
    message.value = '';
    loggedIn.value = b.loggedIn;
  }

  /// 「添加账号」:回到登录表单输入新号(当前账号会话不受影响,仍在其桶中)。
  void beginAddAccount() {
    _resetPageControllers();
    loggedIn.value = false;
    smsSent.value = false;
    mobile.value = '';
    code.value = '';
    message.value = '';
  }

  /// 删除账号:清其会话/设备指纹桶与注册表。删的是当前账号则切到其它账号或回登录。
  Future<void> removeAccount(String mobile) async {
    await AccountStore.instance.remove(mobile);
    await BossProvider.instance.deleteSession(mobile);
    await DeviceConfigStore.instance.remove(mobile);
    if (BossProvider.instance.activeUser == mobile) {
      final rest = AccountStore.instance.accounts;
      if (rest.isNotEmpty) {
        await switchAccount(rest.first.mobile);
      } else {
        await BossProvider.instance.setActiveUser(null);
        beginAddAccount();
      }
    }
  }

  /// 用户在设备指纹页保存后([username] = 编辑归属的号):绑定并用新指纹重建,刷新登录态。
  Future<void> onDeviceChanged(String? username) async {
    await BossProvider.instance.setActiveUser(username);
    BossProvider.instance.reset(); // 编辑页已 reset,这里再确保拿到最新配置
    smsSent.value = false;
    message.value = '设备指纹已更新';
    await _restore();
  }

  /// 获取验证码:man/machine → 极验滑块(手动)→ smsCode。
  Future<void> requestSms(BuildContext context) async {
    if (!mobileValid) {
      message.value = '请输入 11 位手机号';
      return;
    }
    busy.value = true;
    message.value = '';
    try {
      // 绑定到本手机号的设备指纹 + 会话桶(变化则重建客户端)。
      await BossProvider.instance.setActiveUser(mobile.value);
      final b = await _client();
      final reg = await b.manMachine(mobile: mobile.value);
      GeetestResult? gt;
      if (reg.needVerify) {
        if (reg.gt.isEmpty || reg.challenge.isEmpty) {
          message.value = '极验初始化失败(gt/challenge 为空)';
          return;
        }
        // 弹原生滑块(无 WebView,跨平台含 Windows),用户手动拖动
        if (!context.mounted) return;
        gt = await showGeetestSliderNative(context, reg);
        if (gt == null) {
          message.value = '验证已取消';
          return;
        }
      }
      final resp = await b.sendSmsCode(mobile: mobile.value, geetest: gt);
      final ok = (resp['code'] as num?)?.toInt() == 0;
      if (ok) {
        smsSent.value = true;
        message.value = '验证码已发送';
      } else {
        message.value = '发送失败: ${resp['message'] ?? resp}';
      }
    } catch (e) {
      message.value = '异常: $e';
    } finally {
      busy.value = false;
    }
  }

  /// 验证码登录:codeLogin。
  Future<void> login() async {
    if (code.value.isEmpty) {
      message.value = '请输入验证码';
      return;
    }
    busy.value = true;
    message.value = '';
    try {
      await BossProvider.instance.setActiveUser(mobile.value);
      final b = await _client();
      final r = await b.loginWithSms(mobile: mobile.value, code: code.value);
      if (r.ok && r.hasSession) {
        // 删除可能残留的旧控制器(如启动时用过期会话建过),使 MainShell
        // 重新 Get.put → onInit 重新拉取,避免登录后列表/主页不刷新。
        _resetPageControllers();
        await AccountStore.instance.add(mobile.value); // 登进账号列表
        activeAccount.value = mobile.value;
        loggedIn.value = true;
        message.value = '登录成功';
      } else {
        message.value = '登录失败: code=${r.code} ${r.message}';
      }
    } catch (e) {
      message.value = '异常: $e';
    } finally {
      busy.value = false;
    }
  }

  Future<void> logout() async {
    final b = await _client();
    b.logout();
    _resetPageControllers();
    loggedIn.value = false;
    smsSent.value = false;
    code.value = '';
    message.value = '已退出登录';
  }

  /// 清掉首页/消息页控制器,确保下次进入时重建并重新加载(GetX 会缓存实例,
  /// 不清则复用旧数据、onInit 不再触发)。
  void _resetPageControllers() {
    if (Get.isRegistered<HomeController>()) {
      Get.delete<HomeController>(force: true);
    }
    if (Get.isRegistered<ContactListController>()) {
      Get.delete<ContactListController>(force: true);
    }
    if (Get.isRegistered<ImService>()) {
      Get.delete<ImService>(force: true); // 断开并释放全局 IM 连接
    }
  }
}
