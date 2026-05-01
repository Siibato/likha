import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'form_fields.dart';

/// A reusable search and filter bar widget for admin pages
/// with search field and optional filter dropdowns.
class SearchAndFilterBar extends StatelessWidget {
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

  const SearchAndFilterBar({
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

  /// Creates a simple search bar without filters
  factory SearchAndFilterBar.search({
    TextEditingController? controller,
    String hint = 'Search...',
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    bool enabled = true,
  }) {
    return SearchAndFilterBar(
      searchController: controller,
      searchHint: hint,
      onSearchChanged: onChanged,
      onClear: onClear,
      enabled: enabled,
    );
  }

  /// Creates a search bar with role filter for accounts
  factory SearchAndFilterBar.accounts({
    TextEditingController? controller,
    ValueChanged<String>? onSearchChanged,
    VoidCallback? onClear,
    String? selectedRole,
    ValueChanged<String?>? onRoleChanged,
    List<Widget>? actions,
    bool enabled = true,
  }) {
    return SearchAndFilterBar(
      searchController: controller,
      searchHint: 'Search accounts...',
      onSearchChanged: onSearchChanged,
      onClear: onClear,
      filterItems: [
        const DropdownMenuItem(value: null, child: Text('All Roles')),
        const DropdownMenuItem(value: 'admin', child: Text('Admin')),
        const DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
        const DropdownMenuItem(value: 'student', child: Text('Student')),
      ],
      selectedFilter: selectedRole,
      onFilterChanged: onRoleChanged,
      filterLabel: 'Role',
      additionalActions: actions,
      enabled: enabled,
    );
  }

  /// Creates a search bar with status filter for accounts
  factory SearchAndFilterBar.accountStatus({
    TextEditingController? controller,
    ValueChanged<String>? onSearchChanged,
    VoidCallback? onClear,
    String? selectedStatus,
    ValueChanged<String?>? onStatusChanged,
    List<Widget>? actions,
    bool enabled = true,
  }) {
    return SearchAndFilterBar(
      searchController: controller,
      searchHint: 'Search accounts...',
      onSearchChanged: onSearchChanged,
      onClear: onClear,
      filterItems: [
        const DropdownMenuItem(value: null, child: Text('All Status')),
        const DropdownMenuItem(value: 'activated', child: Text('Active')),
        const DropdownMenuItem(value: 'pending_activation', child: Text('Pending')),
        const DropdownMenuItem(value: 'locked', child: Text('Locked')),
        const DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
        const DropdownMenuItem(value: 'deactivated', child: Text('Deactivated')),
      ],
      selectedFilter: selectedStatus,
      onFilterChanged: onStatusChanged,
      filterLabel: 'Status',
      additionalActions: actions,
      enabled: enabled,
    );
  }

  /// Creates a search bar for classes
  factory SearchAndFilterBar.classes({
    TextEditingController? controller,
    ValueChanged<String>? onSearchChanged,
    VoidCallback? onClear,
    String? selectedFilter,
    ValueChanged<String?>? onFilterChanged,
    List<Widget>? actions,
    bool enabled = true,
  }) {
    return SearchAndFilterBar(
      searchController: controller,
      searchHint: 'Search classes...',
      onSearchChanged: onSearchChanged,
      onClear: onClear,
      filterItems: [
        const DropdownMenuItem(value: null, child: Text('All Classes')),
        const DropdownMenuItem(value: 'active', child: Text('Active')),
        const DropdownMenuItem(value: 'archived', child: Text('Archived')),
        const DropdownMenuItem(value: 'advisory', child: Text('Advisory Only')),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Search field
              Expanded(
                flex: 2,
                child: DesktopFormField.searchField(
                  controller: searchController,
                  hintText: searchHint,
                  onChanged: onSearchChanged,
                  onClear: onClear,
                  enabled: enabled,
                ),
              ),
              
              // Filter dropdown
              if (filterItems != null) ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: DesktopFormField.dropdownFormField<String>(
                    value: selectedFilter,
                    items: filterItems!,
                    onChanged: onFilterChanged ?? (value) {},
                    labelText: filterLabel,
                    enabled: enabled,
                  ),
                ),
              ],
              
              // Additional actions
              if (additionalActions != null) ...[
                const SizedBox(width: 16),
                ...additionalActions!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact search bar for use in tight spaces
class CompactSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool enabled;
  final double? width;

  const CompactSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
    this.enabled = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 300,
      child: DesktopFormField.searchField(
        controller: controller,
        hintText: hint,
        onChanged: onChanged,
        onClear: onClear,
        enabled: enabled,
      ),
    );
  }
}

/// A filter chip widget for quick filtering options
class FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Color? selectedColor;
  final Color? backgroundColor;

  const FilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.selectedColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected != null ? () => onSelected!(!selected) : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (selectedColor ?? AppColors.foregroundPrimary)
                : (backgroundColor ?? AppColors.backgroundTertiary),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? (selectedColor ?? AppColors.foregroundPrimary)
                  : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected
                  ? Colors.white
                  : AppColors.foregroundSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of filter chips
class FilterChipRow extends StatelessWidget {
  final List<FilterChip> chips;
  final double spacing;

  const FilterChipRow({
    super.key,
    required this.chips,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: 8,
      children: chips,
    );
  }
}
