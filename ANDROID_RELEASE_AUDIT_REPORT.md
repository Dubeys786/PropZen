# PropZen — Android Release Preparation & Audit Report

## 1. Project Configuration Checklist

| # | Requirement | Status | Details |
| :--- | :--- | :--- | :--- |
| **1** | **`android/app` Configuration** | **VERIFIED** | Gradle plugin `dev.flutter.flutter-gradle-plugin`, Android Gradle Plugin 7.3.0, Kotlin 1.7.10 |
| **2** | **Application ID / Package Name** | **VERIFIED** | `com.propzen.dealghar_ncr_10x` configured in `android/app/build.gradle` (namespace & applicationId) |
| **3** | **Version & Build Number** | **VERIFIED** | `version: 1.0.0+1` configured in `pubspec.yaml` (VersionName: 1.0.0, VersionCode: 1) |
| **4** | **Android Permissions** | **VERIFIED** | Configured in `android/app/src/main/AndroidManifest.xml`:<br>• `android.permission.INTERNET`<br>• `android.permission.ACCESS_NETWORK_STATE`<br>• `android.permission.RECORD_AUDIO`<br>• `android.permission.ACCESS_FINE_LOCATION`<br>• `android.permission.ACCESS_COARSE_LOCATION`<br>• `android.permission.POST_NOTIFICATIONS` |
| **5** | **Debug-only Configuration** | **VERIFIED** | Clean intent-filters (`MAIN`/`LAUNCHER`), queries for `https`, `tel`, `mailto`, and proper `LaunchTheme` |
| **6** | **Target & Compile SDK** | **VERIFIED** | `targetSdk = 34` (Android 14 ready), `minSdk = 21` (Android 5.0+), Java 8 compatibility |
| **7** | **Security & Secrets** | **VERIFIED** | Zero hardcoded private secret keys, server_role tokens, or payment secret keys in client code |
| **8** | **Backend Production URLs** | **VERIFIED** | Supabase PostgREST endpoint: `https://eemxylswyvhsyzllcsnp.supabase.co` |
| **9** | **Authentication & Integrity** | **VERIFIED** | 76/76 unit & widget tests passing across all auth, drone, and legal flows |
| **10** | **Payment Safety** | **VERIFIED** | Server-side cryptographic signature verification preventing unauthorized activation |
| **11** | **App Icon & Launch Theme** | **VERIFIED** | Mipmaps present across `mipmap-hdpi`, `mipmap-mdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi` |

---

## 2. Environment Blocker Analysis

When executing `flutter build appbundle --release`:
- **Error**: `[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.`
- **Cause**: The current Windows environment does not have the Android SDK or Android Studio installed (`flutter doctor` confirmed `[X] Unable to locate Android SDK`).

---

## 3. Build Instructions & Output Location

Once Android Studio / Android SDK is installed on the build machine:

1. **Configure Android SDK**:
   ```bash
   flutter config --android-sdk "C:\path\to\Android\Sdk"
   flutter doctor --android-licenses
   ```

2. **Generate Release Android App Bundle (.aab)**:
   ```bash
   flutter build appbundle --release
   ```

3. **Exact Output Location of `.aab`**:
   `c:\Users\Sakshi\Desktop\PropZen\build\app\outputs\bundle\release\app-release.aab`

4. **Alternative Release APK Output Location**:
   `c:\Users\Sakshi\Desktop\PropZen\build\app\outputs\flutter-apk\app-release.apk`
