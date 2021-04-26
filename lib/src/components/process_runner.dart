import 'dart:io';
import 'dart:convert';

import 'package:ansicolor/ansicolor.dart';

class ProcessRunner {
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
    printOutput(process.stdout, printer: showOutput ? print : nullPrinter);
    printOutput(process.stderr,
        printer: showOutput ? errorPrinter : nullPrinter);

    return await process.exitCode;
  }

  void printOutput(Stream<List<int>> messageStream,
      {required void Function(String) printer}) {
    messageStream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(printer);
  }
}
