import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/select_screen.dart';
import 'screens/layout_screen.dart';
import 'screens/preview_screen.dart';
import 'theme/app_theme.dart';
import 'utils/responsive_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PetAlbumApp(),
    ),
  );
}

class PetAlbumApp extends StatelessWidget {
  const PetAlbumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '排版印相',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0;

  final _screens = const [
    SelectScreen(),
    LayoutScreen(),
    PreviewScreen(),
  ];

  // 底部导航栏样式
  static const _navItems = [
    (icon: Icons.photo_library_rounded, activeIcon: Icons.photo_library_rounded, label: '选片'),
    (icon: Icons.dashboard_customize_rounded, activeIcon: Icons.dashboard_customize_rounded, label: '排版'),
    (icon: Icons.preview_rounded, activeIcon: Icons.preview_rounded, label: '预览'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withAlpha(20),
              blurRadius: context.rw(16),
              offset: Offset(0, -context.rw(4)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(context.rw(20))),
          child: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (index) => setState(() => _currentTab = index),
            backgroundColor: AppTheme.bgCard,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textLight,
            selectedLabelStyle: TextStyle(fontSize: context.rw(12), fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontSize: context.rw(11), fontWeight: FontWeight.w500),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: List.generate(3, (i) {
              final item = _navItems[i];
              final isSelected = _currentTab == i;
              return BottomNavigationBarItem(
                icon: Container(
                  padding: EdgeInsets.all(context.rw(6)),
                  decoration: isSelected
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppTheme.gradientPrimary,
                          ),
                          borderRadius: BorderRadius.circular(context.rw(12)),
                        )
                      : null,
                  child: Icon(
                    item.icon,
                    size: context.rw(24),
                    color: isSelected ? Colors.white : AppTheme.textLight,
                  ),
                ),
                label: item.label,
              );
            }),
          ),
        ),
      ),
    );
  }
}
