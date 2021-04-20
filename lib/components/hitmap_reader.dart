import 'dart:convert';
import 'dart:io';

import 'package:coverage/coverage.dart' as coverage;

class HitmapReader {
  Future<Map<String, Map<int, int>>> fromDirectory(
      Directory coverageOutputDir) async {
    final coverageFiles = await readCoverageFiles(coverageOutputDir);

    final totalHitMap = <String, Map<int, int>>{};
    for (final coverageFile in coverageFiles) {
      final hitMap = await fromFile(coverageFile);
      coverage.mergeHitmaps(hitMap, totalHitMap);
    }

    return totalHitMap;
  }

  Future<Map<String, Map<int, int>>> fromFile(File coverageFile) {
    return fromString(coverageFile.readAsStringSync());
  }

  Future<Map<String, Map<int, int>>> fromString(String coverageContent) {
    final coverageDetails = jsonDecode(coverageContent);
    return coverage.createHitmap(
        List<Map<String, dynamic>>.from(coverageDetails['coverage']));
  }

  Future<List<File>> readCoverageFiles(Directory coverageOutputDir) {
    return coverageOutputDir
        .list(recursive: true)
        .where((item) => item is File)
        .where((item) => item.path.endsWith('_test.dart.vm.json'))
        .map((file) => file as File)
        .toList();
  }
}
