import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../warehouses/providers/warehouse_provider.dart';
import '../models/stocktake_model.dart';

/// موفر الحالة لإدارة جلسات الجرد والتسويات المخزنية (StocktakeProvider)
class StocktakeProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;

  StocktakeProvider({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  bool _isLoading = false;
  String? _errorMessage;
  List<StocktakeModel> _stocktakeHistory = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<StocktakeModel> get stocktakeHistory => _stocktakeHistory;

  /// تعيين بيانات مسبقة لأغراض الاختبارات السريعة (Widget Testing)
  @visibleForTesting
  void setHistoryForTesting(List<StocktakeModel> items) {
    _stocktakeHistory = items;
    _isLoading = false;
    notifyListeners();
  }

  /// جلب سجلات الجرد السابقة من جدول stocktakes مرتبة من الأحدث إلى الأقدم
  Future<void> loadStocktakeHistory({int? warehouseId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stocktakeHistory = await _dbHelper.getStocktakes(
        warehouseId: warehouseId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تحميل سجل الجرد والتسويات: $e';
      notifyListeners();
    }
  }

  /// اعتماد جلسة الجرد وتسوية رصيد المخزن ذرياً في SQLite
  Future<bool> submitStocktakeReconciliation({
    required StocktakeModel stocktake,
    required WarehouseProvider warehouseProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dbHelper.executeStocktakeReconciliation(stocktake);

      // إعادة تحميل سجل الجرد وتحديث أرصدة المخازن فورياً
      await loadStocktakeHistory();
      await warehouseProvider.loadWarehousesWithStock();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في اعتماد تسوية الجرد: $e';
      notifyListeners();
      return false;
    }
  }

  /// الحصول على كود الجرد التسلسلي التالي (مثل: STK-202611-0001)
  Future<String> getNextStocktakeCode() async {
    try {
      return await _dbHelper.generateNextVoucherNumber('stocktake');
    } catch (_) {
      final now = DateTime.now();
      final ym = '${now.year}${now.month.toString().padLeft(2, '0')}';
      return 'STK-$ym-0001';
    }
  }

  /// تفريغ رسالة الخطأ
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
