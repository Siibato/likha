import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'package:likha/data/datasources/remote/operations/tos/tos.dart' as ops;

abstract class TosRemoteDataSource {
  Future<List<TosModel>> getTosByClass({required String classId});
  Future<(TosModel, List<CompetencyModel>)> getTosDetail({required String tosId});
  Future<TosModel> createTos({required String classId, required Map<String, dynamic> data});
  Future<TosModel> updateTos({required String tosId, required Map<String, dynamic> data});
  Future<void> deleteTos({required String tosId});
  Future<CompetencyModel> addCompetency({required String tosId, required Map<String, dynamic> data});
  Future<CompetencyModel> updateCompetency({required String competencyId, required Map<String, dynamic> data});
  Future<void> deleteCompetency({required String competencyId});
  Future<List<CompetencyModel>> bulkAddCompetencies({required String tosId, required List<Map<String, dynamic>> competencies});
  Future<List<MelcEntryModel>> searchMelcs({String? subject, String? gradeLevel, int? quarter, String? query, int limit = 30, int offset = 0});
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
  }) =>
      ops.createTos(
        _dioClient,
        classId: classId,
        data: data,
      );

  @override
  Future<TosModel> updateTos({
    required String tosId,
    required Map<String, dynamic> data,
  }) =>
      ops.updateTos(
        _dioClient,
        tosId: tosId,
        data: data,
      );

  @override
  Future<void> deleteTos({required String tosId}) =>
      ops.deleteTos(
        _dioClient,
        tosId: tosId,
      );

  @override
  Future<CompetencyModel> addCompetency({
    required String tosId,
    required Map<String, dynamic> data,
  }) =>
      ops.addCompetency(
        _dioClient,
        tosId: tosId,
        data: data,
      );

  @override
  Future<CompetencyModel> updateCompetency({
    required String competencyId,
    required Map<String, dynamic> data,
  }) =>
      ops.updateCompetency(
        _dioClient,
        competencyId: competencyId,
        data: data,
      );

  @override
  Future<void> deleteCompetency({required String competencyId}) =>
      ops.deleteCompetency(
        _dioClient,
        competencyId: competencyId,
      );

  @override
  Future<List<CompetencyModel>> bulkAddCompetencies({
    required String tosId,
    required List<Map<String, dynamic>> competencies,
  }) =>
      ops.bulkAddCompetencies(
        _dioClient,
        tosId: tosId,
        competencies: competencies,
      );

  @override
  Future<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? quarter,
    String? query,
    int limit = 30,
    int offset = 0,
  }) =>
      ops.searchMelcs(
        _dioClient,
        subject: subject,
        gradeLevel: gradeLevel,
        quarter: quarter,
        query: query,
        limit: limit,
        offset: offset,
      );
}
