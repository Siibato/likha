import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:likha/core/utils/file_opener.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';

/// Controller for the material detail page (desktop + mobile).
///
/// Owns ephemeral form state and file-handling orchestration.
/// Pages show confirmation dialogs; controller returns intents / data.
class MaterialDetailController extends ChangeNotifier {
  String? formError;

  void setFormError(String? value) {
    if (formError != value) {
      formError = value;
      notifyListeners();
    }
  }

  void clearFormError() {
    if (formError != null) {
      formError = null;
      notifyListeners();
    }
  }

  /// Picks a file and uploads it via [notifier].
  Future<void> uploadFile({
    required String materialId,
    required LearningMaterialNotifier notifier,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'ppt', 'pptx',
        'mp4', 'mp3', 'jpg', 'png', 'gif',
      ],
      withData: true,
    );

    if (result == null) return;

    final pickedFile = result.files.single;

    if (kIsWeb) {
      if (pickedFile.bytes != null) {
        await notifier.uploadFile(
          materialId: materialId,
          filePath: pickedFile.name,
          fileName: pickedFile.name,
          fileBytes: pickedFile.bytes,
        );
      }
    } else if (pickedFile.path != null) {
      await notifier.uploadFile(
        materialId: materialId,
        filePath: pickedFile.path!,
        fileName: pickedFile.name,
      );
    }
  }

  /// Returns an action enum so the page knows which icon/tooltip to show,
  /// but the actual open/download is handled here.
  Future<void> handleFile({
    required MaterialFile file,
    required LearningMaterialNotifier notifier,
  }) async {
    if (kIsWeb) {
      final bytes = await notifier.downloadFile(file.id);
      if (bytes is Uint8List) {
        await openFileInBrowser(bytes, file.fileName);
      }
    } else if (file.isCached) {
      await openLocalFile(file.localPath!);
    } else {
      await notifier.downloadFile(file.id);
    }
  }

  void deleteFile({
    required MaterialFile file,
    required String materialId,
    required LearningMaterialNotifier notifier,
  }) {
    notifier.deleteFile(file.id, materialId);
  }

  void deleteMaterial({
    required String materialId,
    required LearningMaterialNotifier notifier,
  }) {
    notifier.deleteMaterial(materialId);
  }

}
