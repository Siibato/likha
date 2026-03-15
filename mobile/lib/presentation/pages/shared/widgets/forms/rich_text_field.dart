import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

/// A rich text editor with WYSIWYG formatting and toolbar.
///
/// Uses fleather for true WYSIWYG editing - text appears formatted as you type
/// (bold appears bold, bullets appear as bullets, etc.), not as raw markdown syntax.
/// Content is stored as Quill Delta JSON for backward-compatible plain text handling.
class RichTextField extends StatefulWidget {
  final FleatherController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final String? Function(String?)? validator;
  final double? minHeight;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? errorText;

  const RichTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.validator,
    this.minHeight,
    this.hintText,
    this.onChanged,
    this.focusNode,
    this.errorText,
  });

  @override
  State<RichTextField> createState() => _RichTextFieldState();
}

class _RichTextFieldState extends State<RichTextField> {
  late FocusNode _internalFocusNode;
  final GlobalKey<EditorState> _editorKey = GlobalKey();
  bool _showMoreTools = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    // Listen to document changes and notify parent
    widget.controller.document.changes.listen((_) {
      widget.onChanged?.call(
        jsonEncode(widget.controller.document.toJson()),
      );
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Formatting toolbar - only show when enabled
            if (widget.enabled) ...[
              // Primary toolbar row: bold, italic, heading, bullet, numbered, + more button
              Row(
                children: [
                  Expanded(
                    child: FleatherToolbar.basic(
                      controller: widget.controller,
                      editorKey: _editorKey,
                      // Show core buttons: bold, italic, heading, bullet, numbered
                      hideUnderLineButton: true,
                      hideStrikeThrough: true,
                      hideBackgroundColor: true,
                      hideForegroundColor: true,
                      hideInlineCode: true,
                      hideCodeBlock: true,
                      hideQuote: true,
                      hideListChecks: true,
                      hideLink: true,
                      hideHorizontalRule: true,
                      hideDirection: true,
                      hideUndoRedo: true,
                      hideAlignment: true,
                      hideIndentation: true,
                    ),
                  ),
                  // Toggle "more" button
                  IconButton(
                    icon: Icon(
                      _showMoreTools ? Icons.close : Icons.more_horiz_rounded,
                    ),
                    iconSize: 20,
                    color: _showMoreTools
                        ? const Color(0xFF2B2B2B)
                        : const Color(0xFF666666),
                    onPressed: () => setState(() => _showMoreTools = !_showMoreTools),
                  ),
                ],
              ),
              // Expandable secondary toolbar row
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                child: _showMoreTools
                    ? FleatherToolbar.basic(
                        controller: widget.controller,
                        editorKey: _editorKey,
                        // Show secondary buttons: underline, strike, quote, checklist, undo/redo
                        hideBoldButton: true,
                        hideItalicButton: true,
                        hideHeadingStyle: true,
                        hideListBullets: true,
                        hideListNumbers: true,
                        hideBackgroundColor: true,
                        hideForegroundColor: true,
                        hideInlineCode: true,
                        hideCodeBlock: true,
                        hideLink: true,
                        hideHorizontalRule: true,
                        hideDirection: true,
                        hideAlignment: true,
                        hideIndentation: true,
                      )
                    : const SizedBox.shrink(),
              ),
              // Divider between toolbar(s) and editor
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
            ],
            // Editor
            Container(
              constraints: BoxConstraints(
                minHeight: widget.minHeight ?? 120,
              ),
              child: FleatherEditor(
                controller: widget.controller,
                editorKey: _editorKey,
                focusNode: _internalFocusNode,
                readOnly: !widget.enabled,
                padding: const EdgeInsets.all(16),
                showCursor: widget.enabled,
                autofocus: false,
                scrollable: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
