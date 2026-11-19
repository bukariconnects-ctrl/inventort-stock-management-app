import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/stocktake_model.dart';
import '../providers/stocktake_provider.dart';
import 'new_stocktake_screen.dart';

/// شاشة أرشيف وسجل جلسات الجرد والتسويات الدورية (Stocktake History Screen)
class StocktakeHistoryScreen extends StatefulWidget {
  const StocktakeHistoryScreen({super.key});

  @override
  State<StocktakeHistoryScreen> createState() => _StocktakeHistoryScreenState();
}

class _StocktakeHistoryScreenState extends State<StocktakeHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StocktakeProvider>().loadStocktakeHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('أرشيف وسجل جلسات الجرد'),
        backgroundColor: AppColors.stocktakePurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث السجل',
            onPressed: () {
              context.read<StocktakeProvider>().loadStocktakeHistory();
            },
          ),
        ],
      ),
      body: Consumer<StocktakeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.stocktakeHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.stocktakeHistory.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.stocktakePurpleLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fact_check_outlined,
                        size: 64,
                        color: AppColors.stocktakePurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'لا توجد جلسات جرد مسجلة بعد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'قم بإجراء جرد دوري لمطابقة الكميات الدفترية مع الواقع الفعلي بالمستودعات وتسجيل الفروقات.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NewStocktakeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.stocktakePurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text(
                        'بدء جرد مخزني جديد',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadStocktakeHistory(),
            color: AppColors.stocktakePurple,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: provider.stocktakeHistory.length,
              itemBuilder: (context, index) {
                final stocktake = provider.stocktakeHistory[index];
                return _buildStocktakeCard(context, stocktake);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NewStocktakeScreen()));
        },
        backgroundColor: AppColors.stocktakePurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text(
          'بدء جرد جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStocktakeCard(BuildContext context, StocktakeModel stocktake) {
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    if (stocktake.isExactMatch) {
      statusColor = AppColors.receiptGreen;
      statusBgColor = AppColors.receiptGreenLight;
      statusText = 'رصيد مطابق تماماً (0 كرتون)';
      statusIcon = Icons.check_circle_rounded;
    } else if (stocktake.hasDeficit) {
      statusColor = AppColors.damageRed;
      statusBgColor = AppColors.damageRedLight;
      statusText =
          'عجز: ${DateFormatter.formatNumber(stocktake.difference)} كرتون';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppColors.issueBlue;
      statusBgColor = AppColors.issueBlueLight;
      statusText =
          'فائض: +${DateFormatter.formatNumber(stocktake.difference)} كرتون';
      statusIcon = Icons.add_circle_outline_rounded;
    }

    final formattedDate = DateFormatter.formatDateTime(stocktake.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
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
          // رأس الكرت: كود الجرد والتاريخ
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
                      color: AppColors.stocktakePurpleLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stocktake.code,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.stocktakePurple,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stocktake.warehouseName ??
                        'مستودع رقم ${stocktake.warehouseId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // شارة الفارق
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // تفاصيل الكميات: دفتري vs فعلي
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الرصيد الدفتري المسجل:',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormatter.formatNumber(stocktake.systemQuantity)} كرتون',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppColors.divider),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الرصيد الفعلي المعتمد:',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormatter.formatNumber(stocktake.actualQuantity)} كرتون',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ملاحظات أو سبب الفارق
          if (stocktake.notes != null && stocktake.notes!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.comment_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'سبب التسوية: ${stocktake.notes!}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // تذييل الكرت: تاريخ الجرد وأزرار تصدير وطباعة الـ PDF
          const Divider(height: 18, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'تاريخ الجرد: $formattedDate',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.print_rounded, size: 20),
                    color: AppColors.stocktakePurple,
                    tooltip: 'طباعة محضر الجرد (PDF)',
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      try {
                        await PdfService.printStocktake(stocktake);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تعذر فتح الطباعة: $e',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    color: AppColors.stocktakePurple,
                    tooltip: 'مشاركة محضر الجرد',
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      try {
                        await PdfService.shareStocktake(stocktake);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تعذر مشاركة المحضر: $e',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
