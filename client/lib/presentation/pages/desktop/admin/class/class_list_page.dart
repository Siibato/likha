import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/presentation/pages/desktop/admin/class/class_detail_page.dart';
import 'package:likha/presentation/pages/desktop/admin/class/class_create_page.dart';
import 'package:likha/presentation/widgets/desktop/admin/class/class_data_table.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/shared/search/search_filter_bar.dart';

class AdminClassesPage extends ConsumerStatefulWidget {
  const AdminClassesPage({super.key});

  @override
  ConsumerState<AdminClassesPage> createState() =>
      _AdminClassesPageState();
}

class _AdminClassesPageState extends ConsumerState<AdminClassesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classListProvider.notifier).loadAllClasses(skipBackgroundRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(ClassEntity cls) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteClassDialog(
        className: cls.title,
        studentCount: cls.studentCount,
        onConfirm: () {
          Navigator.pop(ctx);
          ref.read(classListProvider.notifier).deleteClass(cls.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classListState = ref.watch(classListProvider);

    final filteredClasses = classListState.classes.where((c) {
      if (_selectedFilter == 'active' && c.isArchived) return false;
      if (_selectedFilter == 'archived' && !c.isArchived) return false;
      if (_selectedFilter == 'advisory' && !c.isAdvisory) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.title.toLowerCase().contains(q) ||
          c.teacherFullName.toLowerCase().contains(q) ||
          c.teacherUsername.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return DesktopPageScaffold(
      title: 'Class Management',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminCreateClassPage(),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Class'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFilterBar.classes(
            controller: _searchController,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
          ),
          const SizedBox(height: 20),

          // Table
          if (classListState.isLoading && classListState.classes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else
            ClassDataTable(
              classes: filteredClasses,
              onTap: (cls) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminClassDetailPage(classId: cls.id),
                ),
              ),
              onDelete: (cls) => _showDeleteConfirmation(cls),
            ),
        ],
      ),
    );
  }
}

class _DeleteClassDialog extends StatefulWidget {
  final String className;
  final int studentCount;
  final VoidCallback onConfirm;

  const _DeleteClassDialog({
    required this.className,
    required this.studentCount,
    required this.onConfirm,
  });

  @override
  State<_DeleteClassDialog> createState() => _DeleteClassDialogState();
}

class _DeleteClassDialogState extends State<_DeleteClassDialog> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final match = _controller.text.trim() == 'DELETE';
      if (match != _canConfirm) setState(() => _canConfirm = match);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Delete Class',
      warningBox: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.semanticErrorDark.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.semanticErrorDark.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_rounded,
                size: 18, color: AppColors.semanticErrorDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This will remove all ${widget.studentCount} student(s) and the teacher from "${widget.className}". This action cannot be undone.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.semanticErrorDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type DELETE to confirm:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'DELETE',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundLight,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.semanticErrorDark, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Delete Class',
          isPrimary: true,
          isDestructive: true,
          onPressed: _canConfirm ? widget.onConfirm : () {},
        ),
      ],
    );
  }
}
