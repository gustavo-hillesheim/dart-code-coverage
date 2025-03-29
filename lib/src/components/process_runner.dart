import 'dart:io';

import 'package:process_run/which.dart';

/// Wrapper for the [Process.start] method that reads the stdout and stderr streams and outputs then to the console
class ProcessRunner {
  /// Runs a given executable with the given args.
  /// If the flag showOutput is true, the stdout and sterr streams will be outputted to the console
  Future<int> run(
    String executable,
    List<String> args, {
    Directory? workingDirectory,
  }) async {
    final process = await Process.start(
      whichSync(executable) ?? executable,
      args,
      workingDirectory: workingDirectory?.absolute.path,
      mode: ProcessStartMode.inheritStdio,
    );

    return await process.exitCode;
  }
}
