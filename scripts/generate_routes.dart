#!/usr/bin/env dart

import 'dart:io';

/// Script to generate all views, viewmodels, and layouts from the route structure
///
/// Usage: dart run scripts/generate_routes.dart
///
/// This script will:
/// - Create layout views with nested routing support
/// - Create child views with platform-specific implementations (mobile, tablet, desktop)
/// - Generate viewmodels with proper Stacked integration
/// - Create test files for all viewmodels
/// - Follow Kinly architecture patterns

void main() async {
  stdout.writeln('🚀 Kinly Route Generator');
  stdout.writeln('=' * 60);
  stdout.writeln('');

  // Define the route structure
  final routes = RouteStructure();

  // Generate all views and viewmodels
  final generator = ViewGenerator();
  await generator.generateAll(routes);

  stdout.writeln('');
  stdout.writeln('=' * 60);
  stdout.writeln('✅ Generation complete!');
  stdout.writeln('');
  stdout.writeln('Next steps:');
  stdout.writeln('1. Review the generated files');
  stdout.writeln('2. Update lib/app/app.dart with the routes');
  stdout.writeln(
      '3. Run: dart run build_runner build --delete-conflicting-outputs');
  stdout.writeln('4. Run: flutter test');
}

/// Route structure definition
class RouteStructure {
  // Layouts with their child routes
  final layouts = <LayoutDefinition>[
    LayoutDefinition(
      name: 'MainLayout',
      path: '/',
      children: [
        ViewDefinition(name: 'Main', path: '', initial: true),
      ],
    ),
    LayoutDefinition(
      name: 'AdminLayout',
      path: '/admin',
      children: [
        ViewDefinition(name: 'AdminDashboard', path: '', initial: true),
        ViewDefinition(name: 'AdminAccess', path: 'access'),
        ViewDefinition(name: 'AdminHumanResources', path: 'human-resources'),
        ViewDefinition(name: 'AdminFinances', path: 'finances'),
        ViewDefinition(name: 'AdminMarketing', path: 'marketing'),
        ViewDefinition(name: 'AdminAccounting', path: 'accounting'),
      ],
    ),
    LayoutDefinition(
      name: 'AuthLayout',
      path: '/authenticate',
      children: [
        ViewDefinition(name: 'AuthSignUp', path: 'sign-up', initial: true),
        ViewDefinition(name: 'AuthSignIn', path: 'sign-in'),
      ],
    ),
    LayoutDefinition(
      name: 'OnboardingLayout',
      path: '/onboarding',
      children: [
        ViewDefinition(name: 'Onboarding', path: '', initial: true),
      ],
    ),
    LayoutDefinition(
      name: 'SettingsLayout',
      path: '/settings',
      children: [
        ViewDefinition(name: 'Settings', path: '', initial: true),
      ],
    ),
    LayoutDefinition(
      name: 'ParticipantLayout',
      path: '/participant',
      children: [
        ViewDefinition(name: 'ParticipantDashboard', path: '', initial: true),
        ViewDefinition(name: 'ParticipantInbox', path: 'inbox'),
        ViewDefinition(name: 'ParticipantBookings', path: 'bookings'),
        ViewDefinition(name: 'ParticipantTeam', path: 'team'),
        ViewDefinition(name: 'ParticipantJournal', path: 'journal'),
        ViewDefinition(name: 'ParticipantProfile', path: 'profile'),
        ViewDefinition(name: 'ParticipantInvoices', path: 'invoices'),
        ViewDefinition(name: 'ParticipantShop', path: 'shop'),
        ViewDefinition(name: 'ParticipantAccount', path: 'account'),
        ViewDefinition(name: 'ParticipantRequests', path: 'requests'),
        ViewDefinition(name: 'ParticipantFunds', path: 'funds'),
      ],
    ),
    LayoutDefinition(
      name: 'ProviderLayout',
      path: '/provider',
      children: [
        ViewDefinition(name: 'ProviderDashboard', path: '', initial: true),
        ViewDefinition(name: 'ProviderInbox', path: 'inbox'),
        ViewDefinition(name: 'ProviderBookings', path: 'bookings'),
        ViewDefinition(name: 'ProviderClients', path: 'clients'),
        ViewDefinition(name: 'ProviderJournal', path: 'journal'),
        ViewDefinition(name: 'ProviderProfile', path: 'profile'),
        ViewDefinition(name: 'ProviderInvoices', path: 'invoices'),
        ViewDefinition(name: 'ProviderShop', path: 'shop'),
        ViewDefinition(name: 'ProviderAccount', path: 'account'),
        ViewDefinition(name: 'ProviderRequests', path: 'requests'),
        ViewDefinition(name: 'ProviderFunds', path: 'funds'),
        ViewDefinition(name: 'ProviderTravelBook', path: 'travel-book'),
      ],
    ),
    LayoutDefinition(
      name: 'SupporterLayout',
      path: '/supporter',
      children: [
        ViewDefinition(name: 'SupporterDashboard', path: '', initial: true),
        ViewDefinition(name: 'SupporterParticipants', path: 'participants'),
        ViewDefinition(name: 'SupporterProviders', path: 'providers'),
        ViewDefinition(name: 'SupporterInvoices', path: 'invoices'),
        ViewDefinition(name: 'SupporterMeetings', path: 'meetings'),
        ViewDefinition(name: 'SupporterInbox', path: 'inbox'),
        ViewDefinition(name: 'SupporterFunds', path: 'funds'),
        ViewDefinition(name: 'SupporterRequests', path: 'requests'),
        ViewDefinition(name: 'SupporterJournal', path: 'journal'),
        ViewDefinition(name: 'SupporterPayments', path: 'payments'),
        ViewDefinition(name: 'SupporterTravelBook', path: 'travel-book'),
        ViewDefinition(name: 'SupporterShop', path: 'shop'),
      ],
    ),
    LayoutDefinition(
      name: 'AccountManagerLayout',
      path: '/account-manager',
      children: [
        ViewDefinition(
            name: 'AccountManagerDashboard', path: '', initial: true),
        ViewDefinition(name: 'AccountManagerInbox', path: 'inbox'),
        ViewDefinition(name: 'AccountManagerTeam', path: 'team'),
        ViewDefinition(name: 'AccountManagerBookings', path: 'bookings'),
      ],
    ),
  ];

  // Standalone views (no layout)
  final standaloneViews = <ViewDefinition>[
    ViewDefinition(name: 'Startup', path: '/', initial: true),
    ViewDefinition(name: 'Unknown', path: '/404'),
  ];
}

class LayoutDefinition {
  final String name;
  final String path;
  final List<ViewDefinition> children;

  LayoutDefinition({
    required this.name,
    required this.path,
    required this.children,
  });

  String get snakeCase => _toSnakeCase(name);
  String get viewName => '${name}View';

  String _toSnakeCase(String text) {
    return text
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .substring(1);
  }
}

class ViewDefinition {
  final String name;
  final String path;
  final bool initial;

  ViewDefinition({
    required this.name,
    required this.path,
    this.initial = false,
  });

  String get snakeCase => _toSnakeCase(name);
  String get viewName => '${name}View';
  String get viewModelName => '${name}ViewModel';

  String _toSnakeCase(String text) {
    return text
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .substring(1);
  }
}

class ViewGenerator {
  final String baseDir = 'lib/ui';
  final String testDir = 'test/viewmodels';

  Future<void> generateAll(RouteStructure routes) async {
    int totalFiles = 0;

    // Generate standalone views
    stdout.writeln('📄 Generating standalone views...\n');
    for (final view in routes.standaloneViews) {
      final count = await generateView(view);
      totalFiles += count;
    }

    // Generate layouts and their children
    stdout.writeln('\n📦 Generating layouts and nested views...\n');
    for (final layout in routes.layouts) {
      // Generate layout
      final layoutCount = await generateLayout(layout);
      totalFiles += layoutCount;

      // Generate child views
      for (final child in layout.children) {
        final childCount = await generateView(child);
        totalFiles += childCount;
      }
    }

    stdout.writeln('\n📊 Summary: Generated $totalFiles files');
  }

  Future<int> generateLayout(LayoutDefinition layout) async {
    final dir = '$baseDir/layouts/${layout.snakeCase}';
    await Directory(dir).create(recursive: true);

    int filesCreated = 0;

    // Generate base layout view
    final baseFile = File('$dir/${layout.snakeCase}_view.dart');
    if (!await baseFile.exists()) {
      await baseFile.writeAsString(_layoutBaseTemplate(layout));
      stdout.writeln('✓ Created ${baseFile.path}');
      filesCreated++;
    }

    // Generate mobile layout
    final mobileFile = File('$dir/${layout.snakeCase}_view.mobile.dart');
    if (!await mobileFile.exists()) {
      await mobileFile.writeAsString(_layoutPlatformTemplate(layout, 'mobile'));
      stdout.writeln('✓ Created ${mobileFile.path}');
      filesCreated++;
    }

    // Generate tablet layout
    final tabletFile = File('$dir/${layout.snakeCase}_view.tablet.dart');
    if (!await tabletFile.exists()) {
      await tabletFile.writeAsString(_layoutPlatformTemplate(layout, 'tablet'));
      stdout.writeln('✓ Created ${tabletFile.path}');
      filesCreated++;
    }

    // Generate desktop layout
    final desktopFile = File('$dir/${layout.snakeCase}_view.desktop.dart');
    if (!await desktopFile.exists()) {
      await desktopFile
          .writeAsString(_layoutPlatformTemplate(layout, 'desktop'));
      stdout.writeln('✓ Created ${desktopFile.path}');
      filesCreated++;
    }

    // Generate viewmodel
    final viewModelFile = File('$dir/${layout.snakeCase}_viewmodel.dart');
    if (!await viewModelFile.exists()) {
      await viewModelFile.writeAsString(_layoutViewModelTemplate(layout));
      stdout.writeln('✓ Created ${viewModelFile.path}');
      filesCreated++;
    }

    // Generate test
    final testFile = File('$testDir/${layout.snakeCase}_viewmodel_test.dart');
    await Directory(testDir).create(recursive: true);
    if (!await testFile.exists()) {
      await testFile.writeAsString(_viewModelTestTemplate(layout.name));
      stdout.writeln('✓ Created ${testFile.path}');
      filesCreated++;
    }

    return filesCreated;
  }

  Future<int> generateView(ViewDefinition view) async {
    final dir = '$baseDir/views/${view.snakeCase}';
    await Directory(dir).create(recursive: true);

    int filesCreated = 0;

    // Generate base view
    final baseFile = File('$dir/${view.snakeCase}_view.dart');
    if (!await baseFile.exists()) {
      await baseFile.writeAsString(_viewBaseTemplate(view));
      stdout.writeln('✓ Created ${baseFile.path}');
      filesCreated++;
    }

    // Generate mobile view
    final mobileFile = File('$dir/${view.snakeCase}_view.mobile.dart');
    if (!await mobileFile.exists()) {
      await mobileFile.writeAsString(_viewPlatformTemplate(view, 'mobile'));
      stdout.writeln('✓ Created ${mobileFile.path}');
      filesCreated++;
    }

    // Generate tablet view
    final tabletFile = File('$dir/${view.snakeCase}_view.tablet.dart');
    if (!await tabletFile.exists()) {
      await tabletFile.writeAsString(_viewPlatformTemplate(view, 'tablet'));
      stdout.writeln('✓ Created ${tabletFile.path}');
      filesCreated++;
    }

    // Generate desktop view
    final desktopFile = File('$dir/${view.snakeCase}_view.desktop.dart');
    if (!await desktopFile.exists()) {
      await desktopFile.writeAsString(_viewPlatformTemplate(view, 'desktop'));
      stdout.writeln('✓ Created ${desktopFile.path}');
      filesCreated++;
    }

    // Generate viewmodel
    final viewModelFile = File('$dir/${view.snakeCase}_viewmodel.dart');
    if (!await viewModelFile.exists()) {
      await viewModelFile.writeAsString(_viewModelTemplate(view));
      stdout.writeln('✓ Created ${viewModelFile.path}');
      filesCreated++;
    }

    // Generate test
    final testFile = File('$testDir/${view.snakeCase}_viewmodel_test.dart');
    await Directory(testDir).create(recursive: true);
    if (!await testFile.exists()) {
      await testFile.writeAsString(_viewModelTestTemplate(view.name));
      stdout.writeln('✓ Created ${testFile.path}');
      filesCreated++;
    }

    return filesCreated;
  }

  // Template: Layout Base View
  String _layoutBaseTemplate(LayoutDefinition layout) {
    return '''import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
import '${layout.snakeCase}_view.desktop.dart';
import '${layout.snakeCase}_view.tablet.dart';
import '${layout.snakeCase}_view.mobile.dart';
import '${layout.snakeCase}_viewmodel.dart';

class ${layout.viewName} extends StackedView<${layout.name}ViewModel> {
  const ${layout.viewName}({super.key});

  @override
  Widget builder(
    BuildContext context,
    ${layout.name}ViewModel viewModel,
    Widget? child,
  ) {
    return ScreenTypeLayout.builder(
      mobile: (_) => const ${layout.viewName}Mobile(),
      tablet: (_) => const ${layout.viewName}Tablet(),
      desktop: (_) => const ${layout.viewName}Desktop(),
    );
  }

  @override
  ${layout.name}ViewModel viewModelBuilder(BuildContext context) =>
      ${layout.name}ViewModel();
}
''';
  }

  // Template: Layout Platform-Specific View
  String _layoutPlatformTemplate(LayoutDefinition layout, String platform) {
    final className =
        '${layout.viewName}${platform[0].toUpperCase()}${platform.substring(1)}';
    return '''import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import '${layout.snakeCase}_viewmodel.dart';

class $className extends ViewModelWidget<${layout.name}ViewModel> {
  const $className({super.key});

  @override
  Widget build(BuildContext context, ${layout.name}ViewModel viewModel) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${layout.name} - ${platform.toUpperCase()}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('This is a layout view with nested routing'),
              const SizedBox(height: 32),
              // Nested router outlet
              const Expanded(
                child: RouterView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';
  }

  // Template: Layout ViewModel
  String _layoutViewModelTemplate(LayoutDefinition layout) {
    return '''import 'package:stacked/stacked.dart';

class ${layout.name}ViewModel extends BaseViewModel {
  static const String widgetId = '${layout.snakeCase}_view';

  ${layout.name}ViewModel() {
    initialize();
  }

  void initialize() {
    // Initialize layout-specific logic
  }

  @override
  void dispose() {
    super.dispose();
  }
}
''';
  }

  // Template: View Base
  String _viewBaseTemplate(ViewDefinition view) {
    return '''import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
import '${view.snakeCase}_view.desktop.dart';
import '${view.snakeCase}_view.tablet.dart';
import '${view.snakeCase}_view.mobile.dart';
import '${view.snakeCase}_viewmodel.dart';

class ${view.viewName} extends StackedView<${view.viewModelName}> {
  const ${view.viewName}({super.key});

  @override
  Widget builder(
    BuildContext context,
    ${view.viewModelName} viewModel,
    Widget? child,
  ) {
    return ScreenTypeLayout.builder(
      mobile: (_) => const ${view.viewName}Mobile(),
      tablet: (_) => const ${view.viewName}Tablet(),
      desktop: (_) => const ${view.viewName}Desktop(),
    );
  }

  @override
  ${view.viewModelName} viewModelBuilder(BuildContext context) =>
      ${view.viewModelName}();
}
''';
  }

  // Template: View Platform-Specific
  String _viewPlatformTemplate(ViewDefinition view, String platform) {
    final className =
        '${view.viewName}${platform[0].toUpperCase()}${platform.substring(1)}';
    return '''import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '${view.snakeCase}_viewmodel.dart';

class $className extends ViewModelWidget<${view.viewModelName}> {
  const $className({super.key});

  @override
  Widget build(BuildContext context, ${view.viewModelName} viewModel) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${view.name} - ${platform.toUpperCase()}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to the ${view.name} view',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              // Add your UI components here using shadcn_ui
              ShadButton(
                onPressed: viewModel.isBusy ? null : () {},
                child: viewModel.isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Example Button'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';
  }

  // Template: ViewModel
  String _viewModelTemplate(ViewDefinition view) {
    return '''import 'package:stacked/stacked.dart';
import 'package:kinly/app/app.locator.dart';

class ${view.viewModelName} extends BaseViewModel {
  static const String widgetId = '${view.snakeCase}_view';

  ${view.viewModelName}() {
    initialize();
  }

  void initialize() {
    // Initialize view-specific logic
    // Load data, set up listeners, etc.
  }

  @override
  void dispose() {
    super.dispose();
  }
}
''';
  }

  // Template: ViewModel Test
  String _viewModelTestTemplate(String viewName) {
    final viewModelName = '${viewName}ViewModel';
    final snakeCase = _toSnakeCase(viewName);

    return '''import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:kinly/app/app.locator.dart';
import 'package:kinly/ui/views/$snakeCase/${snakeCase}_viewmodel.dart';

// Import your mocks here
// import '../../helpers/test_helpers.dart';

void main() {
  group('$viewModelName Tests -', () {
    setUp(() {
      // Register services before each test
      // registerServices();
    });

    tearDown(() {
      // Clean up after each test
      // locator.reset();
    });

    test('ViewModel should initialize correctly', () {
      final viewModel = $viewModelName();
      expect(viewModel, isNotNull);
    });

    // Add more tests here
    test('ViewModel should not be busy initially', () {
      final viewModel = $viewModelName();
      expect(viewModel.isBusy, false);
    });
  });
}
''';
  }

  String _toSnakeCase(String text) {
    return text
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .substring(1);
  }
}
