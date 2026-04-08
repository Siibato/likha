// Conditional import for QR scanner widget
export 'qr_scanner_widget_stub.dart'
    if (dart.library.io) 'qr_scanner_widget_mobile.dart'
    if (dart.library.html) 'qr_scanner_widget_stub.dart';
