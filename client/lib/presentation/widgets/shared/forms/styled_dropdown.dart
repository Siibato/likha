import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A styled dropdown menu that matches the app's design system.
///
/// Generic over any type [T], providing a 2-layer container appearance
/// consistent with other styled form inputs.
/// The label sits outside the field and floats above when focused or selected.
/// Error text appears below the field container.
class StyledDropdown<T> extends StatefulWidget {
  final T? value;
  final String label;
  final IconData icon;
  final bool enabled;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final String? errorText;

  const StyledDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.errorText,
  });

  @override
  State<StyledDropdown<T>> createState() => _StyledDropdownState<T>();
}

class _StyledDropdownState<T> extends State<StyledDropdown<T>> {
  final FocusNode _focusNode = FocusNode();

  bool get _isFocused => _focusNode.hasFocus;
  bool get _hasValue => widget.value != null;
  bool get _isFloating => _isFocused || _hasValue;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label always sits above the field, outside the border
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: _isFloating ? 12 : 15,
              fontWeight: _isFloating ? FontWeight.w600 : FontWeight.w500,
              color: widget.errorText != null
                  ? AppColors.semanticError
                  : _isFocused
                      ? AppColors.accentCharcoal
                      : AppColors.foregroundTertiary,
            ),
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(
            highlightColor: AppColors.backgroundSecondary,
            splashColor: AppColors.backgroundSecondary,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.accentCharcoal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(1, 1, 1, 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: DropdownButtonFormField<T>(
                initialValue: widget.value,
                isExpanded: true,
                validator: widget.validator,
                focusNode: _focusNode,
                items: widget.items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: item.child,
                    ),
                  );
                }).toList(),
                onChanged: widget.enabled ? widget.onChanged : null,
                decoration: InputDecoration(
                  labelText: null,
                  errorText: null,
                  prefixIcon: Icon(
                    widget.icon,
                    color: AppColors.foregroundTertiary,
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: AppColors.accentCharcoal,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: AppColors.semanticError,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: AppColors.semanticError,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foregroundDark,
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.foregroundTertiary,
                ),
                dropdownColor: Colors.white,
              ),
            ),
          ),
        ),
        // Error text rendered below the field
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.semanticError,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
