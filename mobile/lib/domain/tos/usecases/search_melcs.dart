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
    );
  }
}

class SearchMelcsParams {
  final String? subject;
  final String? gradeLevel;
  final int? quarter;
  final String? query;

  SearchMelcsParams({this.subject, this.gradeLevel, this.quarter, this.query});
}
