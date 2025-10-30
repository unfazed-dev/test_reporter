#!/bin/bash

# Kinly Hub Structure Creation Script
# This script creates all necessary directories and placeholder files for the hub routing system

set -e  # Exit on error

BASE_DIR="/Users/unfazed-mac/Developer/apps/kinly"
LIB_DIR="$BASE_DIR/lib"

echo "🚀 Creating Kinly Hub Structure..."

# ============================================
# 1. CREATE DIRECTORY STRUCTURE
# ============================================

echo "📁 Creating directories..."

# Hub Layout
mkdir -p "$LIB_DIR/ui/layouts/hub_layout/widgets"

# Hub Views - Startup
mkdir -p "$LIB_DIR/ui/views/hub/startup"

# Hub Views - Shared (10 views)
mkdir -p "$LIB_DIR/ui/views/hub/shared/inbox"
mkdir -p "$LIB_DIR/ui/views/hub/shared/settings"
mkdir -p "$LIB_DIR/ui/views/hub/shared/payslips"
mkdir -p "$LIB_DIR/ui/views/hub/shared/documents"
mkdir -p "$LIB_DIR/ui/views/hub/shared/calendar"
mkdir -p "$LIB_DIR/ui/views/hub/shared/directory"
mkdir -p "$LIB_DIR/ui/views/hub/shared/announcements"
mkdir -p "$LIB_DIR/ui/views/hub/shared/training"
mkdir -p "$LIB_DIR/ui/views/hub/shared/time_off"
mkdir -p "$LIB_DIR/ui/views/hub/shared/expenses"

# Hub Views - Support Coordinator (11 views)
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/dashboard"
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/participants"
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/providers"
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/invoices"
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/meetings"
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/funds"
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/requests"
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/journal"
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/payments"
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/travel_book"
mkdir -p "$LIB_DIR/ui/views/hub/support_coordinator/shop"

# Hub Views - Support Worker
mkdir -p "$LIB_DIR/ui/views/hub/support_worker/dashboard"

# Hub Views - Admin (6 views)
mkdir -p "$LIB_DIR/ui/views/hub/admin/dashboard"
mkdir -p "$LIB_DIR/ui/views/hub/admin/access"
mkdir -p "$LIB_DIR/ui/views/hub/admin/human_resources"
mkdir -p "$LIB_DIR/ui/views/hub/admin/finances"
mkdir -p "$LIB_DIR/ui/views/hub/admin/marketing"
mkdir -p "$LIB_DIR/ui/views/hub/admin/accounting"

# Hub Views - Accountant
mkdir -p "$LIB_DIR/ui/views/hub/accountant/dashboard"

# Hub Views - HR
mkdir -p "$LIB_DIR/ui/views/hub/hr/dashboard"

# Hub Views - Marketing
mkdir -p "$LIB_DIR/ui/views/hub/marketing/dashboard"

echo "✅ Directories created"

# ============================================
# 2. CREATE PLACEHOLDER FILES
# ============================================

echo "📝 Creating placeholder files..."

# Function to create a basic view file
create_view_file() {
    local file_path=$1
    local class_name=$2
    local view_model_name=$3

    cat > "$file_path" << 'EOF'
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
import '${VIEW_MODEL_FILE}';
import '${VIEW_FILE}.mobile.dart';
import '${VIEW_FILE}.tablet.dart';
import '${VIEW_FILE}.desktop.dart';

class ${CLASS_NAME} extends StackedView<${VIEW_MODEL_NAME}> {
  const ${CLASS_NAME}({super.key});

  @override
  Widget builder(
    BuildContext context,
    ${VIEW_MODEL_NAME} viewModel,
    Widget? child,
  ) {
    return ScreenTypeLayout.builder(
      mobile: (_) => const ${CLASS_NAME}Mobile(),
      tablet: (_) => const ${CLASS_NAME}Tablet(),
      desktop: (_) => const ${CLASS_NAME}Desktop(),
    );
  }

  @override
  ${VIEW_MODEL_NAME} viewModelBuilder(BuildContext context) => ${VIEW_MODEL_NAME}();
}
EOF

    # Replace placeholders
    local view_file=$(basename "$file_path" .dart)
    sed -i '' "s/\${CLASS_NAME}/$class_name/g" "$file_path"
    sed -i '' "s/\${VIEW_MODEL_NAME}/$view_model_name/g" "$file_path"
    sed -i '' "s/\${VIEW_MODEL_FILE}/${view_file}_viewmodel.dart/g" "$file_path"
    sed -i '' "s/\${VIEW_FILE}/$view_file/g" "$file_path"
}

# Function to create a basic viewmodel file
create_viewmodel_file() {
    local file_path=$1
    local class_name=$2

    cat > "$file_path" << EOF
import 'package:stacked/stacked.dart';

class $class_name extends BaseViewModel {
  // TODO: Implement $class_name logic
}
EOF
}

# Function to create a basic mobile view file
create_mobile_view_file() {
    local file_path=$1
    local class_name=$2
    local view_model_name=$3
    local title=$4

    cat > "$file_path" << EOF
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '${view_model_name,,}_viewmodel.dart';

class ${class_name}Mobile extends ViewModelWidget<$view_model_name> {
  const ${class_name}Mobile({super.key});

  @override
  Widget build(BuildContext context, $view_model_name viewModel) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('$title'),
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
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$title',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.foreground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF
}

# Function to create tablet/desktop views (just redirect to mobile)
create_platform_view_file() {
    local file_path=$1
    local class_name=$2
    local view_model_name=$3
    local mobile_class=$4

    cat > "$file_path" << EOF
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '${view_model_name,,}_viewmodel.dart';
import '${mobile_class,,}.dart';

class $class_name extends ViewModelWidget<$view_model_name> {
  const $class_name({super.key});

  @override
  Widget build(BuildContext context, $view_model_name viewModel) {
    return const $mobile_class();
  }
}
EOF
}

# Function to create all view files for a directory
create_view_set() {
    local dir=$1
    local base_name=$2
    local title=$3

    local view_file="${dir}/${base_name}_view.dart"
    local viewmodel_file="${dir}/${base_name}_viewmodel.dart"
    local mobile_file="${dir}/${base_name}_view.mobile.dart"
    local tablet_file="${dir}/${base_name}_view.tablet.dart"
    local desktop_file="${dir}/${base_name}_view.desktop.dart"

    # Convert snake_case to PascalCase
    local class_name=$(echo "$base_name" | sed -r 's/(^|_)([a-z])/\U\2/g')View
    local viewmodel_name=$(echo "$base_name" | sed -r 's/(^|_)([a-z])/\U\2/g')ViewModel

    create_view_file "$view_file" "$class_name" "$viewmodel_name"
    create_viewmodel_file "$viewmodel_file" "$viewmodel_name"
    create_mobile_view_file "$mobile_file" "${class_name}Mobile" "$viewmodel_name" "$title"
    create_platform_view_file "$tablet_file" "${class_name}Tablet" "$viewmodel_name" "${class_name}Mobile"
    create_platform_view_file "$desktop_file" "${class_name}Desktop" "$viewmodel_name" "${class_name}Mobile"
}

# Create all view sets
echo "Creating shared views..."
create_view_set "$LIB_DIR/ui/views/hub/shared/inbox" "hub_inbox" "Inbox"
create_view_set "$LIB_DIR/ui/views/hub/shared/settings" "hub_settings" "Settings"
create_view_set "$LIB_DIR/ui/views/hub/shared/payslips" "hub_payslips" "Payslips"
create_view_set "$LIB_DIR/ui/views/hub/shared/documents" "hub_documents" "Documents"
create_view_set "$LIB_DIR/ui/views/hub/shared/calendar" "hub_calendar" "Calendar"
create_view_set "$LIB_DIR/ui/views/hub/shared/directory" "hub_directory" "Staff Directory"
create_view_set "$LIB_DIR/ui/views/hub/shared/announcements" "hub_announcements" "Announcements"
create_view_set "$LIB_DIR/ui/views/hub/shared/training" "hub_training" "Training"
create_view_set "$LIB_DIR/ui/views/hub/shared/time_off" "hub_time_off" "Time Off"
create_view_set "$LIB_DIR/ui/views/hub/shared/expenses" "hub_expenses" "Expenses"

echo "Creating support coordinator views..."
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/dashboard" "support_coordinator_dashboard" "Support Coordinator Dashboard"
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/participants" "support_coordinator_participants" "Participants"
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/providers" "support_coordinator_providers" "Providers"
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/invoices" "support_coordinator_invoices" "Invoices"
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/meetings" "support_coordinator_meetings" "Meetings"
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/funds" "support_coordinator_funds" "Funds"
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/requests" "support_coordinator_requests" "Requests"
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/journal" "support_coordinator_journal" "Journal"
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/payments" "support_coordinator_payments" "Payments"
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/travel_book" "support_coordinator_travel_book" "Travel Book"
create_view_set "$LIB_DIR/ui/views/hub/support_coordinator/shop" "support_coordinator_shop" "Shop"

echo "Creating other role dashboards..."
create_view_set "$LIB_DIR/ui/views/hub/support_worker/dashboard" "support_worker_dashboard" "Support Worker Dashboard"
create_view_set "$LIB_DIR/ui/views/hub/admin/dashboard" "hub_admin_dashboard" "Admin Dashboard"
create_view_set "$LIB_DIR/ui/views/hub/admin/access" "hub_admin_access" "Access Control"
create_view_set "$LIB_DIR/ui/views/hub/admin/human_resources" "hub_admin_human_resources" "Human Resources"
create_view_set "$LIB_DIR/ui/views/hub/admin/finances" "hub_admin_finances" "Finances"
create_view_set "$LIB_DIR/ui/views/hub/admin/marketing" "hub_admin_marketing" "Marketing"
create_view_set "$LIB_DIR/ui/views/hub/admin/accounting" "hub_admin_accounting" "Accounting"
create_view_set "$LIB_DIR/ui/views/hub/accountant/dashboard" "accountant_dashboard" "Accountant Dashboard"
create_view_set "$LIB_DIR/ui/views/hub/hr/dashboard" "hr_dashboard" "HR Dashboard"
create_view_set "$LIB_DIR/ui/views/hub/marketing/dashboard" "marketing_dashboard" "Marketing Dashboard"

echo "✅ All placeholder files created"

echo ""
echo "🎉 Hub structure creation complete!"
echo ""
echo "Next steps:"
echo "1. The hub_startup files are already created separately"
echo "2. Add imports to app.dart"
echo "3. Add route configuration to app.dart"
echo "4. Run: dart run build_runner build --delete-conflicting-outputs"
echo ""
