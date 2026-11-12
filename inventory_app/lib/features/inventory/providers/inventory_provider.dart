import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../models/item_model.dart';
import '../models/warehouse_stock_model.dart';

/// موفر الحالة لإدارة بيانات الصنف المخزني والأرصدة (Inventory Provider)
class InventoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;

  InventoryProvider({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  bool _isLoading = false;
  String? _errorMessage;
  ItemModel? _defaultItem;
  List<WarehouseStockModel> _inventoryStocks = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ItemModel? get defaultItem => _defaultItem;
  List<WarehouseStockModel> get inventoryStocks => _inventoryStocks;

  /// إجمالي رصيد الكراتين
  int get totalCartons {
    return _inventoryStocks.fold(0, (sum, stock) => sum + stock.quantity);
  }

  /// إجمالي عدد القناني/العلب بناءً على عدد العلب في الكرتون
  int get totalBottles {
    final bottlesPerBox = _defaultItem?.bottlesPerPackage ?? 20;
    return totalCartons * bottlesPerBox;
  }

  /// تحميل بيانات الصنف والأرصدة في كافة المخازن
  Future<void> loadInventory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _defaultItem = await _dbHelper.getDefaultItem();
      _inventoryStocks = await _dbHelper.getAllWarehousesWithStock();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تحميل بيانات المخزون: $e';
      notifyListeners();
    }
  }

  /// جلب رصيد مخزن معين لحظياً
  Future<int> getStockForWarehouse(int warehouseId) async {
    if (_defaultItem == null || _defaultItem!.id == null) return 0;
    try {
      return await _dbHelper.getWarehouseStockQuantity(
        warehouseId,
        _defaultItem!.id!,
      );
    } catch (_) {
      return 0;
    }
  }
}
