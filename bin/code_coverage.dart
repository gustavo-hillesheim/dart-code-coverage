import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:code_coverage/code_coverage.dart';
import 'package:code_coverage/components/code_coverage_runner.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  final errorPen = AnsiPen()..red();

  final argsParser = defineArgsParser();
  final args = extractArgs(argsParser, arguments);
  final error = validateArgs(args);
  if (error != null) {
    print(errorPen(error));
    return;
  }

  final packageName = getPackageName(directory: args.packageDirectory);
  if (packageName == null || packageName.isEmpty) {
    print(errorPen('Could not find package name in pubspec.yaml'));
    return;
  }

  final coverageReport = await CodeCoverageRunner.newDefault().run(
    packages: [packageName],
    packageDirectory: args.packageDirectory,
    showOutput: args.showOutput,
  );

  print(TableFormatter().format(coverageReport));
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

String? getPackageName({required Directory directory}) {
  final pubspecFile = File(path.join(directory.absolute.path, 'pubspec.yaml'));
  final pubspecContent = loadYaml(pubspecFile.readAsStringSync());
  return pubspecContent['name'];
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
