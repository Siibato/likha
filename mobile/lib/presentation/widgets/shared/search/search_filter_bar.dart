import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_text_styles.dart';
import 'app_search_bar.dart';

/// A search bar with optional filter dropdown for desktop list pages.
///
/// Promoted from `desktop/admin/widgets/search_filter_bar.dart` to shared —
/// the original is used by both admin and teacher desktop pages.
///
/// Named constructors provide pre-configured variants:
/// - [SearchFilterBar.search] — search-only, no filter
/// - [SearchFilterBar.accounts] — with role filter
/// - [SearchFilterBar.accountStatus] — with status filter
/// - [SearchFilterBar.classes] — with class filter
class SearchFilterBar extends StatelessWidget {
  final TextEditingController? searchController;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClear;
  final List<DropdownMenuItem<String>>? filterItems;
  final String? selectedFilter;
  final ValueChanged<String?>? onFilterChanged;
  final String filterLabel;
  final List<Widget>? additionalActions;
  final bool enabled;

  const SearchFilterBar({
    super.key,
    this.searchController,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.onClear,
    this.filterItems,
    this.selectedFilter,
    this.onFilterChanged,
    this.filterLabel = 'Filter',
    this.additionalActions,
    this.enabled = true,
  });

  factory SearchFilterBar.search({
    TextEditingController? controller,
    String hint = 'Search...',
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    bool enabled = true,
  }) {
    return SearchFilterBar(
      searchController: controller,
      searchHint: hint,
      onSearchChanged: onChanged,
      onClear: onClear,
      enabled: enabled,
    );
  }

  factory SearchFilterBar.accounts({
    TextEditingController? controller,
    ValueChanged<String>? onSearchChanged,
    VoidCallback? onClear,
    String? selectedRole,
    ValueChanged<String?>? onRoleChanged,
    List<Widget>? actions,
    bool enabled = true,
  }) {
    return SearchFilterBar(
      searchController: controller,
      searchHint: 'Search accounts...',
      onSearchChanged: onSearchChanged,
      onClear: onClear,
      filterItems: const [
        DropdownMenuItem(value: null, child: Text('All Roles')),
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
        DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
        DropdownMenuItem(value: 'student', child: Text('Student')),
      ],
      selectedFilter: selectedRole,
      onFilterChanged: onRoleChanged,
      filterLabel: 'Role',
      additionalActions: actions,
      enabled: enabled,
    );
  }

  factory SearchFilterBar.accountStatus({
    TextEditingController? controller,
    ValueChanged<String>? onSearchChanged,
    VoidCallback? onClear,
    String? selectedStatus,
    ValueChanged<String?>? onStatusChanged,
    List<Widget>? actions,
    bool enabled = true,
  }) {
    return SearchFilterBar(
      searchController: controller,
      searchHint: 'Search accounts...',
      onSearchChanged: onSearchChanged,
      onClear: onClear,
      filterItems: const [
        DropdownMenuItem(value: null, child: Text('All Status')),
        DropdownMenuItem(value: 'activated', child: Text('Active')),
        DropdownMenuItem(value: 'pending_activation', child: Text('Pending')),
        DropdownMenuItem(value: 'locked', child: Text('Locked')),
        DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
        DropdownMenuItem(value: 'deactivated', child: Text('Deactivated')),
      ],
      selectedFilter: selectedStatus,
      onFilterChanged: onStatusChanged,
      filterLabel: 'Status',
      additionalActions: actions,
      enabled: enabled,
    );
  }

  factory SearchFilterBar.classes({
    TextEditingController? controller,
    ValueChanged<String>? onSearchChanged,
    VoidCallback? onClear,
    String? selectedFilter,
    ValueChanged<String?>? onFilterChanged,
    List<Widget>? actions,
    bool enabled = true,
  }) {
    return SearchFilterBar(
      searchController: controller,
      searchHint: 'Search classes...',
      onSearchChanged: onSearchChanged,
      onClear: onClear,
      filterItems: const [
        DropdownMenuItem(value: null, child: Text('All Classes')),
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'archived', child: Text('Archived')),
        DropdownMenuItem(value: 'advisory', child: Text('Advisory Only')),
      ],
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
      filterLabel: 'Filter',
      additionalActions: actions,
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AppSearchBar(
              controller: searchController,
              hint: searchHint,
              onChanged: onSearchChanged,
              onClear: onClear,
              enabled: enabled,
              padding: EdgeInsets.zero,
            ),
          ),
          if (filterItems != null) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 160,
              child: _FilterDropdown(
                value: selectedFilter,
                items: filterItems!,
                onChanged: enabled ? onFilterChanged : null,
                label: filterLabel,
              ),
            ),
          ],
          if (additionalActions != null) ...[
            const SizedBox(width: 16),
            ...additionalActions!,
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final String label;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: Text(label, style: AppTextStyles.inputLabel),
          style: AppTextStyles.inputText,
          borderRadius: BorderRadius.circular(10),
          isExpanded: true,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: AppColors.foregroundTertiary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
