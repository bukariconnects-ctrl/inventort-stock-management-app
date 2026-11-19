import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../reports/screens/reports_screen.dart';
import '../transactions/screens/operations_screen.dart';
import '../warehouses/screens/warehouses_screen.dart';
import 'screens/dashboard_screen.dart';

/// الشاشة الرئيسية الحاضنة لأشرطة التنقل السفلية (Main Navigation Shell)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        onNavigateToWarehouses: () => _onTabSelected(1),
        onNavigateToOperations: () => _onTabSelected(2),
      ),
      const WarehousesScreen(),
      const OperationsScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryLight.withAlpha(50),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(
                Icons.dashboard_rounded,
                color: AppColors.primary,
              ),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.warehouse_outlined),
              selectedIcon: Icon(
                Icons.warehouse_rounded,
                color: AppColors.primary,
              ),
              label: 'المخازن',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_rounded),
              selectedIcon: Icon(
                Icons.swap_horizontal_circle_rounded,
                color: AppColors.primary,
              ),
              label: 'العمليات',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(
                Icons.assignment_rounded,
                color: AppColors.primary,
              ),
              label: 'التقارير والسجل',
            ),
          ],
        ),
      ),
    );
  }
}
