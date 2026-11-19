import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../warehouses/providers/warehouse_provider.dart';
import '../models/stocktake_model.dart';
import '../providers/stocktake_provider.dart';
import 'stocktake_history_screen.dart';

/// شاشة إجراء جرد مخزني وتسوية الأرصدة (New Stocktake Screen)
class NewStocktakeScreen extends StatefulWidget {
  final int? preselectedWarehouseId;

  const NewStocktakeScreen({super.key, this.preselectedWarehouseId});

  @override
  State<NewStocktakeScreen> createState() => _NewStocktakeScreenState();
}

class _NewStocktakeScreenState extends State<NewStocktakeScreen> {
  final _formKey = GlobalKey<FormState>();

  String _stocktakeCode = '';
  int? _selectedWarehouseId;
  final int _itemId = 1;

  final _actualQuantityController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isInitializing = true;
  int _currentSystemStock = 0;
  int? _enteredActualQuantity;

  @override
  void initState() {
    super.initState();
    _initData();
    _actualQuantityController.addListener(_onQuantityChanged);
  }

  Future<void> _initData() async {
    final stocktakeProvider = context.read<StocktakeProvider>();
    final whProvider = context.read<WarehouseProvider>();

    final code = await stocktakeProvider.getNextStocktakeCode();

    if (mounted) {
      setState(() {
        _stocktakeCode = code;
        if (widget.preselectedWarehouseId != null) {
          _selectedWarehouseId = widget.preselectedWarehouseId;
        } else if (whProvider.warehousesWithStock.isNotEmpty) {
          _selectedWarehouseId =
              whProvider.warehousesWithStock.first.warehouseId;
        }
        _updateSystemStock();
        _isInitializing = false;
      });
    }
  }

  void _updateSystemStock() {
    final whProvider = context.read<WarehouseProvider>();
    if (_selectedWarehouseId != null &&
        whProvider.warehousesWithStock.isNotEmpty) {
      final wh = whProvider.warehousesWithStock.firstWhere(
        (w) => w.warehouseId == _selectedWarehouseId,
        orElse: () => whProvider.warehousesWithStock.first,
      );
      _currentSystemStock = wh.quantity;
    } else {
      _currentSystemStock = 0;
    }
  }

  void _onQuantityChanged() {
    final text = _actualQuantityController.text.trim();
    setState(() {
      if (text.isEmpty) {
        _enteredActualQuantity = null;
      } else {
        _enteredActualQuantity = int.tryParse(text);
      }
    });
  }

  @override
  void dispose() {
    _actualQuantityController.removeListener(_onQuantityChanged);
    _actualQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _difference {
    if (_enteredActualQuantity == null) return null;
    return _enteredActualQuantity! - _currentSystemStock;
  }

  Future<void> _handleConfirmAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المستودع المراد جرده'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final actualQuantity = _enteredActualQuantity!;
    final difference = actualQuantity - _currentSystemStock;
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    final whProvider = context.read<WarehouseProvider>();
    final stocktakeProvider = context.read<StocktakeProvider>();
    final selectedWh = whProvider.warehousesWithStock.firstWhere(
      (w) => w.warehouseId == _selectedWarehouseId,
    );

    // حوار التأكيد قبل الاعتماد
    String diffDescription;
    if (difference == 0) {
      diffDescription = 'مطابق تماماً للرصيد الدفتري (0 كرتون)';
    } else if (difference < 0) {
      diffDescription = 'عجز بمقدار ${difference.abs()} كرتون';
    } else {
      diffDescription = 'فائض / زيادة بمقدار +$difference كرتون';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.fact_check_rounded, color: AppColors.stocktakePurple),
            SizedBox(width: 8),
            Text(
              'تأكيد اعتماد نتيجة الجرد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المستودع: ${selectedWh.warehouseName} (${selectedWh.warehouseCode})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('الرصيد الدفتري الحالي: $_currentSystemStock كرتون'),
            Text(
              'الرصيد الفعلي الجديد: $actualQuantity كرتون',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.stocktakePurple,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: difference == 0
                    ? AppColors.receiptGreenLight
                    : (difference < 0
                          ? AppColors.damageRedLight
                          : AppColors.issueBlueLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'النتيجة: $diffDescription',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: difference == 0
                      ? AppColors.receiptGreen
                      : (difference < 0
                            ? AppColors.damageRed
                            : AppColors.issueBlue),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'سيتم تعديل رصيد المخزن في النظام ليصبح فورياً مساوياً للرصيد الفعلي، وتوثيق الجلسة في الأرشيف.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stocktakePurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، اعتمد التسوية'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final stocktake = StocktakeModel(
      code: _stocktakeCode,
      warehouseId: _selectedWarehouseId!,
      itemId: _itemId,
      systemQuantity: _currentSystemStock,
      actualQuantity: actualQuantity,
      difference: difference,
      notes: notes,
      warehouseName: selectedWh.warehouseName,
      warehouseCode: selectedWh.warehouseCode,
      itemName: AppConstants.defaultItemName,
      itemUnit: AppConstants.defaultItemUnit,
      createdAt: DateTime.now(),
    );

    final success = await stocktakeProvider.submitStocktakeReconciliation(
      stocktake: stocktake,
      warehouseProvider: whProvider,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم اعتماد نتيجة الجرد وتسوية رصيد المستودع بنجاح ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // الانتقال لسجل الجرد
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StocktakeHistoryScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stocktakeProvider.errorMessage ?? 'حدث خطأ أثناء اعتماد الجرد',
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
    final stocktakeProvider = context.watch<StocktakeProvider>();

    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('جلسة جرد وتسوية مخزنية'),
        backgroundColor: AppColors.stocktakePurple,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            children: [
              // بطاقة الرأسية: كود الجرد والتاريخ
              _buildHeaderCard(),
              const SizedBox(height: 18),

              // بطاقة الصنف الثابت
              _buildItemInfoCard(),
              const SizedBox(height: 18),

              // اختيار المستودع
              _buildWarehouseDropdown(whProvider),
              const SizedBox(height: 16),

              // بطاقة الرصيد الدفتري المسجل
              _buildSystemStockCard(),
              const SizedBox(height: 20),

              // إدخال الرصيد الفعلي
              _buildActualQuantityInput(),
              const SizedBox(height: 16),

              // بطاقة احتساب الفارق اللحظي والمطابقة
              _buildDifferenceSummaryCard(),
              const SizedBox(height: 18),

              // حقل الملاحظات وسبب الفارق
              _buildNotesInput(),
              const SizedBox(height: 28),

              // زر الاعتماد النهائي
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: stocktakeProvider.isLoading
                      ? null
                      : _handleConfirmAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.stocktakePurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  icon: stocktakeProvider.isLoading
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
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    stocktakeProvider.isLoading
                        ? 'جارٍ الاعتماد والتسوية...'
                        : 'اعتماد الجرد وتسوية الرصيد',
                    style: const TextStyle(
                      fontSize: 16,
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

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'رقم جلسة الجرد (تلقائي)',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.stocktakePurpleLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _stocktakeCode,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.stocktakePurple,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'تاريخ اليوم',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.stocktakePurple,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDate(DateTime.now()),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight.withAlpha(100)),
      ),
      child: const Row(
        children: [
          Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الصنف المجرود: ${AppConstants.defaultItemName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'المواصفة: ${AppConstants.defaultItemSpecification} | الوحدة: ${AppConstants.defaultItemUnit}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseDropdown(WarehouseProvider whProvider) {
    if (whProvider.warehousesWithStock.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.damageRedLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'لا توجد مستودعات مسجلة في النظام لإجراء الجرد.',
          style: TextStyle(color: AppColors.damageRed, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المستودع المراد جرده *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedWarehouseId,
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down_circle_outlined,
                color: AppColors.stocktakePurple,
              ),
              items: whProvider.warehousesWithStock.map((wh) {
                return DropdownMenuItem<int>(
                  value: wh.warehouseId,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${wh.warehouseName} (${wh.warehouseCode})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${wh.quantity} كرتون',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newId) {
                if (newId != null) {
                  setState(() {
                    _selectedWarehouseId = newId;
                    _updateSystemStock();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStockCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.stocktakePurpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.stocktakePurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الرصيد الدفتري المسجل بالنظام حالياً',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormatter.formatNumber(_currentSystemStock)} كرتون',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.stocktakePurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActualQuantityInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الرصيد الفعلي بعد العد اليدوي (كرتون) *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _actualQuantityController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'أدخل الكمية الفعلية المحصورة (مثلاً: 250)',
            prefixIcon: const Icon(
              Icons.pin_outlined,
              color: AppColors.stocktakePurple,
            ),
            suffixText: 'كرتون',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال الكمية الفعلية المحصورة';
            }
            final parsed = int.tryParse(value.trim());
            if (parsed == null) {
              return 'يرجى إدخال رقم صحيح صالح';
            }
            if (parsed < 0) {
              return 'لا يمكن أن تكون الكمية الفعلية سالبة';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDifferenceSummaryCard() {
    if (_difference == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1.2),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'أدخل الكمية الفعلية المحصورة بالأعلى لاحتساب الفارق ومطابقة الرصيد.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final diff = _difference!;
    Color cardBgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String description;

    if (diff == 0) {
      cardBgColor = AppColors.receiptGreenLight;
      borderColor = AppColors.receiptGreen.withAlpha(120);
      textColor = AppColors.receiptGreen;
      icon = Icons.check_circle_rounded;
      title = 'الرصيد مطابق تماماً ✅';
      description =
          'الكمية الفعلية تطابق تماماً الرصيد الدفتري المسجل ($_currentSystemStock كرتون). لا يوجد عجز أو فائض.';
    } else if (diff < 0) {
      cardBgColor = AppColors.damageRedLight;
      borderColor = AppColors.damageRed.withAlpha(120);
      textColor = AppColors.damageRed;
      icon = Icons.warning_rounded;
      title = 'عجز في المخزن بمقدار: ${diff.abs()} كرتون ⚠️';
      description =
          'الكمية الفعلية أقل من المسجل دفترياً. سيتم تسجيل عجز مقداره ${diff.abs()} كرتون وتعديل الرصيد ليصبح $_enteredActualQuantity كرتون.';
    } else {
      cardBgColor = AppColors.issueBlueLight;
      borderColor = AppColors.issueBlue.withAlpha(120);
      textColor = AppColors.issueBlue;
      icon = Icons.add_circle_outline_rounded;
      title = 'فائض / زيادة غير مسجلة بمقدار: +$diff كرتون ℹ️';
      description =
          'الكمية الفعلية أكثر من المسجل دفترياً. سيتم إضافة الفائض وتعديل الرصيد ليصبح $_enteredActualQuantity كرتون.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withAlpha(220),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput() {
    final hasDiff = _difference != null && _difference != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              hasDiff
                  ? 'سبب وتبرير الفارق (إلزامي في حال وجود عجز أو زيادة) *'
                  : 'ملاحظات الجرد (اختياري)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: hasDiff ? AppColors.damageRed : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: hasDiff
                ? 'وضح سبب الفارق (مثل: تلف أثناء المناولة، خطأ تسجيل سابق، إلخ...)'
                : 'أدخل أي ملاحظات إضافية حول جلسة الجرد...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (hasDiff) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى كتابة سبب وتبرير الفارق لتوثيق الجلسة';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
