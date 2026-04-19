import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/teacher/class/class_detail_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_class_state.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/class_card.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/utils/logout_helper.dart';

class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  ConsumerState<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Classes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            color: const Color(0xFF2B2B2B),
            onPressed: () => handleLogoutTap(context, ref),
          ),
        ],
      ),
      body: classState.isLoading && classState.classes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : classState.classes.isEmpty
              ? const EmptyClassState()
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(classProvider.notifier).loadClasses(),
                  color: const Color(0xFF2B2B2B),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: classState.classes.length,
                    itemBuilder: (context, index) {
                      final cls = classState.classes[index];
                      return ClassCard(
                        title: cls.title,
                        subtitle: '${cls.studentCount} student${cls.studentCount != 1 ? 's' : ''}',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClassDetailPage(classId: cls.id),
                          ),
                        ).then((_) =>
                            ref.read(classProvider.notifier).loadClasses()),
                      );
                    },
                  ),
                ),
    );
  }
}