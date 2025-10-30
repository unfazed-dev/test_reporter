#!/usr/bin/env python3
"""
Analyze Coverage Gaps
Reads the coverage report and identifies specific uncovered functions/methods
to help prioritize integration test implementation.
"""

import re
from pathlib import Path

BASE_DIR = Path("/Users/unfazed-mac/Developer/packages/test_analyzer")
REPORT_DIR = BASE_DIR / "test_analyzer_reports" / "code_coverage"


def read_latest_report():
    """Read the most recent coverage report"""
    reports = sorted(REPORT_DIR.glob("bin-fo_test_report_coverage@*.md"), reverse=True)
    if not reports:
        print("❌ No coverage reports found!")
        return None

    latest = reports[0]
    print(f"📄 Reading: {latest.name}\n")
    return latest.read_text()


def extract_uncovered_lines(report_content):
    """Extract uncovered line numbers for each file"""
    uncovered_by_file = {}
    current_file = None

    for line in report_content.split('\n'):
        # Match file lines like "  File: /path/to/file.dart"
        file_match = re.match(r'\s*File:\s*(.+\.dart)', line)
        if file_match:
            current_file = Path(file_match.group(1)).name
            continue

        # Match uncovered lines like "    Uncovered lines: [1, 2, 3, ...]"
        uncovered_match = re.match(r'\s*Uncovered lines:\s*\[(.+)\]', line)
        if uncovered_match and current_file:
            lines_str = uncovered_match.group(1)
            lines = [int(n.strip()) for n in lines_str.split(',')]
            uncovered_by_file[current_file] = lines

    return uncovered_by_file


def analyze_file_for_functions(file_path, uncovered_lines):
    """Analyze a file to find which functions/methods are uncovered"""
    if not file_path.exists():
        return []

    content = file_path.read_text()
    lines = content.split('\n')

    uncovered_functions = []
    current_function = None
    function_start = 0

    for i, line in enumerate(lines, start=1):
        # Match function/method definitions
        func_match = re.search(r'(?:Future<\w+>|void|String|int|double|bool|\w+)\s+(\w+)\s*\(', line)
        if func_match and ('{' in line or i + 1 < len(lines) and '{' in lines[i]):
            current_function = func_match.group(1)
            function_start = i

        # Check if this line is in uncovered list
        if current_function and i in uncovered_lines:
            # Check if we haven't already recorded this function
            if not any(f['name'] == current_function and f['start'] == function_start
                      for f in uncovered_functions):
                uncovered_functions.append({
                    'name': current_function,
                    'start': function_start,
                    'uncovered_line': i,
                })

    return uncovered_functions


def main():
    print("🔍 Analyzing Coverage Gaps...")
    print("=" * 70)

    # Read latest report
    report = read_latest_report()
    if not report:
        return

    # Extract uncovered lines
    uncovered_by_file = extract_uncovered_lines(report)

    print(f"📊 Found {len(uncovered_by_file)} files with uncovered code\n")

    # Analyze each file
    lib_bin_dir = BASE_DIR / "lib" / "src" / "bin"

    priority_functions = {
        'HIGH': [],    # Main execution functions
        'MEDIUM': [],  # Helper functions called by main
        'LOW': [],     # Utility functions
    }

    for filename, uncovered_lines in uncovered_by_file.items():
        file_path = lib_bin_dir / filename

        print(f"\n📁 {filename}")
        print(f"   Uncovered lines: {len(uncovered_lines)}")

        functions = analyze_file_for_functions(file_path, uncovered_lines)

        if functions:
            print(f"   Uncovered functions: {len(functions)}")

            for func in functions[:10]:  # Show first 10
                # Categorize by name
                name = func['name']
                if name in ['main', 'run', 'analyze', 'execute', 'runAll']:
                    priority = 'HIGH'
                elif name.startswith('_'):
                    priority = 'LOW'
                else:
                    priority = 'MEDIUM'

                priority_functions[priority].append({
                    'file': filename,
                    'function': name,
                    'line': func['start'],
                })

                print(f"      - {name}() at line {func['start']}")

    # Summary
    print("\n" + "=" * 70)
    print("🎯 PRIORITY SUMMARY")
    print("=" * 70)

    for priority in ['HIGH', 'MEDIUM', 'LOW']:
        funcs = priority_functions[priority]
        print(f"\n{priority} PRIORITY: {len(funcs)} functions")
        for func in funcs[:5]:  # Top 5 per category
            print(f"   • {func['file']}:{func['line']} - {func['function']}()")

    print("\n💡 Recommendation:")
    print("   Start by testing HIGH priority functions (main execution paths)")
    print("   These will give the biggest coverage improvements")
    print()


if __name__ == "__main__":
    main()
