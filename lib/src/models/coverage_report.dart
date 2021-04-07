import 'package:code_coverage/src/models/file_coverage_report.dart';

class CoverageReport {
  final Map<String, FileCoverageReport> files;

  CoverageReport({
    required this.files,
  });

  double calculateLineCoveragePercent() {
    final lineCoveragePercent =
        calculateTotalLinesCovered() / calculateTotalLines();
    return lineCoveragePercent.isNaN ? 0 : lineCoveragePercent;
  }

  int calculateTotalLinesCovered() {
    if (files.isEmpty) {
      return 0;
    }

    return files.values
        .map((fileReportDetails) => fileReportDetails.calculateLinesCovered())
        .reduce((totalLinesCovered, fileLinesCovered) =>
            totalLinesCovered + fileLinesCovered);
  }

  int calculateTotalLines() {
    if (files.isEmpty) {
      return 0;
    }

    return files.values
        .map((fileReportDetails) => fileReportDetails.totalLines)
        .reduce((totalLines, fileLines) => totalLines + fileLines);
  }
}
