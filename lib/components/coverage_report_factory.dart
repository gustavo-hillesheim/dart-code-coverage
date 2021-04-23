import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:code_coverage/models/coverage_report.dart';
import 'package:code_coverage/models/file_coverage_report.dart';

class CoverageReportFactory {
  CoverageReport create({
    required Map<String, Map<int, int>> hitmap,
    required Directory packageDirectory,
    required String package,
  }) {
    return CoverageReport(
      coveredFiles: _extractFilesReportDetails(hitmap),
      packageFiles: _findPackageFilesNames(
        packageDirectory: packageDirectory,
        package: package,
      ),
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

  List<String> _findPackageFilesNames({
    required Directory packageDirectory,
    required String package,
  }) {
    final srcDirPath = packageDirectory.absolute.path;
    final srcDirPrefix = '$srcDirPath${path.separator}';
    final libDirPrefix = 'lib${path.separator}';
    return packageDirectory
        .listSync(recursive: true)
        .map((file) => file.absolute.path)
        .map((filePath) => filePath.replaceFirst(srcDirPrefix, ''))
        .where((filePath) => filePath.startsWith('lib'))
        .where((filePath) => filePath.endsWith('.dart'))
        .map((filePath) {
      final relativeFilePath = filePath.replaceFirst(libDirPrefix, '');
      final filePackagePath = 'package:$package/$relativeFilePath';
      return filePackagePath;
    }).toList();
  }
}
