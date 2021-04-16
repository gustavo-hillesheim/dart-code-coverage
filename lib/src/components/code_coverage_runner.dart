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

  factory CodeCoverageRunner.newDefault() {
    return CodeCoverageRunner(
      hitmapReader: HitmapReader(),
      coverageReportFactory: CoverageReportFactory(),
    );
  }

  Future<CoverageReport> run(
      {List<String>? packages, required Directory packageDirectory}) async {
    final coverageOutputDir = _getCoverageOutputDir(packageDirectory);
    final coverageOutputDirName =
        coverageOutputDir.path.split(path.separator).last;

    await Process.run(
      'dart',
      ['test', '--coverage=$coverageOutputDirName'],
      workingDirectory: packageDirectory.absolute.path,
    );

    var hitmap = _simplifyHitmap(
      await hitmapReader.fromDirectory(coverageOutputDir),
      packages: packages,
    );

    if (coverageOutputDir.existsSync()) {
      await coverageOutputDir.delete(recursive: true);
    }
    return coverageReportFactory.fromHitmap(hitmap);
  }

  Directory _getCoverageOutputDir(Directory directory) {
    final coverageOutputDirName = _generateCoverageOutputDirName();
    return Directory(
      path.join(directory.absolute.path, coverageOutputDirName),
    );
  }

  String _generateCoverageOutputDirName() {
    final currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
    return 'code_coverage_$currentTimeMillis';
  }

  Map<String, Map<int, int>> _simplifyHitmap(
    Map<String, Map<int, int>> hitmap, {
    List<String>? packages,
  }) {
    hitmap.removeWhere(
      (fileName, hits) => !_fileBelongsInAnyPackage(fileName, packages),
    );
    if (packages?.length == 1) {
      hitmap = _removePackagePrefix(hitmap, packageName: packages!.first);
    }
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
}
