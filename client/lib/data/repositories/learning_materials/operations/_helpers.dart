import 'dart:io';

import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

String mimeType(String filePath) {
  final extension = filePath.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'doc':
    case 'docx':
      return 'application/msword';
    case 'xls':
    case 'xlsx':
      return 'application/vnd.ms-excel';
    case 'ppt':
    case 'pptx':
      return 'application/vnd.ms-powerpoint';
    case 'txt':
      return 'text/plain';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'zip':
      return 'application/zip';
    default:
      return 'application/octet-stream';
  }
}

Future<int> fileSize(String filePath) async {
  try {
    return await File(filePath).length();
  } catch (_) {
    return 0;
  }
}

bool materialsHaveChanged(
  List<LearningMaterial> local,
  List<LearningMaterial> remote,
) {
  if (local.length != remote.length) return true;
  final localById = {for (final m in local) m.id: m};
  for (final r in remote) {
    final l = localById[r.id];
    if (l == null) return true;
    if (l.updatedAt.isBefore(r.updatedAt)) return true;
  }
  return false;
}

bool materialFilesHaveChanged(
  List<MaterialFile> cached,
  List<MaterialFile> fresh,
) {
  if (cached.length != fresh.length) return true;
  final cachedIds = {for (final f in cached) f.id};
  for (final f in fresh) {
    if (!cachedIds.contains(f.id)) return true;
  }
  return false;
}
