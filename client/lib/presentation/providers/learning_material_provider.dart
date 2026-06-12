import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
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
    final previousMaterials = List<LearningMaterial>.from(state.materials);

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMaterial = LearningMaterial(
      id: tempId,
      classId: classId,
      title: title,
      description: description,
      contentText: contentText,
      orderIndex: state.materials.length,
      fileCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final tempDetail = MaterialDetail(
      id: tempId,
      classId: classId,
      title: title,
      description: description,
      contentText: contentText,
      orderIndex: state.materials.length,
      files: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      materials: [...state.materials, tempMaterial],
      currentMaterial: tempDetail,
    );

    final result = await _createMaterial(
      classId: classId,
      title: title,
      description: description,
      contentText: contentText,
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        materials: previousMaterials,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (material) {
        final realDetail = MaterialDetail(
          id: material.id,
          classId: material.classId,
          title: material.title,
          description: material.description,
          contentText: material.contentText,
          orderIndex: material.orderIndex,
          files: const [],
          createdAt: material.createdAt,
          updatedAt: material.updatedAt,
        );
        state = state.copyWith(
          isLoading: false,
          materials: state.materials.map((m) => m.id == tempId ? material : m).toList(),
          currentMaterial: state.currentMaterial?.id == tempId ? realDetail : state.currentMaterial,
          successMessage: 'Material created successfully',
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
    final previousMaterials = List<LearningMaterial>.from(state.materials);
    final previousCurrent = state.currentMaterial;

    final existingMaterial = state.materials.firstWhere(
      (m) => m.id == materialId,
      orElse: () => LearningMaterial(
        id: materialId,
        classId: '',
        title: title ?? '',
        description: description,
        contentText: contentText,
        orderIndex: 0,
        fileCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final optimisticMaterial = LearningMaterial(
      id: existingMaterial.id,
      classId: existingMaterial.classId,
      title: title ?? existingMaterial.title,
      description: description ?? existingMaterial.description,
      contentText: contentText ?? existingMaterial.contentText,
      orderIndex: existingMaterial.orderIndex,
      fileCount: existingMaterial.fileCount,
      createdAt: existingMaterial.createdAt,
      updatedAt: DateTime.now(),
    );

    MaterialDetail? optimisticCurrent;
    if (previousCurrent != null && previousCurrent.id == materialId) {
      optimisticCurrent = MaterialDetail(
        id: previousCurrent.id,
        classId: previousCurrent.classId,
        title: title ?? previousCurrent.title,
        description: description ?? previousCurrent.description,
        contentText: contentText ?? previousCurrent.contentText,
        orderIndex: previousCurrent.orderIndex,
        files: previousCurrent.files,
        createdAt: previousCurrent.createdAt,
        updatedAt: DateTime.now(),
      );
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      materials: state.materials.map((m) => m.id == materialId ? optimisticMaterial : m).toList(),
      currentMaterial: optimisticCurrent ?? previousCurrent,
    );

    final result = await _updateMaterial(
      materialId: materialId,
      title: title,
      description: description,
      contentText: contentText,
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        materials: previousMaterials,
        currentMaterial: previousCurrent,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (material) {
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
          materials: state.materials.map((m) => m.id == materialId ? material : m).toList(),
          currentMaterial: updatedCurrent,
          successMessage: 'Material updated successfully',
        );
      },
    );
  }

  Future<void> deleteMaterial(String materialId) async {
    final previousMaterials = List<LearningMaterial>.from(state.materials);

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      materials: state.materials.where((m) => m.id != materialId).toList(),
      clearCurrent: state.currentMaterial?.id == materialId,
    );

    final result = await _deleteMaterial(materialId);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        materials: previousMaterials,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Material deleted successfully',
      ),
    );
  }

  Future<void> reorderMaterial(String materialId, int newOrderIndex) async {
    final previousMaterials = List<LearningMaterial>.from(state.materials);

    final optimisticMaterials = state.materials.map((m) {
      if (m.id == materialId) {
        return LearningMaterial(
          id: m.id,
          classId: m.classId,
          title: m.title,
          description: m.description,
          contentText: m.contentText,
          orderIndex: newOrderIndex,
          fileCount: m.fileCount,
          createdAt: m.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return m;
    }).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    state = state.copyWith(materials: optimisticMaterials);

    final result = await _reorderMaterial(
      materialId: materialId,
      newOrderIndex: newOrderIndex,
    );
    result.fold(
      (failure) => state = state.copyWith(
        materials: previousMaterials,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) {},
    );
  }

  Future<void> reorderAllMaterials({
    required String classId,
    required List<String> materialIds,
    required List<LearningMaterial> orderedMaterials,
  }) async {
    final previousMaterials = List<LearningMaterial>.from(state.materials);

    state = state.copyWith(materials: orderedMaterials);

    final result = await _reorderAllMaterials(
      classId: classId,
      materialIds: materialIds,
    );
    result.fold(
      (failure) => state = state.copyWith(
        materials: previousMaterials,
        error: failure.message,
      ),
      (_) {},
    );
  }

  Future<void> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
  }) async {
    final previousFiles = state.currentMaterial != null
        ? List<MaterialFile>.from(state.currentMaterial!.files)
        : null;
    final tempFileId = 'temp-file-${DateTime.now().microsecondsSinceEpoch}';
    final optimisticFile = MaterialFile(
      id: tempFileId,
      fileName: fileName,
      fileType: 'application/octet-stream',
      fileSize: 0,
      uploadedAt: DateTime.now(),
      localPath: filePath,
      cachedAt: DateTime.now(),
      needsSync: true,
    );

    if (state.currentMaterial != null) {
      final optimisticFiles = [...state.currentMaterial!.files, optimisticFile];
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
        clearUploadProgress: true,
        currentUploadFileName: fileName,
        currentMaterial: MaterialDetail(
          id: state.currentMaterial!.id,
          classId: state.currentMaterial!.classId,
          title: state.currentMaterial!.title,
          description: state.currentMaterial!.description,
          contentText: state.currentMaterial!.contentText,
          orderIndex: state.currentMaterial!.orderIndex,
          files: optimisticFiles,
          createdAt: state.currentMaterial!.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
        clearUploadProgress: true,
        currentUploadFileName: fileName,
      );
    }

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
      (failure) {
        if (previousFiles != null && state.currentMaterial != null) {
          state = state.copyWith(
            isLoading: false,
            currentMaterial: MaterialDetail(
              id: state.currentMaterial!.id,
              classId: state.currentMaterial!.classId,
              title: state.currentMaterial!.title,
              description: state.currentMaterial!.description,
              contentText: state.currentMaterial!.contentText,
              orderIndex: state.currentMaterial!.orderIndex,
              files: previousFiles,
              createdAt: state.currentMaterial!.createdAt,
              updatedAt: state.currentMaterial!.updatedAt,
            ),
            error: AppErrorMapper.fromFailure(failure),
            clearUploadProgress: true,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: AppErrorMapper.fromFailure(failure),
            clearUploadProgress: true,
          );
        }
      },
      (file) {
        if (state.currentMaterial != null) {
          final updatedFiles = state.currentMaterial!.files
              .map((f) => f.id == tempFileId ? file : f)
              .toList();
          final updatedDetail = MaterialDetail(
            id: state.currentMaterial!.id,
            classId: state.currentMaterial!.classId,
            title: state.currentMaterial!.title,
            description: state.currentMaterial!.description,
            contentText: state.currentMaterial!.contentText,
            orderIndex: state.currentMaterial!.orderIndex,
            files: updatedFiles,
            createdAt: state.currentMaterial!.createdAt,
            updatedAt: state.currentMaterial!.updatedAt,
          );
          state = state.copyWith(
            isLoading: false,
            currentMaterial: updatedDetail,
            successMessage: 'File uploaded successfully',
            clearUploadProgress: true,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            successMessage: 'File uploaded successfully',
            clearUploadProgress: true,
          );
        }
      },
    );
  }

  Future<void> deleteFile(String fileId, String materialId) async {
    final previousFiles = state.currentMaterial != null
        ? List<MaterialFile>.from(state.currentMaterial!.files)
        : null;

    if (state.currentMaterial != null) {
      final updatedFiles = state.currentMaterial!.files.where((f) => f.id != fileId).toList();
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
        currentMaterial: MaterialDetail(
          id: state.currentMaterial!.id,
          classId: state.currentMaterial!.classId,
          title: state.currentMaterial!.title,
          description: state.currentMaterial!.description,
          contentText: state.currentMaterial!.contentText,
          orderIndex: state.currentMaterial!.orderIndex,
          files: updatedFiles,
          createdAt: state.currentMaterial!.createdAt,
          updatedAt: state.currentMaterial!.updatedAt,
        ),
      );
    } else {
      state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    }

    final result = await _deleteFile(fileId);
    result.fold(
      (failure) {
        if (previousFiles != null && state.currentMaterial != null) {
          state = state.copyWith(
            isLoading: false,
            currentMaterial: MaterialDetail(
              id: state.currentMaterial!.id,
              classId: state.currentMaterial!.classId,
              title: state.currentMaterial!.title,
              description: state.currentMaterial!.description,
              contentText: state.currentMaterial!.contentText,
              orderIndex: state.currentMaterial!.orderIndex,
              files: previousFiles,
              createdAt: state.currentMaterial!.createdAt,
              updatedAt: state.currentMaterial!.updatedAt,
            ),
            error: AppErrorMapper.fromFailure(failure),
          );
        } else {
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
        }
      },
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'File deleted successfully',
      ),
    );
  }

  Future<List<int>?> downloadFile(String fileId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _downloadFile(fileId);
    state = state.copyWith(isLoading: false);

    List<int>? bytes;
    result.fold(
      (failure) => state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (data) {
        bytes = data;
      },
    );

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
