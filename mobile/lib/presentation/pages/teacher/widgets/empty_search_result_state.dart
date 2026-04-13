import 'package:flutter/material.dart';

class EmptySearchResultState extends StatelessWidget {
  final String searchQuery;

  const EmptySearchResultState({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text(
            'No classes match "$searchQuery"',
            style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
