import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../inventory/models/warehouse_stock_model.dart';
import '../../warehouses/providers/warehouse_provider.dart';

/// شاشة لوحة التحكم الرئيسية (Dashboard Screen)
class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToWarehouses;
  final VoidCallback? onNavigateToOperations;

  const DashboardScreen({
    super.key,
    this.onNavigateToWarehouses,
    this.onNavigateToOperations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مياه رواء - إدارة المخازن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث البيانات',
            onPressed: () {
              context.read<WarehouseProvider>().loadWarehousesWithStock();
            },
          ),
        ],
      ),
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.warehousesWithStock.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارٍ قراءة أرصدة المخازن...'),
                ],
              ),
            );
          }

          if (provider.errorMessage != null &&
              provider.warehousesWithStock.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 56,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadWarehousesWithStock(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadWarehousesWithStock(),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // 1. الترويسة والترحيب والتاريخ
                _buildGreetingHeader(context),
                const SizedBox(height: 16),

                // 2. بطاقة إحصائية عريضة (Hero Card) لإجمالي المخزون
                _buildHeroTotalStockCard(context, provider.totalStockCount),
                const SizedBox(height: 16),

                // 3. شريط التنبيه البارز لمخازن الرصيد المنخفض
                if (provider.hasLowStockAlert) ...[
                  _buildAlertBanner(context, provider.lowStockWarehouses),
                  const SizedBox(height: 16),
                ],

                // 4. أزرار الإجراءات السريعة
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // 5. قسم أرصدة المخازن الحالية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'أرصدة المخازن الحالية',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (onNavigateToWarehouses != null)
                      TextButton.icon(
                        onPressed: onNavigateToWarehouses,
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                        ),
                        label: const Text(
                          'إدارة المخازن',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (provider.warehousesWithStock.isEmpty)
                  _buildEmptyWarehousesCard(context)
                else
                  ...provider.warehousesWithStock.map(
                    (stock) => _buildWarehouseStockCard(context, stock),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 1. الترويسة والترحيب
  Widget _buildGreetingHeader(BuildContext context) {
    final todayStr = DateFormatter.formatDate(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً بك يا أمين المخزن 👋',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'تاريخ اليوم: $todayStr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.receiptGreenLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.receiptGreen,
                ),
                SizedBox(width: 4),
                Text(
                  'محلي SQLite',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.receiptGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. البطاقة العريضة (Hero Card)
  Widget _buildHeroTotalStockCard(BuildContext context, int totalCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.accentCyan,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(70),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'إجمالي المخزون الكلي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '20 قنينة × 75 مل',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                DateFormatter.formatNumber(totalCount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'كرتون ماء',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'الصنف الأساسي المعتمد: ${AppConstants.defaultItemName}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. شريط التنبيه البارز لمخازن الرصيد المنخفض
  Widget _buildAlertBanner(
    BuildContext context,
    List<WarehouseStockModel> lowStockList,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.damageRedLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.damageRed.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.damageRed.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.damageRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تنبيه: انخفاض المخزون في بعض المستودعات!',
                      style: TextStyle(
                        color: AppColors.damageRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.damageRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${lowStockList.length} مخزن',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...lowStockList.map(
                  (wh) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• ${wh.warehouseName ?? "مخزن"}: المتبقي ${DateFormatter.formatNumber(wh.quantity)} كرتون (حد الأمان: ${wh.minAlertThreshold ?? 100})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. أزرار الإجراءات السريعة
  Widget _buildQuickActions(BuildContext context) {
    void showPhase4Notice(String actionName) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'سيتم تفعيل واجهة "$actionName" بالكامل في المرحلة 4 القادمة بإذن الله.',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryDark,
          action: SnackBarAction(
            label: 'حسناً',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'العمليات السريعة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // زر استلام جديد
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_business_rounded,
                label: 'سند استلام',
                color: AppColors.receiptGreen,
                bgColor: AppColors.receiptGreenLight,
                onTap: () => showPhase4Notice('سند استلام إنتاج جديد'),
              ),
            ),
            const SizedBox(width: 10),

            // زر صرف جديد
            Expanded(
              child: _buildActionButton(
                icon: Icons.local_shipping_rounded,
                label: 'سند صرف',
                color: AppColors.issueBlue,
                bgColor: AppColors.issueBlueLight,
                onTap: () => showPhase4Notice('سند صرف لموزع'),
              ),
            ),
            const SizedBox(width: 10),

            // زر إتلاف وهدر
            Expanded(
              child: _buildActionButton(
                icon: Icons.delete_sweep_rounded,
                label: 'سند إتلاف',
                color: AppColors.damageRed,
                bgColor: AppColors.damageRedLight,
                onTap: () => showPhase4Notice('سند إتلاف وهدر'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. كرت رصيد المخزن
  Widget _buildWarehouseStockCard(
    BuildContext context,
    WarehouseStockModel stock,
  ) {
    final isLow = stock.isLowStock;
    final threshold = stock.minAlertThreshold ?? 100;
    final progress = threshold > 0
        ? (stock.quantity / threshold).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLow ? AppColors.damageRed.withAlpha(100) : AppColors.divider,
          width: isLow ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isLow
                ? AppColors.damageRed.withAlpha(15)
                : Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stock.warehouseCode ?? 'WH',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stock.warehouseName ?? 'مخزن غير مسمى',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // شارة الحالة
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isLow
                      ? AppColors.damageRedLight
                      : AppColors.receiptGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLow
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_rounded,
                      size: 13,
                      color: isLow
                          ? AppColors.damageRed
                          : AppColors.receiptGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLow ? 'مخزون منخفض' : 'رصيد آمن',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLow
                            ? AppColors.damageRed
                            : AppColors.receiptGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // الرصيد الحالي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الرصيد الفعلي المتوفر:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        DateFormatter.formatNumber(stock.quantity),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isLow
                              ? AppColors.damageRed
                              : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'كرتون',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'حد الأمان الأدنى:',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    '$threshold كرتون',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // شريط النسبة
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLow ? AppColors.damageRed : AppColors.receiptGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWarehousesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.warehouse_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد مخازن مسجلة حالياً',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
