import 'package:code_coverage/code_coverage.dart';
import 'package:code_coverage/src/models/coverage_report.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:path/path.dart' as path;

import 'table_builder.dart';
import 'utils.dart';

class TableFormatter {
  String format(
    CoverageReport report, {
    bool colored = true,
    bool compact = true,
    bool inlineFiles = false,
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

    if (inlineFiles) {
      _printInlineFiles(tableBuilder, report, colored);
    } else {
      _printFileTree(tableBuilder, report, colored);
    }

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
      TableCell(fileName),
      TableCell((coveragePercent * 100).toStringAsFixed(2),
          alignment: CellAlignment.RIGHT),
      TableCell(uncoveredLines),
    ], pen: pen);
  }

  void _printInlineFiles(
    TableBuilder tableBuilder,
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
    TableBuilder tableBuilder,
    CoverageReport report,
    bool colored,
  ) {
    void printNode(FileTreeNode node, int spacing) {
      final tab = '  ' * spacing;
      _addRow(
        tableBuilder,
        fileName: '$tab ${node.name}',
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
    return _simplifyCoverageTree(tree);
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
