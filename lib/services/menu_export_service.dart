import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_menu_models.dart';

class MenuExportService {
  static const PdfColor _darkWood = PdfColor.fromInt(0xFF4A2C20);
  static const PdfColor _mediumWood = PdfColor.fromInt(0xFF8B5A2B);
  static const PdfColor _lightWood = PdfColor.fromInt(0xFFF3E2C1);
  static const PdfColor _parchment = PdfColor.fromInt(0xFFFFFBF0);
  static const PdfColor _mutedText = PdfColor.fromInt(0xFF6D5A4D);

  Future<Uint8List> buildMenuPdf(MenuHistoryEntry entry) async {
    final document = pw.Document(
      title: _menuName(entry),
      author: 'RipartoDaMe',
      creator: 'RipartoDaMe',
    );
    final info = entry.generationInfo;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 40),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique(),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 7),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _lightWood, width: 1),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      _menuName(entry),
                      style: const pw.TextStyle(
                        color: _darkWood,
                        fontSize: 9,
                      ),
                    ),
                    pw.Text(
                      'RipartoDaMe',
                      style: const pw.TextStyle(
                        color: _mediumWood,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Pagina ${context.pageNumber} di ${context.pagesCount}',
            style: const pw.TextStyle(color: _mutedText, fontSize: 8),
          ),
        ),
        build: (context) => [
          _buildCover(entry),
          pw.SizedBox(height: 18),
          ...entry.menu.expand(
            (day) => [
              _buildDay(day),
              pw.SizedBox(height: 12),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: _lightWood),
          pw.Text(
            'Generato da RipartoDaMe il ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(color: _mutedText, fontSize: 8),
          ),
          if (entry.modifiedAt != null)
            pw.Text(
              'Menu modificato manualmente il '
              '${_formatDate(entry.modifiedAt!)}.',
              style: pw.TextStyle(
                color: _mediumWood,
                fontSize: 8,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          if (info.dietDocumentName?.isNotEmpty == true)
            pw.Text(
              'Piano alimentare di riferimento: ${info.dietDocumentName}',
              style: const pw.TextStyle(color: _mutedText, fontSize: 8),
            ),
        ],
      ),
    );
    return document.save();
  }

  Future<Uint8List> buildShoppingPdf(
    List<ShoppingItemModel> items, {
    String? menuName,
  }) async {
    final document = pw.Document(
      title: 'Lista della spesa',
      author: 'RipartoDaMe',
    );
    final grouped = _groupShoppingItems(items);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(38),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Pagina ${context.pageNumber} di ${context.pagesCount}',
            style: const pw.TextStyle(color: _mutedText, fontSize: 8),
          ),
        ),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: _darkWood,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LISTA DELLA SPESA',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (menuName?.trim().isNotEmpty == true)
                  pw.Text(
                    menuName!.trim(),
                    style: const pw.TextStyle(
                      color: _lightWood,
                      fontSize: 11,
                    ),
                  ),
                pw.Text(
                  _formatDate(DateTime.now()),
                  style: const pw.TextStyle(
                    color: _lightWood,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          if (grouped.isEmpty)
            pw.Text('La lista della spesa e vuota.')
          else
            ...grouped.entries.expand(
              (group) => [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  color: _lightWood,
                  child: pw.Text(
                    group.key.toUpperCase(),
                    style: pw.TextStyle(
                      color: _darkWood,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                ...group.value.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('- ', style: const pw.TextStyle(fontSize: 10)),
                        pw.Expanded(
                          child: pw.Text(
                            '${item.name}: ${_formatQuantity(item.quantity, item.unit)}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              decoration: item.isChecked
                                  ? pw.TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
              ],
            ),
        ],
      ),
    );
    return document.save();
  }

  String buildShoppingText(
    List<ShoppingItemModel> items, {
    String? menuName,
  }) {
    final buffer = StringBuffer('LISTA DELLA SPESA\n');
    if (menuName?.trim().isNotEmpty == true) {
      buffer.writeln(menuName!.trim());
    }
    buffer.writeln(_formatDate(DateTime.now()));
    final grouped = _groupShoppingItems(items);
    for (final group in grouped.entries) {
      buffer.writeln('\n${group.key}');
      for (final item in group.value) {
        buffer.writeln(
          '- ${item.name}: ${_formatQuantity(item.quantity, item.unit)}',
        );
      }
    }
    return buffer.toString().trimRight();
  }

  Future<void> shareMenuPdf(MenuHistoryEntry entry) async {
    final bytes = await buildMenuPdf(entry);
    final file = await _writeTemporaryFile(
      bytes,
      '${_safeFileName(_menuName(entry))}.pdf',
    );
    await SharePlus.instance.share(
      ShareParams(
        subject: _menuName(entry),
        text: 'Menu settimanale esportato da RipartoDaMe.',
        files: [XFile(file.path, mimeType: 'application/pdf')],
      ),
    );
  }

  Future<void> saveMenuPdf(MenuHistoryEntry entry) async {
    final bytes = await buildMenuPdf(entry);
    final file = await _writeTemporaryFile(
      bytes,
      '${_safeFileName(_menuName(entry))}.pdf',
    );
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Salva ${_menuName(entry)}',
        text: 'Scegli File o un’altra destinazione per salvare il PDF.',
        files: [XFile(file.path, mimeType: 'application/pdf')],
      ),
    );
  }

  Future<void> printMenu(MenuHistoryEntry entry) async {
    final bytes = await buildMenuPdf(entry);
    await Printing.layoutPdf(
      name: '${_safeFileName(_menuName(entry))}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> shareShoppingText(
    List<ShoppingItemModel> items, {
    String? menuName,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Lista della spesa',
        text: buildShoppingText(items, menuName: menuName),
      ),
    );
  }

  Future<void> saveShoppingText(
    List<ShoppingItemModel> items, {
    String? menuName,
  }) async {
    final text = buildShoppingText(items, menuName: menuName);
    final file = await _writeTemporaryFile(
      Uint8List.fromList(utf8.encode(text)),
      'lista_della_spesa.txt',
    );
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Salva lista della spesa',
        text: 'Scegli File o un’altra destinazione per salvare la lista.',
        files: [XFile(file.path, mimeType: 'text/plain')],
      ),
    );
  }

  Future<void> printShoppingList(
    List<ShoppingItemModel> items, {
    String? menuName,
  }) async {
    final bytes = await buildShoppingPdf(items, menuName: menuName);
    await Printing.layoutPdf(
      name: 'lista_della_spesa.pdf',
      onLayout: (_) async => bytes,
    );
  }

  pw.Widget _buildCover(MenuHistoryEntry entry) {
    final info = entry.generationInfo;
    final details = <String>[
      if (info.targetCalories != null) '${info.targetCalories} kcal',
      if (info.dietStyle.trim().isNotEmpty) info.dietStyle.trim(),
    ];
    final constraints = <String>[
      if (info.halal) 'Halal',
      if (info.kosher) 'Kosher',
      if (info.excludedFoods.isNotEmpty)
        'Esclusi: ${info.excludedFoods.join(', ')}',
    ];
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _parchment,
        border: pw.Border.all(color: _mediumWood, width: 1.2),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            decoration: pw.BoxDecoration(
              color: _darkWood,
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Text(
              _menuName(entry),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Generato il ${_formatDate(info.generatedAt)}',
            style: const pw.TextStyle(color: _mutedText, fontSize: 10),
          ),
          if (details.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              details.join(' - '),
              style: pw.TextStyle(
                color: _darkWood,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
          if (constraints.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              constraints.join(' - '),
              style: const pw.TextStyle(color: _mutedText, fontSize: 10),
            ),
          ],
          if (entry.modifiedAt != null) ...[
            pw.SizedBox(height: 7),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              color: _lightWood,
              child: pw.Text(
                'Versione modificata manualmente il '
                '${_formatDate(entry.modifiedAt!)}',
                style: pw.TextStyle(
                  color: _darkWood,
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildDay(DailyMenuModel day) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _lightWood),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: const pw.BoxDecoration(
              color: _darkWood,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(7),
                topRight: pw.Radius.circular(7),
              ),
            ),
            child: pw.Text(
              day.dayName,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          ...day.meals.map(_buildMeal),
        ],
      ),
    );
  }

  pw.Widget _buildMeal(MenuMealModel meal) {
    final calorieLabel =
        meal.calories == null ? '' : ' (${_formatNumber(meal.calories!)} kcal)';
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _lightWood, width: 0.6),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${meal.mealType}$calorieLabel',
            style: pw.TextStyle(
              color: _mediumWood,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (meal.description.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              meal.description.trim(),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
          if (meal.ingredients.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              meal.ingredients
                  .map(
                    (item) =>
                        '${item.name} (${_formatNumber(item.quantity)} ${item.unit})',
                  )
                  .join(', '),
              style: const pw.TextStyle(color: _mutedText, fontSize: 8.5),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, List<ShoppingItemModel>> _groupShoppingItems(
    List<ShoppingItemModel> items,
  ) {
    final grouped = <String, List<ShoppingItemModel>>{};
    for (final item in items) {
      final category =
          item.category.trim().isEmpty ? 'Generale' : item.category.trim();
      grouped.putIfAbsent(category, () => []).add(item);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  Future<File> _writeTemporaryFile(Uint8List bytes, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File(path.join(directory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _menuName(MenuHistoryEntry entry) {
    final name = entry.customName?.trim();
    return name == null || name.isEmpty ? 'Menu della Settimana' : name;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatNumber(num value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  String _formatQuantity(double? quantity, String? unit) {
    if (quantity == null) {
      return unit?.trim().isNotEmpty == true ? unit!.trim() : '-';
    }
    final quantityText = _formatNumber(quantity);
    final unitText = unit?.trim() ?? '';
    return '$quantityText${unitText.isEmpty ? '' : ' $unitText'}';
  }

  String _safeFileName(String value) {
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'menu_settimanale' : cleaned;
  }
}
