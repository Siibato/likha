import 'package:likha/core/sync/mutation_result.dart';
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

  ResultFuture<MutationResult<TableOfSpecifications>> createTos({
    required String classId,
    required Map<String, dynamic> data,
  });

  ResultFuture<MutationResult<TableOfSpecifications>> updateTos({
    required String tosId,
    required Map<String, dynamic> data,
  });

  ResultFuture<MutationResult<void>> deleteTos({required String tosId});

  ResultFuture<MutationResult<TosCompetency>> addCompetency({
    required String tosId,
    required Map<String, dynamic> data,
  });

  ResultFuture<MutationResult<TosCompetency>> updateCompetency({
    required String competencyId,
    required Map<String, dynamic> data,
  });

  ResultFuture<MutationResult<void>> deleteCompetency({required String competencyId});

  ResultFuture<MutationResult<List<TosCompetency>>> bulkAddCompetencies({
    required String tosId,
    required List<Map<String, dynamic>> competencies,
  });

  ResultFuture<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? gradingPeriodNumber,
    String? query,
    int limit = 30,
    int offset = 0,
    bool skipBackgroundRefresh = false,
  });
}
