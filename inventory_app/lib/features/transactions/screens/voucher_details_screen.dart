import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/stock_transaction_model.dart';

/// شاشة عرض تفاصيل السند المخزني المنفذ مع الطباعة والمشاركة (Voucher Details Screen)
class VoucherDetailsScreen extends StatefulWidget {
  final StockTransactionModel transaction;

  const VoucherDetailsScreen({super.key, required this.transaction});

  @override
  State<VoucherDetailsScreen> createState() => _VoucherDetailsScreenState();
}

class _VoucherDetailsScreenState extends State<VoucherDetailsScreen> {
  bool _isPrinting = false;
  bool _isSharing = false;

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      await PdfService.printVoucher(widget.transaction);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح عارض الطباعة: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);
    try {
      await PdfService.shareVoucher(widget.transaction);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر مشاركة السند: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    Color typeBgColor;
    IconData typeIcon;
    String typeTitle;

    switch (widget.transaction.type) {
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

    final formattedDate = DateFormatter.formatDateTime(
      widget.transaction.createdAt,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(typeTitle),
        backgroundColor: typeColor,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'مشاركة السند كـ PDF',
            onPressed: (_isPrinting || _isSharing) ? null : _handleShare,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
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
                        widget.transaction.voucherNumber,
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
                      value: widget.transaction.warehouseName != null
                          ? '${widget.transaction.warehouseName} (${widget.transaction.warehouseCode ?? ""})'
                          : 'مستودع رقم ${widget.transaction.warehouseId}',
                    ),
                    _buildDetailRow(
                      icon: Icons.inventory_2_rounded,
                      label: 'الصنف المخزني:',
                      value:
                          widget.transaction.itemName ??
                          'كرتون مياه رواء - 20 علبة × 75 مل',
                    ),
                    _buildDetailRow(
                      icon: Icons.format_list_numbered_rounded,
                      label: 'الكمية المسجلة:',
                      value:
                          '${DateFormatter.formatNumber(widget.transaction.quantity)} كرتون (${DateFormatter.formatNumber(widget.transaction.quantity * 20)} قنينة)',
                      isEmphasized: true,
                      valueColor: typeColor,
                    ),
                    _buildDetailRow(
                      icon: Icons.person_rounded,
                      label: widget.transaction.type == 'receipt'
                          ? 'المسلِّم من المصنع:'
                          : widget.transaction.type == 'issue'
                          ? 'المستلم / الموزع:'
                          : 'المسؤول الموثِّق:',
                      value: widget.transaction.relatedPerson,
                    ),
                    if (widget.transaction.referenceNumber != null &&
                        widget.transaction.referenceNumber!.isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.tag_rounded,
                        label: widget.transaction.type == 'receipt'
                            ? 'رقم إرسالية المصنع:'
                            : 'رقم أمر الصرف:',
                        value: widget.transaction.referenceNumber!,
                      ),
                    if (widget.transaction.damageReason != null &&
                        widget.transaction.damageReason!.isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.report_problem_rounded,
                        label: 'سبب الإتلاف:',
                        value: widget.transaction.damageReason!,
                        valueColor: AppColors.damageRed,
                      ),
                    if (widget.transaction.notes != null &&
                        widget.transaction.notes!.isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.notes_rounded,
                        label: 'ملاحظات إضافية:',
                        value: widget.transaction.notes!,
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

              // 1. زر معاينة وطباعة الـ PDF
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: (_isPrinting || _isSharing) ? null : _handlePrint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: typeColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isPrinting
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
                      : const Icon(Icons.print_rounded),
                  label: Text(
                    _isPrinting
                        ? 'جارٍ إعداد الطباعة...'
                        : 'معاينة وطباعة السند كملف PDF',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. زر مشاركة السند (واتساب / تطبيقات)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_isPrinting || _isSharing) ? null : _handleShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.share_rounded),
                  label: Text(
                    _isSharing
                        ? 'جارٍ تجهيز المشاركة...'
                        : 'مشاركة السند (واتساب / تطبيقات)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. زر العودة للرئيسية
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
                  icon: const Icon(
                    Icons.home_rounded,
                    color: AppColors.primary,
                  ),
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
