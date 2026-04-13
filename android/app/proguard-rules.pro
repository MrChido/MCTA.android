# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keepnames class com.google.firebase.*

# Keep Firebase Messaging (if used)
-keep class com.google.firebase.messaging.** { *; }

# Keep required Google Play Services classes
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Keep your app's classes
-keep class com.soggywombat.spoonie.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Android components
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends androidx.fragment.app.Fragment

# Keep Kotlin metadata
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
