import 'package:likha/domain/learning_materials/entities/learning_material.dart';

class LearningMaterialModel extends LearningMaterial {
  final DateTime? deletedAt;

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
    super.cachedAt,
    super.needsSync = false,
    this.deletedAt,
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
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  factory LearningMaterialModel.fromMap(Map<String, dynamic> map) {
    return LearningMaterialModel(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      contentText: map['content_text'] as String?,
      orderIndex: map['order_index'] as int,
      fileCount: map['file_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      cachedAt: map['cached_at'] != null
          ? DateTime.parse(map['cached_at'] as String)
          : null,
      needsSync: (map['needs_sync'] as int?) == 1,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'title': title,
      'description': description,
      'content_text': contentText,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'cached_at': cachedAt?.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
