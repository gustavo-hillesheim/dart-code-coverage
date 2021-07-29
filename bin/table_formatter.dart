import 'table_builder.dart';
import 'utils.dart';
import 'package:code_coverage/src/models/coverage_report.dart';
import 'package:ansicolor/ansicolor.dart';

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
      fileName: 'All covered files',
      coveragePercent: report.calculateLineCoveragePercent(),
      uncoveredLines: '',
      colored: colored,
    );

    final filesNames = report.coveredFiles.keys.toList();
    filesNames.sort();
    filesNames.forEach((fileName) {
      final fileReport = report.coveredFiles[fileName]!;
      _addRow(
        tableBuilder,
        fileName: fileReport.fileName,
        coveragePercent: fileReport.calculateLineCoveragePercent(),
        uncoveredLines: summarizeLines(fileReport.getUncoveredLines()) + ' ',
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
    final pen = colored ? coveragePen(coveragePercent) : AnsiPen();
    tableBuilder.addRow([
      fileName,
      (coveragePercent * 100).toStringAsFixed(2),
      uncoveredLines,
    ], pen: pen);
  }
}
