import 'package:code_coverage/src/models/coverage_report.dart';
import 'package:code_coverage/src/models/file_coverage_report.dart';

class CoverageReportFactory {
  CoverageReport fromHitmap(
    Map<String, Map<int, int>> hitmap, {
    List<String>? onlyPackages,
  }) {
    return CoverageReport(
      files: _extractFilesReportDetails(hitmap),
    );
  }

  Map<String, FileCoverageReport> _extractFilesReportDetails(
      Map<String, Map<int, int>> hitmap) {
    final filesReportDetails = <String, FileCoverageReport>{};

    for (final fileName in hitmap.keys) {
      filesReportDetails[fileName] = FileCoverageReport(
        fileName: fileName,
        linesCoverage: hitmap[fileName]!,
      );
    }

    return filesReportDetails;
  }
}
