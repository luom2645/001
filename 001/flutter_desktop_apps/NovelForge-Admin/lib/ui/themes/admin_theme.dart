import 'package:flutter/material.dart';

class AdminTheme {
  // 管理控制台配色方案 - 更加专业和严肃
  static const Color primaryCommand = Color(0xFF00E5FF);      // 指挥蓝
  static const Color secondaryAlert = Color(0xFFFF6B35);      // 警戒橙
  static const Color tertiarySuccess = Color(0xFF00C853);     // 成功绿
  static const Color quaternaryWarning = Color(0xFFFFC107);   // 警告黄
  static const Color dangerCritical = Color(0xFFFF1744);      // 危险红
  
  static const Color darkConsole = Color(0xFF0D1117);        // 控制台背景
  static const Color cardPanel = Color(0xFF161B22);          // 面板背景
  static const Color surfaceLayer = Color(0xFF21262D);       // 表面层
  static const Color borderLine = Color(0xFF30363D);         // 边框颜色
  
  static const Color textPrimary = Color(0xFFF0F6FC);       // 主文本
  static const Color textSecondary = Color(0xFF8B949E);     // 次要文本
  static const Color textMuted = Color(0xFF656D76);         // 弱化文本
  static const Color textDisabled = Color(0xFF484F58);      // 禁用文本

  /// 管理员控制台深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // 颜色方案
      colorScheme: const ColorScheme.dark(
        primary: primaryCommand,
        secondary: secondaryAlert,
        tertiary: tertiarySuccess,
        surface: surfaceLayer,
        background: darkConsole,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onBackground: textPrimary,
        error: dangerCritical,
        onError: Colors.white,
      ),
      
      // 字体配置 - 专业管理界面
      fontFamily: 'Orbitron',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Orbitron',
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontFamily: 'Orbitron',
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryCommand,
          fontFamily: 'Orbitron',
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Orbitron',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Orbitron',
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          fontFamily: 'Orbitron',
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          fontFamily: 'Orbitron',
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: textPrimary,
          fontFamily: 'RobotoMono',
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: textSecondary,
          fontFamily: 'RobotoMono',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textMuted,
          fontFamily: 'RobotoMono',
        ),
      ),
      
      // 卡片主题
      cardTheme: CardTheme(
        color: cardPanel,
        elevation: 2,
        shadowColor: primaryCommand.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderLine,
            width: 1,
          ),
        ),
      ),
      
      // 应用栏主题
      appBarTheme: const AppBarTheme(
        backgroundColor: cardPanel,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryCommand,
          fontFamily: 'Orbitron',
        ),
      ),
      
      // 按钮主题 - 管理员专用样式
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCommand,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // 文本按钮主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryCommand,
          textStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: borderLine,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: primaryCommand.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: primaryCommand,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: dangerCritical,
            width: 1,
          ),
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontFamily: 'Orbitron',
        ),
        hintStyle: const TextStyle(
          color: textMuted,
          fontFamily: 'RobotoMono',
        ),
      ),
      
      // 数据表格主题
      dataTableTheme: DataTableThemeData(
        decoration: BoxDecoration(
          color: cardPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderLine),
        ),
        headingRowColor: MaterialStateColor.resolveWith(
          (states) => surfaceLayer,
        ),
        headingTextStyle: const TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        dataTextStyle: const TextStyle(
          fontFamily: 'RobotoMono',
          color: textSecondary,
        ),
      ),
      
      // 标签页主题
      tabBarTheme: const TabBarTheme(
        labelColor: primaryCommand,
        unselectedLabelColor: textSecondary,
        labelStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.normal,
        ),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: primaryCommand,
              width: 2,
            ),
          ),
        ),
      ),
      
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryCommand;
          }
          return textMuted;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryCommand.withOpacity(0.5);
          }
          return borderLine;
        }),
      ),
      
      // 进度条主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryCommand,
        linearTrackColor: borderLine,
        circularTrackColor: borderLine,
      ),
      
      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: borderLine,
        thickness: 1,
        space: 1,
      ),
      
      // 对话框主题
      dialogTheme: DialogTheme(
        backgroundColor: cardPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primaryCommand.withOpacity(0.3),
            width: 1,
          ),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryCommand,
          fontFamily: 'Orbitron',
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: textPrimary,
          fontFamily: 'RobotoMono',
        ),
      ),
    );
  }
  
  /// 权限等级颜色
  static Color getAdminLevelColor(int level) {
    switch (level) {
      case 1:
        return dangerCritical; // 一级管理员 - 红色
      case 2:
        return quaternaryWarning; // 二级管理员 - 黄色
      case 3:
        return tertiarySuccess; // 普通管理员 - 绿色
      default:
        return textMuted;
    }
  }
  
  /// 状态指示器颜色
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'online':
      case 'success':
        return tertiarySuccess;
      case 'warning':
      case 'pending':
        return quaternaryWarning;
      case 'error':
      case 'danger':
      case 'critical':
        return dangerCritical;
      case 'info':
      case 'primary':
        return primaryCommand;
      default:
        return textMuted;
    }
  }
  
  /// 创建控制台面板装饰
  static BoxDecoration consolePanelDecoration({
    Color borderColor = primaryCommand,
    double borderRadius = 12,
    bool withGlow = true,
  }) {
    return BoxDecoration(
      color: cardPanel,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: withGlow ? [
        BoxShadow(
          color: borderColor.withOpacity(0.1),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ] : null,
    );
  }
  
  /// 创建控制台按钮装饰
  static BoxDecoration consoleButtonDecoration({
    Color color = primaryCommand,
    double borderRadius = 8,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: [
          color.withOpacity(isPressed ? 0.9 : 0.8),
          color.withOpacity(isPressed ? 0.7 : 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: isPressed ? 4 : 8,
          spreadRadius: isPressed ? 0 : 1,
          offset: Offset(0, isPressed ? 1 : 2),
        ),
      ],
    );
  }
  
  /// 创建渐变背景
  static BoxDecoration consoleGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkConsole,
          Color(0xFF0A0E13),
          Color(0xFF161B22),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }
}
