import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/setup/entities/school_details.dart';

class SchoolDetailsModel extends SchoolDetails {
  final DateTime? cachedAt;
  final SyncStatus syncStatus;

  const SchoolDetailsModel({
    required super.id,
    required super.schoolName,
    required super.schoolRegion,
    required super.schoolDivision,
    required super.schoolYear,
    required super.schoolCode,
    super.schoolDistrict,
    super.schoolHeadName,
    super.schoolHeadPosition,
    this.cachedAt,
    this.syncStatus = SyncStatus.synced,
  });

  factory SchoolDetailsModel.fromJson(Map<String, dynamic> json) {
    return SchoolDetailsModel(
      id: json['id'] as String? ?? '1',
      schoolName: json['school_name'] as String? ?? '',
      schoolRegion: json['school_region'] as String? ?? '',
      schoolDivision: json['school_division'] as String? ?? '',
      schoolYear: json['school_year'] as String? ?? '',
      schoolCode: json['school_code'] as String? ?? '',
      schoolDistrict: json['school_district'] as String?,
      schoolHeadName: json['school_head_name'] as String?,
      schoolHeadPosition: json['school_head_position'] as String?,
      syncStatus: SyncStatus.synced,
    );
  }

  factory SchoolDetailsModel.fromMap(Map<String, dynamic> map) {
    return SchoolDetailsModel(
      id: map['id'] as String? ?? '1',
      schoolName: map['school_name'] as String? ?? '',
      schoolRegion: map['school_region'] as String? ?? '',
      schoolDivision: map['school_division'] as String? ?? '',
      schoolYear: map['school_year'] as String? ?? '',
      schoolCode: map['school_code'] as String? ?? '',
      schoolDistrict: map['school_district'] as String?,
      schoolHeadName: map['school_head_name'] as String?,
      schoolHeadPosition: map['school_head_position'] as String?,
      cachedAt: map['cached_at'] != null
          ? DateTime.parse(map['cached_at'] as String)
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.dbValue == (map['sync_status'] as String?),
        orElse: () => SyncStatus.synced,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_name': schoolName,
      'school_region': schoolRegion,
      'school_division': schoolDivision,
      'school_year': schoolYear,
      'school_code': schoolCode,
      'school_district': schoolDistrict,
      'school_head_name': schoolHeadName,
      'school_head_position': schoolHeadPosition,
      'cached_at': cachedAt?.toIso8601String(),
      'sync_status': syncStatus.dbValue,
    };
  }

  Map<String, dynamic> toPayload() {
    return {
      'id': id,
      'school_name': schoolName,
      'school_region': schoolRegion,
      'school_division': schoolDivision,
      'school_year': schoolYear,
      'school_code': schoolCode,
      'school_district': schoolDistrict,
      'school_head_name': schoolHeadName,
      'school_head_position': schoolHeadPosition,
    };
  }

  SchoolDetailsModel copyWith({
    String? id,
    String? schoolName,
    String? schoolRegion,
    String? schoolDivision,
    String? schoolYear,
    String? schoolCode,
    String? schoolDistrict,
    bool clearSchoolDistrict = false,
    String? schoolHeadName,
    bool clearSchoolHeadName = false,
    String? schoolHeadPosition,
    bool clearSchoolHeadPosition = false,
    DateTime? cachedAt,
    SyncStatus? syncStatus,
  }) {
    return SchoolDetailsModel(
      id: id ?? this.id,
      schoolName: schoolName ?? this.schoolName,
      schoolRegion: schoolRegion ?? this.schoolRegion,
      schoolDivision: schoolDivision ?? this.schoolDivision,
      schoolYear: schoolYear ?? this.schoolYear,
      schoolCode: schoolCode ?? this.schoolCode,
      schoolDistrict: clearSchoolDistrict ? null : (schoolDistrict ?? this.schoolDistrict),
      schoolHeadName: clearSchoolHeadName ? null : (schoolHeadName ?? this.schoolHeadName),
      schoolHeadPosition: clearSchoolHeadPosition ? null : (schoolHeadPosition ?? this.schoolHeadPosition),
      cachedAt: cachedAt ?? this.cachedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
