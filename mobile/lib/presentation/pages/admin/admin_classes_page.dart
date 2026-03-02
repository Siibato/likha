import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/admin/admin_class_detail_page.dart';
import 'package:likha/presentation/pages/admin/admin_create_class_page.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminClassesPage extends ConsumerStatefulWidget {
  const AdminClassesPage({super.key});

  @override
  ConsumerState<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends ConsumerState<AdminClassesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadAllClasses();
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
          'Class Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
      ),
      body: classState.isLoading && classState.classes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : classState.classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.class_outlined, size: 64, color: Color(0xFFCCCCCC)),
                      SizedBox(height: 16),
                      Text(
                        'No classes yet',
                        style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(classProvider.notifier).loadAllClasses(),
                  color: const Color(0xFF2B2B2B),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: classState.classes.length,
                    itemBuilder: (context, index) {
                      final cls = classState.classes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: const Icon(
                            Icons.class_outlined,
                            color: Color(0xFF2B2B2B),
                          ),
                          title: Text(
                            cls.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Teacher: ${cls.teacherFullName}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF999999),
                            ),
                          ),
                          trailing: Text(
                            '${cls.studentCount} student${cls.studentCount != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF999999),
                            ),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminClassDetailPage(classId: cls.id),
                            ),
                          ).then((_) => ref.read(classProvider.notifier).loadAllClasses()),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminCreateClassPage()),
        ).then((_) => ref.read(classProvider.notifier).loadAllClasses()),
        backgroundColor: const Color(0xFF2B2B2B),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
