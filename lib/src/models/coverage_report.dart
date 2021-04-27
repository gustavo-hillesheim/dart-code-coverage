import 'package:code_coverage/code_coverage.dart';
import 'package:code_coverage/src/models/file_coverage_report.dart';

/// Representation of a coverage report for a package.
/// This class contains a map of covered files and a list of all package files.
/// There are also some useful methods for calculating total line coverage percent, and also calculate file coverage percent.
///
/// [CoverageReport]s are created through a [CoverageReportFactory].
class CoverageReport {
  final Map<String, FileCoverageReport> coveredFiles;
  final List<String> packageFiles;

  CoverageReport({
    required this.coveredFiles,
    required this.packageFiles,
  });

  double calculateFileCoveragePercent() {
    return coveredFiles.length / packageFiles.length;
  }

  double calculateLineCoveragePercent() {
    final lineCoveragePercent =
        calculateTotalLinesCovered() / calculateTotalLines();
    return lineCoveragePercent.isNaN ? 0 : lineCoveragePercent;
  }

  int calculateTotalLinesCovered() {
    if (coveredFiles.isEmpty) {
      return 0;
    }

    return coveredFiles.values
        .map((fileReportDetails) => fileReportDetails.calculateLinesCovered())
        .reduce((totalLinesCovered, fileLinesCovered) =>
            totalLinesCovered + fileLinesCovered);
  }

  int calculateTotalLines() {
    if (coveredFiles.isEmpty) {
      return 0;
    }

    return coveredFiles.values
        .map((fileReportDetails) => fileReportDetails.totalLines)
        .reduce((totalLines, fileLines) => totalLines + fileLines);
  }

  List<String> getUncoveredFiles() {
    return packageFiles
        .where((file) => !coveredFiles.containsKey(file))
        .toList();
  }
}
