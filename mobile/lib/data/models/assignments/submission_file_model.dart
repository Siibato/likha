import 'package:likha/domain/assignments/entities/submission_file.dart';

/// Server sends NaiveDateTime (UTC without Z suffix).
DateTime _parseUtc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z');

class SubmissionFileModel extends SubmissionFile {
  final String submissionId;

  const SubmissionFileModel({
    required super.id,
    required this.submissionId,
    required super.fileName,
    required super.fileType,
    required super.fileSize,
    required super.uploadedAt,
    super.localPath,
    super.cachedAt,
    super.needsSync = false,
  });

  factory SubmissionFileModel.fromJson(Map<String, dynamic> json) {
    return SubmissionFileModel(
      id: json['id'] as String,
      submissionId: json['submission_id'] as String? ?? '',
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      uploadedAt: _parseUtc(json['uploaded_at'] as String),
    );
  }

  factory SubmissionFileModel.fromMap(Map<String, dynamic> map) {
    return SubmissionFileModel(
      id: map['id'] as String,
      submissionId: map['submission_id'] as String,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'submission_id': submissionId,
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
