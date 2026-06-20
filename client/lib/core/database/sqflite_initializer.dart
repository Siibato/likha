// Conditional import for sqflite initialization based on platform
export 'sqflite_initializer_stub.dart'
    if (dart.library.js_interop) 'sqflite_initializer_web.dart'
    if (dart.library.io) 'sqflite_initializer_native.dart';
