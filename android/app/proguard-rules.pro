# Flutter ProGuard rules

# Keep Flutter and native engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods/fields
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Add any custom keep rules below if plugins or models crash in release mode.
# e.g., if a class is used for JSON serialization:
# -keep class com.yourcompany.app.models.** { *; }
