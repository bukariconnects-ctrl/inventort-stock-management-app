import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../transactions/models/stock_transaction_model.dart';
import '../../transactions/screens/voucher_details_screen.dart';
import '../../warehouses/providers/warehouse_provider.dart';
import '../providers/reports_provider.dart';

/// شاشة سجل الحركات والأرشيف الشامل للسندات المخزنية (Transactions History Screen)
class TransactionsHistoryScreen extends StatefulWidget {
  final String? initialType;

  const TransactionsHistoryScreen({super.key, this.initialType});

  @override
  State<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportsProvider = context.read<ReportsProvider>();
      if (widget.initialType != null) {
        reportsProvider.setTypeFilter(widget.initialType);
      }
      reportsProvider.loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    final warehouseProvider = context.watch<WarehouseProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سجل الحركات والأرشيف المخزني'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث السجل',
            onPressed: () => reportsProvider.loadTransactions(),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // شريط البحث وفلاتر التصفية العلوية
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.8),
                ),
              ),
              child: Column(
                children: [
                  // 1. شريط البحث الفوري
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'ابحث برقم السند، اسم المندوب/المسلّم، أو رقم المرجع...',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                reportsProvider.setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => reportsProvider.setSearchQuery(value),
                  ),
                  const SizedBox(height: 10),

                  // 2. شرائح التصفية السريعة (Filter Chips)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'الكل',
                          isSelected: reportsProvider.selectedType == null,
                          onSelected: () => reportsProvider.setTypeFilter(null),
                          selectedColor: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'توريد واستلام (+)',
                          isSelected: reportsProvider.selectedType == 'receipt',
                          onSelected: () =>
                              reportsProvider.setTypeFilter('receipt'),
                          selectedColor: AppColors.receiptGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'صرف وتوزيع (-)',
                          isSelected: reportsProvider.selectedType == 'issue',
                          onSelected: () =>
                              reportsProvider.setTypeFilter('issue'),
                          selectedColor: AppColors.issueBlue,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'إتلاف وهدر (-)',
                          isSelected: reportsProvider.selectedType == 'damage',
                          onSelected: () =>
                              reportsProvider.setTypeFilter('damage'),
                          selectedColor: AppColors.damageRed,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 3. فلتر المستودع المنسدل
                  Row(
                    children: [
                      const Icon(
                        Icons.warehouse_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'المستودع:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: reportsProvider.selectedWarehouseId,
                            isDense: true,
                            isExpanded: true,
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
                            onChanged: (id) =>
                                reportsProvider.setWarehouseFilter(id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // قائمة السندات والحركات المفلترة
            Expanded(
              child:
                  reportsProvider.isLoading &&
                      reportsProvider.allTransactions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => reportsProvider.loadTransactions(),
                      color: AppColors.primary,
                      child: reportsProvider.filteredTransactions.isEmpty
                          ? _buildEmptyState(reportsProvider)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              itemCount:
                                  reportsProvider.filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final tx =
                                    reportsProvider.filteredTransactions[index];
                                return _buildTransactionCard(context, tx);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color selectedColor,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.divider,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, StockTransactionModel tx) {
    Color typeColor;
    Color typeBgColor;
    String sign;
    IconData typeIcon;
    String typeLabel;

    switch (tx.type) {
      case 'receipt':
        typeColor = AppColors.receiptGreen;
        typeBgColor = AppColors.receiptGreenLight;
        sign = '+';
        typeIcon = Icons.add_business_rounded;
        typeLabel = 'استلام إنتاج (توريد)';
        break;
      case 'issue':
        typeColor = AppColors.issueBlue;
        typeBgColor = AppColors.issueBlueLight;
        sign = '-';
        typeIcon = Icons.local_shipping_rounded;
        typeLabel = 'صرف لموزع / مندوب';
        break;
      case 'damage':
        typeColor = AppColors.damageRed;
        typeBgColor = AppColors.damageRedLight;
        sign = '-';
        typeIcon = Icons.delete_sweep_rounded;
        typeLabel = 'إتلاف وهدر مخزني';
        break;
      default:
        typeColor = AppColors.primary;
        typeBgColor = AppColors.primaryLight.withAlpha(30);
        sign = '';
        typeIcon = Icons.receipt_long_rounded;
        typeLabel = 'حركة مخزنية';
    }

    final formattedDate = DateFormatter.formatDateTime(tx.createdAt);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VoucherDetailsScreen(transaction: tx),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // سطر الرأس: رقم السند وشارة نوع الحركة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: typeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tx.voucherNumber,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: typeBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // سطر البيانات: المستودع والشخص المعني والكمية
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warehouse_rounded,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tx.warehouseName ?? 'مستودع رقم ${tx.warehouseId}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tx.relatedPerson,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (tx.referenceNumber != null &&
                          tx.referenceNumber!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'مرجع: ${tx.referenceNumber}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // شارة الكمية البارزة
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: typeBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: typeColor.withAlpha(60),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sign${DateFormatter.formatNumber(tx.quantity)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: typeColor,
                        ),
                      ),
                      const Text(
                        'كرتون',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),

            // تذييل الكرت: التاريخ وزر الانتقال للتفاصيل
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'عرض التفاصيل وطباعة PDF',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ReportsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد حركات مطابقة لمعايير البحث',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'جرّب تغيير كلمات البحث، أو إزالة فلتر المستودع ونوع السند.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                provider.resetFilters();
              },
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('إعادة تعيين الفلاتر'),
            ),
          ],
        ),
      ),
    );
  }
}
