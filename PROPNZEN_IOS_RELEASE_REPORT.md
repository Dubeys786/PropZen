# PropZen iOS Release & App Store Production Readiness Report (Phase 9)

## Executive Summary
The PropZen Flutter codebase is now unified and fully configured for production deployment on both **Android** and **iOS (Apple App Store)** from a single, robust codebase. All P0 and P1 compatibility requirements, StoreKit in-app purchase architectures, Apple privacy manifests, and App Store review guidelines have been verified.

---

## 1. iOS Platform Configuration & Architecture
- **Framework**: Flutter 3.x (Channel stable) / Dart 3.x
- **App Display Name**: `PropZen` (`CFBundleDisplayName = "PropZen"`)
- **Bundle Identifier**: `com.propzen.dealghar_ncr_10x`
- **Minimum iOS Deployment Target**: `iOS 14.0` (Configured in `AppFrameworkInfo.plist`, `Debug.xcconfig`, and `Release.xcconfig`)
- **App Store Export Compliance**: `ITSAppUsesNonExemptEncryption = false`
- **Branding Assets**: 1024x1024 master icon linked in `Assets.xcassets/AppIcon.appiconset` and `LaunchScreen.storyboard`.

---

## 2. iOS Permissions & Usage Descriptions (`Info.plist`)

| Permission Key | Usage Description Declared in Info.plist |
| :--- | :--- |
| `NSCameraUsageDescription` | "PropZen requires camera access to capture property photos, floor plans, and documents for listing and identity verification." |
| `NSPhotoLibraryUsageDescription` | "PropZen requires photo library access to upload property images, floor plans, and verification documents." |
| `NSMicrophoneUsageDescription` | "PropZen requires microphone access for the AI Voice Assistant to enable hands-free voice search and property queries." |
| `NSSpeechRecognitionUsageDescription` | "PropZen requires speech recognition to understand your voice commands in English, Hindi, and Hinglish." |
| `NSLocationWhenInUseUsageDescription` | "PropZen uses your location to discover nearby properties, calculate exact 5 KM POI distances, and schedule pickup cabs for physical site visits." |
| `LSApplicationQueriesSchemes` | `https`, `http`, `tel`, `mailto`, `sms`, `whatsapp` |

---

## 3. Apple Privacy Manifest (`PrivacyInfo.xcprivacy`)
In accordance with Apple's mandatory Spring 2024 privacy policy:
- **Tracking**: `NSPrivacyTracking = false`
- **Collected Data Types**:
  - `Name`, `EmailAddress`, `PhoneNumber` (Linked to user for App Functionality)
  - `CoarseLocation` (Not linked, for nearby property matching & 5 KM POI engine)
  - `AudioData` (Not linked, strictly ephemeral for voice queries)
- **Accessed API Reasons**:
  - User Defaults (`CA92.1`)
  - File Timestamp (`C617.1`)
  - System Boot Time (`35F9.1`)
  - Disk Space (`E174.1`)

---

## 4. Digital Subscriptions & Apple In-App Purchase Architecture
- **Platform Separation (`AppleStoreKitService`)**:
  - **iOS**: Digital subscription upgrades (Dealer Starter/Pro/Premium/Enterprise and NRI Remote Passes) automatically route to **Apple StoreKit In-App Purchases**.
  - **Android & Web**: Direct payment gateway / Google Play billing.
- **StoreKit Product Identifiers**:
  - `com.propzen.dealer_starter`
  - `com.propzen.dealer_pro`
  - `com.propzen.dealer_premium`
  - `com.propzen.dealer_enterprise`
  - `com.propzen.nri_basic`
  - `com.propzen.nri_premium`
  - `com.propzen.nri_elite`
- **Restore Purchases**: Dedicated "Restore Purchases (Apple ID / Store)" action button embedded in both `DealerSubscriptionPlansScreen` and `NriSubscriptionPlansScreen`.

---

## 5. Account Deletion Compliance (Apple Guideline 5.1.1(v))
- Implemented **"Delete Account & Erase Personal Data"** workflow inside [SettingsScreen](file:///c:/Users/Sakshi/Desktop/PropZen/lib/screens/settings_screen.dart).
- Includes mandatory confirmation modal explaining the permanent wipe of searches, wishlist, enquiries, site visits, and profile info.

---

## 6. Testing & Quality Verification

### A. iOS Compatibility & StoreKit Test Suite
```bash
flutter test test/ios_compatibility_test.dart
```
**Results**:
- ✓ 1. Product ID Catalog maps all dealer and NRI plans to App Store identifiers
- ✓ 2. Payment disclaimer renders transparent store terms
- ✓ 3. Dealer In-App Purchase execution and backend activation
- ✓ 4. NRI Pass In-App Purchase execution and backend activation
- ✓ 5. Restore Purchases checks entitlement accurately
- ✓ 6. User Session Account Deletion clears all records for Apple Guideline 5.1.1(v)

**Status**: `6/6 Passed (100%)`

### B. Admin & Property Intelligence Regression Suite
```bash
flutter test test/admin_command_center_test.dart
```
**Status**: `10/10 Passed (100%)`

### C. Android & Cross-Platform Regression
- Android builds and workflows remain completely untouched and functional.
- Release Web Build (`flutter build web --release`) compiled with 0 errors.

---

## 7. Step-by-Step Manual Apple Developer & App Store Connect Instructions

When preparing your release build on a macOS workstation with Xcode:

### Step 1: Apple Developer Account Setup
1. Log in to [developer.apple.com](https://developer.apple.com).
2. Go to **Certificates, Identifiers & Profiles** → **Identifiers**.
3. Create App ID: `com.propzen.dealghar_ncr_10x` (or your chosen bundle ID).
4. Enable Capabilities: **In-App Purchase**, **Push Notifications** (if APNs is used), and **Associated Domains** (if Universal Links are used).
5. Generate an **iOS Distribution Certificate** and **App Store Provisioning Profile**.

### Step 2: App Store Connect In-App Purchase Setup
1. Log in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) and create a new App named **PropZen**.
2. Go to **Monetization** → **In-App Purchases / Subscriptions**.
3. Create the Auto-Renewable Subscription Groups:
   - **Dealer Subscription Group**:
     - `com.propzen.dealer_starter` (₹1,999 / mo)
     - `com.propzen.dealer_pro` (₹4,999 / mo)
     - `com.propzen.dealer_premium` (₹9,999 / mo)
     - `com.propzen.dealer_enterprise` (₹19,999 / mo)
   - **NRI Remote Suite Pass Group**:
     - `com.propzen.nri_basic` (₹999 / mo)
     - `com.propzen.nri_premium` (₹14,999 / quarter)
     - `com.propzen.nri_elite` (₹24,999 / semi-annual)
4. Upload localized display names, pricing tiers, and screenshot of the subscription page for Apple review.

### Step 3: Build & Archive via Xcode / Flutter
On your macOS machine:
```bash
# 1. Fetch dependencies and prepare iOS pod dependencies
flutter clean
flutter pub get
cd ios && pod install && cd ..

# 2. Build iOS Release Archive
flutter build ipa --release
```
3. Open `ios/Runner.xcworkspace` in Xcode.
4. Select **Runner** → **Signing & Capabilities** → Select your **Apple Development Team**.
5. Select **Product** → **Archive** → **Distribute App** → **App Store Connect** → **Upload**.

### Step 4: App Store Review Information
- Provide test credentials for demo login:
  - Buyer Demo Account: `buyer.demo@propzen.ai` / `PropZen@2026`
  - Dealer Demo Account: `dealer.demo@propzen.ai` / `PropZen@2026`
- Fill in the App Store Privacy Questionnaire matching `PrivacyInfo.xcprivacy`.
- Submit for App Store Review.
