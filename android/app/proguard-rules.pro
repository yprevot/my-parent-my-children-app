# Flutter ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google ML Kit Text Recognition
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }

# JNI & Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Play Core deferred components
-dontwarn com.google.android.play.core.**

# App-specific classes
-keep class online.myschoolmyparents.** { *; }
