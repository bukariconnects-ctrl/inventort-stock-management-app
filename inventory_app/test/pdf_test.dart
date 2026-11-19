import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/core/services/pdf_service.dart';
import 'package:inventory_app/features/stocktake/models/stocktake_model.dart';
import 'package:inventory_app/features/transactions/models/stock_transaction_model.dart';
import 'package:inventory_app/features/warehouses/models/warehouse_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('اختبارات محرك توليد الـ PDF لمياه رواء - المرحلة 6', () {
    test('1. التحقق من توليد سند استلام إنتاج PDF (Receipt Voucher)', () async {
      final tx = StockTransactionModel(
        id: 1,
        voucherNumber: 'REC-202611-0001',
        type: 'receipt',
        warehouseId: 1,
        warehouseName: 'المخزن الرئيسي (المصنع)',
        warehouseCode: 'WH-01',
        itemId: 1,
        itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
        quantity: 500,
        relatedPerson: 'السائق خالد - خط إنتاج 2',
        referenceNumber: 'LOT-2026-99',
        notes: 'دفعة الصباح الأولى مطابقة للمواصفات',
        createdAt: DateTime(2026, 11, 20, 8, 30),
      );

      final pdfBytes = await PdfService.generateVoucherPdf(tx);
      expect(pdfBytes.isNotEmpty, isTrue);
      // التحقق من ترويسة ملفات الـ PDF القياسية (%PDF)
      expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('2. التحقق من توليد سند صرف لموزع PDF (Issue Voucher)', () async {
      final tx = StockTransactionModel(
        id: 2,
        voucherNumber: 'ISS-202611-0002',
        type: 'issue',
        warehouseId: 1,
        warehouseName: 'المخزن الرئيسي (المصنع)',
        warehouseCode: 'WH-01',
        itemId: 1,
        itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
        quantity: 150,
        relatedPerson: 'المندوب فهد الأحمد',
        referenceNumber: 'ORD-5541',
        notes: 'تسليم سيارة التوزيع رقم 4',
        createdAt: DateTime(2026, 11, 20, 9, 15),
      );

      final pdfBytes = await PdfService.generateVoucherPdf(tx);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('3. التحقق من توليد سند إتلاف وهدر PDF (Damage Voucher)', () async {
      final tx = StockTransactionModel(
        id: 3,
        voucherNumber: 'DAM-202611-0003',
        type: 'damage',
        warehouseId: 2,
        warehouseName: 'مخزن التوزيع الخارجي',
        warehouseCode: 'WH-02',
        itemId: 1,
        itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
        quantity: 12,
        relatedPerson: 'أمين المخزن سالم',
        damageReason: 'تسريب مياه من الكرتون وتلف العبوات أثناء النقل',
        notes: 'تم عزل الكراتين التالفة',
        createdAt: DateTime(2026, 11, 20, 10, 0),
      );

      final pdfBytes = await PdfService.generateVoucherPdf(tx);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test(
      '4. التحقق من توليد محضر جرد وتسوية مخزنية PDF (Stocktake Report)',
      () async {
        final stocktake = StocktakeModel(
          id: 1,
          code: 'STK-202611-0001',
          warehouseId: 1,
          itemId: 1,
          systemQuantity: 1200,
          actualQuantity: 1195,
          difference: -5,
          notes: 'عجز طفيف ناتج عن كراتين تالفة قيد التوثيق',
          warehouseName: 'المخزن الرئيسي (المصنع)',
          warehouseCode: 'WH-01',
          itemName: 'كرتون مياه رواء - 20 علبة × 75 مل',
          createdAt: DateTime(2026, 11, 20, 11, 30),
        );

        final warehouse = WarehouseModel(
          id: 1,
          name: 'المخزن الرئيسي (المصنع)',
          code: 'WH-01',
          location: 'المنطقة الصناعية - بوابة المصنع 1',
          createdAt: DateTime.now(),
        );

        final pdfBytes = await PdfService.generateStocktakePdf(
          stocktake,
          warehouse: warehouse,
        );
        expect(pdfBytes.isNotEmpty, isTrue);
        expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
        expect(pdfBytes.length, greaterThan(1000));
      },
    );
  });
}
