import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../transactions/models/stock_transaction_model.dart';

/// خيارات الفترات الزمنية المعتمدة للفلترة
enum DateFilterPreset { today, thisWeek, thisMonth, allTime, custom }

/// موفر الحالة لإدارة التقارير، الرقابة وسجل الحركات المخزنية (ReportsProvider)
class ReportsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;

  ReportsProvider({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  bool _isLoading = false;
  String? _errorMessage;

  List<StockTransactionModel> _allTransactions = [];
  List<StockTransactionModel> _filteredTransactions = [];

  // معايير الفلترة
  int? _selectedWarehouseId;
  String? _selectedType; // null = الكل, 'receipt', 'issue', 'damage'
  DateFilterPreset _selectedDatePreset = DateFilterPreset.thisMonth;
  DateTimeRange? _customDateRange;
  String _searchQuery = '';

  // Getters الأساسية
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<StockTransactionModel> get allTransactions => _allTransactions;
  List<StockTransactionModel> get filteredTransactions => _filteredTransactions;

  int? get selectedWarehouseId => _selectedWarehouseId;
  String? get selectedType => _selectedType;
  DateFilterPreset get selectedDatePreset => _selectedDatePreset;
  DateTimeRange? get customDateRange => _customDateRange;
  String get searchQuery => _searchQuery;

  /// تعيين بيانات مسبقة لأغراض الاختبارات السريعة (Widget Testing)
  @visibleForTesting
  void setTransactionsForTesting(List<StockTransactionModel> transactions) {
    _allTransactions = List.from(transactions);
    _applyFiltersInternal();
    _isLoading = false;
    notifyListeners();
  }

  /// جلب كافة السندات والحركات من قاعدة البيانات وتطبيق الفلاتر الحالية
  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allTransactions = await _dbHelper.getTransactions();
      _applyFiltersInternal();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تحميل سجل الحركات المخزنية: $e';
      notifyListeners();
    }
  }

  /// تغيير فلتر المستودع
  void setWarehouseFilter(int? warehouseId) {
    _selectedWarehouseId = warehouseId;
    _applyFiltersInternal();
    notifyListeners();
  }

  /// تغيير فلتر نوع السند (استلام، صرف، إتلاف)
  void setTypeFilter(String? type) {
    _selectedType = type;
    _applyFiltersInternal();
    notifyListeners();
  }

  /// تغيير فلتر الفترة الزمنية
  void setDatePreset(DateFilterPreset preset, [DateTimeRange? customRange]) {
    _selectedDatePreset = preset;
    if (preset == DateFilterPreset.custom && customRange != null) {
      _customDateRange = customRange;
    }
    _applyFiltersInternal();
    notifyListeners();
  }

  /// تعيين نص البحث السريع
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersInternal();
    notifyListeners();
  }

  /// إعادة تعيين كافة الفلاتر للوضع الافتراضي
  void resetFilters() {
    _selectedWarehouseId = null;
    _selectedType = null;
    _selectedDatePreset = DateFilterPreset.thisMonth;
    _customDateRange = null;
    _searchQuery = '';
    _applyFiltersInternal();
    notifyListeners();
  }

  /// تطبيق الفلاتر داخلياً على القائمة المخزنة
  void _applyFiltersInternal() {
    final effectiveRange = _getEffectiveDateRange();
    final query = _searchQuery.trim().toLowerCase();

    _filteredTransactions = _allTransactions.where((tx) {
      // 1. فلتر المستودع
      if (_selectedWarehouseId != null &&
          tx.warehouseId != _selectedWarehouseId) {
        return false;
      }

      // 2. فلتر نوع السند
      if (_selectedType != null &&
          _selectedType!.isNotEmpty &&
          tx.type != _selectedType) {
        return false;
      }

      // 3. فلتر الفترة الزمنية
      if (effectiveRange != null) {
        final txDate = tx.createdAt;
        if (txDate.isBefore(effectiveRange.start) ||
            txDate.isAfter(effectiveRange.end)) {
          return false;
        }
      }

      // 4. فلتر البحث النصي
      if (query.isNotEmpty) {
        final numberMatch = tx.voucherNumber.toLowerCase().contains(query);
        final personMatch = tx.relatedPerson.toLowerCase().contains(query);
        final refMatch =
            tx.referenceNumber?.toLowerCase().contains(query) ?? false;
        final notesMatch = tx.notes?.toLowerCase().contains(query) ?? false;
        final whMatch =
            tx.warehouseName?.toLowerCase().contains(query) ?? false;

        if (!numberMatch &&
            !personMatch &&
            !refMatch &&
            !notesMatch &&
            !whMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// احتساب النطاق الزمني الفعلي بحسب الـ Preset
  DateTimeRange? _getEffectiveDateRange() {
    final now = DateTime.now();
    switch (_selectedDatePreset) {
      case DateFilterPreset.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case DateFilterPreset.thisWeek:
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday % 7));
        return DateTimeRange(
          start: startOfWeek,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case DateFilterPreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1, 0, 0, 0),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case DateFilterPreset.custom:
        if (_customDateRange != null) {
          return DateTimeRange(
            start: DateTime(
              _customDateRange!.start.year,
              _customDateRange!.start.month,
              _customDateRange!.start.day,
              0,
              0,
              0,
            ),
            end: DateTime(
              _customDateRange!.end.year,
              _customDateRange!.end.month,
              _customDateRange!.end.day,
              23,
              59,
              59,
              999,
            ),
          );
        }
        return null;
      case DateFilterPreset.allTime:
        return null;
    }
  }

  /// عنوان الفترة الزمنية الحالية باللغة العربية
  String get currentPeriodTitle {
    final now = DateTime.now();
    switch (_selectedDatePreset) {
      case DateFilterPreset.today:
        return 'اليوم (${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')})';
      case DateFilterPreset.thisWeek:
        return 'خلال الأسبوع الحالي';
      case DateFilterPreset.thisMonth:
        return 'خلال شهر ${now.month} / ${now.year}';
      case DateFilterPreset.allTime:
        return 'كافة الأوقات التاريخية';
      case DateFilterPreset.custom:
        if (_customDateRange != null) {
          final s = _customDateRange!.start;
          final e = _customDateRange!.end;
          return 'الفترة: ${s.year}/${s.month}/${s.day} إلى ${e.year}/${e.month}/${e.day}';
        }
        return 'فترة مخصصة';
    }
  }

  // =================== Getters الإحصائيات التجميعية ===================

  /// إجمالي الكراتين المستلمة توريداً في الفترة المحددة
  int get totalReceived {
    return _filteredTransactions
        .where((t) => t.type == 'receipt')
        .fold<int>(0, (sum, t) => sum + t.quantity);
  }

  /// إجمالي الكراتين المنصرفة للمناديب في الفترة المحددة
  int get totalIssued {
    return _filteredTransactions
        .where((t) => t.type == 'issue')
        .fold<int>(0, (sum, t) => sum + t.quantity);
  }

  /// إجمالي الكراتين التالفة والهالكة في الفترة المحددة
  int get totalDamaged {
    return _filteredTransactions
        .where((t) => t.type == 'damage')
        .fold<int>(0, (sum, t) => sum + t.quantity);
  }

  /// صافي الحركة المخزنية (الوارد - المنصرف - التالف)
  int get netMovement => totalReceived - totalIssued - totalDamaged;

  /// إجمالي العلب بالكرتون (الكرتون = 20 قنينة)
  int get totalBottlesReceived => totalReceived * 20;
  int get totalBottlesIssued => totalIssued * 20;
  int get totalBottlesDamaged => totalDamaged * 20;

  /// ملخص مسحوبات المناديب والموزعين (اسم المندوب -> إجمالي الكراتين)
  Map<String, int> get driverSummary {
    final summary = <String, int>{};
    for (final tx in _filteredTransactions) {
      if (tx.type == 'issue' && tx.relatedPerson.isNotEmpty) {
        summary[tx.relatedPerson] =
            (summary[tx.relatedPerson] ?? 0) + tx.quantity;
      }
    }
    // ترتيب المناديب بحسب الأكثر استلاماً
    final sortedEntries = summary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  // =================== إحصائيات اليوم اللحظية للوحة التحكم ===================

  /// وارد اليوم من كافة المستودعات
  int get todayReceived {
    final now = DateTime.now();
    return _allTransactions
        .where((t) => t.type == 'receipt' && _isSameDay(t.createdAt, now))
        .fold<int>(0, (sum, t) => sum + t.quantity);
  }

  /// منصرف اليوم للمناديب
  int get todayIssued {
    final now = DateTime.now();
    return _allTransactions
        .where((t) => t.type == 'issue' && _isSameDay(t.createdAt, now))
        .fold<int>(0, (sum, t) => sum + t.quantity);
  }

  /// تالف اليوم
  int get todayDamaged {
    final now = DateTime.now();
    return _allTransactions
        .where((t) => t.type == 'damage' && _isSameDay(t.createdAt, now))
        .fold<int>(0, (sum, t) => sum + t.quantity);
  }

  /// آخر N حركات مخزنية حديثة
  List<StockTransactionModel> recentTransactions([int count = 5]) {
    if (_allTransactions.isEmpty) return [];
    return _allTransactions.take(count).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
