import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> getExpectedFilePath(String fileId, String fileName) async {
  if (kIsWeb) return null;
  try {
    final appDirDoc = await getApplicationDocumentsDirectory();
    final submissionFilesDir = Directory('${appDirDoc.path}/submission_files');
    final shortId = fileId.substring(0, 8);
    final dotIndex = fileName.lastIndexOf('.');
    final localFileName = dotIndex > 0
        ? '${fileName.substring(0, dotIndex)}-$shortId${fileName.substring(dotIndex)}'
        : '$fileName-$shortId';
    return '${submissionFilesDir.path}/$localFileName';
  } catch (e) {
    return null;
  }
}
