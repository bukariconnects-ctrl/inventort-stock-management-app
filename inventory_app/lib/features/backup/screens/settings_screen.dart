import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/backup_service.dart';
import '../../reports/providers/reports_provider.dart';
import '../../stocktake/providers/stocktake_provider.dart';
import '../../warehouses/providers/warehouse_provider.dart';

/// شاشة الإعدادات والنسخ الاحتياطي ومعلومات النظام (SettingsScreen)
class SettingsScreen extends StatefulWidget {
  final BackupService? backupService;
  final DatabaseHelper? dbHelper;

  const SettingsScreen({super.key, this.backupService, this.dbHelper});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final BackupService _backupService;
  late final DatabaseHelper _dbHelper;

  bool _isCreatingBackup = false;
  bool _isRestoring = false;

  String _lastBackupFormatted = 'لم يتم إنشاء نسخة بعد';
  int _totalTransactions = 0;
  int _totalWarehouses = 0;
  String _databasePath = '';

  @override
  void initState() {
    super.initState();
    _backupService = widget.backupService ?? BackupService();
    _dbHelper = widget.dbHelper ?? DatabaseHelper();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    try {
      final lastBackup = await _backupService.getLastBackupTimeFormatted();
      final totalTx = await _dbHelper.getTotalTransactionsCount();
      final totalWh = await _dbHelper.getTotalWarehousesCount();
      final dbPath = await _backupService.getDatabasePath();

      if (mounted) {
        setState(() {
          _lastBackupFormatted = lastBackup;
          _totalTransactions = totalTx;
          _totalWarehouses = totalWh;
          _databasePath = dbPath;
        });
      }
    } catch (_) {
      // تجاهل أخطاء جلب معلومات النظام
    }
  }

  /// إنشاء نسخة احتياطية ومشاركتها
  Future<void> _handleCreateBackup() async {
    setState(() => _isCreatingBackup = true);

    try {
      final result = await _backupService.createBackup(share: true);

      if (!mounted) return;

      if (result.success) {
        final lastTimeStr = await _backupService.getLastBackupTimeFormatted();
        if (!mounted) return;
        setState(() {
          _lastBackupFormatted = lastTimeStr;
          _isCreatingBackup = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.file != null
                        ? 'تم إنشاء النسخة ومشاركتها بنجاح: ${result.file!.uri.pathSegments.last}'
                        : result.message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        setState(() => _isCreatingBackup = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingBackup = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('حدث خطأ أثناء النسخ الاحتياطي: $e'),
          ),
        );
      }
    }
  }

  /// استعادة البيانات من نسخة سابقة مع تنبيه تأكيدي مسبق
  Future<void> _handleRestoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.damageRedLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تأكيد استعادة البيانات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'تحذير: استعادة نسخة سابقة ستستبدل كافة البيانات الحالية، هل تود المتابعة؟',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('متابعة واستعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);

    try {
      final result = await _backupService.restoreBackup();

      if (!mounted) return;

      if (result.success) {
        // تحديث جميع مزودي الحالة فوراً لمطابقة البيانات المستعادة
        context.read<WarehouseProvider>().loadWarehousesWithStock();

        final reportsProvider = Provider.of<ReportsProvider?>(
          context,
          listen: false,
        );
        reportsProvider?.loadTransactions();

        final stocktakeProvider = Provider.of<StocktakeProvider?>(
          context,
          listen: false,
        );
        stocktakeProvider?.loadStocktakeHistory();

        await _loadSystemInfo();

        if (mounted) {
          setState(() => _isRestoring = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تمت استعادة قاعدة البيانات بنجاح وتحديث كافة الشاشات!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else if (result.isCancelled) {
        setState(() => _isRestoring = false);
      } else {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('حدث خطأ أثناء استعادة البيانات: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إعدادات النظام والنسخ الاحتياطي'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSystemInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // البطاقة 1: إدارة البيانات والنسخ الاحتياطي
              _buildBackupCard(theme),
              const SizedBox(height: 16),

              // البطاقة 2: معلومات المنشأة والمصنع
              _buildFacilityCard(theme),
              const SizedBox(height: 16),

              // البطاقة 3: معلومات النظام والتطبيق
              _buildSystemInfoCard(theme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// البطاقة 1: إدارة البيانات والنسخ الاحتياطي
  Widget _buildBackupCard(ThemeData theme) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_sync_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة البيانات والنسخ الاحتياطي',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تأمين ومشاركة أرشيف قاعدة البيانات محلياً',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // تفاصيل آخر نسخة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider, width: 0.6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'آخر نسخة احتياطية:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastBackupFormatted,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // زر إنشاء نسخة احتياطية ومشاركتها
            ElevatedButton.icon(
              key: const Key('create_backup_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _isCreatingBackup || _isRestoring
                  ? null
                  : _handleCreateBackup,
              icon: _isCreatingBackup
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share_rounded, size: 20),
              label: Text(
                _isCreatingBackup
                    ? 'جارٍ تجهيز ومشاركة النسخة...'
                    : 'إنشاء نسخة احتياطية ومشاركتها الآن',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // زر استعادة البيانات من نسخة سابقة
            OutlinedButton.icon(
              key: const Key('restore_backup_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isCreatingBackup || _isRestoring
                  ? null
                  : _handleRestoreBackup,
              icon: _isRestoring
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(Icons.restore_page_rounded, size: 20),
              label: Text(
                _isRestoring
                    ? 'جارٍ استعادة البيانات...'
                    : 'استعادة البيانات من نسخة سابقة',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// البطاقة 2: معلومات المنشأة والمصنع
  Widget _buildFacilityCard(ThemeData theme) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.accentCyan,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات المنشأة والمصنع',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'البيانات الرسمية لمصنع مياه رواء',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            _buildInfoRow(
              icon: Icons.business_rounded,
              title: 'اسم المصنع',
              value: 'مصنع مياه رواء للمياه النقية المعبأة',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.inventory_2_rounded,
              title: 'مواصفات المنتج الأساسية',
              value: 'كرتون مياه رواء (20 عبوة × 75 مل)',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.wifi_off_rounded,
              title: 'نمط العمل التشغيلي',
              value:
                  'نظام مستقل بالكامل دون اتصال بالإنترنت (Offline-First SQLite)',
            ),
          ],
        ),
      ),
    );
  }

  /// البطاقة 3: معلومات النظام والتطبيق
  Widget _buildSystemInfoCard(ThemeData theme) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blueGrey,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات النظام والتطبيق',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'بيانات الإصدار ومحرك قاعدة البيانات',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            _buildInfoRow(
              icon: Icons.verified_rounded,
              title: 'إصدار التطبيق',
              value: 'v1.0.0 (Production Ready)',
              highlight: true,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.storage_rounded,
              title: 'حالة قاعدة البيانات',
              value: 'SQLite متصلة وجاهزة للعمل محلياً',
            ),
            if (_databasePath.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.folder_rounded,
                title: 'مسار ملف البيانات',
                value: _databasePath,
                isSmall: true,
              ),
            ],
            const Divider(height: 24),

            // إحصائيات سريعة
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'إجمالي السندات',
                    value: '$_totalTransactions سند',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.warehouse_rounded,
                    title: 'المخازن المفعلة',
                    value: '$_totalWarehouses مخازن',
                    color: AppColors.accentCyan,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool highlight = false,
    bool isSmall = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: highlight ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: highlight ? AppColors.success : AppColors.textPrimary,
              fontFamily: isSmall ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
