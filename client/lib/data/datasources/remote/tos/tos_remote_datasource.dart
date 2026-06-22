import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'package:likha/data/datasources/remote/tos/operations/tos.dart' as ops;

abstract class TosRemoteDataSource {
  Future<List<TosModel>> getTosByClass({required String classId});
  Future<(TosModel, List<CompetencyModel>)> getTosDetail({required String tosId});
  Future<TosModel> createTos({required String classId, required Map<String, dynamic> data, String? idempotencyKey});
  Future<TosModel> updateTos({required String tosId, required Map<String, dynamic> data, String? idempotencyKey});
  Future<void> deleteTos({required String tosId, String? idempotencyKey});
  Future<CompetencyModel> addCompetency({required String tosId, required Map<String, dynamic> data, String? idempotencyKey});
  Future<CompetencyModel> updateCompetency({required String competencyId, required Map<String, dynamic> data, String? idempotencyKey});
  Future<void> deleteCompetency({required String competencyId, String? idempotencyKey});
  Future<List<CompetencyModel>> bulkAddCompetencies({required String tosId, required List<Map<String, dynamic>> competencies, String? idempotencyKey});
  Future<List<MelcEntryModel>> searchMelcs({String? subject, String? gradeLevel, int? termNumber, String? query, int limit = 30, int offset = 0});
}

class TosRemoteDataSourceImpl implements TosRemoteDataSource {
  final DioClient _dioClient;

  TosRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<TosModel>> getTosByClass({required String classId}) =>
      ops.getTosByClass(
        _dioClient,
        classId: classId,
      );

  @override
  Future<(TosModel, List<CompetencyModel>)> getTosDetail({required String tosId}) =>
      ops.getTosDetail(
        _dioClient,
        tosId: tosId,
      );

  @override
  Future<TosModel> createTos({
    required String classId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.createTos(
        _dioClient,
        classId: classId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<TosModel> updateTos({
    required String tosId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.updateTos(
        _dioClient,
        tosId: tosId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteTos({required String tosId, String? idempotencyKey}) =>
      ops.deleteTos(
        _dioClient,
        tosId: tosId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<CompetencyModel> addCompetency({
    required String tosId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.addCompetency(
        _dioClient,
        tosId: tosId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<CompetencyModel> updateCompetency({
    required String competencyId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.updateCompetency(
        _dioClient,
        competencyId: competencyId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteCompetency({required String competencyId, String? idempotencyKey}) =>
      ops.deleteCompetency(
        _dioClient,
        competencyId: competencyId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<List<CompetencyModel>> bulkAddCompetencies({
    required String tosId,
    required List<Map<String, dynamic>> competencies,
    String? idempotencyKey,
  }) =>
      ops.bulkAddCompetencies(
        _dioClient,
        tosId: tosId,
        competencies: competencies,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? termNumber,
    String? query,
    int limit = 30,
    int offset = 0,
  }) =>
      ops.searchMelcs(
        _dioClient,
        subject: subject,
        gradeLevel: gradeLevel,
        termNumber: termNumber,
        query: query,
        limit: limit,
        offset: offset,
      );
}
