# .agent/ Documentation System

This directory contains comprehensive documentation for AI-assisted development in the test_reporter project.

**Last Updated**: November 2025

---

## 📖 Quick Navigation

### For First-Time Contributors
1. **🔴🟢♻️ MUST READ**: [`knowledge/tdd_methodology.md`](knowledge/tdd_methodology.md) - TDD is mandatory!
2. Start with [`knowledge/full_codebase.md`](knowledge/full_codebase.md) for project overview
3. Read [`knowledge/analyzer_architecture.md`](knowledge/analyzer_architecture.md) to understand core structure
4. Check relevant SOPs in [`guides/`](guides/) before implementing features (all include TDD steps)

### For Specific Tasks
- **🔴🟢♻️ TDD Workflow** → [`knowledge/tdd_methodology.md`](knowledge/tdd_methodology.md) ⭐ READ FIRST
- **Adding failure patterns** → [`guides/01_adding_failure_pattern.md`](guides/01_adding_failure_pattern.md)
- **Creating new analyzer** → [`guides/02_adding_new_analyzer.md`](guides/02_adding_new_analyzer.md)
- **Extending reports** → [`guides/03_adding_report_type.md`](guides/03_adding_report_type.md)
- **Publishing release** → [`guides/04_publishing_release.md`](guides/04_publishing_release.md)
- **Understanding modern Dart** → [`knowledge/modern_dart_features.md`](knowledge/modern_dart_features.md)

---

## 🆕 v3.0 Foundation Utilities

**New in v3.0**: Four centralized utilities power all tools with consistent behavior.

### PathResolver (`lib/src/utils/path_resolver.dart`)
**Purpose**: Automatic bidirectional path inference (test ↔ source)

**Key Methods**:
- `inferSourcePath(String testPath)` - Infer source path from test path
- `inferTestPath(String sourcePath)` - Infer test path from source path
- `resolvePaths(String inputPath)` - Smart resolution with validation
- `validatePaths(String testPath, String sourcePath)` - Existence checks

**When to use**: Whenever you need to map between test and source paths

### ModuleIdentifier (`lib/src/utils/module_identifier.dart`)
**Purpose**: Consistent qualified module naming

**Key Methods**:
- `extractModuleName(String path)` - Extract base module name from path
- `getQualifiedModuleName(String path)` - Get qualified name with suffix (`module-fo/fi/pr`)
- `parseQualifiedName(String qualified)` - Parse back to components
- `isValidModuleName(String name)` - Validate module name format

**Qualifiers**:
- `-fo`: Folder analysis
- `-fi`: File analysis
- `-pr`: Project-wide analysis

**When to use**: When generating or parsing module names for reports

### ReportManager (`lib/src/utils/report_manager.dart`)
**Purpose**: Unified report generation with automatic cleanup

**Key Methods**:
- `startReport(...)` - Create ReportContext for new report
- `writeReport(...)` - Write markdown + JSON atomically, auto-cleanup
- `findLatestReport(...)` - Query reports by criteria
- `cleanupReports(...)` - Manual cleanup with keep count
- `extractJsonFromReport(String markdownPath)` - Parse embedded JSON

**When to use**: All report generation and management operations

### ReportRegistry (`lib/src/utils/report_registry.dart`)
**Purpose**: Cross-tool report discovery and tracking

**Key Methods**:
- `register(...)` - Register a generated report
- `getReports(...)` - Query reports with filters
- `printSummary()` - Display all registered reports
- `clear()` - Clear the registry

**When to use**: When you need to track or query reports across multiple tool runs

---

## 📂 Directory Structure

```
.agent/
├── README.md                            # This file - documentation index
├── knowledge/                            # Project context files (6 files)
│   ├── full_codebase.md                # Complete project overview
│   ├── analyzer_architecture.md        # How the 4 analyzers work
│   ├── report_system.md                # Report generation patterns
│   ├── failure_patterns.md             # Failure type system
│   ├── modern_dart_features.md         # Sealed classes & records
│   └── tdd_methodology.md              # 🔴🟢♻️ Red-green-refactor cycle (MANDATORY)
├── guides/                             # Standard Operating Procedures (7 SOPs)
│   ├── 01_adding_failure_pattern.md
│   ├── 02_adding_new_analyzer.md
│   ├── 03_adding_report_type.md
│   ├── 04_publishing_release.md
│   ├── 05_extending_record_types.md
│   ├── 06_debugging_analyzer.md
│   └── 07_self_testing.md
├── templates/                           # Code templates (4 templates)
│   ├── analyzer_template.dart
│   ├── failure_type_template.dart
│   ├── record_type_template.dart
│   └── report_format_template.md
├── plans/                               # Implementation plans
│   ├── v3-re-engineering-plan.md
│   └── v3-implementation-tracker.md
└── archives/                            # Conversation archives
    └── conversations/                   # Archived AI conversations
```

---

## 📋 Context Files

### [`knowledge/full_codebase.md`](knowledge/full_codebase.md)
**When to use**: First-time exploration, major refactoring, architecture decisions

**Contains**:
- Complete file listing with line counts
- Class hierarchy and relationships
- Package dependencies
- Key statistics

**Token estimate**: ~15-20K tokens

---

### [`knowledge/analyzer_architecture.md`](knowledge/analyzer_architecture.md)
**When to use**: Understanding analyzer design, adding features to existing analyzers

**Contains**:
- Entry point pattern (bin/ vs lib/src/)
- How each of the 4 analyzers work
- Shared utilities and their roles
- CLI argument parsing patterns

**Token estimate**: ~10-15K tokens

---

### [`knowledge/report_system.md`](knowledge/report_system.md)
**When to use**: Modifying report generation, adding new report formats

**Contains**:
- Report directory structure (tests_reports/)
- Naming conventions (-fo/-fi/-pr suffixes)
- ReportManager API and cleanup logic (v3.0+)
- ReportRegistry for cross-tool discovery (v3.0+)
- Markdown + JSON generation patterns

**Token estimate**: ~8-10K tokens

**Note**: v3.0 introduced ReportManager and ReportRegistry. See above section for details.

---

### [`knowledge/failure_patterns.md`](knowledge/failure_patterns.md)
**When to use**: Adding new failure types, improving pattern detection

**Contains**:
- Complete sealed class hierarchy
- Pattern detection regex patterns
- Suggestion generation logic
- When to use each failure type

**Token estimate**: ~8-12K tokens

---

### [`knowledge/modern_dart_features.md`](knowledge/modern_dart_features.md)
**When to use**: Learning modern Dart 3+ patterns, refactoring to use new features

**Contains**:
- Sealed classes explained with examples
- Records usage patterns
- Pattern matching best practices
- When to use each feature

**Token estimate**: ~6-8K tokens

---

### [`knowledge/tdd_methodology.md`](knowledge/tdd_methodology.md) 🔴🟢♻️
**When to use**: ALL development - TDD is MANDATORY for test_reporter

**Contains**:
- Red-Green-Refactor cycle explained
- TDD for sealed classes, analyzers, records
- Meta-testing integration (🔄 phase)
- Quick TDD commands reference
- Common TDD pitfalls to avoid

**Token estimate**: ~15-20K tokens

**CRITICAL**: Read this before starting ANY feature development. All guides include TDD steps.

---

## 🛠️ Standard Operating Procedures (SOPs)

**🔴🟢♻️ Note**: All SOPs follow TDD methodology - tests written FIRST!

### [`guides/01_adding_failure_pattern.md`](guides/01_adding_failure_pattern.md)
**Step-by-step guide to add a new failure type to the sealed class hierarchy**

**Estimated time**: 30-60 minutes
**Token budget**: 40-60K tokens
**Difficulty**: Medium

---

### [`guides/02_adding_new_analyzer.md`](guides/02_adding_new_analyzer.md)
**Complete workflow for creating a new CLI analyzer tool**

**Estimated time**: 3-4 hours
**Token budget**: 120-150K tokens
**Difficulty**: Hard

---

### [`guides/03_adding_report_type.md`](guides/03_adding_report_type.md)
**How to add a new report format or subdirectory**

**Estimated time**: 1-2 hours
**Token budget**: 60-80K tokens
**Difficulty**: Medium

---

### [`guides/04_publishing_release.md`](guides/04_publishing_release.md)
**Comprehensive checklist and workflow for publishing to pub.dev**

**Estimated time**: 1 hour
**Token budget**: 30-40K tokens
**Difficulty**: Easy

---

### [`guides/05_extending_record_types.md`](guides/05_extending_record_types.md)
**When and how to add new record types to result_types.dart**

**Estimated time**: 30 minutes
**Token budget**: 20-30K tokens
**Difficulty**: Easy

---

### [`guides/06_debugging_analyzer.md`](guides/06_debugging_analyzer.md)
**Strategies for debugging failing analyzers**

**Estimated time**: Variable
**Token budget**: 40-80K tokens
**Difficulty**: Medium

---

### [`guides/07_self_testing.md`](guides/07_self_testing.md)
**Meta-testing strategy and fixture generation**

**Estimated time**: 1 hour
**Token budget**: 40-50K tokens
**Difficulty**: Medium

---

## 📝 Templates

### [`templates/analyzer_template.dart`](templates/analyzer_template.dart)
Boilerplate for creating a new analyzer tool with CLI parsing, report generation, and error handling.

### [`templates/failure_type_template.dart`](templates/failure_type_template.dart)
Template for adding a new sealed class case to the failure type hierarchy.

### [`templates/record_type_template.dart`](templates/record_type_template.dart)
Template for adding a new record typedef to result_types.dart.

### [`templates/report_format_template.md`](templates/report_format_template.md)
Standard report structure with sections, formatting, and metadata.

---

## 💡 Usage Guidelines

### Context Management Strategy

**Claude Code has a 200K token limit** - use these files strategically:

#### Small Task (< 2 hours, 50-100K tokens)
- Load only the specific SOP you need
- Skip context files unless necessary

#### Medium Task (2-6 hours, 100-300K tokens)
- Load relevant context file (e.g., `analyzer_architecture.md`)
- Load SOP for the task
- Use `/clear` between sub-tasks

#### Large Task (6+ hours, 300-800K tokens)
- Load `full_codebase.md` at start
- Load specific contexts as needed
- Use `/compact` or `/clear` frequently (every 150K tokens)
- Plan 2-3 compact cycles

### When to Use Each Context File

| Task | Context Files Needed | Estimated Tokens |
|------|---------------------|------------------|
| Add failure pattern | `failure_patterns.md`, `modern_dart_features.md` | 15-20K |
| Create new analyzer | `full_codebase.md`, `analyzer_architecture.md` | 25-35K |
| Modify reports | `report_system.md` | 8-10K |
| Understand codebase | `full_codebase.md`, `analyzer_architecture.md` | 25-35K |
| Debug analyzer | `analyzer_architecture.md`, `failure_patterns.md` | 18-27K |
| Publishing | `04_publishing_release.md` only | 30-40K |

### Token Budget Planning

Before starting any task:

1. **Check current context**: `/context`
2. **Estimate task complexity**:
   - Easy: 20-40K tokens
   - Medium: 40-80K tokens
   - Hard: 80-150K tokens
3. **Load only necessary files**
4. **Plan for `/clear` or `/compact` cycles**

### Best Practices

1. ✅ **Always read the SOP first** before implementing
2. ✅ **Use templates** to maintain consistency
3. ✅ **Test with self-testing** (run tools on themselves)
4. ✅ **Update CHANGELOG.md** for user-facing changes
5. ✅ **Run `dart analyze` and `dart format`** before committing
6. ✅ **Archive conversations** in `archives/conversations/` for future reference

---

## 🗂️ Archiving Conversations

When completing major features or debugging sessions, archive the conversation:

```bash
# Create archive file
touch .agent/archives/conversations/2025-01-04_add-mutation-testing.md

# Add summary of:
# - What was accomplished
# - Key decisions made
# - Challenges encountered
# - Token usage and cycles needed
```

This helps future AI sessions understand:
- Historical context
- Why certain decisions were made
- Common pitfalls to avoid

---

## 🎯 Quick Start Checklist

When starting a new AI session:

- [ ] Run `/context` to check token usage
- [ ] Read this README.md for orientation
- [ ] Identify task type (small/medium/large)
- [ ] Load appropriate context files
- [ ] Load relevant SOP if applicable
- [ ] Estimate token budget
- [ ] Plan `/clear` or `/compact` cycles
- [ ] Begin implementation

---

## 📚 External Resources

- **Main README**: [`../README.md`](../README.md) - User-facing documentation
- **CLAUDE.md**: [`../CLAUDE.md`](../CLAUDE.md) - Quick reference for AI sessions
- **pubspec.yaml**: [`../pubspec.yaml`](../pubspec.yaml) - Package configuration
- **lib/**: Source code directory
- **bin/**: Executable entry points

---

## 🤝 Contributing to Documentation

When adding new documentation:

1. **Context files** → Add to `knowledge/` if it's reusable knowledge
2. **SOPs** → Add to `guides/` if it's a step-by-step procedure
3. **Templates** → Add to `templates/` if it's boilerplate code
4. **Update this README** → Add links and descriptions

Maintain the token estimates to help future sessions plan effectively.

---

**Remember**: This documentation system is designed to maximize productivity while staying within Claude Code's 200K token context window. Use it strategically!
