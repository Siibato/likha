import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A styled text input field that matches the app's design system.
///
/// Provides a 2-layer container appearance with extensive configuration options
/// including icons, multiline support, and various input states.
class StyledTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final String? hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;

  const StyledTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.readOnly = false,
    this.onChanged,
    this.focusNode,
    this.errorText,
    this.inputFormatters,
    this.onTap,
  });

  @override
  State<StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<StyledTextField> {
  late FocusNode _focusNode;

  bool get _isFocused => _focusNode.hasFocus;
  bool get _hasText => widget.controller.text.isNotEmpty;
  bool get _isFloating => _isFocused || _hasText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant StyledTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _focusNode = widget.focusNode ?? _focusNode;
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});
  void _onTextChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null;

    return FormField<String>(
      validator: widget.validator,
      builder: (FormFieldState<String> field) {
        final bool fieldHasError = field.hasError || hasError;
        final String? errorMessage = field.errorText ?? widget.errorText;

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
                  color: fieldHasError
                      ? AppColors.semanticError
                      : _isFocused
                          ? AppColors.accentCharcoal
                          : AppColors.foregroundTertiary,
                ),
              ),
            ),
            // Field container
            Container(
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
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  obscureText: widget.obscureText,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  onChanged: (value) {
                    widget.onChanged?.call(value);
                    field.didChange(value);
                  },
                  focusNode: _focusNode,
                  inputFormatters: widget.inputFormatters,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foregroundDark,
                  ),
                  decoration: InputDecoration(
                    alignLabelWithHint:
                        widget.maxLines != 1 || widget.maxLines == null,
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.foregroundLight,
                    ),
                    prefixIcon: widget.maxLines != 1 || widget.maxLines == null
                        ? Align(
                            alignment: Alignment.topCenter,
                            widthFactor: 1.0,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Icon(
                                widget.icon,
                                color: AppColors.foregroundTertiary,
                                size: 22,
                              ),
                            ),
                          )
                        : Icon(
                            widget.icon,
                            color: AppColors.foregroundTertiary,
                            size: 22,
                          ),
                    suffixIcon: widget.suffixIcon,
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
                      borderSide: BorderSide(
                        color: fieldHasError
                            ? AppColors.semanticError
                            : AppColors.accentCharcoal,
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
                ),
              ),
            ),
            // Error text rendered below the field
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.semanticError,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
