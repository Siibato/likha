import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/usecases/create_material.dart';
import 'package:likha/domain/learning_materials/usecases/delete_file.dart' as material;
import 'package:likha/domain/learning_materials/usecases/delete_material.dart';
import 'package:likha/domain/learning_materials/usecases/download_file.dart' as material;
import 'package:likha/domain/learning_materials/usecases/get_material_detail.dart';
import 'package:likha/domain/learning_materials/usecases/get_materials.dart';
import 'package:likha/domain/learning_materials/usecases/reorder_material.dart';
import 'package:likha/domain/learning_materials/usecases/update_material.dart';
import 'package:likha/domain/learning_materials/usecases/upload_file.dart' as material;
import 'package:likha/injection_container.dart';

class LearningMaterialState {
  final List<LearningMaterial> materials;
  final MaterialDetail? currentMaterial;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  LearningMaterialState({
    this.materials = const [],
    this.currentMaterial,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  LearningMaterialState copyWith({
    List<LearningMaterial>? materials,
    MaterialDetail? currentMaterial,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearCurrent = false,
  }) {
    return LearningMaterialState(
      materials: materials ?? this.materials,
      currentMaterial: clearCurrent ? null : (currentMaterial ?? this.currentMaterial),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error,
      successMessage: clearSuccess ? null : successMessage,
    );
  }
}

class LearningMaterialNotifier extends StateNotifier<LearningMaterialState> {
  final CreateMaterial _createMaterial;
  final GetMaterials _getMaterials;
  final GetMaterialDetail _getMaterialDetail;
  final UpdateMaterial _updateMaterial;
  final DeleteMaterial _deleteMaterial;
  final ReorderMaterial _reorderMaterial;
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
    this._uploadFile,
    this._deleteFile,
    this._downloadFile,
  ) : super(LearningMaterialState()) {
    _refreshSub = sl<DataEventBus>().onMaterialsChanged.listen((classId) {
      if (_currentClassId != null && _currentClassId == classId) {
        loadMaterials(_currentClassId!);
      }
    });
  }

  Future<void> loadMaterials(String classId) async {
    _currentClassId = classId;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getMaterials(classId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (materials) => state = state.copyWith(isLoading: false, materials: materials),
    );
  }

  Future<void> loadMaterialDetail(String materialId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getMaterialDetail(materialId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
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
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (material) {
        final updatedMaterials = [...state.materials, material];
        state = state.copyWith(
          isLoading: false,
          materials: updatedMaterials,
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
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _updateMaterial(
      materialId: materialId,
      title: title,
      description: description,
      contentText: contentText,
    );
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (material) {
        final updatedMaterials = state.materials
            .map((m) => m.id == materialId ? material : m)
            .toList();
        state = state.copyWith(
          isLoading: false,
          materials: updatedMaterials,
          successMessage: 'Material updated successfully',
        );
      },
    );
  }

  Future<void> deleteMaterial(String materialId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _deleteMaterial(materialId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
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
      (failure) => state = state.copyWith(error: failure.message),
      (material) {
        final updatedMaterials = state.materials
            .map((m) => m.id == materialId ? material : m)
            .toList();
        updatedMaterials.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        state = state.copyWith(materials: updatedMaterials);
      },
    );
  }

  Future<void> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _uploadFile(
      materialId: materialId,
      filePath: filePath,
      fileName: fileName,
    );
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (file) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'File uploaded successfully',
        );
        loadMaterialDetail(materialId);
      },
    );
  }

  Future<void> deleteFile(String fileId, String materialId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _deleteFile(fileId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
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
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return null;
      },
      (bytes) => bytes,
    );
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
    sl<ReorderMaterial>(),
    sl<material.UploadFile>(),
    sl<material.DeleteFile>(),
    sl<material.DownloadFile>(),
  ),
);
