import 'package:likha/domain/learning_materials/entities/learning_material.dart';

class LearningMaterialModel extends LearningMaterial {
  const LearningMaterialModel({
    required super.id,
    required super.classId,
    required super.title,
    super.description,
    super.contentText,
    required super.orderIndex,
    required super.fileCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LearningMaterialModel.fromJson(Map<String, dynamic> json) {
    return LearningMaterialModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      contentText: json['content_text'] as String?,
      orderIndex: json['order_index'] as int,
      fileCount: json['file_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'title': title,
      'description': description,
      'content_text': contentText,
      'order_index': orderIndex,
      'file_count': fileCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
