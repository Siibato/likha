import 'package:flutter/material.dart';

class AssignmentTextInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isReadOnly;

  const AssignmentTextInputCard({
    super.key,
    required this.controller,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Response',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202020),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              maxLines: 10,
              readOnly: isReadOnly,
              style: TextStyle(
                fontSize: 15,
                color: isReadOnly
                    ? const Color(0xFF666666)
                    : const Color(0xFF2B2B2B),
              ),
              decoration: InputDecoration(
                hintText: isReadOnly
                    ? 'No response provided'
                    : 'Type your response here...',
                hintStyle: const TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: isReadOnly
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isReadOnly
                        ? const Color(0xFFE0E0E0)
                        : const Color(0xFFFFBD59),
                    width: isReadOnly ? 1 : 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}