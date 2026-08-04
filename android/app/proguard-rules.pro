# 🎯 MEOWTRACK PROGUARD RULES
# Melindungi kod penting daripada terpadam oleh R8 semasa Release Build.

# 1. Flutter Base Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 2. Firebase Rules
# Menghalang Firebase daripada gagal berfungsi (serialization/deserialization)
-keep class com.google.firebase.** { *; }
-keepnames class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# 3. Google Play Services & Maps
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# 4. Google Generative AI (Gemini)
-keep class com.google.generativeai.** { *; }

# 5. ML Kit Subject Segmentation
-keep class com.google.mlkit.** { *; }

# 6. Speech to Text & Permissions
-keep class com.csdcorp.speech_to_text.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }

# 7. Unity Integration (Mini-game)
# Sangat penting jika anda menggunakan Unity Library dalam Flutter
-keep class com.unity3d.player.** { *; }
-keep class com.google.ar.core.** { *; }

# 8. General Networking & Serialization
-keepattributes Signature,Exceptions,*Annotation*
-keep class com.google.gson.** { *; }
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# 9. Model Classes (AppState)
# Jangan tukar nama kelas data anda supaya Firestore mapping tidak rosak
-keep class com.example.meow_track.core.** { *; }
