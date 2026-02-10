import 'package:likha/domain/assignments/entities/submission_file.dart';

/// Server sends NaiveDateTime (UTC without Z suffix).
DateTime _parseUtc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z');

class SubmissionFileModel extends SubmissionFile {
  const SubmissionFileModel({
    required super.id,
    required super.fileName,
    required super.fileType,
    required super.fileSize,
    required super.uploadedAt,
  });

  factory SubmissionFileModel.fromJson(Map<String, dynamic> json) {
    return SubmissionFileModel(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      uploadedAt: _parseUtc(json['uploaded_at'] as String),
    );
  }
}
