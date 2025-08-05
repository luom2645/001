import 'package:flutter/material.dart';

class AppTheme {
  // 科幻风格颜色定义
  static const Color primaryNeon = Color(0xFF00FFFF);      // 青色霓虹
  static const Color secondaryNeon = Color(0xFF FF00FF);   // 品红霓虹
  static const Color accentNeon = Color(0xFF00FF41);       // 绿色霓虹
  static const Color warningNeon = Color(0xFFFF8800);      // 橙色霓虹
  static const Color dangerNeon = Color(0xFFFF0040);       // 红色霓虹
  
  static const Color darkBackground = Color(0xFF0A0A0F);   // 深空背景
  static const Color cardBackground = Color(0xFF1A1A2E);   // 卡片背景
  static const Color surfaceColor = Color(0xFF16213E);     // 表面颜色
  static const Color borderColor = Color(0xFF2A2A3E);     // 边框颜色
  
  static const Color textPrimary = Color(0xFFE0E0E0);     // 主文本
  static const Color textSecondary = Color(0xFFB0B0B0);   // 次要文本
  static const Color textMuted = Color(0xFF707070);       // 弱化文本

  /// 深色科幻主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // 颜色方案
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryNeon,
        tertiary: accentNeon,
        surface: surfaceColor,
        background: darkBackground,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onBackground: textPrimary,
        error: dangerNeon,
      ),
      
      // 字体配置
      fontFamily: 'Orbitron',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Orbitron',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Orbitron',
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryNeon,
          fontFamily: 'Orbitron',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          fontFamily: 'Orbitron',
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Orbitron',
        ),
        titleMedium: TextStyle(
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
          fontSize: 12,
          color: textSecondary,
          fontFamily: 'RobotoMono',
        ),
      ),
      
      // 卡片主题
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: primaryNeon.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      
      // 应用栏主题
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryNeon,
          fontFamily: 'Orbitron',
        ),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
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
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: primaryNeon.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: primaryNeon,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: dangerNeon,
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
      
      // 滑块主题
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryNeon,
        inactiveTrackColor: primaryNeon.withOpacity(0.3),
        thumbColor: primaryNeon,
        overlayColor: primaryNeon.withOpacity(0.2),
        valueIndicatorColor: primaryNeon,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.black,
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryNeon;
          }
          return textMuted;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryNeon.withOpacity(0.5);
          }
          return borderColor;
        }),
      ),
      
      // 进度条主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryNeon,
        linearTrackColor: borderColor,
        circularTrackColor: borderColor,
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      
      // 对话框主题
      dialogTheme: DialogTheme(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primaryNeon.withOpacity(0.3),
            width: 1,
          ),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryNeon,
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
  
  /// 创建发光效果装饰
  static BoxDecoration glowDecoration({
    Color color = primaryNeon,
    double borderRadius = 8,
    double blurRadius = 4,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: color.withOpacity(0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: blurRadius,
          spreadRadius: 1,
        ),
      ],
    );
  }
  
  /// 创建按钮发光效果
  static BoxDecoration buttonGlowDecoration({
    Color color = primaryNeon,
    double borderRadius = 8,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.8),
          color.withOpacity(0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    );
  }
  
  /// 创建渐变背景
  static BoxDecoration gradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkBackground,
          Color(0xFF1A1A2E),
          Color(0xFF16213E),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }
}