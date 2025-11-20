import 'dart:io';

import 'package:args/args.dart';
import 'package:code_coverage/code_coverage.dart';
import 'package:dart_console/dart_console.dart';
import 'package:path/path.dart' as path;
import 'table_formatter.dart';
import 'utils.dart';

void main(List<String> arguments) async {
  final argsParser = defineArgsParser();
  final args = extractArgs(argsParser, arguments);
  final error = validateArgs(args);
  if (error != null) {
    print(error);
    return;
  }

  if (args.help) {
    print('Usage:\n${argsParser.usage}');
    return;
  }

  final coverageExtractionResult = await CodeCoverageExtractor.createDefault()
      .extract(
    packageDirectory: args.packageDirectory,
    additionalTestArgs: args.additionalTestArgs,
  )
      .onError((dynamic error, _) {
    print('Error while extracting coverage: ${error?.message}');
    exit(1);
  });
  final coverageReport = coverageExtractionResult.coverageReport;

  final console = Console();

  printCoverageReport(args, coverageReport, console.windowWidth);
  if (!args.hideUncovered) {
    final uncoveredFiles = coverageReport.getUncoveredFiles();
    if (uncoveredFiles.isNotEmpty) {
      print('\nUncovered files:');
      uncoveredFiles.sort();
      uncoveredFiles.forEach((file) => print('- $file'));
    }
  }
  validateResult(coverageExtractionResult, args);
}

void printCoverageReport(
  ApplicationArgs args,
  CoverageReport coverageReport,
  int maxWidth,
) {
  print(TableFormatter().format(
    coverageReport,
    inlineFiles: args.inlineFiles,
    maxWidth: maxWidth,
    excludeFullyCovered: args.excludeFullyCovered,
  ));

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
    'package-dir',
    abbr: 'd',
    help:
        'Directory containing the package to be tested, if not informed will use current directory',
  );
  argsParser.addOption(
    'minimum',
    abbr: 'm',
    help:
        'Minimum coverage percentage required, if not reached, will exit with code 1',
    defaultsTo: '0',
  );
  argsParser.addFlag(
    'inline-files',
    help:
        'Prints file paths in a single line without separating files by folder',
    negatable: false,
    defaultsTo: false,
  );
  argsParser.addFlag(
    'hide-uncovered-files',
    help: 'Hides files that were not covered',
    negatable: false,
    defaultsTo: false,
  );
  argsParser.addFlag(
    'exclude-fully-covered',
    help: 'Excludes fully covered files from the coverage report',
    negatable: false,
    defaultsTo: false,
  );
  argsParser.addFlag(
    'help',
    abbr: 'h',
    help: 'Show application help',
    negatable: false,
  );
  argsParser.addMultiOption(
    'test-args',
    abbr: 'a',
    help: 'Additional arguments for "dart test" or "flutter test" command',
  );
  return argsParser;
}

ApplicationArgs extractArgs(ArgParser argsParser, List<String> arguments) {
  final argsResult = argsParser.parse(arguments);
  final packageDirectory = argsResult.wasParsed('package-dir')
      ? Directory(argsResult['package-dir'])
      : Directory.current;
  final minimumCoverage = argsResult['minimum'];
  final hideUncovered = argsResult['hide-uncovered-files'];
  final excludeFullyCovered = argsResult['exclude-fully-covered'];
  final help = argsResult['help'];
  final inlineFiles = argsResult['inline-files'];
  final additionalTestArgs = (argsResult['test-args'] as List<String>?)
      ?.expand((a) => a.split(' '))
      .toList();

  try {
    int.parse(minimumCoverage);
  } catch (e) {
    print('minimum option is not an integer');
    exit(1);
  }

  return ApplicationArgs(
    packageDirectory: packageDirectory,
    hideUncovered: hideUncovered,
    excludeFullyCovered: excludeFullyCovered,
    inlineFiles: inlineFiles,
    minimumCoverage: int.parse(minimumCoverage),
    help: help,
    additionalTestArgs: additionalTestArgs,
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
  final int minimumCoverage;
  final bool hideUncovered;
  final bool excludeFullyCovered;
  final bool help;
  final bool inlineFiles;
  final List<String>? additionalTestArgs;

  ApplicationArgs({
    required this.packageDirectory,
    required this.minimumCoverage,
    required this.hideUncovered,
    required this.excludeFullyCovered,
    required this.inlineFiles,
    required this.help,
    this.additionalTestArgs,
  });
}
