import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
      _buildReportsPlaceholder(),
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

  Widget _buildReportsPlaceholder() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('التقارير وأرشيف الحركات')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 64,
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'أرشيف الحركات والتقارير المخزنية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'جاهز لاستقبال فلاتر البحث، تقارير الوارد والمنصرف، وتصدير مستندات PDF في المراحل القادمة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _onTabSelected(0),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('العودة إلى لوحة التحكم'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
