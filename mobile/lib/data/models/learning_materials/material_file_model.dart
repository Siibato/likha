import 'package:likha/domain/learning_materials/entities/material_file.dart';

class MaterialFileModel extends MaterialFile {
  const MaterialFileModel({
    required super.id,
    required super.fileName,
    required super.fileType,
    required super.fileSize,
    required super.uploadedAt,
  });

  factory MaterialFileModel.fromJson(Map<String, dynamic> json) {
    return MaterialFileModel(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
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
}
