#!/usr/bin/env python3
"""
Check Coverage Progress
Compares current coverage against target and shows progress
"""

import re
from pathlib import Path
from datetime import datetime

BASE_DIR = Path("/Users/unfazed-mac/Developer/packages/test_analyzer")
REPORT_DIR = BASE_DIR / "test_analyzer_reports" / "code_coverage"

# Target coverage goal
TARGET_COVERAGE = 95.0


def read_all_reports():
    """Read all coverage reports chronologically"""
    reports = sorted(REPORT_DIR.glob("bin-fo_test_report_coverage@*.md"))
    return reports


def extract_coverage_from_report(report_path):
    """Extract coverage percentage from a report"""
    content = report_path.read_text()

    # Find "Overall Coverage" line
    match = re.search(r'\*\*Overall Coverage\*\*\s+\|\s+\*\*([0-9.]+)%\*\*', content)
    if match:
        return float(match.group(1))

    return None


def extract_timestamp_from_filename(filename):
    """Extract timestamp from report filename"""
    # Format: bin-fo_test_report_coverage@HHMM_DDMMYY.md
    match = re.search(r'@(\d{4})_(\d{6})', filename)
    if match:
        time_str = match.group(1)  # HHMM
        date_str = match.group(2)  # DDMMYY

        hour = int(time_str[:2])
        minute = int(time_str[2:])
        day = int(date_str[:2])
        month = int(date_str[2:4])
        year = 2000 + int(date_str[4:])

        return datetime(year, month, day, hour, minute)

    return None


def calculate_progress(current, start, target):
    """Calculate progress percentage"""
    if target <= start:
        return 100.0

    progress = ((current - start) / (target - start)) * 100
    return min(100.0, max(0.0, progress))


def estimate_remaining_tests(current_coverage, current_tests, target_coverage):
    """Estimate how many more tests needed"""
    if current_coverage >= target_coverage:
        return 0

    # Rough estimate: assume linear relationship
    coverage_per_test = current_coverage / current_tests if current_tests > 0 else 0.1
    remaining_coverage = target_coverage - current_coverage

    if coverage_per_test > 0:
        return int(remaining_coverage / coverage_per_test)
    else:
        return 360  # Default estimate


def main():
    print("📊 Coverage Progress Tracker")
    print("=" * 70)

    reports = read_all_reports()

    if not reports:
        print("❌ No coverage reports found!")
        return

    print(f"📁 Found {len(reports)} coverage report(s)\n")

    # Get coverage history
    coverage_history = []
    for report in reports:
        coverage = extract_coverage_from_report(report)
        timestamp = extract_timestamp_from_filename(report.name)

        if coverage is not None:
            coverage_history.append({
                'filename': report.name,
                'coverage': coverage,
                'timestamp': timestamp,
            })

    if not coverage_history:
        print("❌ Could not extract coverage data!")
        return

    # Sort by timestamp
    coverage_history.sort(key=lambda x: x['timestamp'] or datetime.min)

    # Show history
    print("📈 Coverage History:")
    print("-" * 70)
    for i, entry in enumerate(coverage_history, 1):
        time_str = entry['timestamp'].strftime("%Y-%m-%d %H:%M") if entry['timestamp'] else "Unknown"
        coverage = entry['coverage']
        emoji = "🟢" if coverage >= TARGET_COVERAGE else "🟡" if coverage >= 50 else "🔴"
        print(f"   {i}. {emoji} {coverage:5.1f}% at {time_str}")

    # Current status
    print("\n" + "=" * 70)
    print("🎯 CURRENT STATUS")
    print("=" * 70)

    first = coverage_history[0]
    latest = coverage_history[-1]

    print(f"   Starting:  {first['coverage']:5.1f}%")
    print(f"   Current:   {latest['coverage']:5.1f}%")
    print(f"   Target:    {TARGET_COVERAGE:5.1f}%")
    print()

    # Calculate progress
    progress = calculate_progress(
        latest['coverage'],
        first['coverage'],
        TARGET_COVERAGE
    )

    improvement = latest['coverage'] - first['coverage']

    print(f"   Improvement: {improvement:+.1f}%")
    print(f"   Progress:    {progress:.1f}% toward goal")
    print(f"   Remaining:   {TARGET_COVERAGE - latest['coverage']:.1f}% coverage needed")

    # Progress bar
    bar_length = 50
    filled = int(bar_length * (latest['coverage'] / 100))
    bar = "█" * filled + "░" * (bar_length - filled)
    print(f"\n   [{bar}] {latest['coverage']:.1f}%")

    # Estimate remaining work
    print("\n" + "=" * 70)
    print("🔮 ESTIMATES")
    print("=" * 70)

    # Count current tests (rough estimate from file)
    test_dir = BASE_DIR / "test" / "integration" / "bin"
    test_files = list(test_dir.glob("*_test.dart"))
    print(f"   Integration test files: {len(test_files)}")

    remaining_coverage = TARGET_COVERAGE - latest['coverage']
    remaining_tests = estimate_remaining_tests(latest['coverage'], 539, TARGET_COVERAGE)

    print(f"   Estimated tests needed: ~{remaining_tests}")
    print(f"   Estimated hours: ~{remaining_tests // 20}-{remaining_tests // 15}h")

    # Recommendations
    print("\n" + "=" * 70)
    print("💡 RECOMMENDATIONS")
    print("=" * 70)

    if latest['coverage'] < 10:
        print("   Priority: HIGH - Focus on main execution paths")
        print("   • Implement Process mocking for analyze() methods")
        print("   • Test main() entry points with argument parsing")
        print("   • Each test here will give ~0.5-1% coverage")
    elif latest['coverage'] < 50:
        print("   Priority: MEDIUM - Continue with core workflows")
        print("   • Implement file I/O operations")
        print("   • Test report generation")
        print("   • Each test here will give ~0.2-0.5% coverage")
    elif latest['coverage'] < 90:
        print("   Priority: LOW - Fill in edge cases and helpers")
        print("   • Test error scenarios")
        print("   • Test advanced features (watch, parallel)")
        print("   • Each test here will give ~0.1-0.2% coverage")
    else:
        print("   🎉 Almost there! Focus on remaining gaps")
        print("   • Review coverage report for specific uncovered lines")
        print("   • Add tests for edge cases")

    print()


if __name__ == "__main__":
    main()
