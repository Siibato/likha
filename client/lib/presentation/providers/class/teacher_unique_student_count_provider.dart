import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/providers/class/class_list_provider.dart';

final teacherUniqueStudentCountProvider = FutureProvider<int>((ref) async {
  final classListState = ref.watch(classListProvider);
  final classes = classListState.classes;

  if (classes.isEmpty) return 0;

  final localDataSource = sl<ClassLocalDataSource>();
  final uniqueIds = <String>{};

  for (final cls in classes) {
    final ids = await localDataSource.getParticipantIds(cls.id);
    uniqueIds.addAll(ids);
  }

  return uniqueIds.length;
});
