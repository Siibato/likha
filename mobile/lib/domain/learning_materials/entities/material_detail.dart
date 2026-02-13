import 'package:equatable/equatable.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

class MaterialDetail extends Equatable {
  final String id;
  final String classId;
  final String title;
  final String? description;
  final String? contentText;
  final int orderIndex;
  final List<MaterialFile> files;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaterialDetail({
    required this.id,
    required this.classId,
    required this.title,
    this.description,
    this.contentText,
    required this.orderIndex,
    required this.files,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        classId,
        title,
        description,
        contentText,
        orderIndex,
        files,
        createdAt,
        updatedAt,
      ];
}
