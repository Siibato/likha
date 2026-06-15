import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';

class MaterialDetailModel extends MaterialDetail {
  const MaterialDetailModel({
    required super.id,
    required super.classId,
    required super.title,
    super.description,
    super.contentText,
    required super.orderIndex,
    required super.files,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MaterialDetailModel.fromJson(Map<String, dynamic> json) {
    final filesJson = json['files'] as List<dynamic>?;
    final files = filesJson != null
        ? filesJson.map((f) => MaterialFileModel.fromJson(f as Map<String, dynamic>)).toList()
        : <MaterialFileModel>[];

    return MaterialDetailModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      contentText: json['content_text'] as String?,
      orderIndex: json['order_index'] as int,
      files: files,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
