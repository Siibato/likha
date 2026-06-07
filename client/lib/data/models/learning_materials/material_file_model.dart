import 'package:likha/domain/learning_materials/entities/material_file.dart';

class MaterialFileModel extends MaterialFile {
  final String materialId;

  const MaterialFileModel({
    required super.id,
    required this.materialId,
    required super.fileName,
    required super.fileType,
    required super.fileSize,
    required super.uploadedAt,
    super.localPath,
    super.cachedAt,
    super.needsSync = false,
  });

  factory MaterialFileModel.fromJson(Map<String, dynamic> json) {
    return MaterialFileModel(
      id: json['id'] as String,
      materialId: json['material_id'] as String? ?? '',
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  factory MaterialFileModel.fromMap(Map<String, dynamic> map) {
    return MaterialFileModel(
      id: map['id'] as String,
      materialId: map['material_id'] as String,
      fileName: map['file_name'] as String,
      fileType: map['file_type'] as String,
      fileSize: map['file_size'] as int,
      uploadedAt: DateTime.parse(map['uploaded_at'] as String),
      localPath: map['local_path'] as String?,
      cachedAt: map['cached_at'] != null
          ? DateTime.parse(map['cached_at'] as String)
          : null,
      needsSync: (map['needs_sync'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'material_id': materialId,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
      'local_path': localPath,
      'cached_at': cachedAt?.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
