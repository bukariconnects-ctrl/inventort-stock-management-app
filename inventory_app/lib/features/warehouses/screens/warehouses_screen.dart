import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../inventory/models/warehouse_stock_model.dart';
import '../models/warehouse_model.dart';
import '../providers/warehouse_provider.dart';

/// شاشة إدارة المخازن والمستودعات
class WarehousesScreen extends StatelessWidget {
  const WarehousesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المستودعات والمخازن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث القائمة',
            onPressed: () {
              context.read<WarehouseProvider>().loadWarehousesWithStock();
            },
          ),
        ],
      ),
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.warehousesWithStock.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.warehousesWithStock.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warehouse_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا يوجد أي مخازن مضافة بعد',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditWarehouseDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة مخزن جديد الآن'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadWarehousesWithStock(),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: provider.warehousesWithStock.length,
              itemBuilder: (context, index) {
                final stock = provider.warehousesWithStock[index];
                return _buildWarehouseManageCard(context, stock);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditWarehouseDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text(
          'إضافة مخزن جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildWarehouseManageCard(
    BuildContext context,
    WarehouseStockModel stock,
  ) {
    final isLow = stock.isLowStock;
    final threshold = stock.minAlertThreshold ?? 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLow ? AppColors.damageRed.withAlpha(90) : AppColors.divider,
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stock.warehouseCode ?? 'WH',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    stock.warehouseName ?? 'مخزن',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // زر التعديل
              IconButton(
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'تعديل بيانات المخزن',
                onPressed: () {
                  final warehouse = WarehouseModel(
                    id: stock.warehouseId,
                    name: stock.warehouseName ?? '',
                    code: stock.warehouseCode ?? '',
                    location: null,
                    minAlertThreshold: threshold,
                  );
                  _showAddEditWarehouseDialog(
                    context,
                    warehouseToEdit: warehouse,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // تفاصيل المخزن
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'الموقع: خطوط الإنتاج والشحن الداخلي',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // الرصيد وحد التنبيه
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'الرصيد المتوفر:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormatter.formatNumber(stock.quantity)} كرتون',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isLow
                          ? AppColors.damageRed
                          : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'حد الأمان الأدنى:',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningAmberLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$threshold كرتون',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningAmber,
                      ),
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

  /// نافذة إضافة / تعديل مخزن
  static void _showAddEditWarehouseDialog(
    BuildContext context, {
    WarehouseModel? warehouseToEdit,
  }) {
    final isEditing = warehouseToEdit != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: warehouseToEdit?.name ?? '',
    );
    final codeController = TextEditingController(
      text: warehouseToEdit?.code ?? '',
    );
    final locationController = TextEditingController(
      text: warehouseToEdit?.location ?? '',
    );
    final thresholdController = TextEditingController(
      text: (warehouseToEdit?.minAlertThreshold ?? 100).toString(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Icon(
                  isEditing
                      ? Icons.edit_note_rounded
                      : Icons.add_business_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'تعديل بيانات المخزن' : 'إضافة مخزن جديد',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // اسم المخزن
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المخزن *',
                          hintText: 'مثال: مخزن التوزيع الغربي',
                          prefixIcon: Icon(Icons.warehouse_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال اسم المخزن';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // كود المخزن
                      TextFormField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'كود المخزن الفريد *',
                          hintText: 'مثال: WH-03',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال كود المخزن';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // الموقع / العنوان
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'الموقع أو الوصف (اختياري)',
                          hintText: 'مثال: منطقة الشحن - بوابة رقم 3',
                          prefixIcon: Icon(Icons.location_on_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // حد التنبيه الأدنى
                      TextFormField(
                        controller: thresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'حد التنبيه الأدنى (كرتون) *',
                          hintText: '100',
                          prefixIcon: Icon(
                            Icons.notification_important_rounded,
                          ),
                          suffixText: 'كرتون',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال حد التنبيه';
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'يرجى إدخال رقم صحيح موجب';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final provider = context.read<WarehouseProvider>();
                    final threshold = int.parse(
                      thresholdController.text.trim(),
                    );

                    bool success = false;
                    if (isEditing) {
                      final updated = warehouseToEdit.copyWith(
                        name: nameController.text.trim(),
                        code: codeController.text.trim().toUpperCase(),
                        location: locationController.text.trim().isNotEmpty
                            ? locationController.text.trim()
                            : null,
                        minAlertThreshold: threshold,
                      );
                      success = await provider.updateWarehouse(updated);
                    } else {
                      final newWh = WarehouseModel(
                        name: nameController.text.trim(),
                        code: codeController.text.trim().toUpperCase(),
                        location: locationController.text.trim().isNotEmpty
                            ? locationController.text.trim()
                            : null,
                        minAlertThreshold: threshold,
                      );
                      success = await provider.addWarehouse(newWh);
                    }

                    if (context.mounted) {
                      Navigator.of(dialogCtx).pop();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'تم تحديث بيانات المخزن بنجاح ✅'
                                  : 'تم إضافة المخزن الجديد بنجاح وتهيئة رصيده ✅',
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: AppColors.receiptGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.errorMessage ?? 'حدث خطأ أثناء الحفظ',
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة المخزن'),
              ),
            ],
          ),
        );
      },
    );
  }
}
