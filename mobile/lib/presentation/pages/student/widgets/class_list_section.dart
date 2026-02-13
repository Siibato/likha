import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/student/widgets/class_card.dart';

class ClassListSection extends StatelessWidget {
  final List<dynamic> classes;
  final Function(dynamic) onClassTap;

  const ClassListSection({
    super.key,
    required this.classes,
    required this.onClassTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      // Matching the page's horizontal padding
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final cls = classes[index];
            return ClassCard(
              title: cls.title,
              teacher: cls.teacherFullName,
              onTap: () => onClassTap(cls),
            );
          },
          childCount: classes.length,
        ),
      ),
    );
  }
}