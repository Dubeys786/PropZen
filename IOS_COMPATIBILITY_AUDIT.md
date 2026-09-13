# PropZen iOS Compatibility Audit

## Executive Summary
This document provides a comprehensive component-by-component audit of the existing PropZen Flutter codebase for iOS compatibility, hardware sensor usage, and cross-platform unified operation alongside Android without requiring duplicate code or secondary projects.

---

## 1. Compatibility Matrix & Classification

| Feature Area | Current Implementation | Android Status | iOS Status | Required Architecture | Priority | External Configuration |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **App Bundle & Identity** | `com.propzen.dealghar_ncr_10x` | Fully configured | Configured (`ios/Runner/Info.plist`) | App Display Name: "PropZen", Deployment Target: iOS 14.0+ | **P0 (Prepared)** | Apple Developer App ID |
| **Privacy Manifest** | Spring 2024 Apple Standard | N/A (Android uses manifest) | Configured (`PrivacyInfo.xcprivacy`) | Declared User Defaults, File Timestamps, Disk Space, Audio, Location | **P0 (Prepared)** | App Store Connect Privacy Questionnaire |
| **Microphone & Voice AI** | `PropzenVoiceService` / Speech | Configured (`RECORD_AUDIO`) | Configured (`NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`) | Safe error boundaries, female voice selection fallback | **P0 (Prepared)** | iOS Settings Microphone Permission |
| **Camera & Document Upload** | `FilePicker` / Image upload | Configured (`READ_MEDIA_IMAGES`) | Configured (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`) | On-demand permissions, PDF/Image validation | **P1 (Prepared)** | iOS Settings Photos Permission |
| **Location & Maps** | `PropertyIntelligenceService` / Maps | Configured (`ACCESS_FINE_LOCATION`) | Configured (`NSLocationWhenInUseUsageDescription`) | Geospatial 5 KM POI matching, precise coordinate rendering | **P1 (Prepared)** | Google Maps iOS SDK Key / Apple Maps |
| **URL Schemes & Deep Linking** | `url_launcher` | Configured intent queries | Configured (`LSApplicationQueriesSchemes`: `https`, `tel`, `mailto`, `sms`, `whatsapp`) | Direct advisor WhatsApp & phone dialing | **P1 (Prepared)** | Universal Links entitlement |
| **Digital Subscriptions (IAP)** | `AppleStoreKitService` / `DealerSubscriptionService` | Razorpay / Play Billing | Apple StoreKit In-App Purchase Architecture | StoreKit Product IDs (`com.propzen.dealer_starter`, etc.), "Restore Purchases" button | **P0 (Prepared)** | App Store Connect In-App Purchase Items |
| **Account Deletion** | `SettingsScreen` | Implemented | Implemented with Apple-compliant confirmation dialog | Guideline 5.1.1(v) complete session & data purge | **P0 (Prepared)** | Supabase user record deletion |
| **UI Safe Area & Responsive** | `SafeArea`, `SingleChildScrollView` | Responsive (360px - 1440px) | iPhone SE, iPhone Pro, Dynamic Island, iPad | Keyboard-avoiding scroll, notch avoidance, gesture handling | **P1 (Prepared)** | Xcode Simulator / Physical iPhone |
| **Data Isolation & Integrity** | `Property.sampleDeals` | Isolated | Isolated | Distinct images, prices, locations, RERA IDs, CAD plans | **P0 (Prepared)** | Supabase PostgreSQL Backend |
| **Backend & RLS Security** | Supabase GoTrue + PostgREST | Enforced | Enforced | Zero client-side role elevation, append-only audit logs | **P0 (Prepared)** | Supabase Project API Keys |

---

## 2. P0 Critical Resolutions

1. **Apple In-App Purchase Architecture (`AppleStoreKitService`)**:
   - Integrated platform detection: iOS routes digital subscription upgrades to Apple StoreKit (`com.propzen.dealer_*` and `com.propzen.nri_*`), while Android and Web utilize direct gateway / Play billing.
   - Embedded the required **"Restore Purchases (Apple ID / Store)"** action in both Dealer and NRI subscription screens.

2. **Apple App Store Guideline 5.1.1(v) — Account Deletion**:
   - Implemented a dedicated destructive action in `SettingsScreen` allowing buyers and dealers to permanently erase their account, search history, saved properties, and enquiry records.

3. **Privacy Manifest & Permission Strings**:
   - Generated official `ios/Runner/PrivacyInfo.xcprivacy` declaring data collection types (Name, Email, Phone, Coarse Location, Audio) and system API usage (UserDefaults, FileTimestamp, BootTime, DiskSpace).
   - Configured all user-facing usage descriptions in `ios/Runner/Info.plist`.

---

## 3. P1 Major Resolutions

1. **App Identity & Display Name**:
   - Configured `CFBundleDisplayName = "PropZen"` and `CFBundleName = "PropZen"` so the app appears as "PropZen" on iOS home screen and app switchers.
2. **Deployment Target**:
   - Updated `MinimumOSVersion` to `14.0` in `AppFrameworkInfo.plist`, `Debug.xcconfig`, and `Release.xcconfig`.
3. **Branding Assets**:
   - Linked 1024x1024 master icon in `Assets.xcassets/AppIcon.appiconset` and `LaunchScreen` image sets.
4. **URL Scheme Whitelisting**:
   - Enabled external schemes for WhatsApp (`whatsapp://`), telephone (`tel://`), SMS (`sms://`), and email (`mailto://`).
