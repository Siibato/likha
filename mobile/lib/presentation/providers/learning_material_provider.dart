import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/usecases/create_material.dart';
import 'package:likha/domain/learning_materials/usecases/delete_file.dart' as material;
import 'package:likha/domain/learning_materials/usecases/delete_material.dart';
import 'package:likha/domain/learning_materials/usecases/download_file.dart' as material;
import 'package:likha/domain/learning_materials/usecases/get_material_detail.dart';
import 'package:likha/domain/learning_materials/usecases/get_materials.dart';
import 'package:likha/domain/learning_materials/usecases/reorder_material.dart' as material;
import 'package:likha/domain/learning_materials/usecases/update_material.dart';
import 'package:likha/domain/learning_materials/usecases/upload_file.dart' as material;
import 'package:likha/injection_container.dart';

class LearningMaterialState {
  final List<LearningMaterial> materials;
  final MaterialDetail? currentMaterial;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final double uploadProgress; // 0.0 to 1.0
  final String? currentUploadFileName;

  LearningMaterialState({
    this.materials = const [],
    this.currentMaterial,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.uploadProgress = 0.0,
    this.currentUploadFileName,
  });

  LearningMaterialState copyWith({
    List<LearningMaterial>? materials,
    MaterialDetail? currentMaterial,
    bool? isLoading,
    String? error,
    String? successMessage,
    double? uploadProgress,
    String? currentUploadFileName,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearCurrent = false,
    bool clearUploadProgress = false,
  }) {
    return LearningMaterialState(
      materials: materials ?? this.materials,
      currentMaterial: clearCurrent ? null : (currentMaterial ?? this.currentMaterial),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      uploadProgress: clearUploadProgress ? 0.0 : (uploadProgress ?? this.uploadProgress),
      currentUploadFileName: clearUploadProgress ? null : (currentUploadFileName ?? this.currentUploadFileName),
    );
  }
}

class LearningMaterialNotifier extends StateNotifier<LearningMaterialState> {
  final CreateMaterial _createMaterial;
  final GetMaterials _getMaterials;
  final GetMaterialDetail _getMaterialDetail;
  final UpdateMaterial _updateMaterial;
  final DeleteMaterial _deleteMaterial;
  final material.ReorderMaterial _reorderMaterial;
  final material.ReorderAllMaterials _reorderAllMaterials;
  final material.UploadFile _uploadFile;
  final material.DeleteFile _deleteFile;
  final material.DownloadFile _downloadFile;

  String? _currentClassId;
  late StreamSubscription<String?> _refreshSub;

  LearningMaterialNotifier(
    this._createMaterial,
    this._getMaterials,
    this._getMaterialDetail,
    this._updateMaterial,
    this._deleteMaterial,
    this._reorderMaterial,
    this._reorderAllMaterials,
    this._uploadFile,
    this._deleteFile,
    this._downloadFile,
  ) : super(LearningMaterialState()) {
    _refreshSub = sl<DataEventBus>().onMaterialsChanged.listen((classId) {
      ProviderLogger.instance.log('Event received: classId=$classId, _currentClassId=$_currentClassId');
      if (_currentClassId != null && _currentClassId == classId) {
        ProviderLogger.instance.log('ClassId MATCH! Calling loadMaterials()');
        loadMaterials(_currentClassId!);
        // Also reload the current material detail if it belongs to this class
        if (state.currentMaterial != null && state.currentMaterial!.classId == classId) {
          ProviderLogger.instance.log('Also reloading material detail');
          loadMaterialDetail(state.currentMaterial!.id);
        }
      } else {
        ProviderLogger.instance.log('ClassId MISMATCH or _currentClassId is null');
      }
    });
  }

  Future<void> loadMaterials(String classId) async {
    _currentClassId = classId;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getMaterials(classId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (materials) {
        ProviderLogger.instance.log('Loaded ${materials.length} materials');
        state = state.copyWith(isLoading: false, materials: materials);
        ProviderLogger.instance.log('State updated with new materials');
      },
    );
  }

  Future<void> loadMaterialDetail(String materialId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getMaterialDetail(materialId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (detail) => state = state.copyWith(isLoading: false, currentMaterial: detail),
    );
  }

  Future<void> createMaterial({
    required String classId,
    required String title,
    String? description,
    String? contentText,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _createMaterial(
      classId: classId,
      title: title,
      description: description,
      contentText: contentText,
    );
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (material) {
        final updatedMaterials = [...state.materials, material];
        state = state.copyWith(
          isLoading: false,
          materials: updatedMaterials,
          successMessage: 'Material created successfully',
          // Store the created material so create_material_page can access its ID
          currentMaterial: MaterialDetail(
            id: material.id,
            classId: material.classId,
            title: material.title,
            description: material.description,
            contentText: material.contentText,
            orderIndex: material.orderIndex,
            files: const [],
            createdAt: material.createdAt,
            updatedAt: material.updatedAt,
          ),
        );
      },
    );
  }

  Future<void> updateMaterial({
    required String materialId,
    String? title,
    String? description,
    String? contentText,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _updateMaterial(
      materialId: materialId,
      title: title,
      description: description,
      contentText: contentText,
    );
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (material) {
        final updatedMaterials = state.materials
            .map((m) => m.id == materialId ? material : m)
            .toList();

        // Also update currentMaterial if it matches the updated material
        MaterialDetail? updatedCurrent = state.currentMaterial;
        if (state.currentMaterial != null && state.currentMaterial!.id == materialId) {
          updatedCurrent = MaterialDetail(
            id: material.id,
            classId: material.classId,
            title: material.title,
            description: material.description,
            contentText: material.contentText,
            orderIndex: material.orderIndex,
            files: state.currentMaterial!.files,
            createdAt: material.createdAt,
            updatedAt: material.updatedAt,
          );
        }

        state = state.copyWith(
          isLoading: false,
          materials: updatedMaterials,
          currentMaterial: updatedCurrent,
          successMessage: 'Material updated successfully',
        );
      },
    );
  }

  Future<void> deleteMaterial(String materialId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _deleteMaterial(materialId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) {
        final updatedMaterials = state.materials.where((m) => m.id != materialId).toList();
        state = state.copyWith(
          isLoading: false,
          materials: updatedMaterials,
          successMessage: 'Material deleted successfully',
        );
      },
    );
  }

  Future<void> reorderMaterial(String materialId, int newOrderIndex) async {
    final result = await _reorderMaterial(
      materialId: materialId,
      newOrderIndex: newOrderIndex,
    );
    result.fold(
      (failure) => state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (mat) {
        final updatedMaterials = state.materials
            .map((m) => m.id == materialId ? mat : m)
            .toList();
        updatedMaterials.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        state = state.copyWith(materials: updatedMaterials);
      },
    );
  }

  Future<void> reorderAllMaterials({
    required String classId,
    required List<String> materialIds,
    required List<LearningMaterial> orderedMaterials,
  }) async {
    // Optimistic update: apply new order immediately from the provided list
    state = state.copyWith(materials: orderedMaterials);

    final result = await _reorderAllMaterials(
      classId: classId,
      materialIds: materialIds,
    );
    result.fold(
      (failure) {
        // On error: state already updated optimistically; show error
        state = state.copyWith(error: failure.message);
      },
      (_) {
        // Success: state was already updated optimistically, nothing more to do
      },
    );
  }

  Future<void> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      clearUploadProgress: true,
      currentUploadFileName: fileName,
    );

    final result = await _uploadFile(
      materialId: materialId,
      filePath: filePath,
      fileName: fileName,
      onSendProgress: (sent, total) {
        if (total > 0) {
          state = state.copyWith(uploadProgress: sent / total);
        }
      },
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
        clearUploadProgress: true,
      ),
      (file) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'File uploaded successfully',
          clearUploadProgress: true,
        );
        loadMaterialDetail(materialId);
        if (_currentClassId != null) {
          loadMaterials(_currentClassId!);
        }
      },
    );
  }

  Future<void> deleteFile(String fileId, String materialId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _deleteFile(fileId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'File deleted successfully',
        );
        loadMaterialDetail(materialId);
      },
    );
  }

  Future<List<int>?> downloadFile(String fileId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _downloadFile(fileId);
    state = state.copyWith(isLoading: false);

    List<int>? bytes;
    bool success = false;
    result.fold(
      (failure) => state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (data) {
        bytes = data;
        success = true;
      },
    );

    if (success && state.currentMaterial != null) {
      // Await reload so localPath is updated before caller reads state
      await loadMaterialDetail(state.currentMaterial!.id);
    }
    return bytes;
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  @override
  void dispose() {
    _refreshSub.cancel();
    super.dispose();
  }
}

final learningMaterialProvider =
    StateNotifierProvider<LearningMaterialNotifier, LearningMaterialState>(
  (ref) => LearningMaterialNotifier(
    sl<CreateMaterial>(),
    sl<GetMaterials>(),
    sl<GetMaterialDetail>(),
    sl<UpdateMaterial>(),
    sl<DeleteMaterial>(),
    sl<material.ReorderMaterial>(),
    sl<material.ReorderAllMaterials>(),
    sl<material.UploadFile>(),
    sl<material.DeleteFile>(),
    sl<material.DownloadFile>(),
  ),
);
