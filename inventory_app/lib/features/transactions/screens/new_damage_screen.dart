import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../warehouses/providers/warehouse_provider.dart';
import '../models/stock_transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'voucher_details_screen.dart';

/// شاشة إنشاء سند إتلاف وهدر مخزني (New Damage Voucher Screen)
class NewDamageScreen extends StatefulWidget {
  final int? preselectedWarehouseId;

  const NewDamageScreen({super.key, this.preselectedWarehouseId});

  @override
  State<NewDamageScreen> createState() => _NewDamageScreenState();
}

class _NewDamageScreenState extends State<NewDamageScreen> {
  final _formKey = GlobalKey<FormState>();

  String _voucherNumber = '';
  int? _selectedWarehouseId;
  final int _itemId = 1;

  final _quantityController = TextEditingController();
  final _relatedPersonController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedDamageReason = 'كسر وتهشم عبوات';
  final List<String> _damageReasons = [
    'كسر وتهشم عبوات',
    'تسريب مياه من الكرتون',
    'عيب تغليف ومصنعي',
    'سوء تخزين ورطوبة',
    'أخرى',
  ];

  bool _isInitializing = true;
  int _currentAvailableStock = 0;
  bool _isExceedingStock = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _quantityController.addListener(_onQuantityChanged);
  }

  Future<void> _initData() async {
    final txProvider = context.read<TransactionProvider>();
    final whProvider = context.read<WarehouseProvider>();

    final voucherNumber = await txProvider.getNextVoucherNumber('damage');

    if (mounted) {
      setState(() {
        _voucherNumber = voucherNumber;
        if (widget.preselectedWarehouseId != null) {
          _selectedWarehouseId = widget.preselectedWarehouseId;
        } else if (whProvider.warehousesWithStock.isNotEmpty) {
          _selectedWarehouseId =
              whProvider.warehousesWithStock.first.warehouseId;
        }
        _updateAvailableStock();
        _isInitializing = false;
      });
    }
  }

  void _updateAvailableStock() {
    final whProvider = context.read<WarehouseProvider>();
    if (_selectedWarehouseId != null) {
      final wh = whProvider.warehousesWithStock.firstWhere(
        (w) => w.warehouseId == _selectedWarehouseId,
        orElse: () => whProvider.warehousesWithStock.first,
      );
      _currentAvailableStock = wh.quantity;
    } else {
      _currentAvailableStock = 0;
    }
    _checkExceedingStock();
  }

  void _onQuantityChanged() {
    setState(() {
      _checkExceedingStock();
    });
  }

  void _checkExceedingStock() {
    final text = _quantityController.text.trim();
    if (text.isEmpty) {
      _isExceedingStock = false;
      return;
    }
    final entered = int.tryParse(text) ?? 0;
    _isExceedingStock = entered > _currentAvailableStock;
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    _relatedPersonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSubmitDamage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المستودع'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final quantity = int.parse(_quantityController.text.trim());
    if (quantity > _currentAvailableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الكمية التالفة ($quantity كرتون) تتجاوز الرصيد المتوفر بالمخزن ($_currentAvailableStock كرتون)!',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // إظهار رسالة تأكيد تحذيرية قبل الخصم النهائي
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.damageRed,
                  size: 28,
                ),
                SizedBox(width: 8),
                Text(
                  'تأكيد إتلاف واستبعاد المخزون',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            content: Text(
              'هل أنت متأكد من تسجيل إتلاف $quantity كرتون وخصمها نهائياً من رصيد المستودع بسبب ($_selectedDamageReason)؟\n\nهذا الإجراء سيقلص الرصيد المتاح مباشرة.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('تراجع'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.damageRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('نعم، تأكيد الإتلاف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final relatedPerson = _relatedPersonController.text.trim();
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    final whProvider = context.read<WarehouseProvider>();
    final selectedWh = whProvider.warehousesWithStock.firstWhere(
      (w) => w.warehouseId == _selectedWarehouseId,
    );

    final transaction = StockTransactionModel(
      voucherNumber: _voucherNumber,
      type: 'damage',
      warehouseId: _selectedWarehouseId!,
      itemId: _itemId,
      quantity: quantity,
      relatedPerson: relatedPerson,
      damageReason: _selectedDamageReason,
      notes: notes,
      warehouseName: selectedWh.warehouseName,
      warehouseCode: selectedWh.warehouseCode,
      itemName: AppConstants.defaultItemName,
      createdAt: DateTime.now(),
    );

    final txProvider = context.read<TransactionProvider>();
    final result = await txProvider.submitDamage(
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
            txProvider.errorMessage ?? 'حدث خطأ أثناء حفظ سند الإتلاف',
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

    final isButtonEnabled =
        !_isExceedingStock && _currentAvailableStock > 0 && !txProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سند إتلاف وهدر مخزني'),
        backgroundColor: AppColors.damageRed,
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
                    // رقم سند الإتلاف
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.damageRed.withAlpha(80)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.damageRed.withAlpha(20),
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
                                color: AppColors.damageRed,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'رقم سند الإتلاف:',
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
                              color: AppColors.damageRedLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _voucherNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppColors.damageRed,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // حقول البيانات
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
                            'المستودع المعني *',
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
                                  '${wh.warehouseName} (${wh.warehouseCode})',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedWarehouseId = val;
                                _updateAvailableStock();
                              });
                            },
                            validator: (val) =>
                                val == null ? 'يرجى اختيار المستودع' : null,
                          ),
                          const SizedBox(height: 10),

                          // كرت الرصيد المتاح
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _currentAvailableStock > 0
                                  ? AppColors.primaryLight.withAlpha(30)
                                  : AppColors.damageRedLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _currentAvailableStock > 0
                                    ? AppColors.primaryLight
                                    : AppColors.damageRed.withAlpha(90),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _currentAvailableStock > 0
                                          ? Icons.inventory_rounded
                                          : Icons.warning_amber_rounded,
                                      size: 18,
                                      color: _currentAvailableStock > 0
                                          ? AppColors.primary
                                          : AppColors.damageRed,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'الرصيد المتاح حالياً في هذا المخزن:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${DateFormatter.formatNumber(_currentAvailableStock)} كرتون',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _currentAvailableStock > 0
                                        ? AppColors.primaryDark
                                        : AppColors.damageRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. الكمية التالفة
                          const Text(
                            'الكمية التالفة (بالكرتون) *',
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
                            decoration: InputDecoration(
                              hintText: 'أدخل عدد الكراتين التالفة، مثال: 10',
                              prefixIcon:
                                  const Icon(Icons.format_list_numbered_rounded),
                              suffixText: 'كرتون',
                              errorText: _isExceedingStock
                                  ? 'الكمية التالفة تتجاوز الرصيد المتوفر بالمخزن!'
                                  : null,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال الكمية التالفة';
                              }
                              final parsed = int.tryParse(value.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'يرجى إدخال عدد صحيح أكبر من الصفر';
                              }
                              if (parsed > _currentAvailableStock) {
                                return 'الكمية تتجاوز الرصيد المتوفر ($_currentAvailableStock كرتون)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 3. سبب الإتلاف الرئيسي
                          const Text(
                            'سبب الإتلاف الرئيسي *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedDamageReason,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.report_problem_rounded),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: _damageReasons.map((reason) {
                              return DropdownMenuItem<String>(
                                value: reason,
                                child: Text(reason, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDamageReason = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // 4. اسم أمين المخزن أو المسؤول الموثق
                          const Text(
                            'اسم أمين المخزن أو المسؤول الموثِّق *',
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
                              hintText: 'مثال: أمين المخزن - فهد',
                              prefixIcon: Icon(Icons.badge_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال اسم المسؤول الموثّق للتلف';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 5. تفاصيل وملاحظات إضافية
                          const Text(
                            'تفاصيل وملاحظات إضافية (اختياري)',
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
                              hintText: 'تفاصيل الحادثة أو تقرير الفحص الداخلي',
                              prefixIcon: Icon(Icons.note_alt_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // زر اعتماد الإتلاف
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isButtonEnabled ? _confirmAndSubmitDamage : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.damageRed,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.divider,
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
                            : const Icon(Icons.delete_sweep_rounded),
                        label: Text(
                          txProvider.isLoading
                              ? 'جارٍ قيد الإتلاف وخصم الرصيد...'
                              : 'اعتماد سند الإتلاف وخصم الكمية',
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

