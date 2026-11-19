import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../warehouses/providers/warehouse_provider.dart';
import '../models/stock_transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'voucher_details_screen.dart';

/// شاشة إنشاء سند استلام إنتاج من المصنع (New Receipt Screen)
class NewReceiptScreen extends StatefulWidget {
  final int? preselectedWarehouseId;

  const NewReceiptScreen({super.key, this.preselectedWarehouseId});

  @override
  State<NewReceiptScreen> createState() => _NewReceiptScreenState();
}

class _NewReceiptScreenState extends State<NewReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  String _voucherNumber = '';
  int? _selectedWarehouseId;
  final int _itemId = 1; // الصنف الأساسي الافتراضي

  final _quantityController = TextEditingController();
  final _relatedPersonController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final txProvider = context.read<TransactionProvider>();
    final whProvider = context.read<WarehouseProvider>();

    final voucherNumber = await txProvider.getNextVoucherNumber('receipt');

    if (mounted) {
      setState(() {
        _voucherNumber = voucherNumber;
        if (widget.preselectedWarehouseId != null) {
          _selectedWarehouseId = widget.preselectedWarehouseId;
        } else if (whProvider.warehousesWithStock.isNotEmpty) {
          _selectedWarehouseId =
              whProvider.warehousesWithStock.first.warehouseId;
        }
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _relatedPersonController.dispose();
    _referenceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReceipt() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المستودع المستلم'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final quantity = int.parse(_quantityController.text.trim());
    final relatedPerson = _relatedPersonController.text.trim();
    final referenceNumber = _referenceNumberController.text.trim().isNotEmpty
        ? _referenceNumberController.text.trim()
        : null;
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    final whProvider = context.read<WarehouseProvider>();
    final selectedWh = whProvider.warehousesWithStock.firstWhere(
      (w) => w.warehouseId == _selectedWarehouseId,
    );

    final transaction = StockTransactionModel(
      voucherNumber: _voucherNumber,
      type: 'receipt',
      warehouseId: _selectedWarehouseId!,
      itemId: _itemId,
      quantity: quantity,
      relatedPerson: relatedPerson,
      referenceNumber: referenceNumber,
      notes: notes,
      warehouseName: selectedWh.warehouseName,
      warehouseCode: selectedWh.warehouseCode,
      itemName: AppConstants.defaultItemName,
      createdAt: DateTime.now(),
    );

    final txProvider = context.read<TransactionProvider>();
    final result = await txProvider.submitReceipt(
      transaction: transaction,
      warehouseProvider: whProvider,
    );

    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VoucherDetailsScreen(transaction: result),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            txProvider.errorMessage ?? 'حدث خطأ أثناء حفظ السند',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final whProvider = context.watch<WarehouseProvider>();
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سند استلام إنتاج من المصنع'),
        backgroundColor: AppColors.receiptGreen,
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // رقم السند التسلسلي كـ Badge علوي
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.receiptGreen.withAlpha(80),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.receiptGreen.withAlpha(20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                color: AppColors.receiptGreen,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'رقم السند التلقائي:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.receiptGreenLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _voucherNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppColors.receiptGreen,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // بطاقة حقول البيانات
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. اختيار المستودع
                          const Text(
                            'المستودع المستلم *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            value: _selectedWarehouseId,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.warehouse_rounded),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: whProvider.warehousesWithStock.map((wh) {
                              return DropdownMenuItem<int>(
                                value: wh.warehouseId,
                                child: Text(
                                  '${wh.warehouseName} (${wh.warehouseCode}) - الرصيد: ${wh.quantity} كرتون',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedWarehouseId = val;
                              });
                            },
                            validator: (val) =>
                                val == null ? 'يرجى اختيار المستودع' : null,
                          ),
                          const SizedBox(height: 16),

                          // 2. الصنف الثابت
                          const Text(
                            'الصنف المخزني',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            initialValue: AppConstants.defaultItemName,
                            readOnly: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.background,
                              prefixIcon: const Icon(Icons.inventory_2_rounded),
                              suffixText: '20 قنينة × 75 مل',
                              suffixStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. الكمية المستلمة بالكرتون
                          const Text(
                            'الكمية المستلمة (بالكرتون) *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'أدخل عدد الكراتين الواردة، مثال: 500',
                              prefixIcon: Icon(
                                Icons.format_list_numbered_rounded,
                              ),
                              suffixText: 'كرتون',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال الكمية المستلمة';
                              }
                              final parsed = int.tryParse(value.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'يرجى إدخال عدد صحيح أكبر من الصفر';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 4. اسم المسلّم من المصنع
                          const Text(
                            'اسم المُسَلِّم من المصنع / السائق *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _relatedPersonController,
                            decoration: const InputDecoration(
                              hintText: 'مثال: م. أحمد - خط الإنتاج الأول',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال اسم المسلّم من المصنع';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 5. رقم إرسالية المصنع / رقم الوجبة
                          const Text(
                            'رقم الشحنة / الوجبة (اختياري)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _referenceNumberController,
                            decoration: const InputDecoration(
                              hintText: 'مثال: BATCH-20261113-A',
                              prefixIcon: Icon(Icons.receipt_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 6. ملاحظات إضافية
                          const Text(
                            'ملاحظات إضافية (اختياري)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText:
                                  'أي تفاصيل عن جودة التغليف أو حالة الدفعة',
                              prefixIcon: Icon(Icons.note_alt_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // زر حفظ السند
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: txProvider.isLoading ? null : _submitReceipt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.receiptGreen,
                          foregroundColor: Colors.white,
                        ),
                        icon: txProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(
                          txProvider.isLoading
                              ? 'جارٍ حفظ السند وزيادة الرصيد...'
                              : 'اعتماد وحفظ سند الاستلام',
                          style: const TextStyle(
                            fontSize: 16,
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
}
