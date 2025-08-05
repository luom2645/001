import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/admin_auth_service.dart';
import 'core/security/admin_security.dart';
import 'ui/themes/admin_theme.dart';
import 'ui/screens/admin_splash_screen.dart';
import 'ui/screens/admin_login_screen.dart';
import 'ui/screens/main_admin_screen.dart';
import 'utils/admin_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化窗口管理器
  await windowManager.ensureInitialized();
  
  // 配置管理员桌面窗口
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 900),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    title: 'NovelForge Sentinel Pro - 管理员控制台',
    minimumSize: Size(1200, 800),
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  // 初始化Supabase
  await Supabase.initialize(
    url: AdminConstants.supabaseUrl,
    anonKey: AdminConstants.supabaseAnonKey,
  );
  
  // 初始化管理员安全模块
  await AdminSecurity.initialize();
  
  runApp(
    const ProviderScope(
      child: NovelForgeAdminApp(),
    ),
  );
}

class NovelForgeAdminApp extends ConsumerWidget {
  const NovelForgeAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'NovelForge Sentinel Pro - 管理员控制台',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.darkTheme,
      home: const AdminSplashScreen(),
      routes: {
        '/login': (context) => const AdminLoginScreen(),
        '/dashboard': (context) => const MainAdminScreen(),
      },
    );
  }
}