import 'package:equatable/equatable.dart';

class LearningMaterial extends Equatable {
  final String id;
  final String classId;
  final String title;
  final String? description;
  final String? contentText;
  final int orderIndex;
  final int fileCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearningMaterial({
    required this.id,
    required this.classId,
    required this.title,
    this.description,
    this.contentText,
    required this.orderIndex,
    required this.fileCount,
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
        fileCount,
        createdAt,
        updatedAt,
      ];
}
