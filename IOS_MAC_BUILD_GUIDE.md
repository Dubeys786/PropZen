# PropZen macOS & Xcode Build Guide

## Overview
This guide provides the exact, step-by-step instructions for opening, building, running, and testing the **PropZen Flutter mobile application** on a macOS machine using **Xcode** and real iOS devices / simulators.

---

## 1. Prerequisites on macOS Workstation
Ensure the following tools are installed on the Mac:
1. **macOS**: macOS Sonoma (14.x) or macOS Ventura (13.5+)
2. **Xcode**: Version 15.x or 16.x (from Mac App Store)
3. **Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```
4. **Flutter SDK**: Flutter 3.x (matching project environment):
   ```bash
   flutter --version
   flutter doctor
   ```
5. **CocoaPods**:
   ```bash
   sudo gem install cocoapods
   # or via Homebrew:
   brew install cocoapods
   ```

---

## 2. Opening & Preparing the Project on Mac

### Step 1: Clone or Copy the PropZen Project
Open Terminal and navigate to the project directory:
```bash
cd /path/to/PropZen
```

### Step 2: Fetch Flutter Packages & CocoaPods Pods
```bash
# 1. Clean build artifacts
flutter clean

# 2. Get Flutter Dart dependencies
flutter pub get

# 3. Install iOS CocoaPods dependencies
cd ios
pod install --repo-update
cd ..
```

---

## 3. Opening the Project in Xcode

> [!IMPORTANT]
> Always open the `.xcworkspace` file (NOT `.xcodeproj`) so that CocoaPods dependencies are correctly linked.

1. Open Finder and double-click `ios/Runner.xcworkspace`, or run in Terminal:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. In Xcode's left sidebar, click the top-level **Runner** project item.

---

## 4. Configuring Development Signing & Team

1. Select the **Runner** target in the center pane.
2. Click the **Signing & Capabilities** tab.
3. Check **Automatically manage signing**.
4. In the **Team** dropdown:
   - For local simulator / personal device testing: Select your **Personal Team** or Apple Developer Account.
5. Verify the **Bundle Identifier**:
   - `com.propzen.dealghar_ncr_10x` (or custom prefix if using Personal Team).
6. Verify **Deployment Target**:
   - iOS 14.0 or higher.

---

## 5. Running on iOS Simulator or Physical iPhone

### Running on Simulator:
1. In Xcode top bar, select a simulator (e.g., **iPhone 15 Pro** or **iPhone 14**).
2. Click the **Run** button (▶️) or run from Terminal:
   ```bash
   flutter run -d iPhone
   ```

### Running on Physical iPhone:
1. Connect your iPhone via USB / Lightning / USB-C cable.
2. Unlock the iPhone and tap **Trust This Computer**.
3. In iOS **Settings** → **Privacy & Security** → Scroll down and enable **Developer Mode** (iPhone will restart).
4. In Xcode or Terminal:
   ```bash
   flutter devices
   flutter run -d <your-device-id>
   ```

---

## 6. Verifying Hardware & Sensor Features on iOS
Once running on the iPhone:
1. **AI Voice Assistant**: Tap the Voice icon → Verify microphone permission prompt appears → Speak in Hindi/English → Confirm voice response.
2. **Property Discovery & Maps**: Verify 5 KM POI markers, locality calculation, and distance badges.
3. **Site Visit Booking**: Schedule visit with date, time, visitor count, and cab toggle.
4. **Dealer / NRI Subscription**: Check plan cards and tap "Restore Purchases" button.
5. **Account Deletion**: Open Settings → Tap "Delete Account & Erase Personal Data" → Verify confirmation dialog and clean logout.

---

## 7. Creating a Release Build (For Future Distribution)
When ready for distribution or TestFlight:
```bash
# Build release archive
flutter build ipa --release
```
In Xcode:
1. Select **Product** → **Archive**.
2. When the Organizer window opens, click **Distribute App**.
3. Choose **App Store Connect** / **TestFlight** / **Ad-Hoc**.
