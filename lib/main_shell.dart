import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat/contact_list_page.dart';
import 'chat/im_service.dart';
import 'home/home_page.dart';
import 'profile/profile_page.dart';

/// 登录后的主壳:底部导航切换「职位」「消息」两个 tab。
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // 登录后注册全局唯一 IM 连接(所有会话共享,避免多连接互踢)。
    if (!Get.isRegistered<ImService>()) {
      Get.put(ImService(), permanent: true);
    }
    // 关键:登录后**立即预连接** MQTT(像官方一样常驻在线),不要等打开会话才懒连接。
    // 否则「立即沟通」发起打招呼时连接还没就绪,服务器 ~200ms 内推回来的开场白 type=1
    // 会被错过(那时我们还没连上/订阅),导致会话页空白。抓包实测:官方开场白/职位卡片
    // 全靠 type=1 实时推送,连接必须提前备好。
    ImService.to.ensureConnected().catchError((_) {
      // 预连接失败不阻塞 UI;打开会话时会再重试。
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onLogout: widget.onLogout),
          Scaffold(
            appBar: AppBar(
              title: const Text('消息'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: () {
                    if (Get.isRegistered<ContactListController>()) {
                      Get.find<ContactListController>().load();
                    }
                  },
                ),
              ],
            ),
            body: const ContactListPage(),
          ),
          ProfilePage(onLogout: widget.onLogout),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work),
              label: '职位'),
          NavigationDestination(
              icon: _MsgIcon(Icons.chat_bubble_outline),
              selectedIcon: _MsgIcon(Icons.chat_bubble),
              label: '消息'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '我的'),
        ],
      ),
    );
  }
}

/// 消息 tab 图标 + 未读红点(总数取全局 [ImService.unreadTotal])。
class _MsgIcon extends StatelessWidget {
  const _MsgIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ImService>()) return Icon(icon);
    return Obx(() {
      final n = ImService.to.unreadTotal.value;
      return Badge(
        isLabelVisible: n > 0,
        label: Text(n > 99 ? '99+' : '$n'),
        child: Icon(icon),
      );
    });
  }
}
