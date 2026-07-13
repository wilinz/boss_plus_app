import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_size/window_size.dart';

import 'data/device_profile_repo.dart';
import 'login/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupDesktopWindow();
  await DeviceProfileRepo.instance.load(); // 内嵌真实设备库,供指纹随机派生用
  runApp(const BossPlusApp());
}

/// 桌面端初始窗口:手机版竖排布局,给一个竖屏尺寸并居中。
Future<void> _setupDesktopWindow() async {
  if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    return;
  }
  setWindowTitle('BOSS Plus');
  const size = Size(440, 900);
  setWindowMinSize(const Size(360, 640));
  final info = await getWindowInfo();
  final screen = info.screen;
  if (screen != null) {
    final f = screen.visibleFrame;
    final left = f.left + (f.width - size.width) / 2;
    final top = f.top + (f.height - size.height) / 2;
    setWindowFrame(Rect.fromLTWH(left, top, size.width, size.height));
  } else {
    setWindowFrame(Rect.fromLTWH(100, 100, size.width, size.height));
  }
}

class BossPlusApp extends StatelessWidget {
  const BossPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BOSS Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00BEBD)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
