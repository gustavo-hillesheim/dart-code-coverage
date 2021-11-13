import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:code_coverage/src/models/coverage_report.dart';
import 'package:code_coverage/src/models/file_coverage_report.dart';

/// Component used to create a [CoverageReport] out of a hitmap and package info in a easy way
class CoverageReportFactory {
  /// creates a [CoverageReport] using a hitmap to know which files were covered,
  /// and the packageDirectory to know which files were not covered. The package name
  /// is used to remove the package:${package-name} prefix
  CoverageReport create({
    required Map<String, Map<int, int>> hitmap,
    required Directory packageDirectory,
    required String package,
    List<String>? includeRegexes,
    List<String>? excludeRegexes,
  }) {
    var coveredFiles = _extractFilesReportDetails(hitmap);
    var packageFiles = _findPackageFilesNames(
      packageDirectory: packageDirectory,
      package: package,
    );
    final exclude = excludeRegexes?.map((regExp) => RegExp(regExp)) ?? [];
    final include = includeRegexes?.map((regExp) => RegExp(regExp)) ?? [];
    coveredFiles.removeWhere((path, _) {
      return exclude.any((regExp) => regExp.hasMatch(path)) &&
          !include.any((regExp) => regExp.hasMatch(path));
    });
    packageFiles.removeWhere((path) {
      return exclude.any((regExp) => regExp.hasMatch(path)) &&
          !include.any((regExp) => regExp.hasMatch(path));
    });
    return CoverageReport(
      coveredFiles: coveredFiles,
      packageFiles: packageFiles,
    );
  }

  Map<String, FileCoverageReport> _extractFilesReportDetails(
      Map<String, Map<int, int>> hitmap) {
    final filesReportDetails = <String, FileCoverageReport>{};

    for (final hitmapEntry in hitmap.entries) {
      final fileName = path.normalize(hitmapEntry.key);
      filesReportDetails[fileName] = FileCoverageReport(
        fileName: fileName,
        linesCoverage: hitmapEntry.value,
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
        .map((file) => path.normalize(file.absolute.path))
        .map((filePath) => filePath.replaceFirst(srcDirPrefix, ''))
        .where((filePath) => filePath.startsWith('lib'))
        .where((filePath) => filePath.endsWith('.dart'))
        .map((filePath) {
      final relativeFilePath = filePath.replaceFirst(libDirPrefix, '');
      return relativeFilePath;
    }).toList();
  }
}
