import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/stocktake/models/stocktake_model.dart';
import '../../features/transactions/models/stock_transaction_model.dart';
import '../../features/warehouses/models/warehouse_model.dart';
import '../constants/app_constants.dart';
import '../utils/date_formatter.dart';

/// محرك وخدمة توليد وطباعة ومشاركة مستندات وسندات الـ PDF (PdfService)
class PdfService {
  PdfService._();

  // ألوان هوية مياه رواء المائية
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF0277BD);
  static const PdfColor primaryDark = PdfColor.fromInt(0xFF01579B);
  static const PdfColor accentCyan = PdfColor.fromInt(0xFF00B4D8);
  static const PdfColor receiptGreen = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor receiptGreenLight = PdfColor.fromInt(0xFFE8F5E9);
  static const PdfColor issueBlue = PdfColor.fromInt(0xFF0277BD);
  static const PdfColor issueBlueLight = PdfColor.fromInt(0xFFE1F5FE);
  static const PdfColor damageRed = PdfColor.fromInt(0xFFC62828);
  static const PdfColor damageRedLight = PdfColor.fromInt(0xFFFFEBEE);
  static const PdfColor stocktakePurple = PdfColor.fromInt(0xFF6A1B9A);
  static const PdfColor stocktakePurpleLight = PdfColor.fromInt(0xFFF3E5F5);
  static const PdfColor textPrimary = PdfColor.fromInt(0xFF263238);
  static const PdfColor textSecondary = PdfColor.fromInt(0xFF546E7A);
  static const PdfColor dividerColor = PdfColor.fromInt(0xFFCFD8DC);
  static const PdfColor lightBg = PdfColor.fromInt(0xFFF8FAFC);

  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  /// تنظيف النصوص من رموز التحكم الخفية في اليونيكود (مثل LRM \u200e)
  static String cleanText(String text) {
    return text
        .replaceAll('\u200e', '')
        .replaceAll('\u200f', '')
        .replaceAll('\u061c', '');
  }

  /// تحميل الخط العربي العادي (Offline-First مع fallback)
  static Future<pw.Font> loadRegularFont() async {
    if (_cachedRegularFont != null) return _cachedRegularFont!;
    try {
      final data = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      _cachedRegularFont = pw.Font.ttf(data);
      return _cachedRegularFont!;
    } catch (_) {
      try {
        _cachedRegularFont = await PdfGoogleFonts.cairoRegular();
        return _cachedRegularFont!;
      } catch (_) {
        return pw.Font.helvetica();
      }
    }
  }

  /// تحميل الخط العربي العريض (Offline-First مع fallback)
  static Future<pw.Font> loadBoldFont() async {
    if (_cachedBoldFont != null) return _cachedBoldFont!;
    try {
      final data = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _cachedBoldFont = pw.Font.ttf(data);
      return _cachedBoldFont!;
    } catch (_) {
      try {
        _cachedBoldFont = await PdfGoogleFonts.cairoBold();
        return _cachedBoldFont!;
      } catch (_) {
        return pw.Font.helveticaBold();
      }
    }
  }

  /// توليد سند الحركة المخزنية (استلام / صرف / إتلاف) كملف PDF رسمي
  static Future<Uint8List> generateVoucherPdf(
    StockTransactionModel transaction, {
    pw.Font? fontRegular,
    pw.Font? fontBold,
  }) async {
    final regular = fontRegular ?? await loadRegularFont();
    final bold = fontBold ?? await loadBoldFont();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    // تحديد ألوان ومسمى السند حسب النوع
    PdfColor bannerColor;
    PdfColor bannerBgColor;
    String voucherTitle;
    String partyLabel;

    switch (transaction.type) {
      case 'receipt':
        bannerColor = receiptGreen;
        bannerBgColor = receiptGreenLight;
        voucherTitle = 'سند استلام إنتاج من المصنع (توريد)';
        partyLabel = 'المسلِّم من المصنع / السائق:';
        break;
      case 'issue':
        bannerColor = issueBlue;
        bannerBgColor = issueBlueLight;
        voucherTitle = 'سند صرف بضاعة لموزع / مندوب';
        partyLabel = 'المستلم / الموزع / المندوب:';
        break;
      case 'damage':
        bannerColor = damageRed;
        bannerBgColor = damageRedLight;
        voucherTitle = 'سند إتلاف وهدر مخزني معتمد';
        partyLabel = 'أمين المستودع الموثِّق:';
        break;
      default:
        bannerColor = primaryBlue;
        bannerBgColor = issueBlueLight;
        voucherTitle = 'سند حركة مخزنية رسمية';
        partyLabel = 'الطرف المعني:';
    }

    final formattedDate = cleanText(
      DateFormatter.formatDateTime(transaction.createdAt),
    );
    final totalBottles = transaction.quantity * 20;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. ترويسة المصنع الرسمية
              _buildFactoryHeader(bold, regular),
              pw.SizedBox(height: 14),

              // 2. شريط نوع السند الملون
              _buildVoucherBanner(
                title: voucherTitle,
                color: bannerColor,
                bgColor: bannerBgColor,
                boldFont: bold,
              ),
              pw.SizedBox(height: 14),

              // 3. شبكة تفاصيل السند والمستودع
              _buildVoucherMetadataGrid(
                transaction: transaction,
                formattedDate: formattedDate,
                partyLabel: partyLabel,
                boldFont: bold,
                regularFont: regular,
              ),
              pw.SizedBox(height: 16),

              // 4. جدول البضاعة والكميات
              _buildVoucherItemsTable(
                transaction: transaction,
                totalBottles: totalBottles,
                bannerColor: bannerColor,
                boldFont: bold,
                regularFont: regular,
              ),
              pw.SizedBox(height: 14),

              // 5. قسم الملاحظات أو سبب الإتلاف
              if (transaction.damageReason != null &&
                  transaction.damageReason!.isNotEmpty) ...[
                _buildDamageReasonBox(transaction.damageReason!, bold, regular),
                pw.SizedBox(height: 10),
              ],
              if (transaction.notes != null &&
                  transaction.notes!.isNotEmpty) ...[
                _buildNotesBox(transaction.notes!, bold, regular),
                pw.SizedBox(height: 10),
              ],

              pw.Spacer(),

              // 6. قسم التوقيعات والاعتمادات الثلاثية
              _buildSignaturesSection(
                partyRole: transaction.type == 'receipt'
                    ? 'المسلِّم (المصنع)'
                    : transaction.type == 'issue'
                    ? 'المستلم (المندوب)'
                    : 'المسؤول الموثِّق',
                partyName: transaction.relatedPerson,
                boldFont: bold,
                regularFont: regular,
              ),
              pw.SizedBox(height: 14),

              // 7. تذييل الصفحة والاعتماد الإلكتروني
              _buildDocumentFooter(
                code: transaction.voucherNumber,
                regularFont: regular,
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// توليد محضر الجرد والتسوية المخزنية كملف PDF رسمي
  static Future<Uint8List> generateStocktakePdf(
    StocktakeModel stocktake, {
    WarehouseModel? warehouse,
    pw.Font? fontRegular,
    pw.Font? fontBold,
  }) async {
    final regular = fontRegular ?? await loadRegularFont();
    final bold = fontBold ?? await loadBoldFont();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    final formattedDate = cleanText(
      DateFormatter.formatDateTime(stocktake.createdAt),
    );
    final warehouseName =
        warehouse?.name ??
        stocktake.warehouseName ??
        'مستودع رقم ${stocktake.warehouseId}';
    final warehouseCode = warehouse?.code ?? stocktake.warehouseCode ?? 'WH-01';
    final warehouseLocation =
        warehouse?.location ?? 'مقر المصنع الرئيسي ومستودعات التوزيع';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. ترويسة المصنع الرسمية
              _buildFactoryHeader(bold, regular),
              pw.SizedBox(height: 14),

              // 2. شريط محضر الجرد والتسوية
              _buildVoucherBanner(
                title: 'محضر جرد وتسوية مخزنية دورية',
                color: stocktakePurple,
                bgColor: stocktakePurpleLight,
                boldFont: bold,
              ),
              pw.SizedBox(height: 14),

              // 3. بيانات جلسة الجرد والمستودع
              _buildStocktakeMetadataGrid(
                stocktake: stocktake,
                warehouseName: warehouseName,
                warehouseCode: warehouseCode,
                warehouseLocation: warehouseLocation,
                formattedDate: formattedDate,
                boldFont: bold,
                regularFont: regular,
              ),
              pw.SizedBox(height: 16),

              // 4. جدول مقارنة الأرصدة واحتساب الفوارق
              _buildStocktakeComparisonTable(
                stocktake: stocktake,
                boldFont: bold,
                regularFont: regular,
              ),
              pw.SizedBox(height: 14),

              // 5. بيان سبب الفارق وتبرير أمين المستودع
              _buildStocktakeNotesBox(stocktake, bold, regular),

              pw.Spacer(),

              // 6. توقيعات لجنة الجرد والتدقيق
              _buildStocktakeSignatures(boldFont: bold, regularFont: regular),
              pw.SizedBox(height: 14),

              // 7. تذييل الصفحة
              _buildDocumentFooter(
                code: stocktake.code,
                regularFont: regular,
                customNotice:
                    'محضر جرد وتدقيق مخزني معتمد لتسوية الأرصدة في قاعدة بيانات النظام.',
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // =================== أجزاء قوالب الـ PDF المساعدة ===================

  /// ترويسة المصنع الرسمية
  static pw.Widget _buildFactoryHeader(pw.Font bold, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primaryBlue, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'مصنع مياه رواء المعبأة',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 18,
                  color: primaryDark,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Rawaa Bottled Water Factory',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 10,
                  color: textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'مياه شرب نقية معبأة - عبوة 75 مل (كرتون 20 قنينة)',
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 9,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: primaryBlue,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'Rawaa WMS',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 11,
                    color: PdfColors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'إدارة المخازن والمستودعات',
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 9,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// شريط نوع السند الملون
  static pw.Widget _buildVoucherBanner({
    required String title,
    required PdfColor color,
    required PdfColor bgColor,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1.2),
      ),
      child: pw.Center(
        child: pw.Text(
          title,
          style: pw.TextStyle(font: boldFont, fontSize: 15, color: color),
        ),
      ),
    );
  }

  /// شبكة بيانات السند التفصيلية
  static pw.Widget _buildVoucherMetadataGrid({
    required StockTransactionModel transaction,
    required String formattedDate,
    required String partyLabel,
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: dividerColor),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetaItem(
                  'رقم السند:',
                  transaction.voucherNumber,
                  boldFont,
                  regularFont,
                  isBoldValue: true,
                ),
              ),
              pw.Expanded(
                child: _buildMetaItem(
                  'تاريخ ووقت القيد:',
                  formattedDate,
                  boldFont,
                  regularFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetaItem(
                  'المستودع:',
                  transaction.warehouseName != null
                      ? '${transaction.warehouseName} (${transaction.warehouseCode ?? ""})'
                      : 'مستودع رقم ${transaction.warehouseId}',
                  boldFont,
                  regularFont,
                ),
              ),
              pw.Expanded(
                child: _buildMetaItem(
                  partyLabel,
                  transaction.relatedPerson,
                  boldFont,
                  regularFont,
                ),
              ),
            ],
          ),
          if (transaction.referenceNumber != null &&
              transaction.referenceNumber!.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildMetaItem(
                    transaction.type == 'receipt'
                        ? 'رقم إرسالية / تشغيلة المصنع:'
                        : 'رقم أمر الصرف الإداري:',
                    transaction.referenceNumber!,
                    boldFont,
                    regularFont,
                  ),
                ),
                pw.Expanded(child: pw.Container()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildMetaItem(
    String label,
    String value,
    pw.Font bold,
    pw.Font regular, {
    bool isBoldValue = false,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: regular,
            fontSize: 9.5,
            color: textSecondary,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              font: isBoldValue ? bold : regular,
              fontSize: 9.5,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// جدول البضاعة والكميات
  static pw.Widget _buildVoucherItemsTable({
    required StockTransactionModel transaction,
    required int totalBottles,
    required PdfColor bannerColor,
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: dividerColor, width: 0.8),
      columnWidths: const {
        0: pw.FixedColumnWidth(28),
        1: pw.FlexColumnWidth(3.5),
        2: pw.FlexColumnWidth(2.0),
        3: pw.FlexColumnWidth(2.0),
        4: pw.FlexColumnWidth(2.5),
      },
      children: [
        // رأس الجدول
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: lightBg),
          children: [
            _buildTableHeaderCell('م', boldFont),
            _buildTableHeaderCell('بيان الصنف والمواصفات', boldFont),
            _buildTableHeaderCell('الكمية (كرتون)', boldFont),
            _buildTableHeaderCell('إجمالي العلب (قنينة)', boldFont),
            _buildTableHeaderCell('ملاحظات الفحص', boldFont),
          ],
        ),
        // صف الصنف
        pw.TableRow(
          children: [
            _buildTableCell('1', regularFont, isCenter: true),
            _buildTableCell(
              '${AppConstants.defaultItemName}\n(${AppConstants.defaultItemSpecification})',
              regularFont,
            ),
            _buildTableCell(
              '${cleanText(DateFormatter.formatNumber(transaction.quantity))} كرتون',
              boldFont,
              isCenter: true,
              textColor: bannerColor,
            ),
            _buildTableCell(
              '${cleanText(DateFormatter.formatNumber(totalBottles))} قنينة',
              regularFont,
              isCenter: true,
            ),
            _buildTableCell(
              transaction.notes ?? 'بضاعة سليمة ومطابقة',
              regularFont,
            ),
          ],
        ),
        // سطر الإجمالي
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: lightBg),
          children: [
            _buildTableCell('', boldFont),
            _buildTableCell('الإجمالي الكلي المسجل:', boldFont),
            _buildTableCell(
              '${cleanText(DateFormatter.formatNumber(transaction.quantity))} كرتون',
              boldFont,
              isCenter: true,
              textColor: bannerColor,
            ),
            _buildTableCell(
              '${cleanText(DateFormatter.formatNumber(totalBottles))} قنينة',
              boldFont,
              isCenter: true,
            ),
            _buildTableCell('معتمد نهائياً', regularFont, isCenter: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(font: bold, fontSize: 9.5, color: textPrimary),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isCenter = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: isCenter
          ? pw.Center(
              child: pw.Text(
                text,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: textColor ?? textPrimary,
                ),
              ),
            )
          : pw.Text(
              text,
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: textColor ?? textPrimary,
              ),
            ),
    );
  }

  /// مربع سبب الإتلاف
  static pw.Widget _buildDamageReasonBox(
    String reason,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: damageRedLight,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: damageRed, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'سبب وتوصيف الإتلاف المعتمد: ',
            style: pw.TextStyle(font: bold, fontSize: 9.5, color: damageRed),
          ),
          pw.Expanded(
            child: pw.Text(
              reason,
              style: pw.TextStyle(
                font: regular,
                fontSize: 9.5,
                color: damageRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// مربع الملاحظات
  static pw.Widget _buildNotesBox(String notes, pw.Font bold, pw.Font regular) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: dividerColor),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملاحظات إضافية: ',
            style: pw.TextStyle(
              font: bold,
              fontSize: 9.5,
              color: textSecondary,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              notes,
              style: pw.TextStyle(
                font: regular,
                fontSize: 9.5,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// قسم التوقيعات الثلاثي للسندات
  static pw.Widget _buildSignaturesSection({
    required String partyRole,
    String? partyName,
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSignatureBox(
          role: 'أمين المستودع المسؤول',
          name: 'أمين المخزن',
          boldFont: boldFont,
          regularFont: regularFont,
        ),
        pw.SizedBox(width: 14),
        _buildSignatureBox(
          role: partyRole,
          name: partyName ?? 'المندوب / السائق',
          boldFont: boldFont,
          regularFont: regularFont,
        ),
        pw.SizedBox(width: 14),
        _buildSignatureBox(
          role: 'إدارة المصنع / الحسابات',
          name: 'الختم والاعتماد الرسمي',
          boldFont: boldFont,
          regularFont: regularFont,
          isApproval: true,
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureBox({
    required String role,
    required String name,
    required pw.Font boldFont,
    required pw.Font regularFont,
    bool isApproval = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(
            color: isApproval ? primaryBlue : dividerColor,
            width: isApproval ? 1.2 : 0.8,
          ),
          color: isApproval ? lightBg : PdfColors.white,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              role,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 9.5,
                color: isApproval ? primaryDark : textPrimary,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'الاسم: $name',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 8.5,
                color: textSecondary,
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Container(
              width: 100,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: dividerColor, width: 0.8),
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              isApproval ? 'الاعتماد / الختم' : 'التوقيع والاستلام',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 7.5,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== أجزاء محضر الجرد والتسوية ===================

  static pw.Widget _buildStocktakeMetadataGrid({
    required StocktakeModel stocktake,
    required String warehouseName,
    required String warehouseCode,
    required String warehouseLocation,
    required String formattedDate,
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: dividerColor),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetaItem(
                  'كود جلسة الجرد:',
                  stocktake.code,
                  boldFont,
                  regularFont,
                  isBoldValue: true,
                ),
              ),
              pw.Expanded(
                child: _buildMetaItem(
                  'تاريخ ووقت الجرد:',
                  formattedDate,
                  boldFont,
                  regularFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetaItem(
                  'المستودع المجرود:',
                  '$warehouseName ($warehouseCode)',
                  boldFont,
                  regularFont,
                ),
              ),
              pw.Expanded(
                child: _buildMetaItem(
                  'موقع المستودع:',
                  warehouseLocation,
                  boldFont,
                  regularFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStocktakeComparisonTable({
    required StocktakeModel stocktake,
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    PdfColor diffColor;
    String statusTitle;

    if (stocktake.isExactMatch) {
      diffColor = receiptGreen;
      statusTitle = 'مطابق تماماً (0 كرتون)';
    } else if (stocktake.hasDeficit) {
      diffColor = damageRed;
      statusTitle = 'عجز: ${stocktake.difference} كرتون';
    } else {
      diffColor = issueBlue;
      statusTitle = 'فائض: +${stocktake.difference} كرتون';
    }

    return pw.Table(
      border: pw.TableBorder.all(color: dividerColor, width: 0.8),
      columnWidths: const {
        0: pw.FixedColumnWidth(26),
        1: pw.FlexColumnWidth(3.0),
        2: pw.FlexColumnWidth(2.0),
        3: pw.FlexColumnWidth(2.0),
        4: pw.FlexColumnWidth(2.0),
        5: pw.FlexColumnWidth(2.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: lightBg),
          children: [
            _buildTableHeaderCell('م', boldFont),
            _buildTableHeaderCell('الصنف المجرود', boldFont),
            _buildTableHeaderCell('الرصيد الدفتري', boldFont),
            _buildTableHeaderCell('الرصيد الفعلي', boldFont),
            _buildTableHeaderCell('الفارق (كرتون)', boldFont),
            _buildTableHeaderCell('نتيجة المطابقة', boldFont),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('1', regularFont, isCenter: true),
            _buildTableCell(
              '${AppConstants.defaultItemName}\n(${AppConstants.defaultItemSpecification})',
              regularFont,
            ),
            _buildTableCell(
              '${cleanText(DateFormatter.formatNumber(stocktake.systemQuantity))} كرتون',
              regularFont,
              isCenter: true,
            ),
            _buildTableCell(
              '${cleanText(DateFormatter.formatNumber(stocktake.actualQuantity))} كرتون',
              boldFont,
              isCenter: true,
              textColor: stocktakePurple,
            ),
            _buildTableCell(
              '${stocktake.difference >= 0 ? "+" : ""}${cleanText(DateFormatter.formatNumber(stocktake.difference))} كرتون',
              boldFont,
              isCenter: true,
              textColor: diffColor,
            ),
            _buildTableCell(
              statusTitle,
              boldFont,
              isCenter: true,
              textColor: diffColor,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStocktakeNotesBox(
    StocktakeModel stocktake,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: dividerColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'مبررات وأسباب الفوارق وتوصيات أمين المستودع:',
            style: pw.TextStyle(font: bold, fontSize: 9.5, color: textPrimary),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            stocktake.notes != null && stocktake.notes!.isNotEmpty
                ? stocktake.notes!
                : 'تمت مطابقة الرصيد الفعلي بعد الحصر اليدوي مع الرصيد الدفتري للنظام، ولا توجد أي فروقات تستوجب التبرير.',
            style: pw.TextStyle(
              font: regular,
              fontSize: 9,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStocktakeSignatures({
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSignatureBox(
          role: 'أمين المستودع المسؤول',
          name: 'القائم بالحصر والعد',
          boldFont: boldFont,
          regularFont: regularFont,
        ),
        pw.SizedBox(width: 14),
        _buildSignatureBox(
          role: 'المدقق / المراجع الداخلي',
          name: 'مطابقة السجلات والواقع',
          boldFont: boldFont,
          regularFont: regularFont,
        ),
        pw.SizedBox(width: 14),
        _buildSignatureBox(
          role: 'إدارة المصنع / الحسابات العامة',
          name: 'اعتماد التسوية النهائية',
          boldFont: boldFont,
          regularFont: regularFont,
          isApproval: true,
        ),
      ],
    );
  }

  /// تذييل الصفحة والاعتماد الإلكتروني
  static pw.Widget _buildDocumentFooter({
    required String code,
    required pw.Font regularFont,
    String? customNotice,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: dividerColor, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            customNotice ??
                'تم إصدار هذا السند إلكترونياً عبر نظام رواء لإدارة المستودعات (Rawaa WMS) - سري ومعتمد.',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8,
              color: textSecondary,
            ),
          ),
          pw.Text(
            'مرجع الوثيقة: $code',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // =================== دوال الطباعة والمشاركة المباشرة ===================

  /// طباعة سند حركة مخزنية
  static Future<void> printVoucher(StockTransactionModel transaction) async {
    final pdfBytes = await generateVoucherPdf(transaction);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'سند_${transaction.voucherNumber}',
    );
  }

  /// مشاركة سند حركة مخزنية عبر التطبيقات (واتساب، بريد، درايف)
  static Future<void> shareVoucher(StockTransactionModel transaction) async {
    final pdfBytes = await generateVoucherPdf(transaction);
    String typeArabic;
    switch (transaction.type) {
      case 'receipt':
        typeArabic = 'استلام';
        break;
      case 'issue':
        typeArabic = 'صرف';
        break;
      case 'damage':
        typeArabic = 'إتلاف';
        break;
      default:
        typeArabic = 'حركة';
    }
    final fileName = 'سند_${typeArabic}_${transaction.voucherNumber}.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  /// طباعة محضر جرد وتسوية مخزنية
  static Future<void> printStocktake(
    StocktakeModel stocktake, {
    WarehouseModel? warehouse,
  }) async {
    final pdfBytes = await generateStocktakePdf(
      stocktake,
      warehouse: warehouse,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'محضر_جرد_${stocktake.code}',
    );
  }

  /// مشاركة محضر جرد وتسوية مخزنية عبر التطبيقات
  static Future<void> shareStocktake(
    StocktakeModel stocktake, {
    WarehouseModel? warehouse,
  }) async {
    final pdfBytes = await generateStocktakePdf(
      stocktake,
      warehouse: warehouse,
    );
    final fileName = 'محضر_جرد_${stocktake.code}.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  // =================== تقرير حركة المخزون الشامل ===================

  /// توليد تقرير حركة ومسحوبات المخزون العام كملف PDF
  static Future<Uint8List> generateMovementReportPdf({
    required List<StockTransactionModel> transactions,
    required String periodTitle,
    String? warehouseName,
    int? totalReceived,
    int? totalIssued,
    int? totalDamaged,
    int? netMovement,
    Map<String, int>? driverSummary,
    pw.Font? fontRegular,
    pw.Font? fontBold,
  }) async {
    final regular = fontRegular ?? await loadRegularFont();
    final bold = fontBold ?? await loadBoldFont();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    final rec =
        totalReceived ??
        transactions
            .where((t) => t.type == 'receipt')
            .fold<int>(0, (s, t) => s + t.quantity);
    final iss =
        totalIssued ??
        transactions
            .where((t) => t.type == 'issue')
            .fold<int>(0, (s, t) => s + t.quantity);
    final dam =
        totalDamaged ??
        transactions
            .where((t) => t.type == 'damage')
            .fold<int>(0, (s, t) => s + t.quantity);
    final net = netMovement ?? (rec - iss - dam);

    final reportDate = cleanText(DateFormatter.formatDateTime(DateTime.now()));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        header: (context) {
          if (context.pageNumber > 1) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.only(bottom: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: dividerColor, width: 0.8),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'مصنع مياه رواء - تقرير حركة ومسحوبات المخزون',
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 8.5,
                      color: textSecondary,
                    ),
                  ),
                  pw.Text(
                    'صفحة ${context.pageNumber} من ${context.pagesCount}',
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 8.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return pw.Container();
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: dividerColor, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تم إصدار التقرير آلياً عبر نظام رواء لإدارة المستودعات (Rawaa WMS) - معتمد.',
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 8,
                    color: textSecondary,
                  ),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 8,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            // 1. ترويسة المصنع
            _buildFactoryHeader(bold, regular),
            pw.SizedBox(height: 12),

            // 2. شريط العنوان
            _buildVoucherBanner(
              title: 'تقرير حركة ومسحوبات المخزون العام',
              color: primaryBlue,
              bgColor: issueBlueLight,
              boldFont: bold,
            ),
            pw.SizedBox(height: 12),

            // 3. معلومات التقرير والفترة
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: dividerColor),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: _buildMetaItem(
                      'الفترة الزمنية:',
                      periodTitle,
                      bold,
                      regular,
                    ),
                  ),
                  pw.Expanded(
                    child: _buildMetaItem(
                      'المستودع المستهدف:',
                      warehouseName ?? 'كافة المخازن',
                      bold,
                      regular,
                    ),
                  ),
                  pw.Expanded(
                    child: _buildMetaItem(
                      'تاريخ الاستخراج:',
                      reportDate,
                      bold,
                      regular,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // 4. بطاقات الإحصائيات الأربع
            _buildReportKpiSummaryRow(
              rec: rec,
              iss: iss,
              dam: dam,
              net: net,
              boldFont: bold,
              regularFont: regular,
            ),
            pw.SizedBox(height: 16),

            // 5. جدول ملخص مسحوبات المناديب إذا وجد
            if (driverSummary != null && driverSummary.isNotEmpty) ...[
              _buildDriverSummaryTable(driverSummary, bold, regular),
              pw.SizedBox(height: 16),
            ],

            // 6. ترويسة جدول الحركات
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'سجل العمليات والحركات المخزنية (${transactions.length} حركة):',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 11,
                    color: textPrimary,
                  ),
                ),
                pw.Text(
                  'صنف: ${AppConstants.defaultItemName}',
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 9,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // 7. جدول الحركات المخزنية
            _buildTransactionsReportTable(transactions, bold, regular),
            pw.SizedBox(height: 20),

            // 8. توقيعات الاعتماد
            _buildReportSignatures(bold, regular),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// بطاقات إحصائيات تقرير الحركة الأربع
  static pw.Widget _buildReportKpiSummaryRow({
    required int rec,
    required int iss,
    required int dam,
    required int net,
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Row(
      children: [
        _buildReportKpiBox(
          title: 'إجمالي الوارد (+)',
          value: '+${cleanText(DateFormatter.formatNumber(rec))} كرتون',
          color: receiptGreen,
          bgColor: receiptGreenLight,
          boldFont: boldFont,
          regularFont: regularFont,
        ),
        pw.SizedBox(width: 8),
        _buildReportKpiBox(
          title: 'إجمالي المنصرف (-)',
          value: '-${cleanText(DateFormatter.formatNumber(iss))} كرتون',
          color: issueBlue,
          bgColor: issueBlueLight,
          boldFont: boldFont,
          regularFont: regularFont,
        ),
        pw.SizedBox(width: 8),
        _buildReportKpiBox(
          title: 'إجمالي التالف (-)',
          value: '-${cleanText(DateFormatter.formatNumber(dam))} كرتون',
          color: damageRed,
          bgColor: damageRedLight,
          boldFont: boldFont,
          regularFont: regularFont,
        ),
        pw.SizedBox(width: 8),
        _buildReportKpiBox(
          title: 'صافي التغير',
          value:
              '${net >= 0 ? "+" : ""}${cleanText(DateFormatter.formatNumber(net))} كرتون',
          color: primaryDark,
          bgColor: lightBg,
          boldFont: boldFont,
          regularFont: regularFont,
        ),
      ],
    );
  }

  static pw.Widget _buildReportKpiBox({
    required String title,
    required String value,
    required PdfColor color,
    required PdfColor bgColor,
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color, width: 0.8),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 8.5,
                color: textSecondary,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(font: boldFont, fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  /// جدول مسحوبات المناديب
  static pw.Widget _buildDriverSummaryTable(
    Map<String, int> driverSummary,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ملخص مسحوبات المناديب والموزعين خلال الفترة:',
          style: pw.TextStyle(font: bold, fontSize: 10, color: textPrimary),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: dividerColor, width: 0.8),
          columnWidths: const {
            0: pw.FixedColumnWidth(28),
            1: pw.FlexColumnWidth(4),
            2: pw.FlexColumnWidth(3),
            3: pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: lightBg),
              children: [
                _buildTableHeaderCell('م', bold),
                _buildTableHeaderCell('اسم المندوب / الموزع', bold),
                _buildTableHeaderCell('الكمية المصروفة (كرتون)', bold),
                _buildTableHeaderCell('إجمالي العلب (قنينة)', bold),
              ],
            ),
            ...driverSummary.entries.toList().asMap().entries.map((entry) {
              final index = entry.key + 1;
              final driverName = entry.value.key;
              final qty = entry.value.value;
              return pw.TableRow(
                children: [
                  _buildTableCell('$index', regular, isCenter: true),
                  _buildTableCell(driverName, regular),
                  _buildTableCell(
                    '${cleanText(DateFormatter.formatNumber(qty))} كرتون',
                    bold,
                    isCenter: true,
                    textColor: issueBlue,
                  ),
                  _buildTableCell(
                    '${cleanText(DateFormatter.formatNumber(qty * 20))} قنينة',
                    regular,
                    isCenter: true,
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// جدول تفاصيل الحركات المخزنية
  static pw.Widget _buildTransactionsReportTable(
    List<StockTransactionModel> transactions,
    pw.Font bold,
    pw.Font regular,
  ) {
    if (transactions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: dividerColor),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Center(
          child: pw.Text(
            'لا توجد حركات مخزنية مسجلة خلال الفترة الزمنية المحددة.',
            style: pw.TextStyle(
              font: regular,
              fontSize: 10,
              color: textSecondary,
            ),
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: dividerColor, width: 0.8),
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FlexColumnWidth(2.6),
        2: pw.FlexColumnWidth(2.6),
        3: pw.FlexColumnWidth(2.2),
        4: pw.FlexColumnWidth(2.8),
        5: pw.FlexColumnWidth(2.8),
        6: pw.FlexColumnWidth(2.2),
        7: pw.FlexColumnWidth(2.4),
      },
      children: [
        // رأس الجدول
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: lightBg),
          children: [
            _buildTableHeaderCell('م', bold),
            _buildTableHeaderCell('رقم السند', bold),
            _buildTableHeaderCell('التاريخ', bold),
            _buildTableHeaderCell('نوع الحركة', bold),
            _buildTableHeaderCell('المستودع', bold),
            _buildTableHeaderCell('الطرف المعني', bold),
            _buildTableHeaderCell('الكمية', bold),
            _buildTableHeaderCell('رقم المرجع', bold),
          ],
        ),
        // صفوف الحركات
        ...transactions.asMap().entries.map((entry) {
          final i = entry.key + 1;
          final tx = entry.value;

          String typeName;
          PdfColor typeColor;
          String sign;

          switch (tx.type) {
            case 'receipt':
              typeName = 'استلام إنتاج';
              typeColor = receiptGreen;
              sign = '+';
              break;
            case 'issue':
              typeName = 'صرف موزع';
              typeColor = issueBlue;
              sign = '-';
              break;
            case 'damage':
              typeName = 'إتلاف وهدر';
              typeColor = damageRed;
              sign = '-';
              break;
            default:
              typeName = 'حركة';
              typeColor = textPrimary;
              sign = '';
          }

          final dateStr = cleanText(DateFormatter.formatDate(tx.createdAt));

          return pw.TableRow(
            children: [
              _buildTableCell('$i', regular, isCenter: true),
              _buildTableCell(tx.voucherNumber, bold, isCenter: true),
              _buildTableCell(dateStr, regular, isCenter: true),
              _buildTableCell(
                typeName,
                bold,
                isCenter: true,
                textColor: typeColor,
              ),
              _buildTableCell(
                tx.warehouseName ?? 'مستودع ${tx.warehouseId}',
                regular,
              ),
              _buildTableCell(tx.relatedPerson, regular),
              _buildTableCell(
                '$sign${cleanText(DateFormatter.formatNumber(tx.quantity))}',
                bold,
                isCenter: true,
                textColor: typeColor,
              ),
              _buildTableCell(
                tx.referenceNumber ?? tx.damageReason ?? '-',
                regular,
                isCenter: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// توقيعات تقرير الحركة العام
  static pw.Widget _buildReportSignatures(pw.Font bold, pw.Font regular) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSignatureBox(
          role: 'أمين المستودع المسؤول',
          name: 'إعداد ومطابقة البيانات',
          boldFont: bold,
          regularFont: regular,
        ),
        pw.SizedBox(width: 14),
        _buildSignatureBox(
          role: 'الإشراف المالي والمخزني',
          name: 'المراجعة والتدقيق',
          boldFont: bold,
          regularFont: regular,
        ),
        pw.SizedBox(width: 14),
        _buildSignatureBox(
          role: 'إدارة المصنع العامة',
          name: 'الاعتماد النهائي للتقرير',
          boldFont: bold,
          regularFont: regular,
          isApproval: true,
        ),
      ],
    );
  }

  /// طباعة تقرير حركة المخزون العام
  static Future<void> printMovementReport({
    required List<StockTransactionModel> transactions,
    required String periodTitle,
    String? warehouseName,
    int? totalReceived,
    int? totalIssued,
    int? totalDamaged,
    int? netMovement,
    Map<String, int>? driverSummary,
  }) async {
    final pdfBytes = await generateMovementReportPdf(
      transactions: transactions,
      periodTitle: periodTitle,
      warehouseName: warehouseName,
      totalReceived: totalReceived,
      totalIssued: totalIssued,
      totalDamaged: totalDamaged,
      netMovement: netMovement,
      driverSummary: driverSummary,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'تقرير_حركة_المخزون',
    );
  }

  /// مشاركة تقرير حركة المخزون العام
  static Future<void> shareMovementReport({
    required List<StockTransactionModel> transactions,
    required String periodTitle,
    String? warehouseName,
    int? totalReceived,
    int? totalIssued,
    int? totalDamaged,
    int? netMovement,
    Map<String, int>? driverSummary,
  }) async {
    final pdfBytes = await generateMovementReportPdf(
      transactions: transactions,
      periodTitle: periodTitle,
      warehouseName: warehouseName,
      totalReceived: totalReceived,
      totalIssued: totalIssued,
      totalDamaged: totalDamaged,
      netMovement: netMovement,
      driverSummary: driverSummary,
    );
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final fileName = 'تقرير_حركة_المخزون_$dateStr.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
