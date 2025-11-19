import 'dart:math';

import 'package:code_coverage/code_coverage.dart';
import 'package:path/path.dart' as path;
import 'package:cli_table/cli_table.dart';

import 'utils.dart';

class TableFormatter {
  String format(
    CoverageReport report, {
    bool inlineFiles = false,
    bool excludeFullyCovered = false,
    required int maxWidth,
  }) {
    const headers = [
      'File',
      'File Cov. %',
      'Total Cov. %',
      'LOC %',
      'Uncovered Lines'
    ];
    final formatter =
        inlineFiles ? _InlineReportFormatter() : _TreeReportFormatter();

    final tableContent = formatter.formatLines(report);
    tableContent.add((
      fileName: 'All covered files',
      coveragePercent: report.calculateLineCoveragePercent(),
      percentOfTotalCoverage: report.calculateLineCoveragePercent(),
      percentOfTotalLines: 1,
      uncoveredLines: '',
    ));

    final columnWidths = _calculateColumnWidths(
      maxWidth: maxWidth,
      headers: headers,
      tableContent: tableContent,
    );

    final table = Table(
      header: headers,
      columnWidths: columnWidths,
      columnAlignment: [
        HorizontalAlign.left,
        HorizontalAlign.right,
        HorizontalAlign.right,
        HorizontalAlign.right,
        HorizontalAlign.left,
      ],
      wordWrap: true,
      style: TableStyle(header: []),
    );
    for (final line in tableContent) {
      final pen = coveragePen(line.coveragePercent);
      final isFullyCovered = line.coveragePercent >= 1.0;
      if (excludeFullyCovered && isFullyCovered) {
        continue;
      }
      table.add(
        [
          pen(line.fileName),
          pen(line.formattedCoveragePercent),
          pen(line.formattedPercentOfTotalCoverage),
          pen(line.formattedPercentOfTotalLines),
          pen(line.uncoveredLines),
        ],
      );
    }

    return table.toString();
  }

  List<int> _calculateColumnWidths({
    required int maxWidth,
    required List<String> headers,
    required List<TableLine> tableContent,
  }) {
    const columnPadding = 2;
    const safeSpacing = 20;
    maxWidth -= safeSpacing;
    int fileNameColumnWidth = headers[0].length;
    int coverageColumnWidth = headers[1].length;
    int totalCoverageColumnWidth = headers[2].length;
    int locColumnWidth = headers[3].length;
    int uncoveredLinesColumnWidth = headers[4].length;
    for (final line in tableContent) {
      fileNameColumnWidth = max(fileNameColumnWidth, line.fileName.length);
      coverageColumnWidth =
          max(coverageColumnWidth, line.formattedCoveragePercent.length);
      totalCoverageColumnWidth = max(totalCoverageColumnWidth,
          line.formattedPercentOfTotalCoverage.length);
      locColumnWidth =
          max(locColumnWidth, line.formattedPercentOfTotalLines.length);
      uncoveredLinesColumnWidth =
          max(uncoveredLinesColumnWidth, line.uncoveredLines.length);
    }
    int availableExpandableWidth = maxWidth -
        coverageColumnWidth -
        totalCoverageColumnWidth -
        locColumnWidth -
        columnPadding * 4;
    final maxExpandableColumnsWidth = availableExpandableWidth ~/ 2;
    fileNameColumnWidth = min(fileNameColumnWidth, maxExpandableColumnsWidth);
    uncoveredLinesColumnWidth = min(
      uncoveredLinesColumnWidth,
      availableExpandableWidth - fileNameColumnWidth,
    );
    return [
      fileNameColumnWidth + columnPadding,
      coverageColumnWidth + columnPadding,
      totalCoverageColumnWidth + columnPadding,
      locColumnWidth + columnPadding,
      uncoveredLinesColumnWidth + columnPadding,
    ];
  }
}

abstract class _ReportFormatter {
  List<TableLine> formatLines(CoverageReport report);
}

class _InlineReportFormatter implements _ReportFormatter {
  const _InlineReportFormatter();

  List<TableLine> formatLines(CoverageReport report) {
    final filesNames = report.coveredFiles.keys.toList();
    final totalLines = report.calculateTotalLines();
    filesNames.sort();
    return filesNames.map((fileName) {
      final fileReport = report.coveredFiles[fileName]!;
      final fileLines = fileReport.totalLines;
      final coveredLines = fileReport.calculateLinesCovered();
      return (
        fileName: fileReport.fileName,
        coveragePercent: coveredLines / fileLines,
        percentOfTotalCoverage: coveredLines / totalLines,
        percentOfTotalLines: fileLines / totalLines,
        uncoveredLines: summarizeLines(fileReport.getUncoveredLines()),
      );
    }).toList();
  }
}

class _TreeReportFormatter implements _ReportFormatter {
  const _TreeReportFormatter();

  List<TableLine> formatLines(CoverageReport report) {
    final result = <TableLine>[];
    final totalLines = report.calculateTotalLines();
    void addNodeToResult(FileTreeNode node, int spacing) {
      final leftSpacing = '  ' * spacing;
      final fileLines = node.totalLineCount;
      final coveredLines = node.coveredLineCount;
      result.add((
        fileName: '$leftSpacing ${node.name}',
        coveragePercent: node.calculateLineCoveragePercent(),
        percentOfTotalCoverage: coveredLines / totalLines,
        percentOfTotalLines: fileLines / totalLines,
        uncoveredLines: node.uncoveredLines,
      ));
      node.children.forEach((node) => addNodeToResult(node, spacing + 1));
    }

    _createFileTree(report.coveredFiles)
        .forEach((node) => addNodeToResult(node, 0));
    return result;
  }

  List<FileTreeNode> _createFileTree(
    Map<String, FileCoverageReport> coverageReport,
  ) {
    final nodes = <FileTreeNode>[];
    final coverageTree = _createCoverageTree(coverageReport);
    for (final entry in coverageTree.entries) {
      nodes.add(_createFileTreeNode(entry.key, entry.value));
    }
    return nodes;
  }

  Map<String, dynamic> _createCoverageTree(
    Map<String, FileCoverageReport> coverageReport,
  ) {
    final tree = <String, dynamic>{};
    final files = coverageReport.keys.toList()..sort((a, b) => a.compareTo(b));
    for (final file in files) {
      final fileName = path.basename(file);
      var parentNode = tree;
      if (!file.contains(path.separator)) {
        parentNode[fileName] = coverageReport[file];
        continue;
      }
      final dirPath = path.dirname(file).split(path.separator);
      for (var i = 0; i < dirPath.length; i++) {
        final isLast = i == dirPath.length - 1;
        final dir = dirPath[i];
        parentNode.putIfAbsent(dir, () => <String, dynamic>{});
        parentNode = parentNode[dir];
        if (isLast) {
          parentNode[fileName] = coverageReport[file];
        }
      }
    }
    return tree;
  }

  FileTreeNode _createFileTreeNode(String name, dynamic value) {
    var coveredLineCount = 0;
    var totalLineCount = 0;
    var uncoveredLines = '';
    var children = <FileTreeNode>[];
    if (value is FileCoverageReport) {
      coveredLineCount = value.calculateLinesCovered();
      totalLineCount = value.totalLines;
      uncoveredLines = summarizeLines(value.getUncoveredLines());
    }
    if (value is Map<String, dynamic>) {
      children = value.entries
          .map((e) => _createFileTreeNode(e.key, e.value))
          .toList();
      coveredLineCount =
          children.map((c) => c.coveredLineCount).fold(0, (v1, v2) => v1 + v2);
      totalLineCount =
          children.map((c) => c.totalLineCount).fold(0, (v1, v2) => v1 + v2);
    }
    return FileTreeNode(
      name: name,
      coveredLineCount: coveredLineCount,
      totalLineCount: totalLineCount,
      uncoveredLines: uncoveredLines,
      children: children,
    );
  }
}

typedef TableLine = ({
  String fileName,
  double coveragePercent,
  double percentOfTotalCoverage,
  double percentOfTotalLines,
  String uncoveredLines,
});

extension on TableLine {
  String get formattedCoveragePercent =>
      (coveragePercent * 100).toStringAsFixed(2);

  String get formattedPercentOfTotalCoverage =>
      (percentOfTotalCoverage * 100).toStringAsFixed(2);

  String get formattedPercentOfTotalLines =>
      (percentOfTotalLines * 100).toStringAsFixed(2);
}

class FileTreeNode {
  final String name;
  final int coveredLineCount;
  final int totalLineCount;
  final String uncoveredLines;
  final List<FileTreeNode> children;

  FileTreeNode({
    required this.name,
    required this.coveredLineCount,
    required this.totalLineCount,
    required this.uncoveredLines,
    required this.children,
  });

  double calculateLineCoveragePercent() {
    return coveredLineCount / totalLineCount;
  }
}
