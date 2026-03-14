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
