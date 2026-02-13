import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/learning_materials/data/datasources/learning_material_remote_datasource.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

class LearningMaterialRepositoryImpl implements LearningMaterialRepository {
  final LearningMaterialRemoteDataSource _remoteDataSource;

  LearningMaterialRepositoryImpl(this._remoteDataSource);

  @override
  ResultFuture<LearningMaterial> createMaterial({
    required String classId,
    required String title,
    String? description,
    String? contentText,
  }) async {
    try {
      final result = await _remoteDataSource.createMaterial(
        classId: classId,
        data: {
          'title': title,
          if (description != null) 'description': description,
          if (contentText != null) 'content_text': contentText,
        },
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<List<LearningMaterial>> getMaterials({required String classId}) async {
    try {
      final result = await _remoteDataSource.getMaterials(classId: classId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<MaterialDetail> getMaterialDetail({required String materialId}) async {
    try {
      final result = await _remoteDataSource.getMaterialDetail(materialId: materialId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<LearningMaterial> updateMaterial({
    required String materialId,
    String? title,
    String? description,
    String? contentText,
  }) async {
    try {
      final result = await _remoteDataSource.updateMaterial(
        materialId: materialId,
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (contentText != null) 'content_text': contentText,
        },
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultVoid deleteMaterial({required String materialId}) async {
    try {
      await _remoteDataSource.deleteMaterial(materialId: materialId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<LearningMaterial> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
  }) async {
    try {
      final result = await _remoteDataSource.reorderMaterial(
        materialId: materialId,
        newOrderIndex: newOrderIndex,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<MaterialFile> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final result = await _remoteDataSource.uploadFile(
        materialId: materialId,
        filePath: filePath,
        fileName: fileName,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultVoid deleteFile({required String fileId}) async {
    try {
      await _remoteDataSource.deleteFile(fileId: fileId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<List<int>> downloadFile({required String fileId}) async {
    try {
      final result = await _remoteDataSource.downloadFile(fileId: fileId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
