import 'package:flutter/material.dart';

/// 应用主题管理 - 甜美可爱风
class AppTheme {
  // ===== 主色调：樱花粉系 =====
  static const Color primaryColor = Color(0xFFFF7EB3);      // 樱花粉 主色
  static const Color primaryDark = Color(0xFFFF5C8A);       // 深粉色
  static const Color primaryLight = Color(0xFFFFB5C2);      // 浅粉色
  static const Color secondaryColor = Color(0xFFA78BFA);    // 薰衣草紫
  static const Color accentColor = Color(0xFF67E8F9);       // 天蓝点缀
  static const Color accentWarm = Color(0xFFFFD54F);        // 暖黄点缀

  // ===== 背景色 =====
  static const Color bgLight = Color(0xFFFFF5F5);           // 暖奶油白
  static const Color bgCard = Color(0xFFFFFFFF);             // 纯白卡片
  static const Color bgDark = Color(0xFF1A1A2E);             // 深色模式背景
  static const Color bgCardDark = Color(0xFF242438);         // 深色模式卡片

  // ===== 文字颜色 =====
  static const Color textPrimary = Color(0xFF3D2C3A);       // 深棕紫
  static const Color textSecondary = Color(0xFF8E7F8A);     // 灰紫
  static const Color textLight = Color(0xFFC4B5BD);         // 浅紫灰

  // ===== 渐变 =====
  static const List<Color> gradientPrimary = [
    Color(0xFFFF7EB3),
    Color(0xFFFF5C8A),
  ];
  static const List<Color> gradientHeader = [
    Color(0xFFFF7EB3),
    Color(0xFFA78BFA),
  ];

  // ===== 8 套可爱预设主题 =====
  static const List<AlbumTheme> albumThemes = [
    AlbumTheme(
      name: '🌸 樱花粉',
      bgColor: Color(0xFFFFF0F3),
      accentColor: Color(0xFFFF7EB3),
      textColor: Color(0xFF5C3D4A),
    ),
    AlbumTheme(
      name: '🍃 薄荷绿',
      bgColor: Color(0xFFF0FFF4),
      accentColor: Color(0xFF38B2AC),
      textColor: Color(0xFF234E52),
    ),
    AlbumTheme(
      name: '🌼 奶油黄',
      bgColor: Color(0xFFFFFBF0),
      accentColor: Color(0xFFF6AD55),
      textColor: Color(0xFF744210),
    ),
    AlbumTheme(
      name: '💜 薰衣草',
      bgColor: Color(0xFFF5F0FF),
      accentColor: Color(0xFFA78BFA),
      textColor: Color(0xFF44337A),
    ),
    AlbumTheme(
      name: '🩵 天空蓝',
      bgColor: Color(0xFFF0F9FF),
      accentColor: Color(0xFF67E8F9),
      textColor: Color(0xFF2A4365),
    ),
    AlbumTheme(
      name: '🍑 蜜桃橘',
      bgColor: Color(0xFFFFF5F0),
      accentColor: Color(0xFFFF9A76),
      textColor: Color(0xFF7B4A3A),
    ),
    AlbumTheme(
      name: '🌿 抹茶绿',
      bgColor: Color(0xFFF8FFF0),
      accentColor: Color(0xFF9CCC65),
      textColor: Color(0xFF4A5D23),
    ),
    AlbumTheme(
      name: '☁️ 云朵白',
      bgColor: Color(0xFFFFFFFF),
      accentColor: Color(0xFFCBD5E1),
      textColor: Color(0xFF334155),
    ),
  ];

  /// Material 主题
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: bgLight,

        // ===== AppBar =====
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: textPrimary,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),

        // ===== BottomNav =====
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: bgCard,
          selectedItemColor: primaryColor,
          unselectedItemColor: textLight,
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
          elevation: 8,
        ),

        // ===== 按钮 =====
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: primaryColor.withAlpha(60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),

        // ===== 卡片 =====
        cardTheme: CardThemeData(
          elevation: 0,
          color: bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),

        // ===== 输入框 =====
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFF0F3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFD1DC), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),

        // ===== Dialog =====
        dialogTheme: DialogThemeData(
          backgroundColor: bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),

        // ===== Chip =====
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFFFF0F3),
          selectedColor: primaryColor,
          labelStyle: const TextStyle(fontSize: 13, color: textPrimary),
          secondaryLabelStyle: const TextStyle(fontSize: 13, color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),

        // ===== SnackBar =====
        snackBarTheme: SnackBarThemeData(
          backgroundColor: textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // ===== BottomSheet =====
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      );

  /// Material 暗色主题 - 用于 iOS 暗色模式
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: bgDark,

        // ===== AppBar =====
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFE8E0EC),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE8E0EC),
            letterSpacing: 0.5,
          ),
        ),

        // ===== BottomNav =====
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Color(0xFF242438),
          selectedItemColor: primaryColor,
          unselectedItemColor: Color(0xFF8E8E9A),
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
          elevation: 8,
        ),

        // ===== 按钮 =====
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),

        // ===== 卡片 =====
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF242438),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),

        // ===== 输入框 =====
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A3E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D3D55), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),

        // ===== Dialog =====
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF242438),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE8E0EC),
          ),
        ),

        // ===== Chip =====
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2A2A3E),
          selectedColor: primaryColor,
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFFE8E0EC)),
          secondaryLabelStyle: const TextStyle(fontSize: 13, color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),

        // ===== SnackBar =====
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFFE8E0EC),
          contentTextStyle: const TextStyle(color: Color(0xFF1A1A2E)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // ===== BottomSheet =====
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF242438),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      );
}
class AlbumTheme {
  final String name;
  final Color bgColor;
  final Color accentColor;
  final Color textColor;

  const AlbumTheme({
    required this.name,
    required this.bgColor,
    required this.accentColor,
    required this.textColor,
  });
}
