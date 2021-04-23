import 'package:code_coverage/models/file_coverage_report.dart';

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
}
