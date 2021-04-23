import 'dart:io';

import 'package:code_coverage/components/coverage_report_factory.dart';
import 'package:code_coverage/components/hitmap_reader.dart';
import 'package:code_coverage/components/process_runner.dart';
import 'package:code_coverage/models/coverage_report.dart';
import 'package:code_coverage/utils.dart';
import 'package:path/path.dart' as path;

class CodeCoverageExtractor {
  final HitmapReader hitmapReader;
  final CoverageReportFactory coverageReportFactory;
  final ProcessRunner processRunner;

  CodeCoverageExtractor({
    required this.hitmapReader,
    required this.coverageReportFactory,
    required this.processRunner,
  });

  factory CodeCoverageExtractor.createDefault() {
    return CodeCoverageExtractor(
      hitmapReader: HitmapReader(),
      coverageReportFactory: CoverageReportFactory(),
      processRunner: ProcessRunner(),
    );
  }

  Future<CoverageReport> extract({
    required Directory packageDirectory,
    required bool showTestOutput,
  }) async {
    final coverageOutputDirectory = _getCoverageOutputDir(packageDirectory);
    final package = getPackageName(directory: packageDirectory);
    if (package == null) {
      throw Exception(
          'Could not find package name in pubspec.yaml; Working directory: ${packageDirectory.absolute.path}');
    }

    print('Running package tests...');
    await processRunner.run(
      'dart',
      ['test', '--coverage=${coverageOutputDirectory.absolute.path}'],
      workingDirectory: packageDirectory,
      showOutput: showTestOutput,
    );

    final hitmap = _filterAndSimpliflyFileNames(
      await hitmapReader.fromDirectory(coverageOutputDirectory),
      package: package,
    );

    if (coverageOutputDirectory.existsSync()) {
      await coverageOutputDirectory.delete(recursive: true);
    }

    return coverageReportFactory.create(
      hitmap: hitmap,
      package: package,
      packageDirectory: packageDirectory,
    );
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

  Map<String, Map<int, int>> _filterAndSimpliflyFileNames(
    Map<String, Map<int, int>> hitmap, {
    required String package,
  }) {
    hitmap.removeWhere(
      (fileName, hits) => !fileName.startsWith('package:$package/'),
    );
    return hitmap.map(
      (fileName, hits) =>
          MapEntry(fileName.replaceFirst('package:$package/', ''), hits),
    );
  }
}
