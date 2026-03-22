import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

abstract class TosRepository {
  ResultFuture<List<TableOfSpecifications>> getTosList({
    required String classId,
  });

  ResultFuture<(TableOfSpecifications, List<TosCompetency>)> getTosDetail({
    required String tosId,
  });

  ResultFuture<TableOfSpecifications> createTos({
    required String classId,
    required Map<String, dynamic> data,
  });

  ResultFuture<TableOfSpecifications> updateTos({
    required String tosId,
    required Map<String, dynamic> data,
  });

  ResultVoid deleteTos({required String tosId});

  ResultFuture<TosCompetency> addCompetency({
    required String tosId,
    required Map<String, dynamic> data,
  });

  ResultFuture<TosCompetency> updateCompetency({
    required String competencyId,
    required Map<String, dynamic> data,
  });

  ResultVoid deleteCompetency({required String competencyId});

  ResultFuture<List<TosCompetency>> bulkAddCompetencies({
    required String tosId,
    required List<Map<String, dynamic>> competencies,
  });

  ResultFuture<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? quarter,
    String? query,
  });
}
