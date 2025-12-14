# Makefile for test_reporter commands
#
# Usage:
#   make analyze   - Full test suite analysis
#   make coverage  - Coverage analysis
#   make flaky     - Flaky test detection
#   make failures  - Extract failures
#   make ci        - Simulate CI locally
#   make help      - Show all targets
#
# Customize variables below for your project.

# Configuration
TEST_PATH ?= test/
SOURCE_PATH ?= lib/src
MIN_COVERAGE ?= 80
TEST_RUNS ?= 3
FLAKY_RUNS ?= 10

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help analyze coverage flaky failures ci quick clean setup watch

## help: Show this help message
help:
	@echo "test_reporter Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /'

## setup: Install dependencies
setup:
	@echo "$(GREEN)Installing dependencies...$(NC)"
	dart pub get

## analyze: Run full test suite analysis
analyze: setup
	@echo "$(GREEN)Running full test suite analysis...$(NC)"
	dart run test_reporter:analyze_suite $(TEST_PATH) \
		--runs=$(TEST_RUNS) \
		--verbose
	@echo "$(GREEN)Reports saved to tests_reports/$(NC)"

## coverage: Run coverage analysis
coverage: setup
	@echo "$(GREEN)Running coverage analysis...$(NC)"
	dart run test_reporter:analyze_coverage $(SOURCE_PATH) \
		--min-coverage=$(MIN_COVERAGE) \
		--verbose
	@echo "$(GREEN)Report saved to tests_reports/quality/$(NC)"

## coverage-fix: Run coverage with auto-fix
coverage-fix: setup
	@echo "$(GREEN)Running coverage analysis with auto-fix...$(NC)"
	dart run test_reporter:analyze_coverage $(SOURCE_PATH) \
		--fix \
		--verbose
	@echo "$(GREEN)Missing test stubs generated$(NC)"

## flaky: Run flaky test detection ($(FLAKY_RUNS) runs)
flaky: setup
	@echo "$(GREEN)Running flaky test detection ($(FLAKY_RUNS) runs)...$(NC)"
	dart run test_reporter:analyze_tests $(TEST_PATH) \
		--runs=$(FLAKY_RUNS) \
		--performance \
		--verbose
	@echo "$(GREEN)Report saved to tests_reports/reliability/$(NC)"

## failures: Extract and list failed tests
failures: setup
	@echo "$(GREEN)Extracting failed tests...$(NC)"
	dart run test_reporter:extract_failures $(TEST_PATH) \
		--list-only \
		--verbose
	@echo "$(GREEN)Report saved to tests_reports/failures/$(NC)"

## failures-rerun: Extract and rerun failed tests
failures-rerun: setup
	@echo "$(GREEN)Extracting and rerunning failed tests...$(NC)"
	dart run test_reporter:extract_failures $(TEST_PATH) \
		--auto-rerun \
		--group-by-file \
		--verbose

## quick: Quick validation (1 run, no verbose)
quick: setup
	@echo "$(GREEN)Running quick validation...$(NC)"
	dart run test_reporter:analyze_suite $(TEST_PATH) --runs=1

## watch: Start watch mode for continuous testing
watch: setup
	@echo "$(GREEN)Starting watch mode...$(NC)"
	dart run test_reporter:analyze_tests $(TEST_PATH) \
		--runs=3 \
		--watch

## ci: Simulate CI pipeline locally
ci: setup
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)  CI Simulation$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 1: Static Analysis$(NC)"
	@dart analyze || (echo "$(RED)FAILED: Static analysis$(NC)" && exit 1)
	@echo "$(GREEN)PASSED$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 2: Format Check$(NC)"
	@dart format --set-exit-if-changed --output=none . || (echo "$(RED)FAILED: Format check$(NC)" && exit 1)
	@echo "$(GREEN)PASSED$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 3: Test Suite$(NC)"
	@dart run test_reporter:analyze_suite $(TEST_PATH) --runs=$(TEST_RUNS) || (echo "$(RED)FAILED: Test suite$(NC)" && exit 1)
	@echo "$(GREEN)PASSED$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 4: Coverage Threshold$(NC)"
	@dart run test_reporter:analyze_coverage $(SOURCE_PATH) --min-coverage=$(MIN_COVERAGE) --no-report || (echo "$(RED)FAILED: Coverage$(NC)" && exit 1)
	@echo "$(GREEN)PASSED$(NC)"
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)  ALL CHECKS PASSED$(NC)"
	@echo "$(GREEN)========================================$(NC)"

## ci-strict: Strict CI simulation (fails on any issue)
ci-strict: setup
	@echo "$(GREEN)Running strict CI simulation...$(NC)"
	dart analyze --fatal-infos
	dart format --set-exit-if-changed .
	dart run test_reporter:analyze_suite $(TEST_PATH) --runs=5 --performance
	dart run test_reporter:analyze_coverage $(SOURCE_PATH) --min-coverage=90 --fail-on-decrease

## clean: Remove generated reports
clean:
	@echo "$(YELLOW)Removing generated reports...$(NC)"
	rm -rf tests_reports/
	@echo "$(GREEN)Done$(NC)"

## report: Open latest suite report
report:
	@echo "$(GREEN)Opening latest suite report...$(NC)"
	@if [ -d "tests_reports/suite" ]; then \
		open tests_reports/suite/*.md 2>/dev/null || \
		xdg-open tests_reports/suite/*.md 2>/dev/null || \
		echo "Reports in: tests_reports/suite/"; \
	else \
		echo "$(YELLOW)No reports found. Run 'make analyze' first.$(NC)"; \
	fi

## baseline: Save current coverage as baseline
baseline: coverage
	@echo "$(GREEN)Saving coverage baseline...$(NC)"
	@mkdir -p .coverage
	@cp tests_reports/quality/*_coverage*.json .coverage/baseline.json 2>/dev/null || \
		echo "$(YELLOW)No coverage JSON found$(NC)"
	@echo "$(GREEN)Baseline saved to .coverage/baseline.json$(NC)"

## compare: Compare coverage against baseline
compare: setup
	@echo "$(GREEN)Comparing coverage against baseline...$(NC)"
	@if [ -f ".coverage/baseline.json" ]; then \
		dart run test_reporter:analyze_coverage $(SOURCE_PATH) \
			--baseline=.coverage/baseline.json \
			--fail-on-decrease \
			--verbose; \
	else \
		echo "$(YELLOW)No baseline found. Run 'make baseline' first.$(NC)"; \
	fi

# Default target
.DEFAULT_GOAL := help
