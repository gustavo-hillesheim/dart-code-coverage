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
    showTestOutput: args.showOutput,
    includeRegexes: args.includeRegexes,
    excludeRegexes: args.excludeRegexes,
    ignoreBarrelFiles: args.ignoreBarrelFiles,
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
    'ignore-barrel-files',
    help: 'Ignores barrel files when creating the code coverage report',
    negatable: false,
    defaultsTo: true,
  );
  argsParser.addFlag(
    'inline-files',
    help:
        'Prints file paths in a single line without separating files by folder',
    negatable: false,
    defaultsTo: false,
  );
  argsParser.addFlag(
    'show-output',
    help: 'Show tests output',
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
  final include = argsResult['include'];
  final exclude = argsResult['exclude'];
  final minimumCoverage = argsResult['minimum'];
  final showOutput = argsResult['show-output'];
  final hideUncovered = argsResult['hide-uncovered-files'];
  final help = argsResult['help'];
  final ignoreBarrelFiles = argsResult['ignore-barrel-files'];
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
    showOutput: showOutput,
    hideUncovered: hideUncovered,
    ignoreBarrelFiles: ignoreBarrelFiles,
    inlineFiles: inlineFiles,
    minimumCoverage: int.parse(minimumCoverage),
    help: help,
    includeRegexes: include,
    excludeRegexes: exclude,
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
  final List<String>? includeRegexes;
  final List<String>? excludeRegexes;
  final int minimumCoverage;
  final bool showOutput;
  final bool hideUncovered;
  final bool help;
  final bool ignoreBarrelFiles;
  final bool inlineFiles;
  final List<String>? additionalTestArgs;

  ApplicationArgs({
    required this.packageDirectory,
    required this.minimumCoverage,
    required this.showOutput,
    required this.hideUncovered,
    required this.ignoreBarrelFiles,
    required this.inlineFiles,
    required this.help,
    this.includeRegexes,
    this.excludeRegexes,
    this.additionalTestArgs,
  });
}
