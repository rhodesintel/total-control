# dnsjava rules - suppress warnings for optional dependencies
# These are platform-specific features not used on Android

# SLF4J logging (optional)
-dontwarn lombok.Generated
-dontwarn lombok.NonNull
-dontwarn org.slf4j.**

# JNA - Windows native access (not used on Android)
-dontwarn com.sun.jna.**

# JNDI - Java naming (not available on Android)
-dontwarn javax.naming.**

# Sun internal classes
-dontwarn sun.net.spi.nameservice.**

# Keep dnsjava core classes
-keep class org.xbill.DNS.** { *; }

# Google ML Kit - keep all text recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
