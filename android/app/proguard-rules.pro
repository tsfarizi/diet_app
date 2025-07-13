-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

-keep class com.google.mlkit.vision.text.latin.** { *; }
-keep class com.google.mlkit.vision.objects.** { *; }
-keep class com.google.mlkit.vision.text.** { *; }

-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

-keep,allowobfuscation,allowshrinking class com.google.mlkit.vision.text.chinese.** 
-keep,allowobfuscation,allowshrinking class com.google.mlkit.vision.text.devanagari.**
-keep,allowobfuscation,allowshrinking class com.google.mlkit.vision.text.japanese.**
-keep,allowobfuscation,allowshrinking class com.google.mlkit.vision.text.korean.**

-keep class androidx.camera.** { *; }
-keep class com.google.common.** { *; }

-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.measurement.** { *; }

-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Fix untuk Google Common Reflection Error
-dontwarn java.lang.reflect.AnnotatedType
-keep class java.lang.reflect.** { *; }
-keep class com.google.common.reflect.** { *; }

# Reflection API rules untuk targetSdk 35
-keepclassmembers class * {
    @com.google.common.annotations.VisibleForTesting *;
}

-keep class * extends java.lang.reflect.Type { *; }
-keep class * implements java.lang.reflect.AnnotatedElement { *; }

# Google Common Guava compatibility
-dontwarn com.google.common.util.concurrent.ListenableFuture
-dontwarn com.google.errorprone.annotations.**

# Additional safety for targetSdk 35
-keep class * implements java.util.concurrent.Callable { *; }
-keep class * extends java.util.concurrent.FutureTask { *; }