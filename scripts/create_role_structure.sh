#!/bin/bash

# Universal Role Structure Generation Script
# Generates views, ViewModels, and tests based on role_structures.yaml
# Usage: ./scripts/create_role_structure.sh [--role participant|provider] [--all]

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$BASE_DIR/lib"
TEST_DIR="$BASE_DIR/test"
CONFIG_FILE="$SCRIPT_DIR/role_structures.yaml"

echo "🚀 Universal Role Structure Generator"
echo "======================================"

# Check if yq is installed (for YAML parsing)
if ! command -v yq &> /dev/null; then
    echo "❌ Error: yq is not installed"
    echo "Install with: brew install yq"
    exit 1
fi

# Parse arguments
ROLE=""
GENERATE_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --role)
            ROLE="$2"
            shift 2
            ;;
        --all)
            GENERATE_ALL=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--role participant|provider] [--all]"
            exit 1
            ;;
    esac
done

# Function to convert snake_case to PascalCase
snake_to_pascal() {
    echo "$1" | sed -r 's/(^|_)([a-z])/\U\2/g'
}

# Function to convert snake_case to Title Case
snake_to_title() {
    echo "$1" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

# Function to create view file
create_view_file() {
    local file_path=$1
    local class_name=$2
    local view_model_name=$3
    local view_file=$(basename "$file_path" .dart)

    cat > "$file_path" << EOF
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
import '${view_file}_viewmodel.dart';
import '${view_file}.mobile.dart';
import '${view_file}.tablet.dart';
import '${view_file}.desktop.dart';

class ${class_name} extends StackedView<${view_model_name}> {
  const ${class_name}({super.key});

  @override
  Widget builder(
    BuildContext context,
    ${view_model_name} viewModel,
    Widget? child,
  ) {
    return ScreenTypeLayout.builder(
      mobile: (_) => const ${class_name}Mobile(),
      tablet: (_) => const ${class_name}Tablet(),
      desktop: (_) => const ${class_name}Desktop(),
    );
  }

  @override
  ${view_model_name} viewModelBuilder(BuildContext context) => ${view_model_name}();
}
EOF
}

# Function to create viewmodel file
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

# Function to create mobile view file
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
        title: const Text('$title'),
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

# Function to create tablet/desktop views (delegate to mobile)
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

# Function to create test file
create_test_file() {
    local file_path=$1
    local viewmodel_name=$2

    cat > "$file_path" << EOF
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Import your viewmodel
// import 'package:kinly/path/to/${viewmodel_name,,}_viewmodel.dart';

void main() {
  group('$viewmodel_name Tests', () {
    late $viewmodel_name viewModel;

    setUp(() {
      // viewModel = $viewmodel_name();
    });

    tearDown(() {
      // viewModel.dispose();
    });

    test('should initialize correctly', () {
      // TODO: Implement test
      expect(true, true);
    });

    // TODO: Add more tests for 100% coverage
  });
}
EOF
}

# Function to create all view files for a directory
create_view_set() {
    local dir=$1
    local base_name=$2
    local title=$3

    # Create directory if it doesn't exist
    mkdir -p "$dir"

    local view_file="${dir}/${base_name}_view.dart"
    local viewmodel_file="${dir}/${base_name}_viewmodel.dart"
    local mobile_file="${dir}/${base_name}_view.mobile.dart"
    local tablet_file="${dir}/${base_name}_view.tablet.dart"
    local desktop_file="${dir}/${base_name}_view.desktop.dart"

    # Convert snake_case to PascalCase
    local class_name=$(snake_to_pascal "$base_name")View
    local viewmodel_name=$(snake_to_pascal "$base_name")ViewModel

    echo "  📝 Creating $class_name..."

    create_view_file "$view_file" "$class_name" "$viewmodel_name"
    create_viewmodel_file "$viewmodel_file" "$viewmodel_name"
    create_mobile_view_file "$mobile_file" "${class_name}Mobile" "$viewmodel_name" "$title"
    create_platform_view_file "$tablet_file" "${class_name}Tablet" "$viewmodel_name" "${class_name}Mobile"
    create_platform_view_file "$desktop_file" "${class_name}Desktop" "$viewmodel_name" "${class_name}Mobile"

    # Create test file
    local test_file="$TEST_DIR/viewmodels/${base_name}_viewmodel_test.dart"
    mkdir -p "$(dirname "$test_file")"
    create_test_file "$test_file" "$viewmodel_name"
}

# Function to process YAML and generate views
generate_role_structure() {
    local role=$1
    echo ""
    echo "🔨 Generating $role structure..."
    echo "================================"

    # Get base path
    local base_path=$(yq e ".${role}.base_path" "$CONFIG_FILE")

    # Generate startup view if needed
    local has_startup=$(yq e ".${role}.startup_view" "$CONFIG_FILE")
    if [ "$has_startup" == "true" ]; then
        echo "📦 Creating startup view..."
        create_view_set "$LIB_DIR/ui/views/${role}/startup" "${role}_startup" "${role^} Startup"
    fi

    # Generate shared views
    echo "📦 Creating shared views..."
    local shared_count=$(yq e ".${role}.shared_views | length" "$CONFIG_FILE")
    for ((i=0; i<shared_count; i++)); do
        local view_name=$(yq e ".${role}.shared_views[$i].name" "$CONFIG_FILE")
        local view_title=$(yq e ".${role}.shared_views[$i].title" "$CONFIG_FILE")
        create_view_set "$LIB_DIR/ui/views/${role}/shared/${view_name}" "${role}_shared_${view_name}" "$view_title"
    done

    # Generate sub-role views (recursive handling)
    generate_sub_roles "$role" ".${role}.sub_roles" "$LIB_DIR/ui/views/${role}"
}

# Recursive function to generate sub-role views
generate_sub_roles() {
    local role=$1
    local yaml_path=$2
    local dir_path=$3

    # Get list of sub-roles
    local sub_roles=$(yq e "${yaml_path} | keys | .[]" "$CONFIG_FILE")

    for sub_role in $sub_roles; do
        echo "📦 Creating ${sub_role} views..."

        # Check if sub-role has startup
        local has_startup=$(yq e "${yaml_path}.${sub_role}.startup_view" "$CONFIG_FILE")
        if [ "$has_startup" == "true" ]; then
            create_view_set "${dir_path}/${sub_role}/startup" "${role}_${sub_role}_startup" "${sub_role^} Startup"
        fi

        # Generate shared views for this sub-role
        local shared_count=$(yq e "${yaml_path}.${sub_role}.shared_views | length" "$CONFIG_FILE")
        if [ "$shared_count" != "null" ] && [ "$shared_count" -gt 0 ]; then
            for ((i=0; i<shared_count; i++)); do
                local view_name=$(yq e "${yaml_path}.${sub_role}.shared_views[$i].name" "$CONFIG_FILE")
                local view_title=$(yq e "${yaml_path}.${sub_role}.shared_views[$i].title" "$CONFIG_FILE")
                create_view_set "${dir_path}/${sub_role}/shared/${view_name}" "${role}_${sub_role}_shared_${view_name}" "$view_title"
            done
        fi

        # Generate views for this sub-role
        local view_count=$(yq e "${yaml_path}.${sub_role}.views | length" "$CONFIG_FILE")
        if [ "$view_count" != "null" ] && [ "$view_count" -gt 0 ]; then
            for ((i=0; i<view_count; i++)); do
                local view_name=$(yq e "${yaml_path}.${sub_role}.views[$i].name" "$CONFIG_FILE")
                local view_title=$(yq e "${yaml_path}.${sub_role}.views[$i].title" "$CONFIG_FILE")
                create_view_set "${dir_path}/${sub_role}/${view_name}" "${role}_${sub_role}_${view_name}" "$view_title"
            done
        fi

        # Recursively process nested sub-roles
        local has_sub_roles=$(yq e "${yaml_path}.${sub_role}.sub_roles | length" "$CONFIG_FILE")
        if [ "$has_sub_roles" != "null" ] && [ "$has_sub_roles" -gt 0 ]; then
            generate_sub_roles "$role" "${yaml_path}.${sub_role}.sub_roles" "${dir_path}/${sub_role}"
        fi
    done
}

# Main execution
if [ "$GENERATE_ALL" == true ]; then
    generate_role_structure "participant"
    generate_role_structure "provider"
elif [ -n "$ROLE" ]; then
    generate_role_structure "$ROLE"
else
    echo "Usage: $0 [--role participant|provider] [--all]"
    echo ""
    echo "Examples:"
    echo "  $0 --all                    # Generate all role structures"
    echo "  $0 --role participant       # Generate participant structure only"
    echo "  $0 --role provider          # Generate provider structure only"
    exit 1
fi

echo ""
echo "✅ Generation complete!"
echo ""
echo "Next steps:"
echo "1. Review generated files in lib/ui/views/"
echo "2. Implement ViewModels with business logic"
echo "3. Update app.dart with route definitions"
echo "4. Run: dart run build_runner build --delete-conflicting-outputs"
echo "5. Run: flutter test"
echo ""
