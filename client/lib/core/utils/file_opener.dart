// Conditional import for file opening based on platform
export 'file_opener_stub.dart'
    if (dart.library.io) 'file_opener_native.dart'
    if (dart.library.js_interop) 'file_opener_web.dart';
