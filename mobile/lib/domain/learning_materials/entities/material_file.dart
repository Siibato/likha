import 'package:equatable/equatable.dart';

class MaterialFile extends Equatable {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;

  const MaterialFile({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [
        id,
        fileName,
        fileType,
        fileSize,
        uploadedAt,
      ];
}
