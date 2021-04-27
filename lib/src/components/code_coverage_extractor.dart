import 'dart:io';

import 'package:code_coverage/src/components/coverage_report_factory.dart';
import 'package:code_coverage/src/components/hitmap_reader.dart';
import 'package:code_coverage/src/components/process_runner.dart';
import 'package:code_coverage/src/models/coverage_report.dart';
import 'package:code_coverage/src/utils.dart';
import 'package:path/path.dart' as path;

/// Component used to generate a [CoverageReport] for a given package.
/// This is the main class of the package, summarizing all of its funcionality.
class CodeCoverageExtractor {
  final HitmapReader hitmapReader;
  final CoverageReportFactory coverageReportFactory;
  final ProcessRunner processRunner;

  CodeCoverageExtractor({
    required this.hitmapReader,
    required this.coverageReportFactory,
    required this.processRunner,
  });

  /// Creates a [CodeCoverageExtractor] instance with default  dependencies
  factory CodeCoverageExtractor.createDefault() {
    return CodeCoverageExtractor(
      hitmapReader: HitmapReader(),
      coverageReportFactory: CoverageReportFactory(),
      processRunner: ProcessRunner(),
    );
  }

  /// Runs the given package tests with the [processRunner], parses the coverage output
  /// with the [hitmapReader] and creates a [CoverageReport] with the [coverageReportFactory]
  /// with the resulting hitmaps.
  /// Return a [CoverageExtractionResult] containing the coverage report and
  /// the status of the tests executed as a [TestResultStatus].
  /// If the showTestOutput flag is true, the tests outputs will be shows in the console
  Future<CoverageExtractionResult> extract({
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
    final exitCode = await processRunner.run(
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

    final coverageReport = coverageReportFactory.create(
      hitmap: hitmap,
      package: package,
      packageDirectory: packageDirectory,
    );
    return CoverageExtractionResult(
      testResultStatus:
          exitCode == 1 ? TestResultStatus.ERROR : TestResultStatus.SUCCESS,
      coverageReport: coverageReport,
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

class CoverageExtractionResult {
  final TestResultStatus testResultStatus;
  final CoverageReport coverageReport;

  CoverageExtractionResult({
    required this.testResultStatus,
    required this.coverageReport,
  });
}

enum TestResultStatus { ERROR, SUCCESS }
