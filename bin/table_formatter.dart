import 'dart:math';

import 'package:code_coverage/code_coverage.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:path/path.dart' as path;
import 'package:cli_table/cli_table.dart';

import 'utils.dart';

const fileHeader = 'File';
const coverageHeader = 'Coverage %';
const uncoveredLinesHeader = 'Uncovered Lines';
const allCoveredFilesText = 'All covered files';

class TableFormatter {
  String format(
    CoverageReport report, {
    bool colored = true,
    bool compact = true,
    bool inlineFiles = false,
    required int maxWidth,
  }) {
    final table = Table(
      header: [fileHeader, coverageHeader, uncoveredLinesHeader],
      columnWidths: _calculateColumnWidths(report, maxWidth, inlineFiles),
      columnAlignment: [
        HorizontalAlign.left,
        HorizontalAlign.right,
        HorizontalAlign.left,
      ],
      wordWrap: true,
    );
    _addRow(
      table,
      fileName: allCoveredFilesText,
      coveragePercent: report.calculateLineCoveragePercent(),
      uncoveredLines: '',
      colored: colored,
    );

    if (inlineFiles) {
      _printInlineFiles(table, report, colored);
    } else {
      _printFileTree(table, report, colored);
    }

    return table.toString();
  }

  List<int> _calculateColumnWidths(
    CoverageReport report,
    int maxWidth,
    bool inlineFiles,
  ) {
    const columnPadding = 2;
    const safeSpacing = 20;
    maxWidth -= safeSpacing;
    const coverageColumnWidth = coverageHeader.length;
    final availableWidth = maxWidth - coverageColumnWidth;
    final longestFileText = _calculateLongestFileText(report, inlineFiles);
    final fileColumnWidth = min(longestFileText, availableWidth ~/ 2);
    final longestUncoveredLinesText = _calculateLongestUncoveredLinesText(
      report,
    );
    final uncoveredLinesColumnWidth = min(
      longestUncoveredLinesText,
      availableWidth - fileColumnWidth,
    );
    return [
      max(allCoveredFilesText.length, fileColumnWidth) + columnPadding,
      coverageColumnWidth + columnPadding,
      max(uncoveredLinesHeader.length, uncoveredLinesColumnWidth) +
          columnPadding,
    ];
  }

  int _calculateLongestFileText(CoverageReport report, bool inlineFiles) {
    if (inlineFiles) {
      return report.coveredFiles.values
          .map((r) => r.fileName.length)
          .fold<int>(0, max);
    } else {
      return report.coveredFiles.keys.map((fileName) {
        // print(fileName);
        final pathSegments = fileName.split(path.separator);
        final depthLevel = pathSegments.length - 1;
        final baseName = path.basename(fileName);
        final fileText = '${tab * depthLevel} $baseName';
        // print('$fileText |');
        return fileText.length;
      }).fold<int>(0, max);
    }
  }

  int _calculateLongestUncoveredLinesText(CoverageReport report) {
    return report.coveredFiles.values
        .map((r) => summarizeLines(r.getUncoveredLines()).length)
        .fold<int>(0, max);
  }

  void _addRow(
    Table tableBuilder, {
    required String fileName,
    required double coveragePercent,
    required String uncoveredLines,
    required bool colored,
  }) {
    final pen = colored ? coveragePen(coveragePercent) : AnsiPen();
    tableBuilder.add(
      [
        pen(fileName),
        pen((coveragePercent * 100).toStringAsFixed(2)),
        pen(uncoveredLines),
      ],
    );
  }

  void _printInlineFiles(
    Table tableBuilder,
    CoverageReport report,
    bool colored,
  ) {
    final filesNames = report.coveredFiles.keys.toList();
    filesNames.sort();
    filesNames.forEach((fileName) {
      final fileReport = report.coveredFiles[fileName]!;
      _addRow(
        tableBuilder,
        fileName: fileReport.fileName,
        coveragePercent: fileReport.calculateLineCoveragePercent(),
        uncoveredLines: summarizeLines(fileReport.getUncoveredLines()),
        colored: colored,
      );
    });
  }

  void _printFileTree(
    Table tableBuilder,
    CoverageReport report,
    bool colored,
  ) {
    void printNode(FileTreeNode node, int spacing) {
      final leftSpacing = tab * spacing;
      _addRow(
        tableBuilder,
        fileName: '$leftSpacing ${node.name}',
        coveragePercent: node.calculateLineCoveragePercent(),
        uncoveredLines: node.uncoveredLines,
        colored: colored,
      );
      node.children.forEach((node) => printNode(node, spacing + 1));
    }

    _createFileTree(report.coveredFiles).forEach((node) => printNode(node, 0));
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

  Map<String, dynamic> _simplifyCoverageTree(
    Map<String, dynamic> coverageTree,
  ) {
    final keys = coverageTree.keys.toList();
    for (var key in keys) {
      final value = coverageTree[key];
      if (value is Map) {
        coverageTree[key] = _simplifyCoverageTree(coverageTree[key]);
        if (value.length == 1) {
          coverageTree.remove(key);
          final childEntry = value.entries.first;
          key = key + path.separator + childEntry.key;
          coverageTree[key] = childEntry.value;
        }
      }
    }
    return coverageTree;
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

const tab = '  ';

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
