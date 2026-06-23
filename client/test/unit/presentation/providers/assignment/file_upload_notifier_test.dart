import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assignments/usecases/download_file.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/presentation/providers/assignment/file_upload_provider.dart';

import '../../../../helpers/fake_entities.dart';

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUploadFile extends Mock implements UploadFile {}
class MockDownloadFile extends Mock implements DownloadFile {}

FileUploadNotifier _buildNotifier({
  MockUploadFile? uploadFile,
  MockDownloadFile? downloadFile,
}) {
  return FileUploadNotifier(
    _FakeRef(),
    uploadFile ?? MockUploadFile(),
    downloadFile ?? MockDownloadFile(),
  );
}

void main() {
  final tFile = FakeEntities.submissionFile();

  group('FileUploadNotifier', () {
    group('uploadFile', () {
      test('sets successMessage and returns null on success', () async {
        final mockUpload = MockUploadFile();
        final notifier = _buildNotifier(uploadFile: mockUpload);

        when(() => mockUpload(any())).thenAnswer((_) async =>
            Right(MutationResult(entity: tFile, status: SyncStatus.pending)));

        final error = await notifier.uploadFile(UploadFileParams(
          submissionId: 's-1',
          filePath: '/path/to/file.pdf',
          fileName: 'file.pdf',
        ));

        expect(error, isNull);
        expect(notifier.state.isUploading, isFalse);
        expect(notifier.state.successMessage, isNotNull);
        expect(notifier.state.error, isNull);
      });

      test('sets error and returns error message on failure', () async {
        final mockUpload = MockUploadFile();
        final notifier = _buildNotifier(uploadFile: mockUpload);

        when(() => mockUpload(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Upload failed')));

        final error = await notifier.uploadFile(UploadFileParams(
          submissionId: 's-1',
          filePath: '/path/to/file.pdf',
          fileName: 'file.pdf',
        ));

        expect(error, isNotNull);
        expect(notifier.state.isUploading, isFalse);
        expect(notifier.state.error, isNotNull);
      });
    });

    group('downloadFile', () {
      test('returns file bytes on success', () async {
        final mockDownload = MockDownloadFile();
        final notifier = _buildNotifier(downloadFile: mockDownload);

        final bytes = [1, 2, 3, 4];
        when(() => mockDownload(any()))
            .thenAnswer((_) async => Right(bytes));

        final result = await notifier.downloadFile('file-1');

        expect(result, isNotNull);
        expect(result, equals(bytes));
        expect(notifier.state.isDownloading, isFalse);
        expect(notifier.state.error, isNull);
      });

      test('sets error and returns null on failure', () async {
        final mockDownload = MockDownloadFile();
        final notifier = _buildNotifier(downloadFile: mockDownload);

        when(() => mockDownload(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Download failed')));

        final result = await notifier.downloadFile('file-1');

        expect(result, isNull);
        expect(notifier.state.isDownloading, isFalse);
        expect(notifier.state.error, isNotNull);
      });
    });

    group('clearMessages', () {
      test('clears error and successMessage', () {
        final notifier = _buildNotifier();
        notifier.state = notifier.state.copyWith(
          error: 'Some error',
          successMessage: 'Some success',
        );
        notifier.clearMessages();
        expect(notifier.state.error, isNull);
        expect(notifier.state.successMessage, isNull);
      });
    });

    group('initial state', () {
      test('starts not uploading and not downloading', () {
        final notifier = _buildNotifier();
        expect(notifier.state.isUploading, isFalse);
        expect(notifier.state.isDownloading, isFalse);
        expect(notifier.state.uploadProgress, 0.0);
        expect(notifier.state.error, isNull);
      });
    });
  });
}
