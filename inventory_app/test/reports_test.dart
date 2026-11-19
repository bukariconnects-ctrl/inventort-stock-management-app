import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/core/services/pdf_service.dart';
import 'package:inventory_app/features/reports/providers/reports_provider.dart';
import 'package:inventory_app/features/transactions/models/stock_transaction_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTransactions = [
    StockTransactionModel(
      id: 1,
      voucherNumber: 'REC-202611-0001',
      type: 'receipt',
      warehouseId: 1,
      warehouseName: 'المخزن الرئيسي (المصنع)',
      warehouseCode: 'WH-01',
      itemId: 1,
      itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
      quantity: 1000,
      relatedPerson: 'السائق خالد',
      referenceNumber: 'LOT-101',
      createdAt: DateTime.now(),
    ),
    StockTransactionModel(
      id: 2,
      voucherNumber: 'ISS-202611-0002',
      type: 'issue',
      warehouseId: 1,
      warehouseName: 'المخزن الرئيسي (المصنع)',
      warehouseCode: 'WH-01',
      itemId: 1,
      itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
      quantity: 300,
      relatedPerson: 'المندوب فهد',
      referenceNumber: 'ORD-501',
      createdAt: DateTime.now(),
    ),
    StockTransactionModel(
      id: 3,
      voucherNumber: 'ISS-202611-0003',
      type: 'issue',
      warehouseId: 2,
      warehouseName: 'مخزن التوزيع الخارجي',
      warehouseCode: 'WH-02',
      itemId: 1,
      itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
      quantity: 150,
      relatedPerson: 'المندوب سعد',
      referenceNumber: 'ORD-502',
      createdAt: DateTime.now(),
    ),
    StockTransactionModel(
      id: 4,
      voucherNumber: 'DAM-202611-0004',
      type: 'damage',
      warehouseId: 1,
      warehouseName: 'المخزن الرئيسي (المصنع)',
      warehouseCode: 'WH-01',
      itemId: 1,
      itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
      quantity: 20,
      relatedPerson: 'أمين المخزن',
      damageReason: 'عبوات مكسورة أثناء النقل',
      createdAt: DateTime.now(),
    ),
  ];

  group(
    'اختبارات مزود التقارير وسجل الحركات (ReportsProvider) - المرحلة 7',
    () {
      late ReportsProvider provider;

      setUp(() {
        provider = ReportsProvider();
        provider.setDatePreset(DateFilterPreset.allTime);
        provider.setTransactionsForTesting(sampleTransactions);
      });

      test('1. التحقق من الحسابات والإحصائيات التجميعية الأولية', () {
        expect(provider.totalReceived, 1000);
        expect(provider.totalIssued, 450); // 300 + 150
        expect(provider.totalDamaged, 20);
        expect(provider.netMovement, 530); // 1000 - 450 - 20
        expect(provider.totalBottlesReceived, 20000);
        expect(provider.totalBottlesIssued, 9000);

        // مسحوبات المناديب
        final summary = provider.driverSummary;
        expect(summary['المندوب فهد'], 300);
        expect(summary['المندوب سعد'], 150);
      });

      test('2. التحقق من تصفية السندات حسب المستودع', () {
        provider.setWarehouseFilter(2); // مخزن التوزيع الخارجي فقط
        expect(provider.filteredTransactions.length, 1);
        expect(
          provider.filteredTransactions.first.voucherNumber,
          'ISS-202611-0003',
        );
        expect(provider.totalIssued, 150);
        expect(provider.totalReceived, 0);

        // إعادة التعيين
        provider.setWarehouseFilter(null);
        expect(provider.filteredTransactions.length, 4);
      });

      test(
        '3. التحقق من تصفية السندات حسب نوع الحركة (receipt, issue, damage)',
        () {
          provider.setTypeFilter('receipt');
          expect(provider.filteredTransactions.length, 1);
          expect(provider.totalReceived, 1000);

          provider.setTypeFilter('issue');
          expect(provider.filteredTransactions.length, 2);
          expect(provider.totalIssued, 450);

          provider.setTypeFilter('damage');
          expect(provider.filteredTransactions.length, 1);
          expect(provider.totalDamaged, 20);

          provider.setTypeFilter(null);
          expect(provider.filteredTransactions.length, 4);
        },
      );

      test('4. التحقق من البحث النصي الفوري (Search Query)', () {
        // بحث باسم المندوب
        provider.setSearchQuery('فهد');
        expect(provider.filteredTransactions.length, 1);
        expect(
          provider.filteredTransactions.first.voucherNumber,
          'ISS-202611-0002',
        );

        // بحث برقم السند
        provider.setSearchQuery('REC-202611');
        expect(provider.filteredTransactions.length, 1);
        expect(provider.filteredTransactions.first.type, 'receipt');

        // تفريغ البحث
        provider.setSearchQuery('');
        expect(provider.filteredTransactions.length, 4);
      });

      test(
        '5. التحقق من إحصائيات نشاط اليوم والعمليات الحديثة للوحة التحكم',
        () {
          expect(provider.todayReceived, 1000);
          expect(provider.todayIssued, 450);
          expect(provider.todayDamaged, 20);

          final recents = provider.recentTransactions(2);
          expect(recents.length, 2);
        },
      );
    },
  );

  group('اختبارات توليد تقرير حركة المخزون الشامل PDF - المرحلة 7', () {
    test('6. التحقق من توليد تقرير حركة المخزون العام كـ PDF صالح', () async {
      final pdfBytes = await PdfService.generateMovementReportPdf(
        transactions: sampleTransactions,
        periodTitle: 'تقرير شهر نوفمبر 2026',
        warehouseName: 'كافة المستودعات والمخازن',
        totalReceived: 1000,
        totalIssued: 450,
        totalDamaged: 20,
        netMovement: 530,
        driverSummary: {'المندوب فهد': 300, 'المندوب سعد': 150},
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]); // %PDF
      expect(pdfBytes.length, greaterThan(2000));
    });
  });
}
