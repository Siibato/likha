import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerWidget extends StatelessWidget {
  final Function(String) onDetect;

  const QrScannerWidget({
    super.key,
    required this.onDetect,
  });

  void _handleDetection(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      onDetect(barcode!.rawValue!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: MobileScanner(onDetect: _handleDetection),
    );
  }
}
