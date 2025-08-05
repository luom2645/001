import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_service.dart';
import 'core/security/device_security.dart';
import 'ui/themes/app_theme.dart';
import 'ui/creation_screens/splash_screen.dart';
import 'ui/creation_screens/auth_screen.dart';
import 'ui/creation_screens/main_creation_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化窗口管理器
  await windowManager.ensureInitialized();
  
  // 配置桌面窗口
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    title: 'NovelForge Client - AI小说创作工具',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  // 初始化Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  // 初始化设备安全
  await DeviceSecurity.initialize();
  
  runApp(
    const ProviderScope(
      child: NovelForgeClientApp(),
    ),
  );
}

class NovelForgeClientApp extends ConsumerWidget {
  const NovelForgeClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'NovelForge Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/main': (context) => const MainCreationScreen(),
      },
    );
  }
}
