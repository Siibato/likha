import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/repositories/learning_materials/learning_material_repository_base.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';

mixin LearningMaterialQueryMixin on LearningMaterialRepositoryBase {
  @override
  ResultFuture<List<LearningMaterial>> getMaterials({
    required String classId,
  }) async {
    try {
      var cachedMaterials = <LearningMaterial>[];
      bool hasCachedData = false;

      try {
        cachedMaterials = await localDataSource.getCachedMaterials(classId);
        hasCachedData = true;
      } on CacheException {
        hasCachedData = false;
      }

      if (serverReachabilityService.isServerReachable) {
        try {
          final freshMaterials = await remoteDataSource.getMaterials(classId: classId);
          await localDataSource.cacheMaterials(freshMaterials);
          return Right(freshMaterials);
        } catch (e) {
          if (!hasCachedData) {
            if (e is ServerException) return Left(ServerFailure(e.message));
            if (e is NetworkException) return Left(NetworkFailure(e.message));
            return Left(ServerFailure(e.toString()));
          }
          // Has cache — fall through
        }
      }

      if (hasCachedData) return Right(cachedMaterials);

      return const Left(NetworkFailure('No internet connection and no cached data'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<MaterialDetail> getMaterialDetail({
    required String materialId,
  }) async {
    try {
      LearningMaterialModel? cachedMaterial;
      bool hasCachedData = false;

      try {
        cachedMaterial = await localDataSource.getCachedMaterialDetail(materialId);
        hasCachedData = true;
      } on CacheException {
        hasCachedData = false;
      }

      if (serverReachabilityService.isServerReachable) {
        try {
          final freshMaterial = await remoteDataSource.getMaterialDetail(materialId: materialId);

          final detail = MaterialDetail(
            id: freshMaterial.id,
            classId: freshMaterial.classId,
            title: freshMaterial.title,
            description: freshMaterial.description,
            contentText: freshMaterial.contentText,
            orderIndex: freshMaterial.orderIndex,
            files: const [],
            createdAt: freshMaterial.createdAt,
            updatedAt: freshMaterial.updatedAt,
          );
          return Right(detail);
        } catch (e) {
          if (!hasCachedData) {
            if (e is ServerException) return Left(ServerFailure(e.message));
            if (e is NetworkException) return Left(NetworkFailure(e.message));
            return Left(ServerFailure(e.toString()));
          }
          // Has cache — fall through
        }
      }

      if (hasCachedData && cachedMaterial != null) {
        return Right(_toDetail(cachedMaterial));
      }

      return const Left(NetworkFailure('No internet connection and no cached data'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Converts a [LearningMaterialModel] to a [MaterialDetail].
  MaterialDetail _toDetail(LearningMaterialModel m) => MaterialDetail(
        id: m.id,
        classId: m.classId,
        title: m.title,
        description: m.description,
        contentText: m.contentText,
        orderIndex: m.orderIndex,
        files: const [], // Files are stored separately in the database
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      );
}