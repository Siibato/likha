import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assignments/usecases/download_file.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/providers/assignment/submission_provider.dart';

class FileUploadState {
  final bool isUploading;
  final bool isDownloading;
  final double uploadProgress;
  final String? currentUploadFileName;
  final String? error;
  final String? successMessage;

  const FileUploadState({
    this.isUploading = false,
    this.isDownloading = false,
    this.uploadProgress = 0.0,
    this.currentUploadFileName,
    this.error,
    this.successMessage,
  });

  FileUploadState copyWith({
    bool? isUploading,
    bool? isDownloading,
    double? uploadProgress,
    String? currentUploadFileName,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool resetUploadFile = false,
  }) {
    return FileUploadState(
      isUploading: isUploading ?? this.isUploading,
      isDownloading: isDownloading ?? this.isDownloading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      currentUploadFileName: resetUploadFile
          ? null
          : (currentUploadFileName ?? this.currentUploadFileName),
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class FileUploadNotifier extends StateNotifier<FileUploadState> {
  final Ref _ref;
  final UploadFile _uploadFile;
  final DownloadFile _downloadFile;

  FileUploadNotifier(this._ref, this._uploadFile, this._downloadFile)
      : super(const FileUploadState());

  Future<String?> uploadFile(UploadFileParams params) async {
    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
      currentUploadFileName: params.fileName,
      clearError: true,
      clearSuccess: true,
    );

    final result = await _uploadFile(params);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isUploading: false,
          error: AppErrorMapper.fromFailure(failure) ?? failure.message,
        );
        return state.error;
      },
      (mutationResult) {
        _ref
            .read(submissionProvider.notifier)
            .handleFileUploaded(params.submissionId, mutationResult.entity);
        state = state.copyWith(
          isUploading: false,
          uploadProgress: 1.0,
          successMessage: 'File uploaded',
          resetUploadFile: true,
        );
        return null;
      },
    );
  }

  Future<List<int>?> downloadFile(String fileId) async {
    state = state.copyWith(isDownloading: true, clearError: true, clearSuccess: true);
    final result = await _downloadFile(fileId);
    state = state.copyWith(isDownloading: false);

    List<int>? fileBytes;
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure) ?? failure.message,
      ),
      (bytes) => fileBytes = bytes,
    );

    return fileBytes;
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final fileUploadProvider =
    StateNotifierProvider<FileUploadNotifier, FileUploadState>((ref) {
  return FileUploadNotifier(
    ref,
    sl<UploadFile>(),
    sl<DownloadFile>(),
  );
});
