# Flutter/Dart
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.** { *; }
-keep class com.google.android.material.** { *; }

# Google Play Core Library (for deferred components)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# Dio HTTP Client (network library)
-keep class io.flutter.plugins.httpclientadapter.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep your app models and services
-keep class * implements com.google.gson.JsonDeserializable
-keep class * implements com.google.gson.JsonSerializable

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep Android API classes
-keep public class android.net.** { public *; }
-keep public class android.webkit.** { public *; }
-keep public class java.net.** { public *; }

# Keep HTTP and networking classes
-keep public class javax.net.ssl.** { public *; }
-keep public class java.security.** { public *; }

# Don't obfuscate
-dontobfuscate
