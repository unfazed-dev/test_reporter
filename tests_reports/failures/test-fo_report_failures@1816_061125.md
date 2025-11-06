# 🔴 Failed Test Report

**Generated:** 2025-11-06 18:16:13.104534
**Test Path:** `/var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test`

## 📊 Summary

| Metric | Value |
|--------|-------|
| Total Tests | 4 |
| Passed | ✅ 1 |
| Failed | ❌ 3 |
| Success Rate | 25.0% |
| Execution Time | 0.000s |

## ❌ Failed Tests

### /var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test/failing_test.dart

#### this test will fail
**Group:** group_2
**Runtime:** 0.247s

#### null error test
**Group:** group_2
**Runtime:** 0.250s

#### another failing test
**Group:** group_2
**Runtime:** 0.253s


## ✅ Failure Triage Workflow

Follow this checklist to systematically fix each failing test:

### File: `/var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test/failing_test.dart`

- [ ] **Fix: this test will fail**
  - [ ] **Step 1: Identify root cause**
  - [ ] **Step 2: Apply fix**
    - Modify test or implementation code
  - [ ] **Step 3: Verify fix**
    - Run: `dart test /var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test/failing_test.dart --name="this test will fail"`

- [ ] **Fix: null error test**
  - [ ] **Step 1: Identify root cause**
  - [ ] **Step 2: Apply fix**
    - Modify test or implementation code
  - [ ] **Step 3: Verify fix**
    - Run: `dart test /var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test/failing_test.dart --name="null error test"`

- [ ] **Fix: another failing test**
  - [ ] **Step 1: Identify root cause**
  - [ ] **Step 2: Apply fix**
    - Modify test or implementation code
  - [ ] **Step 3: Verify fix**
    - Run: `dart test /var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test/failing_test.dart --name="another failing test"`

**Progress:** 0 of 3 failures triaged (0.0%)

### 🚀 Quick Commands

```bash
# Rerun all failed tests
dart test /var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test/failing_test.dart
```



---

## 📊 Machine-Readable Data

The following JSON contains all report data in machine-parseable format:

```json
{
  "metadata": {
    "tool": "failed_test_extractor",
    "version": "2.0",
    "generated": "2025-11-06T18:16:13.104534",
    "test_path": "/var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test"
  },
  "summary": {
    "totalTests": 4,
    "passedTests": 1,
    "failedTests": 3,
    "successRate": 25.0,
    "executionTime": 0
  },
  "failedTests": [
    {
      "name": "this test will fail",
      "filePath": "/var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test/failing_test.dart",
      "group": "group_2",
      "error": null,
      "stackTrace": null,
      "runtime": 247,
      "testId": "3"
    },
    {
      "name": "null error test",
      "filePath": "/var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test/failing_test.dart",
      "group": "group_2",
      "error": null,
      "stackTrace": null,
      "runtime": 250,
      "testId": "4"
    },
    {
      "name": "another failing test",
      "filePath": "/var/folders/z_/vsddl0v124771l0kwkndsptw0000gn/T/failure_test_HO9u9e/test/failing_test.dart",
      "group": "group_2",
      "error": null,
      "stackTrace": null,
      "runtime": 253,
      "testId": "5"
    }
  ]
}
```
