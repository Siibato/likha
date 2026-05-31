import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class SearchMelcs {
  final TosRepository _repository;

  SearchMelcs(this._repository);

  ResultFuture<List<MelcEntryModel>> call(SearchMelcsParams params) {
    return _repository.searchMelcs(
      subject: params.subject,
      gradeLevel: params.gradeLevel,
      gradingPeriodNumber: params.quarter,
      query: params.query,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class SearchMelcsParams {
  final String? subject;
  final String? gradeLevel;
  final int? quarter;
  final String? query;
  final int limit;
  final int offset;

  SearchMelcsParams({
    this.subject,
    this.gradeLevel,
    this.quarter,
    this.query,
    this.limit = 30,
    this.offset = 0,
  });

  SearchMelcsParams copyWith({
    String? subject,
    String? gradeLevel,
    int? quarter,
    String? query,
    int? limit,
    int? offset,
  }) {
    return SearchMelcsParams(
      subject: subject ?? this.subject,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      quarter: quarter ?? this.quarter,
      query: query ?? this.query,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}
