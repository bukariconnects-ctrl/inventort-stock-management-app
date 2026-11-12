import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/stock_transaction_model.dart';

/// شاشة عرض تفاصيل السند المخزني المنفذ (Voucher Details Screen)
class VoucherDetailsScreen extends StatelessWidget {
  final StockTransactionModel transaction;

  const VoucherDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    Color typeBgColor;
    IconData typeIcon;
    String typeTitle;

    switch (transaction.type) {
      case 'receipt':
        typeColor = AppColors.receiptGreen;
        typeBgColor = AppColors.receiptGreenLight;
        typeIcon = Icons.add_business_rounded;
        typeTitle = 'سند استلام إنتاج من المصنع';
        break;
      case 'issue':
        typeColor = AppColors.issueBlue;
        typeBgColor = AppColors.issueBlueLight;
        typeIcon = Icons.local_shipping_rounded;
        typeTitle = 'سند صرف لموزع / مندوب';
        break;
      case 'damage':
        typeColor = AppColors.damageRed;
        typeBgColor = AppColors.damageRedLight;
        typeIcon = Icons.delete_sweep_rounded;
        typeTitle = 'سند إتلاف وهدر مخزني';
        break;
      default:
        typeColor = AppColors.primary;
        typeBgColor = AppColors.primaryLight.withAlpha(40);
        typeIcon = Icons.receipt_long_rounded;
        typeTitle = 'سند حركة مخزنية';
    }

    final formattedDate =
        DateFormatter.formatDateTime(transaction.createdAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(typeTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // بطاقة السند الرسمية
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // شارة ورأس السند
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: typeBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(typeIcon, size: 36, color: typeColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    typeTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      transaction.voucherNumber,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تاريخ القيد: $formattedDate',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 16),

                  // تفاصيل العملية
                  _buildDetailRow(
                    icon: Icons.warehouse_rounded,
                    label: 'المستودع المعني:',
                    value: transaction.warehouseName != null
                        ? '${transaction.warehouseName} (${transaction.warehouseCode ?? ""})'
                        : 'مستودع رقم ${transaction.warehouseId}',
                  ),
                  _buildDetailRow(
                    icon: Icons.inventory_2_rounded,
                    label: 'الصنف المخزني:',
                    value: transaction.itemName ??
                        'كرتون مياه رواء - 20 علبة × 75 مل',
                  ),
                  _buildDetailRow(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'الكمية المسجلة:',
                    value:
                        '${DateFormatter.formatNumber(transaction.quantity)} كرتون',
                    isEmphasized: true,
                    valueColor: typeColor,
                  ),
                  _buildDetailRow(
                    icon: Icons.person_rounded,
                    label: transaction.type == 'receipt'
                        ? 'المسلِّم من المصنع:'
                        : transaction.type == 'issue'
                            ? 'المستلم / الموزع:'
                            : 'المسؤول الموثِّق:',
                    value: transaction.relatedPerson,
                  ),
                  if (transaction.referenceNumber != null &&
                      transaction.referenceNumber!.isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.tag_rounded,
                      label: transaction.type == 'receipt'
                          ? 'رقم الشحنة / الوجبة:'
                          : 'رقم أمر الصرف:',
                      value: transaction.referenceNumber!,
                    ),
                  if (transaction.damageReason != null &&
                      transaction.damageReason!.isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.report_problem_rounded,
                      label: 'سبب الإتلاف:',
                      value: transaction.damageReason!,
                      valueColor: AppColors.damageRed,
                    ),
                  if (transaction.notes != null &&
                      transaction.notes!.isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.notes_rounded,
                      label: 'ملاحظات إضافية:',
                      value: transaction.notes!,
                    ),

                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 16),

                  // شارة الحالة
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.receiptGreenLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.receiptGreen,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'معتمد ومسجل محلياً في قاعدة البيانات ✅',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.receiptGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // زر معاينة وطباعة الـ PDF
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'سيتم تفعيل تصدير وطباعة سندات الـ PDF ومشاركتها في المرحلة 6 بإذن الله.',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
                icon: const Icon(Icons.print_rounded),
                label: const Text(
                  'معاينة وطباعة السند كملف PDF',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // زر العودة للرئيسية
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.home_rounded, color: AppColors.primary),
                label: const Text(
                  'العودة إلى لوحة التحكم',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isEmphasized = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: isEmphasized ? 16 : 13,
                fontWeight: isEmphasized ? FontWeight.w900 : FontWeight.bold,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

