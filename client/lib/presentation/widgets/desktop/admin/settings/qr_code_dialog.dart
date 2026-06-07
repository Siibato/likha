import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';

class QrCodeDialog extends StatelessWidget {
  final String qrBase64;
  final String? schoolCode;
  final VoidCallback onDownload;

  const QrCodeDialog({
    super.key,
    required this.qrBase64,
    this.schoolCode,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'School QR Code',
      subtitle: schoolCode != null ? 'Code: $schoolCode' : null,
      content: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Image.memory(
            base64Decode(qrBase64),
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
      actions: [
        StyledDialogAction(
          label: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Download',
          isPrimary: true,
          onPressed: () {
            onDownload();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
