## Flutter Local Notifications - keep Gson type information
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Flutter Local Notifications plugin
-keep class com.dexterous.** { *; }

## Suppress missing Play Core classes (used by Flutter deferred components but not needed)
-dontwarn com.google.android.play.core.**

## ML Kit Text Recognition (ignore optional script models)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
