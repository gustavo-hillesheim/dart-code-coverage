import 'dart:io';

import 'package:args/args.dart';
import 'package:code_coverage/code_coverage.dart';
import 'package:code_coverage/src/components/table_formatter.dart';
import 'package:code_coverage/src/constants.dart';
import 'package:code_coverage/src/utils.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  final argsParser = defineArgsParser();
  final args = extractArgs(argsParser, arguments);
  final error = validateArgs(args);
  if (error != null) {
    print(kRedPen(error));
    return;
  }

  final coverageReport = await CodeCoverageExtractor.createDefault().extract(
    packageDirectory: args.packageDirectory,
    showTestOutput: args.showOutput,
  );

  printCoverageReport(coverageReport);
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

ArgParser defineArgsParser() {
  final argsParser = ArgParser();
  argsParser.addOption(
    'packageDir',
    abbr: 'd',
    help: 'Directory containing the package to be tested',
  );
  argsParser.addFlag('showOutput',
      abbr: 'o',
      help: 'Show tests output',
      negatable: false,
      defaultsTo: false);
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
  final showOutput = argsResult['showOutput'];
  final help = argsResult['help'];

  return ApplicationArgs(
    packageDirectory: packageDirectory,
    showOutput: showOutput,
    help: help,
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
  final bool showOutput;
  final bool help;

  ApplicationArgs({
    required this.packageDirectory,
    required this.showOutput,
    required this.help,
  });
}
