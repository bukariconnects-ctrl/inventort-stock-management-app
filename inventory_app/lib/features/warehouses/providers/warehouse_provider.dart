import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../inventory/models/warehouse_stock_model.dart';
import '../models/warehouse_model.dart';

/// موفر الحالة لإدارة المستودعات والأرصدة ونظام التنبيهات (WarehouseProvider)
class WarehouseProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;

  WarehouseProvider({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  bool _isLoading = false;
  String? _errorMessage;
  List<WarehouseStockModel> _warehousesWithStock = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<WarehouseStockModel> get warehousesWithStock => _warehousesWithStock;

  /// إجمالي كراتين المياه في جميع المخازن معاً
  int get totalStockCount {
    return _warehousesWithStock.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  /// قائمة المخازن التي وصل رصيدها الحالي إلى أو أقل من حد التنبيه
  List<WarehouseStockModel> get lowStockWarehouses {
    return _warehousesWithStock.where((item) => item.isLowStock).toList();
  }

  /// هل يوجد أي مخزن منخفض الرصيد لإظهار شريط التنبيه؟
  bool get hasLowStockAlert => lowStockWarehouses.isNotEmpty;

  /// تعيين بيانات مسبقة لأغراض الاختبارات السريعة (Widget Testing)
  @visibleForTesting
  void setWarehousesForTesting(List<WarehouseStockModel> items) {
    _warehousesWithStock = items;
    _isLoading = false;
    notifyListeners();
  }

  /// جلب المخازن والأرصدة من قاعدة البيانات وتحديث الواجهة
  Future<void> loadWarehousesWithStock() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _warehousesWithStock = await _dbHelper.getAllWarehousesWithStock();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تحميل بيانات المخازن والأرصدة: $e';
      notifyListeners();
    }
  }

  /// إضافة مخزن جديد مع تهيئة رصيد الصنف الافتراضي له بصفر، ثم إعادة تحميل البيانات
  Future<bool> addWarehouse(WarehouseModel warehouse) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dbHelper.insertWarehouse(warehouse);
      await loadWarehousesWithStock();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في إضافة المخزن: $e';
      notifyListeners();
      return false;
    }
  }

  /// تعديل بيانات المخزن وتحديثه في SQLite
  Future<bool> updateWarehouse(WarehouseModel warehouse) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dbHelper.updateWarehouse(warehouse);
      await loadWarehousesWithStock();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تحديث بيانات المخزن: $e';
      notifyListeners();
      return false;
    }
  }
}
