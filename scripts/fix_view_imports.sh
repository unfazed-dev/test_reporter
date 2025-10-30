#!/bin/bash

# Fix incorrect ViewModel imports in generated view files
# Changes: participant_manager_dashboard_view_viewmodel.dart
# To: participant_manager_dashboard_viewmodel.dart

echo "Fixing ViewModel imports in generated views..."

# Find all *_view.dart files (not .mobile, .desktop, .tablet)
find lib/ui/views/participant lib/ui/views/provider -name "*_view.dart" -type f | while read -r file; do
    # Check if file contains the incorrect pattern
    if grep -q "_view_viewmodel.dart" "$file"; then
        echo "Fixing: $file"
        # Replace _view_viewmodel.dart with _viewmodel.dart
        sed -i '' 's/_view_viewmodel\.dart/_viewmodel.dart/g' "$file"
    fi
done

# Also fix the platform-specific files (.mobile, .desktop, .tablet)
find lib/ui/views/participant lib/ui/views/provider -name "*_view.mobile.dart" -o -name "*_view.desktop.dart" -o -name "*_view.tablet.dart" | while read -r file; do
    if grep -q "_viewmodel\.dart" "$file"; then
        echo "Fixing: $file"
        # Fix incorrect lowercased imports
        # E.g., participantmanagerdashboard_viewmodel.dart -> participant_manager_dashboard_viewmodel.dart
        # This is more complex, so let's handle case by case
        sed -i '' "s/participantsharedaccount_viewmodel/participant_shared_account_viewmodel/g" "$file"
        sed -i '' "s/participantsharedbookings_viewmodel/participant_shared_bookings_viewmodel/g" "$file"
        sed -i '' "s/participantshareddashboard_viewmodel/participant_shared_dashboard_viewmodel/g" "$file"
        sed -i '' "s/participantsharedfunds_viewmodel/participant_shared_funds_viewmodel/g" "$file"
        sed -i '' "s/participantsharedinbox_viewmodel/participant_shared_inbox_viewmodel/g" "$file"
        sed -i '' "s/participantsharedinvoices_viewmodel/participant_shared_invoices_viewmodel/g" "$file"
        sed -i '' "s/participantsharedjournal_viewmodel/participant_shared_journal_viewmodel/g" "$file"
        sed -i '' "s/participantsharedprofile_viewmodel/participant_shared_profile_viewmodel/g" "$file"
        sed -i '' "s/participantsharedproviders_viewmodel/participant_shared_providers_viewmodel/g" "$file"
        sed -i '' "s/participantsharedrequests_viewmodel/participant_shared_requests_viewmodel/g" "$file"
        sed -i '' "s/participantsharedshop_viewmodel/participant_shared_shop_viewmodel/g" "$file"
        sed -i '' "s/participantsharedteam_viewmodel/participant_shared_team_viewmodel/g" "$file"

        sed -i '' "s/participantmanagerapprovals_viewmodel/participant_manager_approvals_viewmodel/g" "$file"
        sed -i '' "s/participantmanagercarecoordination_viewmodel/participant_manager_care_coordination_viewmodel/g" "$file"
        sed -i '' "s/participantmanagerdashboard_viewmodel/participant_manager_dashboard_viewmodel/g" "$file"
        sed -i '' "s/participantmanagerdocuments_viewmodel/participant_manager_documents_viewmodel/g" "$file"
        sed -i '' "s/participantmanagerparticipantmanagement_viewmodel/participant_manager_participant_management_viewmodel/g" "$file"

        # Fix mobile/tablet/desktop file names
        sed -i '' "s/participantsharedaccount_viewmobile/participant_shared_account_view.mobile/g" "$file"
        sed -i '' "s/participantsharedbookings_viewmobile/participant_shared_bookings_view.mobile/g" "$file"
        sed -i '' "s/participantshareddashboard_viewmobile/participant_shared_dashboard_view.mobile/g" "$file"
        sed -i '' "s/participantsharedfunds_viewmobile/participant_shared_funds_view.mobile/g" "$file"
        sed -i '' "s/participantsharedinbox_viewmobile/participant_shared_inbox_view.mobile/g" "$file"
        sed -i '' "s/participantsharedinvoices_viewmobile/participant_shared_invoices_view.mobile/g" "$file"
        sed -i '' "s/participantsharedjournal_viewmobile/participant_shared_journal_view.mobile/g" "$file"
        sed -i '' "s/participantsharedprofile_viewmobile/participant_shared_profile_view.mobile/g" "$file"
        sed -i '' "s/participantsharedproviders_viewmobile/participant_shared_providers_view.mobile/g" "$file"
        sed -i '' "s/participantsharedrequests_viewmobile/participant_shared_requests_view.mobile/g" "$file"
        sed -i '' "s/participantsharedshop_viewmobile/participant_shared_shop_view.mobile/g" "$file"
        sed -i '' "s/participantsharedteam_viewmobile/participant_shared_team_view.mobile/g" "$file"

        sed -i '' "s/participantmanagerapprovals_viewmobile/participant_manager_approvals_view.mobile/g" "$file"
        sed -i '' "s/participantmanagercarecoordination_viewmobile/participant_manager_care_coordination_view.mobile/g" "$file"
        sed -i '' "s/participantmanagerdashboard_viewmobile/participant_manager_dashboard_view.mobile/g" "$file"
        sed -i '' "s/participantmanagerdocuments_viewmobile/participant_manager_documents_view.mobile/g" "$file"
        sed -i '' "s/participantmanagerparticipantmanagement_viewmobile/participant_manager_participant_management_view.mobile/g" "$file"
    fi
done

echo "✅ Fixed ViewModel imports!"
