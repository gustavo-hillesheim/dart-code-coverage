import 'dart:io';
import 'dart:convert';

import 'package:ansicolor/ansicolor.dart';

/// Wrapper for the [Process.start] method that reads the stdout and stderr streams and outputs then to the console
class ProcessRunner {
  /// Runs a given executable with the given args.
  /// If the flag showOutput is true, the stdout and sterr streams will be outputted to the console
  Future<int> run(
    String executable,
    List<String> args, {
    Directory? workingDirectory,
    bool showOutput = false,
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory?.absolute.path,
    );

    final nullPrinter = (_) {};
    final errorPen = AnsiPen()..red();
    final errorPrinter = (line) => print(errorPen(line));
    _printOutput(process.stdout, printer: showOutput ? print : nullPrinter);
    _printOutput(process.stderr,
        printer: showOutput ? errorPrinter : nullPrinter);

    return await process.exitCode;
  }

  void _printOutput(Stream<List<int>> messageStream,
      {required void Function(String) printer}) {
    messageStream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(printer);
  }
}
