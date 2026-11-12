import 'package:flutter/foundation.dart';
import '../../../core/database/database_exceptions.dart';
import '../../../core/database/database_helper.dart';
import '../../warehouses/providers/warehouse_provider.dart';
import '../models/stock_transaction_model.dart';

/// موفر الحالة لإدارة سندات وحركات المخزون (استلام، صرف، إتلاف)
class TransactionProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;

  TransactionProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  bool _isLoading = false;
  String? _errorMessage;
  StockTransactionModel? _lastSubmittedTransaction;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StockTransactionModel? get lastSubmittedTransaction =>
      _lastSubmittedTransaction;

  /// الحصول على رقم السند التسلسلي التالي تلقائياً
  Future<String> getNextVoucherNumber(String type) async {
    try {
      return await _dbHelper.generateNextVoucherNumber(type);
    } catch (_) {
      final now = DateTime.now();
      final ym = '${now.year}${now.month.toString().padLeft(2, '0')}';
      final prefix = type == 'receipt'
          ? 'REC'
          : type == 'issue'
              ? 'ISS'
              : 'DAM';
      return '$prefix-$ym-0001';
    }
  }

  /// 1. تنفيذ وحفظ سند استلام إنتاج من المصنع
  Future<StockTransactionModel?> submitReceipt({
    required StockTransactionModel transaction,
    required WarehouseProvider warehouseProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final txId = await _dbHelper.insertReceiptTransaction(transaction);
      final submittedTx = transaction.copyWith(id: txId);
      _lastSubmittedTransaction = submittedTx;

      // تحديث أرصدة المخازن والـ Dashboard فورياً
      await warehouseProvider.loadWarehousesWithStock();

      _isLoading = false;
      notifyListeners();
      return submittedTx;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في حفظ سند الاستلام: $e';
      notifyListeners();
      return null;
    }
  }

  /// 2. تنفيذ وحفظ سند صرف لموزع مع التحقق من الرصيد
  Future<StockTransactionModel?> submitIssue({
    required StockTransactionModel transaction,
    required WarehouseProvider warehouseProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final txId = await _dbHelper.insertIssueTransaction(transaction);
      final submittedTx = transaction.copyWith(id: txId);
      _lastSubmittedTransaction = submittedTx;

      // تحديث أرصدة المخازن والـ Dashboard فورياً
      await warehouseProvider.loadWarehousesWithStock();

      _isLoading = false;
      notifyListeners();
      return submittedTx;
    } on InsufficientStockException catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في إتمام سند الصرف: $e';
      notifyListeners();
      return null;
    }
  }

  /// 3. تنفيذ وحفظ سند إتلاف وهدر مخزني
  Future<StockTransactionModel?> submitDamage({
    required StockTransactionModel transaction,
    required WarehouseProvider warehouseProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final txId = await _dbHelper.insertDamageTransaction(transaction);
      final submittedTx = transaction.copyWith(id: txId);
      _lastSubmittedTransaction = submittedTx;

      // تحديث أرصدة المخازن والـ Dashboard فورياً
      await warehouseProvider.loadWarehousesWithStock();

      _isLoading = false;
      notifyListeners();
      return submittedTx;
    } on InsufficientStockException catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تسجيل سند الإتلاف: $e';
      notifyListeners();
      return null;
    }
  }

  /// تفريغ رسالة الخطأ
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

