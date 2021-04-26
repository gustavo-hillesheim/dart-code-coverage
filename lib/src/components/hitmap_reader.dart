import 'dart:convert';
import 'dart:io';

import 'package:coverage/coverage.dart' as coverage;

/// Component used to read hitmaps created by the dart test coverage option
class HitmapReader {
  /// Reads all coverage files (files ending with _test.dart.vm.json) and creates
  /// a hitmap merging all of the individual hitmaps
  Future<Map<String, Map<int, int>>> fromDirectory(
      Directory coverageOutputDir) async {
    final coverageFiles = await _readCoverageFiles(coverageOutputDir);

    final totalHitMap = <String, Map<int, int>>{};
    for (final coverageFile in coverageFiles) {
      final hitMap = await fromFile(coverageFile);
      coverage.mergeHitmaps(hitMap, totalHitMap);
    }

    return totalHitMap;
  }

  /// Reads a file and creates a hitmap out of if
  Future<Map<String, Map<int, int>>> fromFile(File coverageFile) {
    return fromString(coverageFile.readAsStringSync());
  }

  /// Creates a hitmap out of a given String
  Future<Map<String, Map<int, int>>> fromString(String coverageContent) {
    final coverageDetails = jsonDecode(coverageContent);
    return coverage.createHitmap(
        List<Map<String, dynamic>>.from(coverageDetails['coverage']));
  }

  Future<List<File>> _readCoverageFiles(Directory coverageOutputDir) {
    return coverageOutputDir
        .list(recursive: true)
        .where((item) => item is File)
        .where((item) => item.path.endsWith('_test.dart.vm.json'))
        .map((file) => file as File)
        .toList();
  }
}
