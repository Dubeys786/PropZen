# PropZen — Drone Tour Subscription & Dealer Separation Report

## Executive Summary
The **Dealer Subscription System** and **Drone Tour Subscription System** are strictly decoupled across the PropZen Flutter mobile application. Dealer subscriptions now govern exclusively dealer-related features (listing limits, lead management, dealer portal, analytics) and never unlock Drone Tours. The Drone Tour feature is universally visible to all users (Resident Buyers, NRI Investors, Dealers, and Normal users), while opening the interactive Drone Tour player strictly requires an **Active, Verified Drone Tour Subscription**.

---

## 1. Business Logic Architecture & Separation Rules

### A. Strict Decoupling Rules
1. **Dealer Subscription ≠ Drone Tour Subscription**:
   - `dealer_subscription_status` governs only listing quotas, lead scores, and broker tools.
   - Having an active Dealer subscription **never** grants Drone Tour access (`UserSession.hasActiveDroneAccess == false` unless a separate Drone Tour pass is verified).
2. **Universal Visibility**:
   - Drone Tour items (`🚁 Drone Tour`, `Premium Aerial Experience`, and `PREMIUM` badge) are visible to all users regardless of role or residency.
3. **Controlled Access Flow**:
   - **Subscribed (`drone_subscription_status == 'active'` and within expiry)**:
     - Property Card shows `[ ▶ Watch Drone Tour ]`.
     - Clicking opens `NriDroneTourPlayerModal`.
   - **Unsubscribed / Expired / Pending**:
     - Property Card shows `[ 🔒 Unlock ]`.
     - Clicking opens the dedicated **Unlock Premium Drone Tours** subscription screen ([DroneTourSubscriptionScreen](file:///c:/Users/Sakshi/Desktop/PropZen/lib/screens/drone_tour_subscription_screen.dart)).
4. **Zero Pre-Activation**:
   - Clicking "Subscribe Now" or selecting a plan creates a `pending` order in memory and does **not** unlock the tour.
   - Subscription only becomes `active` after cryptographic payment verification (`verifyAndActivateSubscription`).
   - Failed or cancelled payments keep the pass `inactive` or `cancelled`.
5. **Automatic Expiration**:
   - When `drone_subscription_expiry < DateTime.now()`, the pass is dynamically marked as `expired` and the tour locks automatically across all properties.

---

## 2. Database Schema & Fields Separation

### Supabase Migration ([supabase_drone_subscription_schema.sql](file:///c:/Users/Sakshi/Desktop/PropZen/supabase_drone_subscription_schema.sql))

```sql
-- 1. Dedicated Drone Tour Subscriptions Table
CREATE TABLE IF NOT EXISTS public.drone_subscriptions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    user_email TEXT NOT NULL,
    drone_plan_id TEXT NOT NULL,
    drone_plan_name TEXT NOT NULL,
    tier TEXT DEFAULT 'popular',
    duration_months INT DEFAULT 3,
    drone_subscription_status TEXT NOT NULL DEFAULT 'inactive', -- 'inactive', 'pending', 'active', 'expired', 'cancelled'
    drone_subscription_start TIMESTAMPTZ NOT NULL,
    drone_subscription_expiry TIMESTAMPTZ NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    currency TEXT DEFAULT 'INR',
    drone_payment_id TEXT,
    transaction_id TEXT,
    signature_verification_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Dedicated Columns on Users Table (Zero Overwrite with Dealer Fields)
ALTER TABLE public.users 
    ADD COLUMN IF NOT EXISTS dealer_subscription_status TEXT DEFAULT 'inactive',
    ADD COLUMN IF NOT EXISTS dealer_plan_id TEXT,
    ADD COLUMN IF NOT EXISTS drone_subscription_status TEXT DEFAULT 'inactive',
    ADD COLUMN IF NOT EXISTS drone_plan_id TEXT,
    ADD COLUMN IF NOT EXISTS drone_payment_id TEXT,
    ADD COLUMN IF NOT EXISTS drone_subscription_start TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS drone_subscription_expiry TIMESTAMPTZ;
```

---

## 3. Files Created & Modified

| File | Description |
| :--- | :--- |
| [lib/models/drone_tour_subscription_model.dart](file:///c:/Users/Sakshi/Desktop/PropZen/lib/models/drone_tour_subscription_model.dart) | Dedicated `DroneTourSubscription` and `DroneTourPlan` lifecycle models with strict expiration and status helpers. |
| [lib/services/drone_subscription_service.dart](file:///c:/Users/Sakshi/Desktop/PropZen/lib/services/drone_subscription_service.dart) | Central Drone Tour subscription manager handling orders, signature verification, and backend persistence. |
| [lib/screens/drone_tour_subscription_screen.dart](file:///c:/Users/Sakshi/Desktop/PropZen/lib/screens/drone_tour_subscription_screen.dart) | Dedicated screen with title *"Unlock Premium Drone Tours"*, subtitle, benefits list, plan cards, and secure checkout. |
| [lib/screens/user_profile_screen.dart](file:///c:/Users/Sakshi/Desktop/PropZen/lib/screens/user_profile_screen.dart) | Updated `UserSession` with `droneSubscriptionNotifier`, strict `hasActiveDroneAccess`, and separate profile pass status card. |
| [lib/widgets/nri_drone_tour_card.dart](file:///c:/Users/Sakshi/Desktop/PropZen/lib/widgets/nri_drone_tour_card.dart) | Universal Remote Experience Suite card with `🚁 Drone Tour`, `PREMIUM` tag, and dynamic `[ ▶ Watch Drone Tour ]` / `[ 🔒 Unlock ]` buttons. |
| [lib/widgets/nri_drone_tour_player_modal.dart](file:///c:/Users/Sakshi/Desktop/PropZen/lib/widgets/nri_drone_tour_player_modal.dart) | Access guard in `show()` preventing unverified access and redirecting to subscription screen if locked. |
| [lib/widgets/property_card.dart](file:///c:/Users/Sakshi/Desktop/PropZen/lib/widgets/property_card.dart) | Integrated Drone Tour status bar with `[ ▶ Watch Drone Tour ]` / `[ 🔒 Unlock ]` button directly on property cards. |
| [lib/services/supabase_service.dart](file:///c:/Users/Sakshi/Desktop/PropZen/lib/services/supabase_service.dart) | Added `saveDroneSubscription` targeting `drone_subscriptions` and `users.drone_subscription_status`. |
| [supabase_drone_subscription_schema.sql](file:///c:/Users/Sakshi/Desktop/PropZen/supabase_drone_subscription_schema.sql) | Production SQL migration for dedicated drone subscription schema and RLS policies. |
| [test/drone_subscription_separation_test.dart](file:///c:/Users/Sakshi/Desktop/PropZen/test/drone_subscription_separation_test.dart) | 13 automated unit tests verifying all 14 business logic scenarios. |

---

## 4. Test Verification Matrix

| Test Scenario | Condition | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| **A. Normal Buyer without Drone Pass** | Unsubscribed Buyer | Visible, `hasActiveDroneAccess == false`, opens subscription screen | **PASS** |
| **B. Normal Buyer with Drone Pass** | Verified Drone Subscription | `hasActiveDroneAccess == true`, Drone Tour unlocks | **PASS** |
| **C. Dealer without Drone Pass** | Verified Dealer | Dealer features work, Drone Tour remains locked | **PASS** |
| **D. Dealer with Dealer Subscription** | Active Dealer Sub only | Drone Tour MUST remain locked | **PASS** |
| **E. Dealer with BOTH Subscriptions** | Active Dealer + Active Drone | Both dealer tools and Drone Tour work | **PASS** |
| **F. NRI without Drone Pass** | NRI residency | Drone Tour is visible but locked | **PASS** |
| **G. NRI with Drone Pass** | Verified Drone Subscription | Drone Tour unlocks | **PASS** |
| **H. Plan Selection (Pre-Payment)** | User selects plan / creates order | Status `pending`, Drone Tour remains locked | **PASS** |
| **I. Payment Failed** | Gateway returns failure | Status `inactive`, Drone Tour remains locked | **PASS** |
| **J. Payment Cancelled** | User cancels payment modal | Status `inactive`, Drone Tour remains locked | **PASS** |
| **K. Expiration Logic** | Expiry date < now | `isExpired == true`, Drone Tour automatically relocks | **PASS** |
| **L. Logout Lifecycle** | User logs out | Drone subscription cleared from session | **PASS** |
| **M. Database Separation** | Serialization check | Dedicated `drone_subscription_status` fields formatted without overwriting dealer fields | **PASS** |

### Automated Test Command Results
```bash
flutter test test/drone_subscription_separation_test.dart test/unique_validation_test.dart test/ios_compatibility_test.dart test/signup_validation_test.dart test/admin_command_center_test.dart
```
**Total Tests: 52/52 Passed (100% Success Rate)**.
