#!/usr/bin/env python3
"""Generate all hub imports for app.dart"""

# Hub Layout
print("// Hub Layout")
print("import 'package:kinly/ui/layouts/hub_layout/hub_layout_view.dart';")
print()

# Hub Startup
print("// Hub Startup")
print("import 'package:kinly/ui/views/hub/startup/hub_startup_view.dart';")
print()

# Shared Views (10)
print("// Hub Shared Views")
shared_views = ["inbox", "settings", "payslips", "documents", "calendar",
                "directory", "announcements", "training", "time_off", "expenses"]
for view in shared_views:
    pascal_name = ''.join(word.capitalize() for word in view.split('_'))
    print(f"import 'package:kinly/ui/views/hub/shared/{view}/hub_{view}_view.dart';")
print()

# Support Coordinator Views (11)
print("// Hub Support Coordinator Views")
sc_views = ["dashboard", "participants", "providers", "invoices", "meetings",
            "funds", "requests", "journal", "payments", "travel_book", "shop"]
for view in sc_views:
    pascal_name = ''.join(word.capitalize() for word in view.split('_'))
    print(f"import 'package:kinly/ui/views/hub/support_coordinator/{view}/support_coordinator_{view}_view.dart';")
print()

# Support Worker
print("// Hub Support Worker Views")
print("import 'package:kinly/ui/views/hub/support_worker/dashboard/support_worker_dashboard_view.dart';")
print()

# Admin Views (6)
print("// Hub Admin Views")
admin_views = ["dashboard", "access", "human_resources", "finances", "marketing", "accounting"]
for view in admin_views:
    print(f"import 'package:kinly/ui/views/hub/admin/{view}/hub_admin_{view}_view.dart';")
print()

# Other Roles
print("// Hub Other Role Dashboards")
print("import 'package:kinly/ui/views/hub/accountant/dashboard/accountant_dashboard_view.dart';")
print("import 'package:kinly/ui/views/hub/hr/dashboard/hr_dashboard_view.dart';")
print("import 'package:kinly/ui/views/hub/marketing/dashboard/marketing_dashboard_view.dart';")
