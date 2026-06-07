import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

/// A widget that displays rich text content (Delta JSON or plain text).
///
/// Renders both Quill Delta JSON (new format from fleather) and legacy plain text
/// as formatted content using fleather's read-only editor.
/// Handles null/empty content gracefully.
class MarkdownDisplay extends StatefulWidget {
  final String? content;

  const MarkdownDisplay({
    super.key,
    this.content,
  });

  @override
  State<MarkdownDisplay> createState() => _MarkdownDisplayState();
}

class _MarkdownDisplayState extends State<MarkdownDisplay> {
  late FleatherController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.content);
  }

  @override
  void didUpdateWidget(MarkdownDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _controller.dispose();
      _controller = _buildController(widget.content);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  FleatherController _buildController(String? content) {
    if (content == null || content.isEmpty) {
      return FleatherController();
    }

    try {
      // Try to parse as Delta JSON (new format)
      final List decoded = jsonDecode(content);
      return FleatherController(
        document: ParchmentDocument.fromJson(decoded),
      );
    } catch (_) {
      // Legacy plain text format - wrap in a Delta
      final delta = Delta()..insert(content)..insert('\n');
      return FleatherController(
        document: ParchmentDocument.fromDelta(delta),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content == null || widget.content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return FleatherEditor(
      controller: _controller,
      readOnly: true,
      padding: EdgeInsets.zero,
      scrollable: false,
    );
  }
}
