import 'package:ansicolor/ansicolor.dart';

class _TableRowDefinition {
  final List<String> cells;
  final AnsiPen? pen;

  _TableRowDefinition({required this.cells, this.pen});
}

class TableBuilder {
  static const TOP_LEFT_CORNER = '┌';
  static const TOP_RIGHT_CORNER = '┐';
  static const BOTTOM_LEFT_CORNER = '└';
  static const BOTTOM_RIGHT_CORNER = '┘';
  static const HORIZONTAL_BAR = '─';
  static const VERTICAL_BAR = '│';
  static const LEFT_VERTICAL_DIVIDER = '├';
  static const RIGHT_VERTICAL_DIVIDER = '┤';
  static const TOP_HORIZONTAL_DIVIDER = '┬';
  static const BOTTOM_HORIZONTAL_DIVIDER = '┴';
  static const CENTER_DIVIDER = '┼';
  static const CELL_PADDING = 1;

  List<String> _headers = [];
  final List<_TableRowDefinition> _rows = [];

  TableBuilder setHeaders(List<String> headers) {
    _headers = headers;
    return this;
  }

  TableBuilder addRow(List<String> cells, {AnsiPen? pen}) {
    _rows.add(_TableRowDefinition(cells: cells, pen: pen));
    return this;
  }

  String build({required bool compact}) {
    final cellSizes = _calculateCellsSizes();
    var table = _buildHeaders(cellSizes);
    table += '\n' + _buildRows(cellSizes, compact: compact);
    return table;
  }

  List<int> _calculateCellsSizes() {
    final cellsSizes = _headers.map((header) => header.length).toList();
    _rows.forEach((row) {
      for (var i = 0; i < row.cells.length; i++) {
        final rowCell = row.cells[i];
        if (rowCell.length > cellsSizes[i]) {
          cellsSizes[i] = rowCell.length;
        }
      }
    });
    return cellsSizes;
  }

  String _buildHeaders(List<int> cellsSizes) {
    var headersStr = _buildRowDivider(cellsSizes, isFirst: true) + '\n';
    for (var i = 0; i < _headers.length; i++) {
      final isLast = i == _headers.length - 1;
      final cellSize = cellsSizes[i];
      final header = _addPaddingAndAlignment(
        _headers[i],
        cellSize: cellSize,
        alignment: CellAlignment.LEFT,
      );
      headersStr += VERTICAL_BAR + header;
      if (isLast) {
        headersStr += VERTICAL_BAR;
      }
    }
    headersStr += '\n' + _buildRowDivider(cellsSizes);
    return headersStr;
  }

  String _buildRows(List<int> cellsSizes, {required bool compact}) {
    var rowsStr = '';
    for (var i = 0; i < _rows.length; i++) {
      final isLastRow = i == _rows.length - 1;
      final row = _rows[i];
      final cells = row.cells;
      final pen = row.pen ?? AnsiPen();
      for (var ri = 0; ri < cells.length; ri++) {
        final isLastCell = ri == cells.length - 1;
        final cellSize = cellsSizes[ri];
        final cellValue = _addPaddingAndAlignment(
          cells[ri],
          cellSize: cellSize,
          alignment: _getCellAlignment(cells[ri]),
        );
        rowsStr += VERTICAL_BAR + pen(cellValue);
        if (isLastCell) {
          rowsStr += VERTICAL_BAR;
        }
      }
      if (!compact || isLastRow) {
        rowsStr += '\n' + _buildRowDivider(cellsSizes, isLast: isLastRow);
      }
      if (!isLastRow) {
        rowsStr += '\n';
      }
    }
    return rowsStr;
  }

  CellAlignment _getCellAlignment(String cellValue) {
    final isNumber =
        int.tryParse(cellValue) != null || double.tryParse(cellValue) != null;
    if (isNumber) {
      return CellAlignment.RIGHT;
    }
    return CellAlignment.LEFT;
  }

  String _buildRowDivider(
    List<int> cellsSizes, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    var divider = _getRowDividerLeftCorner(isFirst: isFirst, isLast: isLast);
    for (var i = 0; i < cellsSizes.length; i++) {
      final isLastCell = i == cellsSizes.length - 1;
      final cellSize = cellsSizes[i];
      final cellCover = HORIZONTAL_BAR * (cellSize + CELL_PADDING * 2);
      divider += cellCover;
      if (!isLastCell) {
        divider += _getCellDivider(isFirst: isFirst, isLast: isLast);
      }
    }
    divider += _getRowDividerRightCorner(isFirst: isFirst, isLast: isLast);
    return divider;
  }

  String _getRowDividerLeftCorner({bool isFirst = false, bool isLast = false}) {
    if (isFirst) {
      return TOP_LEFT_CORNER;
    }
    if (isLast) {
      return BOTTOM_LEFT_CORNER;
    }
    return LEFT_VERTICAL_DIVIDER;
  }

  String _getRowDividerRightCorner(
      {bool isFirst = false, bool isLast = false}) {
    if (isFirst) {
      return TOP_RIGHT_CORNER;
    }
    if (isLast) {
      return BOTTOM_RIGHT_CORNER;
    }
    return RIGHT_VERTICAL_DIVIDER;
  }

  String _getCellDivider({bool isFirst = false, bool isLast = false}) {
    if (isFirst) {
      return TOP_HORIZONTAL_DIVIDER;
    }
    if (isLast) {
      return BOTTOM_HORIZONTAL_DIVIDER;
    }
    return CENTER_DIVIDER;
  }

  String _addPaddingAndAlignment(
    String value, {
    required int cellSize,
    CellAlignment alignment = CellAlignment.RIGHT,
  }) {
    final leftEmptySpaceSize = CELL_PADDING +
        (alignment == CellAlignment.RIGHT ? cellSize - value.length : 0);
    final rightEmptySpaceSize = CELL_PADDING +
        (alignment == CellAlignment.LEFT ? cellSize - value.length : 0);
    return (' ' * leftEmptySpaceSize) + value + (' ' * rightEmptySpaceSize);
  }
}

enum CellAlignment { LEFT, RIGHT }
