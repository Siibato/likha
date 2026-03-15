import 'package:equatable/equatable.dart';

class MaterialFile extends Equatable {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;
  final String? localPath;
  final DateTime? cachedAt;
  final bool needsSync;

  const MaterialFile({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    this.localPath,
    this.cachedAt,
    this.needsSync = false,
  });

  bool get isCached => localPath != null && localPath!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        fileName,
        fileType,
        fileSize,
        uploadedAt,
        localPath,
        cachedAt,
        needsSync,
      ];
}
