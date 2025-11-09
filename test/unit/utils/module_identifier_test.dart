import 'package:test/test.dart';
import 'package:test_reporter/src/utils/module_identifier.dart';

void main() {
  group('ModuleIdentifier.extractModuleName', () {
    test('should extract from test folder path', () {
      expect(
        ModuleIdentifier.extractModuleName('test/auth/'),
        equals('auth'),
      );
    });

    test('should extract from source folder path', () {
      expect(
        ModuleIdentifier.extractModuleName('lib/src/auth/'),
        equals('auth'),
      );
    });

    test('should extract from nested path', () {
      expect(
        ModuleIdentifier.extractModuleName('test/auth_service/'),
        equals('auth_service'),
      );
    });

    test('should strip _test.dart suffix from files', () {
      expect(
        ModuleIdentifier.extractModuleName('test/auth_test.dart'),
        equals('auth'),
      );
    });

    test('should strip .dart suffix from source files', () {
      expect(
        ModuleIdentifier.extractModuleName('lib/src/auth_service.dart'),
        equals('auth_service'),
      );
    });

    test('should handle special case: test root', () {
      expect(
        ModuleIdentifier.extractModuleName('test/'),
        equals('all_tests'),
      );
    });

    test('should handle special case: lib root', () {
      expect(
        ModuleIdentifier.extractModuleName('lib/'),
        equals('all_sources'),
      );
    });

    test('should handle integration directory', () {
      expect(
        ModuleIdentifier.extractModuleName('test/integration/'),
        equals('integration'),
      );
    });

    test('should handle unit directory', () {
      expect(
        ModuleIdentifier.extractModuleName('test/unit/'),
        equals('unit'),
      );
    });

    test('should preserve underscores in path', () {
      expect(
        ModuleIdentifier.extractModuleName('test/auth_service/'),
        equals('auth_service'),
      );
    });

    test('should preserve hyphens in path', () {
      expect(
        ModuleIdentifier.extractModuleName('test/auth-service/'),
        equals('auth-service'),
      );
    });

    test('should handle lib/src/ vs lib/ paths', () {
      expect(
        ModuleIdentifier.extractModuleName('lib/auth/'),
        equals('auth'),
      );
    });
  });

  group('ModuleIdentifier.generateQualifiedName', () {
    test('should add -fo suffix for folders', () {
      expect(
        ModuleIdentifier.generateQualifiedName('auth', PathType.folder),
        equals('auth-fo'),
      );
    });

    test('should add -fi suffix for files', () {
      expect(
        ModuleIdentifier.generateQualifiedName('auth_test', PathType.file),
        equals('auth-test-fi'),
      );
    });

    test('should replace underscores with hyphens', () {
      expect(
        ModuleIdentifier.generateQualifiedName('auth_service', PathType.folder),
        equals('auth-service-fo'),
      );
    });

    test('should add -pr suffix for project', () {
      expect(
        ModuleIdentifier.generateQualifiedName('all_tests', PathType.project),
        equals('all-tests-pr'),
      );
    });

    test('should convert to lowercase', () {
      expect(
        ModuleIdentifier.generateQualifiedName('AuthService', PathType.folder),
        equals('authservice-fo'),
      );
    });

    test('should preserve existing hyphens', () {
      expect(
        ModuleIdentifier.generateQualifiedName('auth-service', PathType.folder),
        equals('auth-service-fo'),
      );
    });

    test('should handle empty name', () {
      expect(
        () => ModuleIdentifier.generateQualifiedName('', PathType.folder),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle very long names', () {
      final longName = 'a' * 100;
      expect(
        ModuleIdentifier.generateQualifiedName(longName, PathType.folder),
        equals('$longName-fo'),
      );
    });
  });

  group('ModuleIdentifier.getQualifiedModuleName', () {
    test('should generate qualified name from test folder', () {
      expect(
        ModuleIdentifier.getQualifiedModuleName('test/auth/'),
        equals('auth-fo'),
      );
    });

    test('should generate qualified name from source file', () {
      expect(
        ModuleIdentifier.getQualifiedModuleName('lib/src/auth_service.dart'),
        equals('auth-service-fi'),
      );
    });

    test('should handle test root', () {
      expect(
        ModuleIdentifier.getQualifiedModuleName('test/'),
        equals('all-tests-pr'),
      );
    });

    test('should handle lib root', () {
      expect(
        ModuleIdentifier.getQualifiedModuleName('lib/'),
        equals('all-sources-pr'),
      );
    });

    test('should detect file vs folder correctly', () {
      // File
      expect(
        ModuleIdentifier.getQualifiedModuleName('test/auth_test.dart'),
        equals('auth-fi'),
      );

      // Folder
      expect(
        ModuleIdentifier.getQualifiedModuleName('test/auth/'),
        equals('auth-fo'),
      );
    });
  });

  group('ModuleIdentifier.parseQualifiedName', () {
    test('should parse folder qualified name', () {
      final result = ModuleIdentifier.parseQualifiedName('auth-service-fo');

      expect(result, isNotNull);
      expect(result!.baseName, equals('auth-service'));
      expect(result.type, equals(PathType.folder));
    });

    test('should parse file qualified name', () {
      final result = ModuleIdentifier.parseQualifiedName('auth-test-fi');

      expect(result, isNotNull);
      expect(result!.baseName, equals('auth-test'));
      expect(result.type, equals(PathType.file));
    });

    test('should parse project qualified name', () {
      final result = ModuleIdentifier.parseQualifiedName('all-tests-pr');

      expect(result, isNotNull);
      expect(result!.baseName, equals('all-tests'));
      expect(result.type, equals(PathType.project));
    });

    test('should return null for invalid format', () {
      expect(
        ModuleIdentifier.parseQualifiedName('invalid'),
        isNull,
      );
    });

    test('should return null for missing suffix', () {
      expect(
        ModuleIdentifier.parseQualifiedName('auth-service'),
        isNull,
      );
    });

    test('should return null for unknown suffix', () {
      expect(
        ModuleIdentifier.parseQualifiedName('auth-xx'),
        isNull,
      );
    });

    test('should return null for empty string', () {
      expect(
        ModuleIdentifier.parseQualifiedName(''),
        isNull,
      );
    });
  });

  group('ModuleIdentifier.isValidModuleName', () {
    test('should validate correct name', () {
      expect(
        ModuleIdentifier.isValidModuleName('auth-service-fo'),
        isTrue,
      );
    });

    test('should reject invalid characters', () {
      expect(
        ModuleIdentifier.isValidModuleName('auth@service-fo'),
        isFalse,
      );
    });

    test('should reject empty name', () {
      expect(
        ModuleIdentifier.isValidModuleName(''),
        isFalse,
      );
    });

    test('should reject too long name', () {
      final longName = 'a' * 200;
      expect(
        ModuleIdentifier.isValidModuleName(longName),
        isFalse,
      );
    });

    test('should reject just hyphens', () {
      expect(
        ModuleIdentifier.isValidModuleName('---'),
        isFalse,
      );
    });
  });

  group('ModuleIdentifier.qualifyManualModuleName', () {
    test('should qualify unqualified folder module name', () {
      expect(
        ModuleIdentifier.qualifyManualModuleName('utils', 'lib/src/utils/'),
        equals('utils-fo'),
      );
    });

    test('should qualify unqualified file module name', () {
      expect(
        ModuleIdentifier.qualifyManualModuleName(
            'report_utils', 'lib/src/utils/report_utils.dart'),
        equals('report-utils-fi'),
      );
    });

    test('should qualify unqualified project module name', () {
      expect(
        ModuleIdentifier.qualifyManualModuleName('test-suite', 'test/'),
        equals('test-suite-pr'),
      );
    });

    test('should keep already qualified folder name', () {
      expect(
        ModuleIdentifier.qualifyManualModuleName('utils-fo', 'lib/src/utils/'),
        equals('utils-fo'),
      );
    });

    test('should keep already qualified file name', () {
      expect(
        ModuleIdentifier.qualifyManualModuleName(
            'report-utils-fi', 'lib/src/utils/report_utils.dart'),
        equals('report-utils-fi'),
      );
    });

    test('should validate and keep qualified project name', () {
      expect(
        ModuleIdentifier.qualifyManualModuleName('all-tests-pr', 'test/'),
        equals('all-tests-pr'),
      );
    });

    test('should throw on mismatched type (folder name for file path)', () {
      expect(
        () => ModuleIdentifier.qualifyManualModuleName(
            'report-utils-fo', 'lib/src/utils/report_utils.dart'),
        throwsArgumentError,
      );
    });

    test('should throw on mismatched type (file name for folder path)', () {
      expect(
        () => ModuleIdentifier.qualifyManualModuleName(
            'utils-fi', 'lib/src/utils/'),
        throwsArgumentError,
      );
    });

    test('should handle underscores in module name', () {
      expect(
        ModuleIdentifier.qualifyManualModuleName(
            'report_utils', 'lib/src/utils/'),
        equals('report-utils-fo'),
      );
    });
  });
}
