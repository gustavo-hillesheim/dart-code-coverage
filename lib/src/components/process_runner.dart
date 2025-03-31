import 'dart:io';

/// Wrapper for [Process.start] method.
class ProcessRunner {
  /// Runs a given executable with the given args.
  Future<int> run(
    String executable,
    List<String> args, {
    Directory? workingDirectory,
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory?.absolute.path,
      mode: ProcessStartMode.inheritStdio,
    );

    return await process.exitCode;
  }
}
