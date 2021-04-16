import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:code_coverage/code_coverage.dart';
import 'package:code_coverage/src/components/code_coverage_runner.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

final errorPen = AnsiPen()..red();

void main(List<String> arguments) async {
  final argsParser = ArgParser();
  argsParser.addOption('packageDir',
      abbr: 'd', help: 'Directory containing the package to be tested');
  argsParser.addFlag('showOutput',
      abbr: 'o',
      help: 'Show tests output',
      negatable: false,
      defaultsTo: false);
  argsParser.addFlag('help',
      abbr: 'h', help: 'Show application help', negatable: false);

  final argsResult = argsParser.parse(arguments);

  if (argsResult.wasParsed('help')) {
    print(argsParser.usage);
    return;
  }

  final dir = argsResult.wasParsed('packageDir')
      ? Directory(argsResult['packageDir'])
      : Directory.current;
  final showOutput = argsResult['showOutput'];

  final dirIsValid = validateDir(dir);
  if (!dirIsValid) {
    return;
  }

  final packageName = getPackageName(directory: dir);
  if (packageName == null || packageName.isEmpty) {
    print(errorPen('Could not find package name'));
    return;
  }

  final coverageReport = await CodeCoverageRunner.newDefault().run(
    packages: [packageName],
    packageDirectory: dir,
    showOutput: showOutput,
  );

  print(TableFormatter().format(coverageReport));
}

bool validateDir(Directory dir) {
  final dirPath = dir.absolute.path;
  if (!dir.existsSync()) {
    print(errorPen('Directory \"$dirPath\" does not exist'));
    return false;
  }
  final pubspecYamlFile = File(path.join(dirPath, 'pubspec.yaml'));
  if (!pubspecYamlFile.existsSync()) {
    print(errorPen(
        'Directory \"$dirPath\" does not contain a pubspec.yaml file'));
    return false;
  }
  return true;
}

String? getPackageName({required Directory directory}) {
  final pubspecFile = File(path.join(directory.absolute.path, 'pubspec.yaml'));
  final pubspecContent = loadYaml(pubspecFile.readAsStringSync());
  return pubspecContent['name'];
}
