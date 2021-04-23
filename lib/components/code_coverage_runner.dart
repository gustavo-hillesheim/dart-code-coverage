import 'dart:convert';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:code_coverage/components/coverage_report_factory.dart';
import 'package:code_coverage/components/hitmap_reader.dart';
import 'package:code_coverage/models/coverage_report.dart';
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

  Future<CoverageReport> run({
    required String package,
    required Directory packageDirectory,
    required bool showOutput,
  }) async {
    final coverageOutputDir = _getCoverageOutputDir(packageDirectory);

    await _runTests(
      packageDirectory: packageDirectory,
      coverageOutputDirName: coverageOutputDir.path.split(path.separator).last,
      showOutput: showOutput,
    );

    var hitmap = _filterAndSimpliflyFileNames(
      await hitmapReader.fromDirectory(coverageOutputDir),
      package: package,
    );

    if (coverageOutputDir.existsSync()) {
      await coverageOutputDir.delete(recursive: true);
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

  Future<void> _runTests({
    required Directory packageDirectory,
    required String coverageOutputDirName,
    bool showOutput = false,
  }) async {
    print('Running package tests...');

    final process = await Process.start(
      'dart',
      ['test', '--coverage=$coverageOutputDirName'],
      workingDirectory: packageDirectory.absolute.path,
    );

    final errorPen = AnsiPen()..red();
    final nullPrinter = (_) {};
    final errorPrinter = (line) => print(errorPen(line));
    listenLines(process.stdout, printer: showOutput ? print : nullPrinter);
    listenLines(process.stderr,
        printer: showOutput ? errorPrinter : nullPrinter);

    await process.exitCode;
  }

  void listenLines(Stream<List<int>> messageStream,
      {required void Function(String) printer}) {
    messageStream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(printer);
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
