import 'dart:io';

import 'package:args/args.dart';
import 'package:code_coverage/code_coverage.dart';
import 'package:path/path.dart' as path;
import 'table_formatter.dart';
import 'constants.dart';
import 'utils.dart';

void main(List<String> arguments) async {
  final argsParser = defineArgsParser();
  final args = extractArgs(argsParser, arguments);
  final error = validateArgs(args);
  if (error != null) {
    print(kRedPen(error));
    return;
  }

  if (args.help) {
    print('Usage:\n${argsParser.usage}');
    return;
  }

  final coverageExtractionResult = await CodeCoverageExtractor.createDefault()
      .extract(
    packageDirectory: args.packageDirectory,
    showTestOutput: args.showOutput,
    includeRegexes: args.includeRegexes,
    excludeRegexes: args.excludeRegexes,
  )
      .onError((dynamic error, _) {
    print(kRedPen('Error while extracting coverage: ${error?.message}'));
    exit(1);
  });
  final coverageReport = coverageExtractionResult.coverageReport;

  printCoverageReport(coverageReport);
  if (args.showUncovered) {
    final uncoveredFiles = coverageReport.getUncoveredFiles();
    if (uncoveredFiles.isNotEmpty) {
      print('\nUncovered files:');
      uncoveredFiles.sort();
      uncoveredFiles.forEach((file) => print('- $file'));
    }
  }
  validateResult(coverageExtractionResult, args);
}

void printCoverageReport(CoverageReport coverageReport) {
  print(TableFormatter().format(coverageReport));

  final fileCoveragePercent = coverageReport.calculateFileCoveragePercent();
  final totalCoveredFiles = coverageReport.coveredFiles.length;
  final totalFiles = coverageReport.packageFiles.length;
  final fileCoveragePen = coveragePen(fileCoveragePercent);
  print(fileCoveragePen(
    '${(fileCoveragePercent * 100).toStringAsFixed(2)}% ($totalCoveredFiles/$totalFiles) of all files were covered',
  ));
}

void validateResult(
    CoverageExtractionResult coverageExtractionResult, ApplicationArgs args) {
  if (coverageExtractionResult.testResultStatus == TestResultStatus.ERROR) {
    print('Some tests failed, exiting with code 1');
    exit(1);
  }
  final coverageReport = coverageExtractionResult.coverageReport;

  if (coverageReport.calculateLineCoveragePercent() * 100 <
      args.minimumCoverage) {
    print('The minimum line coverage was not reached, exiting with code 1');
    exit(1);
  }

  if (coverageReport.calculateFileCoveragePercent() * 100 <
      args.minimumCoverage) {
    print('The minimum file coverage was not reached, exiting with code 1');
    exit(1);
  }
}

ArgParser defineArgsParser() {
  final argsParser = ArgParser();
  argsParser.addOption(
    'packageDir',
    abbr: 'd',
    help:
        'Directory containing the package to be tested, if not informed will use current directory',
  );
  argsParser.addMultiOption(
    'include',
    abbr: 'i',
    help:
        'Regex of files to be included to the coverage. If informed, only files in a path that matches any of these regex will be reported',
  );
  argsParser.addMultiOption(
    'exclude',
    abbr: 'e',
    help:
        'Regex of files to be excluded from the coverage. If informed, files that don\'t match any of these regex won\'t be reported',
  );
  argsParser.addOption(
    'minimum',
    abbr: 'm',
    help:
        'Minimum coverage percentage required, if not reached, will exit with code 1',
    defaultsTo: '0',
  );
  argsParser.addFlag(
    'showOutput',
    abbr: 'o',
    help: 'Show tests output',
    negatable: false,
    defaultsTo: false,
  );
  argsParser.addFlag(
    'showUncovered',
    abbr: 'u',
    help: 'Show which files were not covered',
    negatable: false,
    defaultsTo: false,
  );
  argsParser.addFlag(
    'help',
    abbr: 'h',
    help: 'Show application help',
    negatable: false,
  );
  return argsParser;
}

ApplicationArgs extractArgs(ArgParser argsParser, List<String> arguments) {
  final argsResult = argsParser.parse(arguments);
  final packageDirectory = argsResult.wasParsed('packageDir')
      ? Directory(argsResult['packageDir'])
      : Directory.current;
  final include = argsResult['include'];
  final exclude = argsResult['exclude'];
  final minimumCoverage = argsResult['minimum'];
  final showOutput = argsResult['showOutput'];
  final showUncovered = argsResult['showUncovered'];
  final help = argsResult['help'];

  try {
    int.parse(minimumCoverage);
  } catch (e) {
    print(kRedPen('minimum option is not an integer'));
    exit(1);
  }

  return ApplicationArgs(
    packageDirectory: packageDirectory,
    showOutput: showOutput,
    showUncovered: showUncovered,
    minimumCoverage: int.parse(minimumCoverage),
    help: help,
    includeRegexes: include,
    excludeRegexes: exclude,
  );
}

String? validateArgs(ApplicationArgs args) {
  final packageDirectory = args.packageDirectory;
  final packageDirectoryPath = packageDirectory.absolute.path;
  if (!packageDirectory.existsSync()) {
    return 'Directory \"$packageDirectoryPath\" does not exist';
  }
  final pubspecYamlFile = File(path.join(packageDirectoryPath, 'pubspec.yaml'));
  if (!pubspecYamlFile.existsSync()) {
    return 'Directory \"$packageDirectoryPath\" does not contain a pubspec.yaml file';
  }
  return null;
}

class ApplicationArgs {
  final Directory packageDirectory;
  final List<String>? includeRegexes;
  final List<String>? excludeRegexes;
  final int minimumCoverage;
  final bool showOutput;
  final bool showUncovered;
  final bool help;

  ApplicationArgs({
    required this.packageDirectory,
    required this.minimumCoverage,
    required this.showOutput,
    required this.showUncovered,
    required this.help,
    this.includeRegexes,
    this.excludeRegexes,
  });
}
