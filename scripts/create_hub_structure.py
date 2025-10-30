#!/usr/bin/env python3
"""
Kinly Hub Structure Creation Script
Creates all necessary directories and placeholder files for the hub routing system
"""

import os
from pathlib import Path

BASE_DIR = Path("/Users/unfazed-mac/Developer/apps/kinly")
LIB_DIR = BASE_DIR / "lib"

def snake_to_pascal(snake_str):
    """Convert snake_case to PascalCase"""
    return ''.join(word.capitalize() for word in snake_str.split('_'))

def create_view_file(file_path, class_name, view_model_name, base_name, mobile_class, tablet_class, desktop_class):
    """Create main view file"""
    content = f"""import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
import '{base_name}_viewmodel.dart';
import '{base_name}_view.mobile.dart';
import '{base_name}_view.tablet.dart';
import '{base_name}_view.desktop.dart';

class {class_name} extends StackedView<{view_model_name}> {{
  const {class_name}({{super.key}});

  @override
  Widget builder(
    BuildContext context,
    {view_model_name} viewModel,
    Widget? child,
  ) {{
    return ScreenTypeLayout.builder(
      mobile: (_) => const {mobile_class}(),
      tablet: (_) => const {tablet_class}(),
      desktop: (_) => const {desktop_class}(),
    );
  }}

  @override
  {view_model_name} viewModelBuilder(BuildContext context) => {view_model_name}();
}}
"""
    file_path.write_text(content)

def create_viewmodel_file(file_path, class_name):
    """Create viewmodel file"""
    content = f"""import 'package:stacked/stacked.dart';

class {class_name} extends BaseViewModel {{
  // TODO: Implement {class_name} logic
}}
"""
    file_path.write_text(content)

def create_mobile_view_file(file_path, class_name, view_model_name, title):
    """Create mobile view file"""
    # Convert PascalCase ViewModel name to snake_case file name
    viewmodel_file = ''.join(['_'+c.lower() if c.isupper() else c for c in view_model_name.replace("ViewModel", "")]).lstrip('_')
    content = f"""import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '{viewmodel_file}_viewmodel.dart';

class {class_name} extends ViewModelWidget<{view_model_name}> {{
  const {class_name}({{super.key}});

  @override
  Widget build(BuildContext context, {view_model_name} viewModel) {{
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('{title}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '{title}',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.foreground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }}
}}
"""
    file_path.write_text(content)

def create_platform_view_file(file_path, class_name, view_model_name, mobile_class, base_name):
    """Create tablet/desktop view file"""
    content = f"""import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '{base_name}_viewmodel.dart';
import '{base_name}_view.mobile.dart';

class {class_name} extends ViewModelWidget<{view_model_name}> {{
  const {class_name}({{super.key}});

  @override
  Widget build(BuildContext context, {view_model_name} viewModel) {{
    return const {mobile_class}();
  }}
}}
"""
    file_path.write_text(content)

def create_view_set(dir_path, base_name, title):
    """Create all view files for a directory"""
    dir_path.mkdir(parents=True, exist_ok=True)

    class_name = snake_to_pascal(base_name) + "View"
    viewmodel_name = snake_to_pascal(base_name) + "ViewModel"

    # Create class names for mobile, tablet, desktop
    mobile_class_name = class_name.replace("View", "") + "ViewMobile"
    tablet_class_name = class_name.replace("View", "") + "ViewTablet"
    desktop_class_name = class_name.replace("View", "") + "ViewDesktop"

    # Main view file
    create_view_file(
        dir_path / f"{base_name}_view.dart",
        class_name,
        viewmodel_name,
        base_name,
        mobile_class_name,
        tablet_class_name,
        desktop_class_name
    )

    # ViewModel file
    create_viewmodel_file(
        dir_path / f"{base_name}_viewmodel.dart",
        viewmodel_name
    )

    # Mobile view
    create_mobile_view_file(
        dir_path / f"{base_name}_view.mobile.dart",
        mobile_class_name,
        viewmodel_name,
        title
    )

    # Tablet view
    create_platform_view_file(
        dir_path / f"{base_name}_view.tablet.dart",
        tablet_class_name,
        viewmodel_name,
        mobile_class_name,
        base_name
    )

    # Desktop view
    create_platform_view_file(
        dir_path / f"{base_name}_view.desktop.dart",
        desktop_class_name,
        viewmodel_name,
        mobile_class_name,
        base_name
    )

def main():
    print("🚀 Creating Kinly Hub Structure...")

    # Shared views (10)
    print("Creating shared views...")
    shared_views = [
        ("inbox", "Inbox"),
        ("settings", "Settings"),
        ("payslips", "Payslips"),
        ("documents", "Documents"),
        ("calendar", "Calendar"),
        ("directory", "Staff Directory"),
        ("announcements", "Announcements"),
        ("training", "Training"),
        ("time_off", "Time Off"),
        ("expenses", "Expenses"),
    ]

    for view_name, title in shared_views:
        create_view_set(
            LIB_DIR / "ui" / "views" / "hub" / "shared" / view_name,
            f"hub_{view_name}",
            title
        )

    # Support Coordinator views (11)
    print("Creating support coordinator views...")
    sc_views = [
        ("dashboard", "Support Coordinator Dashboard"),
        ("participants", "Participants"),
        ("providers", "Providers"),
        ("invoices", "Invoices"),
        ("meetings", "Meetings"),
        ("funds", "Funds"),
        ("requests", "Requests"),
        ("journal", "Journal"),
        ("payments", "Payments"),
        ("travel_book", "Travel Book"),
        ("shop", "Shop"),
    ]

    for view_name, title in sc_views:
        create_view_set(
            LIB_DIR / "ui" / "views" / "hub" / "support_coordinator" / view_name,
            f"support_coordinator_{view_name}",
            title
        )

    # Admin views (6)
    print("Creating admin views...")
    admin_views = [
        ("dashboard", "Admin Dashboard"),
        ("access", "Access Control"),
        ("human_resources", "Human Resources"),
        ("finances", "Finances"),
        ("marketing", "Marketing"),
        ("accounting", "Accounting"),
    ]

    for view_name, title in admin_views:
        create_view_set(
            LIB_DIR / "ui" / "views" / "hub" / "admin" / view_name,
            f"hub_admin_{view_name}",
            title
        )

    # Other role dashboards
    print("Creating other role dashboards...")
    other_roles = [
        ("support_worker", "Support Worker Dashboard"),
        ("accountant", "Accountant Dashboard"),
        ("hr", "HR Dashboard"),
        ("marketing", "Marketing Dashboard"),
    ]

    for role, title in other_roles:
        create_view_set(
            LIB_DIR / "ui" / "views" / "hub" / role / "dashboard",
            f"{role}_dashboard",
            title
        )

    # Create hub layout
    print("Creating hub layout...")
    layout_dir = LIB_DIR / "ui" / "layouts" / "hub_layout"
    layout_dir.mkdir(parents=True, exist_ok=True)

    # Hub layout viewmodel
    (layout_dir / "hub_layout_viewmodel.dart").write_text("""import 'package:stacked/stacked.dart';

class HubLayoutViewModel extends BaseViewModel {
  // TODO: Add hub-specific logic here
}
""")

    # Hub layout view
    (layout_dir / "hub_layout_view.dart").write_text("""import 'package:flutter/material.dart';
import 'package:kinly/ui/layouts/hub_layout/hub_layout_viewmodel.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
import 'hub_layout_view.mobile.dart';
import 'hub_layout_view.tablet.dart';
import 'hub_layout_view.desktop.dart';

class HubLayoutView extends StackedView<HubLayoutViewModel> {
  const HubLayoutView({super.key});

  @override
  Widget builder(
    BuildContext context,
    HubLayoutViewModel viewModel,
    Widget? child,
  ) {
    return ScreenTypeLayout.builder(
      mobile: (_) => HubLayoutViewMobile(child: child),
      tablet: (_) => HubLayoutViewTablet(child: child),
      desktop: (_) => HubLayoutViewDesktop(child: child),
    );
  }

  @override
  HubLayoutViewModel viewModelBuilder(BuildContext context) => HubLayoutViewModel();
}
""")

    # Hub layout mobile
    (layout_dir / "hub_layout_view.mobile.dart").write_text("""import 'package:flutter/material.dart';
import 'package:kinly/ui/layouts/hub_layout/hub_layout_viewmodel.dart';
import 'package:stacked/stacked.dart';

class HubLayoutViewMobile extends ViewModelWidget<HubLayoutViewModel> {
  final Widget? child;

  const HubLayoutViewMobile({super.key, this.child});

  @override
  Widget build(BuildContext context, HubLayoutViewModel viewModel) {
    return Scaffold(
      body: child ?? const SizedBox.shrink(),
    );
  }
}
""")

    # Hub layout tablet
    (layout_dir / "hub_layout_view.tablet.dart").write_text("""import 'package:flutter/material.dart';
import 'package:kinly/ui/layouts/hub_layout/hub_layout_view.mobile.dart';
import 'package:kinly/ui/layouts/hub_layout/hub_layout_viewmodel.dart';
import 'package:stacked/stacked.dart';

class HubLayoutViewTablet extends ViewModelWidget<HubLayoutViewModel> {
  final Widget? child;

  const HubLayoutViewTablet({super.key, this.child});

  @override
  Widget build(BuildContext context, HubLayoutViewModel viewModel) {
    return HubLayoutViewMobile(child: child);
  }
}
""")

    # Hub layout desktop
    (layout_dir / "hub_layout_view.desktop.dart").write_text("""import 'package:flutter/material.dart';
import 'package:kinly/ui/layouts/hub_layout/hub_layout_view.mobile.dart';
import 'package:kinly/ui/layouts/hub_layout/hub_layout_viewmodel.dart';
import 'package:stacked/stacked.dart';

class HubLayoutViewDesktop extends ViewModelWidget<HubLayoutViewModel> {
  final Widget? child;

  const HubLayoutViewDesktop({super.key, this.child});

  @override
  Widget build(BuildContext context, HubLayoutViewModel viewModel) {
    return HubLayoutViewMobile(child: child);
  }
}
""")

    print("✅ All files created!")
    print("")
    print("📊 Summary:")
    print("  - Hub Layout: ✅")
    print("  - Hub Startup: ✅ (created separately)")
    print("  - Shared Views: 10 ✅")
    print("  - Support Coordinator Views: 11 ✅")
    print("  - Admin Views: 6 ✅")
    print("  - Other Role Dashboards: 4 ✅")
    print("")
    print("Next steps:")
    print("1. Add imports to app.dart")
    print("2. Add route configuration to app.dart")
    print("3. Run: dart run build_runner build --delete-conflicting-outputs")

if __name__ == "__main__":
    main()
