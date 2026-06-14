import 'dart:io';

import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';

String mimeType(String filePath) {
  final extension = filePath.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'doc':
    case 'docx':
      return 'application/msword';
    case 'xls':
    case 'xlsx':
      return 'application/vnd.ms-excel';
    case 'ppt':
    case 'pptx':
      return 'application/vnd.ms-powerpoint';
    case 'txt':
      return 'text/plain';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'zip':
      return 'application/zip';
    default:
      return 'application/octet-stream';
  }
}

Future<int> fileSize(String filePath) async {
  try {
    return await File(filePath).length();
  } catch (_) {
    return 0;
  }
}

bool assignmentsHaveChanged(List<Assignment> local, List<Assignment> remote) {
  if (local.length != remote.length) return true;
  final localById = {for (final a in local) a.id: a};
  for (final r in remote) {
    final l = localById[r.id];
    if (l == null) return true;
    if (l.updatedAt.isBefore(r.updatedAt)) return true;
  }
  return false;
}

bool submissionDataHasChanged(
  AssignmentSubmission? cached,
  AssignmentSubmission fresh,
) {
  if (cached == null) return true;
  if (cached.status != fresh.status) return true;
  if (cached.score != fresh.score) return true;
  if (cached.textContent != fresh.textContent) return true;
  if (cached.feedback != fresh.feedback) return true;
  if (cached.gradedBy != fresh.gradedBy) return true;
  if (submissionFilesHaveChanged(cached.files, fresh.files)) return true;
  return false;
}

AssignmentSubmissionModel toSubmissionModel(AssignmentSubmission submission) {
  return AssignmentSubmissionModel(
    id: submission.id,
    assignmentId: submission.assignmentId,
    studentId: submission.studentId,
    studentName: submission.studentName,
    status: submission.status,
    textContent: submission.textContent,
    submittedAt: submission.submittedAt,
    score: submission.score,
    feedback: submission.feedback,
    gradedAt: submission.gradedAt,
    gradedBy: submission.gradedBy,
    files: submission.files,
    createdAt: submission.createdAt,
    updatedAt: submission.updatedAt,
    cachedAt: submission.cachedAt,
    needsSync: submission.needsSync,
  );
}

bool submissionFilesHaveChanged(
  List<SubmissionFile> cached,
  List<SubmissionFile> fresh,
) {
  if (cached.length != fresh.length) return true;
  final cachedIds = {for (final f in cached) f.id};
  for (final f in fresh) {
    if (!cachedIds.contains(f.id)) return true;
  }
  return false;
}


