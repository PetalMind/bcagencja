import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../state/models/property_model.dart';
import '../state/models/saved_offer_model.dart';

/// Eksport zapisanych ofert do CSV i PDF.
class SavedOffersExportService {
  SavedOffersExportService._();

  static String _escapeCsv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  /// Generuje CSV z listy ofert. Encoding: UTF-8 with BOM dla Excel.
  static String buildCsv(List<({Property property, SavedOfferEntry entry})> items) {
    const sep = ';';
    final sb = StringBuffer();
    sb.write('\uFEFF'); // BOM UTF-8
    sb.writeln([
      'Nazwa',
      'Cena',
      'ROI %',
      'Powierzchnia m²',
      'Typ',
      'Miasto',
      'Zapisano',
      'Notatka',
    ].map(_escapeCsv).join(sep));
    for (final item in items) {
      final p = item.property;
      final e = item.entry;
      sb.writeln([
        p.title,
        p.formattedPrice,
        p.roi?.toStringAsFixed(1) ?? '',
        p.area.toStringAsFixed(0),
        p.propertyTypeLabel,
        p.city,
        _formatDate(e.savedAt),
        e.note ?? '',
      ].map(_escapeCsv).join(sep));
    }
    return sb.toString();
  }

  /// Udostępnia CSV (zapisz / wyślij). [filename] np. "zapisane_oferty.csv".
  static Future<void> shareCsv(
    List<({Property property, SavedOfferEntry entry})> items, {
    String filename = 'zapisane_oferty.csv',
  }) async {
    final csv = buildCsv(items);
    final bytes = utf8.encode(csv);
    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: filename, mimeType: 'text/csv')],
        text: 'Eksport zapisanych ofert ($filename)',
        subject: 'Zapisane oferty - BC Agencja',
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Eksport zapisanych ofert ($filename)',
      subject: 'Zapisane oferty - BC Agencja',
    );
  }

  /// Generuje PDF z listy ofert.
  static Future<pw.Document> buildPdf(
    List<({Property property, SavedOfferEntry entry})> items,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            'Zapisane oferty – BC Agencja',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        build: (ctx) => [
          pw.Table(
    border: pw.TableBorder.all(width: 0.5),
    columnWidths: {
      0: const pw.FlexColumnWidth(2.5),
      1: const pw.FlexColumnWidth(1),
      2: const pw.FlexColumnWidth(0.6),
      3: const pw.FlexColumnWidth(0.8),
      4: const pw.FlexColumnWidth(1.2),
      5: const pw.FlexColumnWidth(1),
      6: const pw.FlexColumnWidth(0.8),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _cell('Nazwa'),
          _cell('Cena'),
          _cell('ROI'),
          _cell('m²'),
          _cell('Typ'),
          _cell('Miasto'),
          _cell('Zapisano'),
        ],
      ),
      ...items.map((item) {
        final p = item.property;
        final e = item.entry;
        return pw.TableRow(
          children: [
            _cell(p.title, fontSize: 8),
            _cell(p.formattedPrice, fontSize: 8),
            _cell(p.roi != null ? '${p.roi!.toStringAsFixed(1)}%' : '–', fontSize: 8),
            _cell(p.area.toStringAsFixed(0), fontSize: 8),
            _cell(p.propertyTypeLabel, fontSize: 8),
            _cell(p.city, fontSize: 8),
            _cell(_formatDate(e.savedAt), fontSize: 8),
          ],
        );
      }),
    ],
          ),
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _cell(String text, {double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text.length > 50 ? '${text.substring(0, 50)}...' : text,
        style: pw.TextStyle(fontSize: fontSize),
      ),
    );
  }

  /// Zapisuje PDF i udostępnia (na web: XFile.fromData).
  static Future<void> sharePdf(
    List<({Property property, SavedOfferEntry entry})> items, {
    String filename = 'zapisane_oferty.pdf',
  }) async {
    final doc = await buildPdf(items);
    final bytes = await doc.save();
    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: filename, mimeType: 'application/pdf')],
        text: 'Eksport zapisanych ofert (PDF)',
        subject: 'Zapisane oferty - BC Agencja',
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Eksport zapisanych ofert (PDF)',
      subject: 'Zapisane oferty - BC Agencja',
    );
  }
}
