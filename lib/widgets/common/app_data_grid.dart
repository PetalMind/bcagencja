import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API types
// ─────────────────────────────────────────────────────────────────────────────

/// Tryb zaznaczania wierszy w [AppDataGrid].
enum AppGridSelectionMode {
  /// Zaznaczanie wyłączone.
  none,

  /// Można zaznaczyć jeden wiersz naraz.
  single,

  /// Można zaznaczyć wiele wierszy (Ctrl/Shift na desktopie, tap na mobile).
  multiple,
}

/// Definicja kolumny w [AppDataGrid].
class AppDataGridColumn {
  const AppDataGridColumn({
    required this.name,
    required this.label,
    this.width,
    this.minimumWidth = 80,
    this.alignment = Alignment.centerLeft,
    this.sortable = true,
  });

  /// Unikalny identyfikator kolumny używany wewnętrznie.
  final String name;

  /// Tekst wyświetlany w nagłówku.
  final String label;

  /// Stała szerokość w pikselach. Jeśli `null`, kolumna wypełnia dostępną przestrzeń.
  final double? width;

  /// Minimalna szerokość (stosowana przy zmianie rozmiaru).
  final double minimumWidth;

  /// Wyrównanie zawartości komórki nagłówka.
  final Alignment alignment;

  /// Czy nagłówek tej kolumny umożliwia sortowanie.
  /// Działa wyłącznie gdy [AppDataGrid.allowSorting] jest `true`.
  final bool sortable;
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal DataGridSource
// ─────────────────────────────────────────────────────────────────────────────

class _WidgetGridSource extends DataGridSource {
  _WidgetGridSource({
    required List<List<Widget>> rows,
    required List<String> columnNames,
    List<List<dynamic>>? sortValues,
    int pageSize = 0,
  }) : _pageSize = pageSize {
    _refresh(rows, columnNames, sortValues);
  }

  List<String> _columnNames = [];
  List<DataGridRow> _originalDataRows = [];

  /// Macierz wartości używanych wyłącznie do porównywania przy sortowaniu.
  /// Indeks [i][j] odpowiada wierszowi i, kolumnie j.
  List<List<dynamic>> _sortValueMatrix = [];

  /// Wiersze po ewentualnym posortowaniu – z tej listy pobierana jest bieżąca strona.
  List<DataGridRow> _displayRows = [];

  /// Mapowanie DataGridRow → indeks w oryginalnej liście (przed sortowaniem).
  final Map<DataGridRow, int> _rowToOriginalIndex = {};

  int _pageSize;
  int _currentPage = 0;

  int get totalRowCount => _originalDataRows.length;

  void _refresh(
    List<List<Widget>> rows,
    List<String> columnNames,
    List<List<dynamic>>? sortValues,
  ) {
    _columnNames = columnNames;
    _rowToOriginalIndex.clear();

    _originalDataRows = List.generate(rows.length, (i) {
      final cells = rows[i];
      final row = DataGridRow(
        cells: List.generate(
          columnNames.length,
          (j) => DataGridCell<Widget>(
            columnName: columnNames[j],
            value: j < cells.length ? cells[j] : const SizedBox.shrink(),
          ),
        ),
      );
      _rowToOriginalIndex[row] = i;
      return row;
    });

    _sortValueMatrix = List.generate(rows.length, (i) {
      if (sortValues != null && i < sortValues.length) return sortValues[i];
      return List<dynamic>.filled(columnNames.length, '');
    });

    _displayRows = List.from(_originalDataRows);
    _currentPage = 0;
    notifyListeners();
  }

  /// Wiersze widoczne na bieżącej stronie (lub wszystkie, gdy paginacja jest wyłączona).
  @override
  List<DataGridRow> get rows {
    if (_pageSize > 0) {
      final start = _currentPage * _pageSize;
      if (start >= _displayRows.length) return [];
      final end = (start + _pageSize).clamp(0, _displayRows.length);
      return _displayRows.sublist(start, end);
    }
    return _displayRows;
  }

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: cell.value as Widget,
          ),
        );
      }).toList(),
    );
  }

  /// Sortowanie po kliknięciu nagłówka kolumny.
  /// Używa wartości z [_sortValueMatrix] zamiast wartości widgetów.
  @override
  Future<void> performSorting(List<DataGridRow> rows) async {
    if (sortedColumns.isEmpty) {
      _displayRows = List.from(_originalDataRows);
      return;
    }

    final sortedIndices = List.generate(_originalDataRows.length, (i) => i);

    // Aplikuj sortowanie w odwrotnej kolejności, żeby zachować priorytety
    for (final sortCol in sortedColumns.reversed) {
      final colIdx = _columnNames.indexOf(sortCol.name);
      if (colIdx < 0) continue;

      sortedIndices.sort((a, b) {
        final aVal = colIdx < _sortValueMatrix[a].length ? _sortValueMatrix[a][colIdx] : '';
        final bVal = colIdx < _sortValueMatrix[b].length ? _sortValueMatrix[b][colIdx] : '';
        final cmp = _compareValues(aVal, bVal);
        return sortCol.sortDirection == DataGridSortDirection.descending ? -cmp : cmp;
      });
    }

    _displayRows = sortedIndices.map((i) => _originalDataRows[i]).toList();
  }

  int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is num && b is num) return a.compareTo(b);
    if (a is DateTime && b is DateTime) return a.compareTo(b);
    return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
  }

  /// Wywoływane przez [SfDataPager] przy zmianie strony.
  @override
  Future<bool> handlePageChange(int oldPageIndex, int newPageIndex) async {
    _currentPage = newPageIndex;
    notifyListeners();
    return true;
  }

  /// Konwertuje zaznaczone [DataGridRow] na indeksy w oryginalnej liście [rows].
  List<int> selectedOriginalIndices(List<DataGridRow> selectedRows) {
    return selectedRows
        .map((row) => _rowToOriginalIndex[row])
        .whereType<int>()
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppDataGrid widget
// ─────────────────────────────────────────────────────────────────────────────

/// Reużywalny widget tabeli oparty na [SfDataGrid] ze spójnym stylem aplikacji.
///
/// **Funkcjonalności:**
/// - Sortowanie kolumn (klik nagłówka) z opcją multi-column sort
/// - Zmiana szerokości kolumn przeciąganiem
/// - Zaznaczanie wierszy (single / multiple)
/// - Paginacja z kontrolką [SfDataPager]
///
/// **Sortowanie** wymaga przekazania [sortValues] – listy wartości równoległej
/// do [rows], używanej wyłącznie do porównywania (widgety nie są porównywalne).
///
/// ```dart
/// AppDataGrid(
///   allowSorting: true,
///   allowColumnsResizing: true,
///   selectionMode: AppGridSelectionMode.multiple,
///   onSelectionChanged: (indices) => print('Zaznaczono: $indices'),
///   showPagination: true,
///   pageSize: 25,
///   columns: [
///     AppDataGridColumn(name: 'name', label: 'Nazwa'),
///     AppDataGridColumn(name: 'price', label: 'Cena', width: 120),
///   ],
///   sortValues: items.map((e) => [e.name, e.price]).toList(),
///   rows: items.map((e) => [Text(e.name), Text(e.formattedPrice)]).toList(),
/// )
/// ```
class AppDataGrid extends StatefulWidget {
  const AppDataGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.sortValues,
    this.rowHeight = 56,
    this.headerRowHeight = 44,
    this.shrinkWrapRows = true,
    this.allowSorting = false,
    this.allowMultiColumnSorting = false,
    this.allowColumnsResizing = false,
    this.selectionMode = AppGridSelectionMode.none,
    this.onSelectionChanged,
    this.showPagination = false,
    this.pageSize = 20,
  });

  /// Definicje kolumn (nagłówki, szerokości, sortowanie).
  final List<AppDataGridColumn> columns;

  /// Wiersze danych – każdy wiersz to lista widgetów odpowiadających kolumnom.
  final List<List<Widget>> rows;

  /// Wartości używane do sortowania – równoległe do [rows].
  ///
  /// Format: `[[wiersz0_kol0, wiersz0_kol1, ...], [wiersz1_kol0, ...], ...]`
  ///
  /// Obsługiwane typy: [num], [DateTime], [String] (reszta rzutowana na String).
  /// Bez tego parametru kliknięcie nagłówka nie zmienia kolejności wierszy.
  final List<List<dynamic>>? sortValues;

  /// Wysokość wiersza danych w pikselach.
  final double rowHeight;

  /// Wysokość wiersza nagłówkowego w pikselach.
  final double headerRowHeight;

  /// Czy wysokość siatki ma dopasować się do zawartości.
  /// Ustaw `false` gdy widget jest bezpośrednio w [Expanded].
  final bool shrinkWrapRows;

  /// Włącza sortowanie po kliknięciu nagłówka kolumny.
  final bool allowSorting;

  /// Zezwala na sortowanie po wielu kolumnach jednocześnie (Ctrl+klik).
  final bool allowMultiColumnSorting;

  /// Włącza zmianę szerokości kolumn przez przeciąganie prawego brzegu nagłówka.
  final bool allowColumnsResizing;

  /// Tryb zaznaczania wierszy.
  final AppGridSelectionMode selectionMode;

  /// Callback wywoływany po zmianie zaznaczenia.
  ///
  /// Zwraca listę indeksów zaznaczonych wierszy w **oryginalnej** liście [rows]
  /// (niezależnie od aktualnego sortowania).
  final void Function(List<int> selectedIndices)? onSelectionChanged;

  /// Włącza kontrolkę [SfDataPager] pod tabelą.
  final bool showPagination;

  /// Liczba wierszy wyświetlanych na jednej stronie (aktywna gdy [showPagination]).
  final int pageSize;

  @override
  State<AppDataGrid> createState() => _AppDataGridState();
}

class _AppDataGridState extends State<AppDataGrid> {
  late _WidgetGridSource _source;
  final DataGridController _controller = DataGridController();

  List<String> get _columnNames => widget.columns.map((c) => c.name).toList();

  SelectionMode get _sfSelectionMode => switch (widget.selectionMode) {
        AppGridSelectionMode.single => SelectionMode.single,
        AppGridSelectionMode.multiple => SelectionMode.multiple,
        AppGridSelectionMode.none => SelectionMode.none,
      };

  @override
  void initState() {
    super.initState();
    _source = _WidgetGridSource(
      rows: widget.rows,
      columnNames: _columnNames,
      sortValues: widget.sortValues,
      pageSize: widget.showPagination ? widget.pageSize : 0,
    );
  }

  @override
  void didUpdateWidget(AppDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dataChanged = widget.rows != oldWidget.rows ||
        widget.columns != oldWidget.columns ||
        widget.sortValues != oldWidget.sortValues;
    final pagerChanged = widget.pageSize != oldWidget.pageSize ||
        widget.showPagination != oldWidget.showPagination;

    if (dataChanged || pagerChanged) {
      _source._pageSize = widget.showPagination ? widget.pageSize : 0;
      _source._refresh(widget.rows, _columnNames, widget.sortValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataGrid = SfDataGridTheme(
      data: SfDataGridThemeData(
        headerColor: AppColors.grey50,
        gridLineColor: AppColors.borderLight,
        gridLineStrokeWidth: 1,
        rowHoverColor: AppColors.grey100,
        selectionColor: AppColors.accent.withValues(alpha: 0.1),
        sortIconColor: AppColors.textSecondary,
        headerHoverColor: AppColors.grey100,
      ),
      child: SfDataGrid(
        source: _source,
        controller: _controller,
        rowHeight: widget.rowHeight,
        headerRowHeight: widget.headerRowHeight,
        shrinkWrapRows: widget.shrinkWrapRows,
        gridLinesVisibility: GridLinesVisibility.horizontal,
        headerGridLinesVisibility: GridLinesVisibility.horizontal,
        columnWidthMode: ColumnWidthMode.fill,
        // Sortowanie
        allowSorting: widget.allowSorting,
        allowMultiColumnSorting: widget.allowMultiColumnSorting,
        // Zmiana szerokości kolumn
        allowColumnsResizing: widget.allowColumnsResizing,
        onColumnResizeUpdate: widget.allowColumnsResizing
            ? (ColumnResizeUpdateDetails details) => true
            : null,
        // Zaznaczanie wierszy
        selectionMode: _sfSelectionMode,
        onSelectionChanged: widget.onSelectionChanged != null
            ? (List<DataGridRow> addedRows, List<DataGridRow> removedRows) {
                widget.onSelectionChanged!(
                  _source.selectedOriginalIndices(_controller.selectedRows),
                );
              }
            : null,
        columns: widget.columns.map((col) {
          return GridColumn(
            columnName: col.name,
            minimumWidth: col.minimumWidth,
            width: col.width ?? double.nan,
            allowSorting: widget.allowSorting && col.sortable,
            label: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: col.alignment,
              child: Text(
                col.label,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (!widget.showPagination) return dataGrid;

    final pageCount = widget.rows.isEmpty
        ? 1.0
        : (widget.rows.length / widget.pageSize).ceil().toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dataGrid,
        SfDataPagerTheme(
          data: SfDataPagerThemeData(
            itemColor: AppColors.white,
            selectedItemColor: AppColors.accent,
            itemBorderColor: AppColors.borderLight,
            backgroundColor: AppColors.grey50,
            itemTextStyle: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            selectedItemTextStyle: AppTextStyles.labelMedium.copyWith(
              color: AppColors.white,
            ),
          ),
          child: SfDataPager(
            delegate: _source,
            pageCount: pageCount,
            direction: Axis.horizontal,
          ),
        ),
      ],
    );
  }
}
