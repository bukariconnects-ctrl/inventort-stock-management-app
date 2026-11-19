import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../stocktake/screens/new_stocktake_screen.dart';
import '../../stocktake/screens/stocktake_history_screen.dart';
import 'new_damage_screen.dart';
import 'new_issue_screen.dart';
import 'new_receipt_screen.dart';

/// الشاشة الرئيسية لتبويب العمليات وسندات المخزون (Operations Screen)
class OperationsScreen extends StatelessWidget {
  const OperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('سندات وعمليات المخزون')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // بطاقة توجيهية
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: Colors.white, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إصدار السندات وحركات المخزن',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'اختر نوع السند المطلوب لتسجيل الحركة فورياً في قاعدة البيانات وتحديث الأرصدة.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. بطاقة سند استلام من المصنع
          _buildOperationHubCard(
            context: context,
            title: 'سند استلام إنتاج من المصنع',
            subtitle:
                'إدخال كميات الكراتين الواردة من خطوط الإنتاج بالمصنع وزيادة رصيد المستودع.',
            icon: Icons.add_business_rounded,
            color: AppColors.receiptGreen,
            bgColor: AppColors.receiptGreenLight,
            badgeText: 'زيادة رصيد (+)',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NewReceiptScreen()),
              );
            },
          ),
          const SizedBox(height: 14),

          // 2. بطاقة سند صرف لموزع
          _buildOperationHubCard(
            context: context,
            title: 'سند صرف لموزع / مندوب',
            subtitle:
                'تسليم وصرف كراتين مياه لسيارات التوزيع والمناديب مع فحص الرصيد المتاح آلياً.',
            icon: Icons.local_shipping_rounded,
            color: AppColors.issueBlue,
            bgColor: AppColors.issueBlueLight,
            badgeText: 'خصم رصيد (-)',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const NewIssueScreen()));
            },
          ),
          const SizedBox(height: 14),

          // 3. بطاقة سند إتلاف وهدر
          _buildOperationHubCard(
            context: context,
            title: 'سند إتلاف وهدر مخزني',
            subtitle:
                'إثبات واستبعاد الكراتين والعبوات التالفة وتوثيق سبب الهدر لمنع العجز غير المبرر.',
            icon: Icons.delete_sweep_rounded,
            color: AppColors.damageRed,
            bgColor: AppColors.damageRedLight,
            badgeText: 'خصم تالف (-)',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NewDamageScreen()),
              );
            },
          ),
          const SizedBox(height: 14),

          // 4. بطاقة الجرد والتسوية المخزنية الدورية
          _buildStocktakeSectionCard(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStocktakeSectionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.stocktakePurpleLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: AppColors.stocktakePurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الجرد والتسوية الدورية',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.stocktakePurple,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.stocktakePurpleLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'مطابقة وفروقات',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.stocktakePurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'حصر الكميات الفعلية ومطابقتها مع الأرصدة الدفترية وتسجيل الفروقات وإجراء التسوية الفورية.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_task_rounded, size: 16),
                  label: const Text(
                    'بدء جرد جديد',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StocktakeHistoryScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.stocktakePurple,
                    side: const BorderSide(color: AppColors.stocktakePurple),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text(
                    'سجل الجرد السابق',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationHubCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
