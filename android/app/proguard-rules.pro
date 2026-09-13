# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ZegoCloud
-keep class im.zego.** { *; }
-dontwarn im.zego.**

# Flutter Play Store split-install (deferred components) - not used by this app
-dontwarn com.google.android.play.core.**
