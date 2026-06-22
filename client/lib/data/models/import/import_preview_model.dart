class PreviewRowModel {
  final int rowIndex;
  final Map<String, dynamic> data;
  final List<String> errors;
  final List<String> warnings;

  PreviewRowModel({
    required this.rowIndex,
    required this.data,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  factory PreviewRowModel.fromJson(Map<String, dynamic> json) {
    return PreviewRowModel(
      rowIndex: json['row_index'] as int,
      data: json['data'] as Map<String, dynamic>? ?? {},
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row_index': rowIndex,
      'data': data,
      'errors': errors,
      'warnings': warnings,
    };
  }
}

class PreviewResponseModel {
  final List<PreviewRowModel> rows;

  PreviewResponseModel({required this.rows});

  int get errorCount => rows.where((r) => r.hasErrors).length;
  int get warningCount => rows.where((r) => r.hasWarnings).length;
  int get validCount => rows.where((r) => !r.hasErrors).length;
  bool get hasErrors => rows.any((r) => r.hasErrors);

  factory PreviewResponseModel.fromJson(Map<String, dynamic> json) {
    return PreviewResponseModel(
      rows: (json['rows'] as List<dynamic>)
          .map((e) => PreviewRowModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ImportResultModel {
  final int imported;
  final List<String> errors;

  ImportResultModel({required this.imported, required this.errors});

  bool get hasErrors => errors.isNotEmpty;

  factory ImportResultModel.fromJson(Map<String, dynamic> json) {
    return ImportResultModel(
      imported: json['imported'] as int? ?? 0,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
