import 'dart:typed_data';

/// واجهة خدمة توليد وطباعة ومشاركة السندات والتقارير بصيغة PDF
abstract class PdfService {
  /// توليد سند PDF كـ Uint8List
  Future<Uint8List> generateTransactionVoucher({
    required String voucherNumber,
    required String voucherType,
    required String warehouseName,
    required String itemName,
    required int quantity,
    required DateTime date,
    String? partyName,
    String? notes,
  });

  /// طباعة السند مباشرة أو فتح عارض الطباعة
  Future<void> printTransactionVoucher(Uint8List pdfBytes, String title);

  /// مشاركة ملف السند عبر التطبيقات
  Future<void> shareTransactionVoucher(Uint8List pdfBytes, String fileName);
}
