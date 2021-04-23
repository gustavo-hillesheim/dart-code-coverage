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
      fileName: 'All covered files',
      coveragePercent: report.calculateLineCoveragePercent(),
      uncoveredLines: '',
      colored: colored,
    );

    report.coveredFiles.values.forEach((fileReport) {
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
