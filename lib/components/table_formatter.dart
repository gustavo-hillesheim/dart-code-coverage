import 'package:code_coverage/components/table_builder.dart';
import 'package:code_coverage/models/coverage_report.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:code_coverage/utils.dart';

class TableFormatter {
  String format(
    CoverageReport report, {
    bool colored = true,
    bool compact = true,
  }) {
    final tableBuilder =
        TableBuilder().setHeaders(['File', 'Coverage %', 'Uncovered Lines']);
    _addRow(
      tableBuilder,
      fileName: 'All files',
      coveragePercent: report.calculateLineCoveragePercent(),
      uncoveredLines: '',
      colored: colored,
    );

    report.files.values.forEach((fileReport) {
      _addRow(
        tableBuilder,
        fileName: fileReport.fileName,
        coveragePercent: fileReport.calculateLineCoveragePercent(),
        uncoveredLines: summarizeLines(fileReport.getUncoveredLines()),
        colored: colored,
      );
    });

    return tableBuilder.build(compact: compact);
  }

  void _addRow(
    TableBuilder tableBuilder, {
    required String fileName,
    required double coveragePercent,
    required String uncoveredLines,
    required bool colored,
  }) {
    final pen =
        colored ? _createPen(coveragePercent: coveragePercent) : AnsiPen();
    tableBuilder.addRow([
      fileName,
      (coveragePercent * 100).toStringAsFixed(2),
      uncoveredLines,
    ], pen: pen);
  }

  AnsiPen _createPen({required double coveragePercent}) {
    if (coveragePercent < .6) {
      return AnsiPen()..red();
    } else if (coveragePercent < .8) {
      return AnsiPen()..yellow();
    } else {
      return AnsiPen()..green();
    }
  }
}
