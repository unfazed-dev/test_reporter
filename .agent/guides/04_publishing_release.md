# SOP: Publishing Release

**Estimated Time**: 1 hour
**Token Budget**: 30-40K tokens
**Difficulty**: Easy

---

## Overview

Complete workflow for publishing a new version of test_reporter to pub.dev.

---

## Pre-Release Checklist

- [ ] All features complete and tested
- [ ] No known critical bugs
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version number decided (major.minor.patch)

---

## Step 1: Update Version Number

**File**: `pubspec.yaml`

```yaml
name: test_reporter
version: 2.1.0  # ← Update this
```

**Semantic Versioning**:
- **Major** (X.0.0): Breaking changes
- **Minor** (2.X.0): New features, backwards compatible
- **Patch** (2.1.X): Bug fixes, backwards compatible

---

## Step 2: Update CHANGELOG.md

**File**: `CHANGELOG.md`

Add entry for new version:

```markdown
## 2.1.0 - 2025-01-05

### Added
- Dependency analyzer tool for test dependency graphs
- XML report format support
- Circular dependency detection

### Fixed
- Report cleanup now handles all formats correctly
- Null safety improvements in pattern detection

### Changed
- Improved performance for parallel test execution
- Better error messages in failure suggestions
```

**Format**:
- **Added**: New features
- **Fixed**: Bug fixes
- **Changed**: Changes to existing features
- **Deprecated**: Features marked for removal
- **Removed**: Removed features
- **Security**: Security fixes

---

## Step 3: Run Quality Checks

### 3.1 Analyze Code

```bash
dart analyze

# Expected output: No issues found!
```

Fix any issues before continuing.

### 3.2 Format Code

```bash
# Check formatting
dart format --set-exit-if-changed .

# If changes needed:
dart format .
```

### 3.3 Self-Test All Tools

```bash
# Test each executable
dart run test_reporter:analyze_tests bin/ --runs=3
dart run test_reporter:analyze_coverage lib/src
dart run test_reporter:extract_failures test/ --list-only
dart run test_reporter:analyze_suite bin/

# All should complete without errors
```

---

## Step 4: Dry Run Publication

```bash
dart pub publish --dry-run
```

**Check for**:
- ✅ No errors
- ✅ Package size reasonable (< 100MB)
- ✅ All necessary files included
- ✅ LICENSE file present
- ✅ README.md present
- ✅ No sensitive files (credentials, .env, etc.)

**Review warnings** and fix if needed.

---

## Step 5: Commit Version Changes

```bash
git add pubspec.yaml
git add CHANGELOG.md

git commit -m "chore: bump version to 2.1.0"
```

---

## Step 6: Create Git Tag

```bash
git tag v2.1.0
git push origin main
git push origin v2.1.0
```

---

## Step 7: Publish to pub.dev

```bash
dart pub publish
```

**Interactive prompts**:
1. Review package contents
2. Confirm publication
3. Authenticate (if needed)

**Authentication**:
- First time: Follow OAuth flow
- Subsequent: Uses saved credentials

**Expected output**:
```
Publishing test_reporter 2.1.0 to https://pub.dev:
Package has 0 warnings.
Uploading...
Successfully uploaded package.
```

---

## Step 8: Verify Publication

### 8.1 Check pub.dev

Visit https://pub.dev/packages/test_reporter

Verify:
- ✅ New version appears
- ✅ README renders correctly
- ✅ CHANGELOG visible
- ✅ Example code works
- ✅ Dependencies listed correctly

### 8.2 Check Package Score

Wait ~10 minutes for scoring, then check:
- **Popularity**: Based on downloads
- **Likes**: User likes
- **Pub Points**: Max 140 points

**Scoring criteria**:
- Follow Dart conventions: 30 pts
- Documentation: 10 pts
- Null safety: 20 pts
- Platform support: 20 pts
- Pass static analysis: 50 pts
- Support latest SDKs: 10 pts

### 8.3 Test Installation

```bash
# Global activation
dart pub global activate test_reporter

# Verify version
analyze_tests --help
```

---

## Step 9: Create GitHub Release

### 9.1 Go to Releases

https://github.com/unfazed-dev/test_reporter/releases

### 9.2 Create New Release

- **Tag**: Select `v2.1.0`
- **Title**: `v2.1.0 - Dependency Analysis`
- **Description**: Copy from CHANGELOG.md

```markdown
## Added
- Dependency analyzer tool for test dependency graphs
- XML report format support
- Circular dependency detection

## Fixed
- Report cleanup now handles all formats correctly
- Null safety improvements in pattern detection

## Changed
- Improved performance for parallel test execution
- Better error messages in failure suggestions

## Installation

\`\`\`bash
dart pub global activate test_reporter
\`\`\`

See [README](https://github.com/unfazed-dev/test_reporter#readme) for usage.
```

### 9.3 Publish Release

Click "Publish release"

---

## Step 10: Announce (Optional)

- Twitter/X
- Flutter/Dart Discord
- Reddit (r/FlutterDev)
- Dev.to article

---

## Rollback Procedure (If Needed)

### If published with critical bug:

```bash
# Mark version as discontinued on pub.dev
dart pub discontinue 2.1.0

# Publish fixed version
# 1. Update to 2.1.1
# 2. Fix bug
# 3. Follow publishing steps again
```

**Note**: Cannot delete published versions, only mark as discontinued.

---

## Troubleshooting

### "Package validation failed"

**Fix**: Run `dart pub publish --dry-run` and fix all errors

### "Authentication failed"

**Fix**: Run `dart pub logout` then `dart pub publish` to re-authenticate

### "Version already exists"

**Fix**: You cannot publish the same version twice. Increment version number.

### "Package too large"

**Fix**: Check `.gitignore` and `pubspec.yaml` excludes. Remove unnecessary files.

---

## Post-Release Checklist

- [ ] Version published to pub.dev
- [ ] Appears on pub.dev with correct info
- [ ] GitHub release created
- [ ] Git tag pushed
- [ ] Package score acceptable (>100)
- [ ] Installation tested
- [ ] Announcement posted (optional)

---

## Version Strategy

**Rapid fixes**: 2.1.1, 2.1.2 (patches)
**Monthly features**: 2.2.0, 2.3.0 (minor)
**Major changes**: 3.0.0 (major)

**Example timeline**:
- Week 1: Development
- Week 2: Testing & fixes
- Week 3: Documentation
- Week 4: Release

---

**Token usage**: ~30-40K tokens
**Next steps**: Monitor issue tracker for bug reports
