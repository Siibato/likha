import 'package:likha/data/models/auth/teacher_details_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/student_records/learner_details_model.dart';

class AccountDetailResponseModel {
  final UserModel user;
  final LearnerDetailsModel? learnerDetails;
  final TeacherDetailsModel? teacherDetails;

  AccountDetailResponseModel({
    required this.user,
    this.learnerDetails,
    this.teacherDetails,
  });

  factory AccountDetailResponseModel.fromJson(Map<String, dynamic> json) {
    return AccountDetailResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      learnerDetails: json['learner_details'] != null
          ? LearnerDetailsModel.fromJson(json['learner_details'] as Map<String, dynamic>)
          : null,
      teacherDetails: json['teacher_details'] != null
          ? TeacherDetailsModel.fromJson(json['teacher_details'] as Map<String, dynamic>)
          : null,
    );
  }
}
