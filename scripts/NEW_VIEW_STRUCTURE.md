# New View Structure - Role-Based Organization

## 📁 New Directory Structure

Views are now organized by role for better maintainability:

```
lib/ui/views/
├── participant/          # Participant-specific views
│   ├── dashboard/
│   ├── inbox/
│   ├── bookings/
│   ├── team/
│   ├── journal/
│   ├── profile/
│   ├── invoices/
│   ├── shop/
│   ├── account/
│   ├── requests/
│   └── funds/
│
├── provider/             # Provider-specific views
│   ├── dashboard/
│   ├── inbox/
│   ├── bookings/
│   ├── clients/
│   ├── journal/
│   ├── profile/
│   ├── invoices/
│   ├── shop/
│   ├── account/
│   ├── requests/
│   ├── funds/
│   └── travel_book/
│
├── admin/                # Admin-specific views
│   ├── dashboard/
│   ├── access/
│   ├── human_resources/
│   ├── finances/
│   ├── marketing/
│   └── accounting/
│
├── supporter/            # Supporter-specific views
│   ├── dashboard/
│   ├── participants/
│   ├── providers/
│   ├── invoices/
│   ├── meetings/
│   ├── inbox/
│   ├── funds/
│   ├── requests/
│   ├── journal/
│   ├── payments/
│   ├── travel_book/
│   └── shop/
│
├── participant_manager/      # Participant Manager-specific views
│   ├── dashboard/
│   ├── inbox/
│   ├── team/
│   └── bookings/
│
├── auth/                 # Authentication views
│   ├── sign_up/
│   └── sign_in/
│
└── common/               # Shared/Common views
    ├── main/
    ├── startup/
    ├── unknown/
    ├── settings/
    └── onboarding/
```

## 🔄 Path Migration Map

### Before → After

#### Participant Views
```
participant_dashboard     → participant/dashboard
participant_inbox         → participant/inbox
participant_bookings      → participant/bookings
participant_team          → participant/team
participant_journal       → participant/journal
participant_profile       → participant/profile
participant_invoices      → participant/invoices
participant_shop          → participant/shop
participant_account       → participant/account
participant_requests      → participant/requests
participant_funds         → participant/funds
```

#### Provider Views
```
provider_dashboard        → provider/dashboard
provider_inbox            → provider/inbox
provider_bookings         → provider/bookings
provider_clients          → provider/clients
provider_journal          → provider/journal
provider_profile          → provider/profile
provider_invoices         → provider/invoices
provider_shop             → provider/shop
provider_account          → provider/account
provider_requests         → provider/requests
provider_funds            → provider/funds
provider_travel_book      → provider/travel_book
```

#### Admin Views
```
admin_dashboard           → admin/dashboard
admin_access              → admin/access
admin_human_resources     → admin/human_resources
admin_finances            → admin/finances
admin_marketing           → admin/marketing
admin_accounting          → admin/accounting
```

#### Supporter Views
```
supporter_dashboard       → supporter/dashboard
supporter_participants    → supporter/participants
supporter_providers       → supporter/providers
supporter_invoices        → supporter/invoices
supporter_meetings        → supporter/meetings
supporter_inbox           → supporter/inbox
supporter_funds           → supporter/funds
supporter_requests        → supporter/requests
supporter_journal         → supporter/journal
supporter_payments        → supporter/payments
supporter_travel_book     → supporter/travel_book
supporter_shop            → supporter/shop
```

#### Participant Manager Views
```
participant_manager_dashboard → participant_manager/dashboard
participant_manager_inbox     → participant_manager/inbox
participant_manager_team      → participant_manager/team
participant_manager_bookings  → participant_manager/bookings
```

#### Auth Views
```
auth_sign_up              → auth/sign_up
auth_sign_in              → auth/sign_in
```

#### Common Views
```
main                      → common/main
startup                   → common/startup
unknown                   → common/unknown
settings                  → common/settings
onboarding                → common/onboarding
```

## 📝 Updated Import Paths

### Example: Participant Dashboard

**Before:**
```dart
import 'package:kinly/ui/views/participant_dashboard/participant_dashboard_view.dart';
import 'package:kinly/ui/views/participant_dashboard/participant_dashboard_viewmodel.dart';
```

**After:**
```dart
import 'package:kinly/ui/views/participant/dashboard/participant_dashboard_view.dart';
import 'package:kinly/ui/views/participant/dashboard/participant_dashboard_viewmodel.dart';
```

### Example: Admin Access

**Before:**
```dart
import 'package:kinly/ui/views/admin_access/admin_access_view.dart';
```

**After:**
```dart
import 'package:kinly/ui/views/admin/access/admin_access_view.dart';
```

## ✅ What Was Updated

1. **52 view directories moved** into role-based folders
2. **51 test files updated** with new import paths
3. **All ViewModels retain their original names** (e.g., `ParticipantDashboardViewModel`)
4. **Test files remain in original locations** (`test/viewmodels/participant_dashboard_viewmodel_test.dart`)

## 📊 Statistics

| Role | Views Moved |
|------|-------------|
| Participant | 11 |
| Provider | 12 |
| Admin | 6 |
| Supporter | 12 |
| Participant Manager | 4 |
| Auth | 2 |
| Common | 5 |
| **Total** | **52** |

## 🎯 Benefits

1. **Better Organization** - Views grouped by user role
2. **Easier Navigation** - Find views faster
3. **Clearer Structure** - Role-based folders reflect app architecture
4. **Scalability** - Easy to add new role-specific views
5. **Maintainability** - Related views are co-located

## 📋 Next Steps

1. Update `lib/app/app.dart` with new import paths (see `scripts/app_imports_updated.txt`)
2. Run: `dart format .`
3. Run: `flutter analyze`
4. Run: `flutter test`
5. Run: `dart run build_runner build --delete-conflicting-outputs`

## ⚙️ File Naming Convention

- **ViewModel files**: Keep original names with role prefix
  - `participant_dashboard_viewmodel.dart` (not changed)
- **View files**: Keep original names with role prefix
  - `participant_dashboard_view.dart` (not changed)
- **Test files**: Keep original names
  - `participant_dashboard_viewmodel_test.dart` (not changed)

This ensures backward compatibility with existing references while organizing the directory structure.

---

**Reorganization Date:** $(date)
**Script:** `scripts/reorganize_views.dart`
**Total Files Moved:** 52 view directories
**Total Imports Updated:** 51 test files
