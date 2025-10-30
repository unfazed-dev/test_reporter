# 🔴 Failed Test Report

**Generated:** 2025-10-30 09:54:12.128874
**Test Path:** `test/bin`
**Source:** Test Analyzer
**Analysis Runs:** 3

## 📊 Summary

| Metric | Value |
|--------|-------|
| Total Tests | 161 |
| Passed Consistently | 160 |
| Consistent Failures | ❌ 1 |
| Flaky Tests | ⚠️ 0 |
| Pass Rate | 99.4% |

## ❌ Consistent Failures
*Tests that failed all 3 runs*

### test_1
**File:** `1`
**Type:** unknown
**Category:** Unknown Error

**Suggested Fix:**
```
Review test setup/teardown and verify all dependencies are properly initialized
```

## 💡 Recommendations

1. **🔴 Critical:** Fix 1 consistently failing tests immediately

For detailed analysis and stack traces, see the full analyzer report.

---

## 📊 Machine-Readable Data

The following JSON contains all report data in machine-parseable format:

```json
{
  "metadata": {
    "tool": "test_analyzer",
    "version": "2.0",
    "generated": "2025-10-30T09:54:12.129051",
    "test_path": "test/bin",
    "analysis_runs": 3
  },
  "summary": {
    "total_tests": 161,
    "passed_consistently": 160,
    "consistent_failures": 1,
    "flaky_tests": 0,
    "pass_rate": 99.37888198757764,
    "stability_score": 99.37888198757764,
    "health_status": "Excellent"
  },
  "consistent_failures": [
    {
      "test_id": "1::test_1",
      "file": "1",
      "test_name": "test_1",
      "failure_type": "unknown",
      "category": "Unknown Error",
      "suggestion": "Review test setup/teardown and verify all dependencies are properly initialized"
    }
  ],
  "flaky_tests": []
}
```
