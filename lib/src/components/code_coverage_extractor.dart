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
    List<String>? includeRegexes,
    List<String>? excludeRegexes,
  }) async {
    if (!hasTestDirectory(packageDirectory)) {
      throw Exception(
          'Could not find "test" directory in "${packageDirectory.absolute.path}"');
    }
    final coverageOutputDirectory = _getCoverageOutputDir(packageDirectory);
    final packageData = getPackageData(directory: packageDirectory);
    if (packageData == null) {
      throw Exception(
          'Could not find package name in pubspec.yaml. Working directory: ${packageDirectory.absolute.path}');
    }

    print('Running tests for package ${packageData.name}...');
    final testRunner = _createTestRunner(packageData);
    final testResult = await testRunner.runTests(
      packageData,
      coverageOutputDirectory: coverageOutputDirectory,
      showTestOutput: showTestOutput,
      includeRegexes: includeRegexes,
      excludeRegexes: excludeRegexes,
    );

    if (coverageOutputDirectory.existsSync()) {
      await coverageOutputDirectory.delete(recursive: true);
    }
    return CoverageExtractionResult(
      testResultStatus: testResult.exitCode == 1
          ? TestResultStatus.ERROR
          : TestResultStatus.SUCCESS,
      coverageReport: testResult.coverageReport,
    );
  }

  bool hasTestDirectory(Directory packageDirectory) {
    return Directory(
            path.relative('test', from: packageDirectory.absolute.path))
        .existsSync();
  }

  Directory _getCoverageOutputDir(Directory directory) {
    final coverageOutputDirName = _generateCoverageOutputDirName();
    return Directory(
      path.join(directory.absolute.path, coverageOutputDirName),
    );
  }

  TestRunner _createTestRunner(PackageData packageData) {
    if (packageData.isFlutterProject) {
      return FlutterTestRunner(processRunner, coverageReportFactory);
    } else {
      return DartTestRunner(processRunner, coverageReportFactory, hitmapReader);
    }
  }

  String _generateCoverageOutputDirName() {
    final currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
    return 'code_coverage_$currentTimeMillis';
  }
}

abstract class TestRunner {
  Future<TestResult> runTests(
    PackageData packageData, {
    required Directory coverageOutputDirectory,
    required bool showTestOutput,
    List<String>? includeRegexes,
    List<String>? excludeRegexes,
  });
}

class DartTestRunner extends TestRunner {
  final ProcessRunner processRunner;
  final CoverageReportFactory coverageReportFactory;
  final HitmapReader hitmapReader;

  DartTestRunner(
    this.processRunner,
    this.coverageReportFactory,
    this.hitmapReader,
  );

  @override
  Future<TestResult> runTests(
    PackageData packageData, {
    required Directory coverageOutputDirectory,
    required bool showTestOutput,
    List<String>? includeRegexes,
    List<String>? excludeRegexes,
  }) async {
    final exitCode = await processRunner.run(
      'dart',
      ['test', '--coverage=${coverageOutputDirectory.absolute.path}'],
      workingDirectory: packageData.directory,
      showOutput: showTestOutput,
    );

    final hitmap = _filterAndSimpliflyFileNames(
      await hitmapReader.fromDirectory(coverageOutputDirectory),
      package: packageData.name,
    );

    final coverageReport = coverageReportFactory.create(
      hitmap: hitmap,
      package: packageData.name,
      packageDirectory: packageData.directory,
      includeRegexes: includeRegexes,
      excludeRegexes: excludeRegexes,
    );
    return TestResult(coverageReport: coverageReport, exitCode: exitCode);
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

class FlutterTestRunner extends TestRunner {
  final ProcessRunner processRunner;
  final CoverageReportFactory coverageReportFactory;

  FlutterTestRunner(
    this.processRunner,
    this.coverageReportFactory,
  );

  @override
  Future<TestResult> runTests(
    PackageData packageData, {
    required Directory coverageOutputDirectory,
    required bool showTestOutput,
    List<String>? includeRegexes,
    List<String>? excludeRegexes,
  }) async {
    final coverageOutputFilePath =
        '${coverageOutputDirectory.absolute.path}${path.separator}lcov.info';
    final exitCode = await processRunner.run(
      'flutter',
      ['test', '--coverage', '--coverage-path=$coverageOutputFilePath'],
      workingDirectory: packageData.directory,
      showOutput: showTestOutput,
    );

    final hitmap = _parseTestCoverage(coverageOutputFilePath);

    final coverageReport = coverageReportFactory.create(
      hitmap: hitmap,
      package: packageData.name,
      packageDirectory: packageData.directory,
      includeRegexes: includeRegexes,
      excludeRegexes: excludeRegexes,
    );
    return TestResult(coverageReport: coverageReport, exitCode: exitCode);
  }

  Map<String, Map<int, int>> _parseTestCoverage(String filePath) {
    final lcovData = File(filePath).readAsStringSync();
    final result = <String, Map<int, int>>{};
    lcovData
        .split('end_of_record')
        .map((fileCoverage) => fileCoverage.trim())
        .where((fileCoverage) =>
            fileCoverage.isNotEmpty && fileCoverage.startsWith('SF:'))
        .forEach(
      (fileCoverage) {
        final lines = fileCoverage.split('\n');
        final fileName =
            lines.first.replaceFirst('SF:lib${path.separator}', '');
        final reachedLines =
            lines.where((line) => line.startsWith('DA:')).toList();
        final hitmap = _createHitmap(reachedLines);
        result[fileName] = hitmap;
      },
    );
    return result;
  }

  Map<int, int> _createHitmap(List<String> fileLinesReached) {
    final fileHitmap = <int, int>{};
    for (var line in fileLinesReached) {
      final segments = line.substring(3).split(',');
      final lineNumber = int.parse(segments.first);
      final lineReached = int.parse(segments.last);
      fileHitmap[lineNumber] = lineReached;
    }
    return fileHitmap;
  }
}

class TestResult {
  final int exitCode;
  final CoverageReport coverageReport;

  TestResult({required this.exitCode, required this.coverageReport});
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
