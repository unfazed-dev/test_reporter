# Kinly Scripts

This directory contains utility scripts for the Kinly project.

## Route Generator

**Purpose**: Automatically generate all views, viewmodels, and layouts based on the defined route structure.

### Files

- `generate_routes.dart` - Main Dart script that generates all files
- `generate_routes.sh` - Bash wrapper for easy execution
- `app_routes_template.dart` - Template for app.dart routes section

### Usage

#### Option 1: Run with bash wrapper (Recommended)
```bash
./scripts/generate_routes.sh
```

#### Option 2: Run with Dart directly
```bash
dart run scripts/generate_routes.dart
```

### What Gets Generated

For each view/layout, the script creates:

1. **Base View** (`{name}_view.dart`)
   - Platform detection logic
   - Routes to platform-specific implementations

2. **Mobile View** (`{name}_view.mobile.dart`)
   - Mobile-optimized layout
   - Uses shadcn_ui components

3. **Tablet View** (`{name}_view.tablet.dart`)
   - Tablet-optimized layout
   - Uses shadcn_ui components

4. **Desktop View** (`{name}_view.desktop.dart`)
   - Desktop-optimized layout
   - Uses shadcn_ui components

5. **ViewModel** (`{name}_viewmodel.dart`)
   - Business logic layer
   - Follows Stacked architecture patterns

6. **Test File** (`test/viewmodels/{name}_viewmodel_test.dart`)
   - Unit test structure
   - Mock setup included

### After Generation

1. **Review Generated Files**
   ```bash
   # Views and layouts
   ls -la lib/ui/views/
   ls -la lib/ui/layouts/

   # Tests
   ls -la test/viewmodels/
   ```

2. **Update app.dart**

   Copy the route definitions from the script output and paste into `lib/app/app.dart`:

   ```dart
   @StackedApp(
     routes: [
       CustomRoute(page: StartupView, initial: true),
       CustomRoute(
         page: MainLayoutView,
         deferredLoading: true,
         path: '/',
         children: [
           CustomRoute(page: MainView, path: '', initial: true),
         ],
       ),
       // ... add all generated routes
     ],
   )
   ```

3. **Generate Stacked Code**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run Tests**
   ```bash
   flutter test
   ```

### Route Structure

The script generates routes for the following structure:

#### Layouts
- **MainLayout** (`/`)
  - MainView

- **AdminLayout** (`/admin`)
  - AdminDashboardView
  - AdminAccessView
  - AdminHumanResourcesView
  - AdminFinancesView
  - AdminMarketingView
  - AdminAccountingView

- **AuthLayout** (`/authenticate`)
  - AuthSignUpView (sign-up)
  - AuthSignInView (sign-in)

- **OnboardingLayout** (`/onboarding`)
  - OnboardingView

- **SettingsLayout** (`/settings`)
  - SettingsView

- **ParticipantLayout** (`/participant`)
  - ParticipantDashboardView
  - ParticipantInboxView
  - ParticipantBookingsView
  - ParticipantTeamView
  - ParticipantJournalView
  - ParticipantProfileView
  - ParticipantInvoicesView
  - ParticipantShopView
  - ParticipantAccountView
  - ParticipantRequestsView
  - ParticipantFundsView

- **ProviderLayout** (`/provider`)
  - ProviderDashboardView
  - ProviderInboxView
  - ProviderBookingsView
  - ProviderClientsView
  - ProviderJournalView
  - ProviderProfileView
  - ProviderInvoicesView
  - ProviderShopView
  - ProviderAccountView
  - ProviderRequestsView
  - ProviderFundsView
  - ProviderTravelBookView

- **SupporterLayout** (`/supporter`)
  - SupporterDashboardView
  - SupporterParticipantsView
  - SupporterProvidersView
  - SupporterInvoicesView
  - SupporterMeetingsView
  - SupporterInboxView
  - SupporterFundsView
  - SupporterRequestsView
  - SupporterJournalView
  - SupporterPaymentsView
  - SupporterTravelBookView
  - SupporterShopView

- **AccountManagerLayout** (`/account-manager`)
  - AccountManagerDashboardView
  - AccountManagerInboxView
  - AccountManagerTeamView
  - AccountManagerBookingsView

#### Standalone Views
- StartupView (`/`)
- UnknownView (`/404`)

#### Redirects
- `/login` → `/authenticate/sign-in`
- `/register` → `/authenticate/sign-up`
- `/sign-in` → `/authenticate/sign-in`
- `/sign-up` → `/authenticate/sign-up`
- `*` → `/404`

### Customization

To customize the generated files, edit the templates in `generate_routes.dart`:

- `_layoutBaseTemplate()` - Layout base view
- `_layoutPlatformTemplate()` - Layout platform views
- `_layoutViewModelTemplate()` - Layout viewmodel
- `_viewBaseTemplate()` - View base
- `_viewPlatformTemplate()` - View platform implementations
- `_viewModelTemplate()` - ViewModel
- `_viewModelTestTemplate()` - Test file

### File Output Locations

```
lib/
├── ui/
│   ├── layouts/
│   │   ├── main_layout/
│   │   │   ├── main_layout_view.dart
│   │   │   ├── main_layout_view.mobile.dart
│   │   │   ├── main_layout_view.tablet.dart
│   │   │   ├── main_layout_view.desktop.dart
│   │   │   └── main_layout_viewmodel.dart
│   │   ├── admin_layout/
│   │   └── ... (other layouts)
│   └── views/
│       ├── main/
│       │   ├── main_view.dart
│       │   ├── main_view.mobile.dart
│       │   ├── main_view.tablet.dart
│       │   ├── main_view.desktop.dart
│       │   └── main_viewmodel.dart
│       └── ... (other views)
test/
└── viewmodels/
    ├── main_layout_viewmodel_test.dart
    ├── main_viewmodel_test.dart
    └── ... (other tests)
```

### Best Practices

1. **Run the generator at the start of development** to create the structure
2. **Review generated files** before committing
3. **Customize templates** if you have project-specific patterns
4. **Re-run the script** if you add new routes (existing files won't be overwritten)
5. **Always run `dart run build_runner build`** after generation
6. **Run tests** to ensure everything compiles

### Troubleshooting

**Issue**: Script fails with "Dart not found"
- **Solution**: Ensure Flutter/Dart is in your PATH

**Issue**: Permission denied
- **Solution**: `chmod +x scripts/generate_routes.sh`

**Issue**: Files already exist
- **Solution**: The script skips existing files. Delete files you want to regenerate.

**Issue**: Routes not working after generation
- **Solution**: Ensure you've updated app.dart and run `dart run build_runner build`

### Contributing

When adding new routes:
1. Update the `RouteStructure` class in `generate_routes.dart`
2. Run the generator
3. Update app.dart with new routes
4. Test the new routes
5. Commit both the script changes and generated files
