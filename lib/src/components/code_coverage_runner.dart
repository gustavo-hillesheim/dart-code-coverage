import 'dart:io';

import 'package:code_coverage/code_coverage.dart';
import 'package:path/path.dart' as path;

class CodeCoverageRunner {
  final HitmapReader hitmapReader;
  final CoverageReportFactory coverageReportFactory;

  CodeCoverageRunner({
    required this.hitmapReader,
    required this.coverageReportFactory,
  });

  Future<CoverageReport> run({List<String>? packages}) async {
    final coverageOutputDirName = _generateCoverageOutputDirName();
    await _runTestsWithCoverage(coverageOutputDirName: coverageOutputDirName);

    final coverageOutputDir = Directory(
      path.join(Directory.current.absolute.path, coverageOutputDirName),
    );
    var hitmap = await hitmapReader.fromDirectory(coverageOutputDir);
    hitmap = _filterHitMap(hitmap, packages: packages);
    if (packages?.length == 1) {
      hitmap = _removePackagePrefix(hitmap, packageName: packages!.first);
    }

    await coverageOutputDir.delete(recursive: true);
    return coverageReportFactory.fromHitmap(hitmap);
  }

  Map<String, Map<int, int>> _filterHitMap(
    Map<String, Map<int, int>> hitmap, {
    List<String>? packages,
  }) {
    hitmap.removeWhere(
        (fileName, hits) => !_fileBelongsInAnyPackage(fileName, packages));
    return hitmap;
  }

  bool _fileBelongsInAnyPackage(String fileName, List<String>? packages) {
    if (packages == null) {
      return true;
    }
    return packages.any((package) => fileName.startsWith('package:$package/'));
  }

  Map<String, Map<int, int>> _removePackagePrefix(
      Map<String, Map<int, int>> hitmap,
      {required String packageName}) {
    return hitmap.map(
      (fileName, hits) =>
          MapEntry(fileName.replaceFirst('package:$packageName/', ''), hits),
    );
  }

  String _generateCoverageOutputDirName() {
    final currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
    return 'code_coverage_$currentTimeMillis';
  }

  Future<void> _runTestsWithCoverage(
      {required String coverageOutputDirName}) async {
    await Process.run('dart', ['test', '--coverage=$coverageOutputDirName']);
  }
}
