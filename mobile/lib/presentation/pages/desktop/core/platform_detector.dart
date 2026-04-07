import 'package:flutter/foundation.dart';

class PlatformDetector {
  static bool get isDesktop {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static bool get isMobile => !isDesktop;
}
