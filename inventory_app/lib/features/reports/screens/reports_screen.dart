import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../warehouses/providers/warehouse_provider.dart';
import '../providers/reports_provider.dart';
import 'transactions_history_screen.dart';

/// شاشة التقارير والرقابة المخزنية الشاملة (Reports Screen)
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isExportingPdf = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadTransactions();
    });
  }

  Future<void> _handleExportPdf(bool isShare) async {
    final reportsProvider = context.read<ReportsProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();

    setState(() => _isExportingPdf = true);

    String? whName;
    if (reportsProvider.selectedWarehouseId != null) {
      final wh = warehouseProvider.warehousesWithStock.firstWhere(
        (w) => w.warehouseId == reportsProvider.selectedWarehouseId,
        orElse: () => warehouseProvider.warehousesWithStock.first,
      );
      whName = '${wh.warehouseName} (${wh.warehouseCode})';
    }

    try {
      if (isShare) {
        await PdfService.shareMovementReport(
          transactions: reportsProvider.filteredTransactions,
          periodTitle: reportsProvider.currentPeriodTitle,
          warehouseName: whName,
          totalReceived: reportsProvider.totalReceived,
          totalIssued: reportsProvider.totalIssued,
          totalDamaged: reportsProvider.totalDamaged,
          netMovement: reportsProvider.netMovement,
          driverSummary: reportsProvider.driverSummary,
        );
      } else {
        await PdfService.printMovementReport(
          transactions: reportsProvider.filteredTransactions,
          periodTitle: reportsProvider.currentPeriodTitle,
          warehouseName: whName,
          totalReceived: reportsProvider.totalReceived,
          totalIssued: reportsProvider.totalIssued,
          totalDamaged: reportsProvider.totalDamaged,
          netMovement: reportsProvider.netMovement,
          driverSummary: reportsProvider.driverSummary,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر تجهيز تقرير الـ PDF: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  void _showExportOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withAlpha(50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'تصدير تقرير الحركة المخزنية (PDF)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.issueBlueLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.print_rounded,
                        color: AppColors.issueBlue,
                      ),
                    ),
                    title: const Text(
                      'معاينة وطباعة التقرير مباشرة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'فتح نافذة المعاينة والطباعة على الطابعة المتصلة أو حفظ PDF',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleExportPdf(false);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: Color(0xFF25D366),
                      ),
                    ),
                    title: const Text(
                      'مشاركة التقرير (واتساب / تطبيقات)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'إرسال ملف الـ PDF فورياً إلى الإدارة أو الحسابات',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleExportPdf(true);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final reportsProvider = context.read<ReportsProvider>();
    final initialRange =
        reportsProvider.customDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      reportsProvider.setDatePreset(DateFilterPreset.custom, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    final warehouseProvider = context.watch<WarehouseProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التقارير والرقابة المخزنية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'سجل الحركات التفصيلي',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TransactionsHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث التقرير',
            onPressed: () => reportsProvider.loadTransactions(),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: () => reportsProvider.loadTransactions(),
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // 1. شريط الفلترة الزمني والمستودع
              _buildFilterSection(context, reportsProvider, warehouseProvider),
              const SizedBox(height: 18),

              // 2. كروت المؤشرات الكبرى (KPIs)
              _buildKpiGrid(reportsProvider),
              const SizedBox(height: 20),

              // 3. بطاقة الانتقال السريع لسجل السندات التفصيلي
              _buildAuditLogNavigationBanner(context, reportsProvider),
              const SizedBox(height: 20),

              // 4. قسم مسحوبات المناديب والموزعين
              _buildDriverBreakdownSection(reportsProvider),
              const SizedBox(height: 24),

              // 5. زر تصدير التقرير PDF العريض
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isExportingPdf
                      ? null
                      : () => _showExportOptionsBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  icon: _isExportingPdf
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(
                    _isExportingPdf
                        ? 'جارٍ تجهيز ملف PDF...'
                        : 'تصدير التقرير كملف PDF (طباعة ومشاركة)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. قسم الفلترة العلوية (الفترة الزمنية والمستودع)
  Widget _buildFilterSection(
    BuildContext context,
    ReportsProvider reportsProvider,
    WarehouseProvider warehouseProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // أزرار الفترات الزمنية السريعة
          const Text(
            'الفترة الزمنية للتقرير:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodPresetChip(
                  label: 'اليوم',
                  preset: DateFilterPreset.today,
                  reportsProvider: reportsProvider,
                ),
                const SizedBox(width: 6),
                _buildPeriodPresetChip(
                  label: 'هذا الأسبوع',
                  preset: DateFilterPreset.thisWeek,
                  reportsProvider: reportsProvider,
                ),
                const SizedBox(width: 6),
                _buildPeriodPresetChip(
                  label: 'هذا الشهر',
                  preset: DateFilterPreset.thisMonth,
                  reportsProvider: reportsProvider,
                ),
                const SizedBox(width: 6),
                _buildPeriodPresetChip(
                  label: 'كل الأوقات',
                  preset: DateFilterPreset.allTime,
                  reportsProvider: reportsProvider,
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color:
                            reportsProvider.selectedDatePreset ==
                                DateFilterPreset.custom
                            ? Colors.white
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'فترة مخصصة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              reportsProvider.selectedDatePreset ==
                                  DateFilterPreset.custom
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor:
                      reportsProvider.selectedDatePreset ==
                          DateFilterPreset.custom
                      ? AppColors.primary
                      : AppColors.background,
                  onPressed: () => _pickCustomDateRange(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // فلتر المستودع
          Row(
            children: [
              const Icon(
                Icons.warehouse_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'المستودع المستهدف:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: reportsProvider.selectedWarehouseId,
                      isExpanded: true,
                      isDense: true,
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.primary,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'كافة المستودعات والمخازن',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        ...warehouseProvider.warehousesWithStock.map(
                          (wh) => DropdownMenuItem<int?>(
                            value: wh.warehouseId,
                            child: Text(
                              '${wh.warehouseName} (${wh.warehouseCode})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (id) => reportsProvider.setWarehouseFilter(id),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // إشعار الفترة الزمنية الحالية
          Text(
            'نطاق العرض: ${reportsProvider.currentPeriodTitle}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodPresetChip({
    required String label,
    required DateFilterPreset preset,
    required ReportsProvider reportsProvider,
  }) {
    final isSelected = reportsProvider.selectedDatePreset == preset;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      onSelected: (_) => reportsProvider.setDatePreset(preset),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  /// 2. شبكة المؤشرات الكبرى (KPIs)
  Widget _buildKpiGrid(ReportsProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            // كرت إجمالي الوارد
            Expanded(
              child: _buildKpiCard(
                title: 'إجمالي الوارد (+)',
                cartons: provider.totalReceived,
                bottles: provider.totalBottlesReceived,
                color: AppColors.receiptGreen,
                bgColor: AppColors.receiptGreenLight,
                icon: Icons.add_business_rounded,
              ),
            ),
            const SizedBox(width: 12),
            // كرت إجمالي المنصرف
            Expanded(
              child: _buildKpiCard(
                title: 'إجمالي المنصرف (-)',
                cartons: provider.totalIssued,
                bottles: provider.totalBottlesIssued,
                color: AppColors.issueBlue,
                bgColor: AppColors.issueBlueLight,
                icon: Icons.local_shipping_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // كرت إجمالي التالف
            Expanded(
              child: _buildKpiCard(
                title: 'إجمالي التالف (-)',
                cartons: provider.totalDamaged,
                bottles: provider.totalBottlesDamaged,
                color: AppColors.damageRed,
                bgColor: AppColors.damageRedLight,
                icon: Icons.delete_sweep_rounded,
              ),
            ),
            const SizedBox(width: 12),
            // كرت صافي التغير
            Expanded(
              child: _buildKpiCard(
                title: 'صافي التغير',
                cartons: provider.netMovement,
                bottles: provider.netMovement * 20,
                color: AppColors.primaryDark,
                bgColor: AppColors.primaryLight.withAlpha(30),
                icon: Icons.stacked_line_chart_rounded,
                isNet: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int cartons,
    required int bottles,
    required Color color,
    required Color bgColor,
    required IconData icon,
    bool isNet = false,
  }) {
    final sign = isNet ? (cartons >= 0 ? '+' : '') : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(10),
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$sign${DateFormatter.formatNumber(cartons)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'كرتون',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${DateFormatter.formatNumber(bottles.abs())} قنينة',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  /// 3. بطاقة الانتقال السريع لسجل السندات التفصيلي
  Widget _buildAuditLogNavigationBanner(
    BuildContext context,
    ReportsProvider provider,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionsHistoryScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سجل الحركات والأرشيف التفصيلي',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'عرض وتصفية ${provider.filteredTransactions.length} حركة مسجلة مع تفاصيل السندات',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  /// 4. قسم مسحوبات المناديب والموزعين
  Widget _buildDriverBreakdownSection(ReportsProvider provider) {
    final summary = provider.driverSummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.local_shipping_rounded,
                  size: 20,
                  color: AppColors.issueBlue,
                ),
                SizedBox(width: 8),
                Text(
                  'مسحوبات المناديب والموزعين',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.issueBlueLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${summary.length} مندوب',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.issueBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (summary.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text(
                'لا توجد عمليات صرف للمناديب مسجلة في الفترة المحددة.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...summary.entries.map((entry) {
            final driverName = entry.key;
            final cartons = entry.value;
            final bottles = cartons * 20;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.issueBlueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: AppColors.issueBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormatter.formatNumber(bottles)} قنينة ماء',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormatter.formatNumber(cartons),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.issueBlue,
                        ),
                      ),
                      const Text(
                        'كرتون منصرف',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
