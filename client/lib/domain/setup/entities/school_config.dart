import 'package:equatable/equatable.dart';

class SchoolConfig extends Equatable {
  final String serverUrl;
  final String schoolName;

  const SchoolConfig({
    required this.serverUrl,
    required this.schoolName,
  });

  @override
  List<Object> get props => [serverUrl, schoolName];
}
