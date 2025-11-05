/// Comprehensive Flutter/Dart test reporting toolkit
///
/// Provides utilities for:
/// - Coverage analysis with branch coverage support
/// - Flaky test detection
/// - Performance profiling
/// - Failed test extraction
/// - Unified reporting
library test_reporter;

// Export modern models with sealed classes and records
export 'src/models/failure_types.dart';
export 'src/models/result_types.dart';
export 'src/utils/constants.dart';
export 'src/utils/extensions.dart';

// Export utilities
export 'src/utils/formatting_utils.dart';
export 'src/utils/path_utils.dart';
export 'src/utils/report_utils.dart';

// Export v3.0 utilities (PathResolver, ModuleIdentifier, ReportManager, ReportRegistry)
export 'src/utils/module_identifier.dart';
export 'src/utils/path_resolver.dart';
export 'src/utils/report_manager.dart';
export 'src/utils/report_registry.dart';

// Export services (when created)
// export 'src/services/coverage_service.dart';
