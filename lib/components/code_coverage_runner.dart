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
    List<String>? packages,
    required Directory packageDirectory,
    required bool showOutput,
  }) async {
    final coverageOutputDir = _getCoverageOutputDir(packageDirectory);
    final coverageOutputDirName =
        coverageOutputDir.path.split(path.separator).last;

    await _runTests(
      packageDirectory: packageDirectory,
      coverageOutputDirName: coverageOutputDirName,
      showOutput: showOutput,
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
