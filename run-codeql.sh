#!/bin/bash
set -e

echo "=== CodeQL Analysis Script ==="

# Configuration
CODEQL_DIR="$HOME/codeql-home"
CODEQL_CLI="$CODEQL_DIR/codeql-cli/codeql"
CODEQL_QUERIES="$CODEQL_DIR/codeql-queries"
PROJECT_DIR="$(pwd)"
DB_DIR="$PROJECT_DIR/codeql-db"
RESULTS_DIR="$PROJECT_DIR/results"
SARIF_FILE="$RESULTS_DIR/cpp-results.sarif"

# Check if CodeQL is installed
if [ ! -f "$CODEQL_CLI" ]; then
    echo "Error: CodeQL CLI not found at $CODEQL_CLI"
    echo "Please run setup-codeql.sh first"
    exit 1
fi

# Clean previous analysis
if [ -d "$DB_DIR" ]; then
    echo "Removing previous CodeQL database..."
    rm -rf "$DB_DIR"
fi

if [ -d "$RESULTS_DIR" ]; then
    echo "Removing previous results..."
    rm -rf "$RESULTS_DIR"
fi

mkdir -p "$RESULTS_DIR"

echo ""
echo "Step 1: Creating CodeQL database..."
"$CODEQL_CLI" database create "$DB_DIR" \
    --language=cpp \
    --command="make clean all" \
    --source-root="$PROJECT_DIR" \
    --overwrite

echo ""
echo "Step 2: Running CodeQL analysis with alert suppression..."
echo "Note: Including custom alert-suppression query to process suppression comments"

# Check if custom suppression query exists
SUPPRESSION_QUERY="$PROJECT_DIR/AlertSuppression.ql"
if [ -f "$SUPPRESSION_QUERY" ]; then
    echo "Found custom suppression query at: $SUPPRESSION_QUERY"
    "$CODEQL_CLI" database analyze "$DB_DIR" \
        --format=sarif-latest \
        --output="$SARIF_FILE" \
        --sarif-add-query-help \
        --sarif-category=cpp-analysis \
        --compilation-cache="$PROJECT_DIR/.codeql-cache" \
        -- "$CODEQL_QUERIES/cpp/ql/src/codeql-suites/cpp-security-and-quality.qls" \
           "AlertSuppression.ql"
else
    echo "Warning: No custom suppression query found. Running without suppression support."
    echo "Create AlertSuppression.ql to enable suppression comments."
    "$CODEQL_CLI" database analyze "$DB_DIR" \
        --format=sarif-latest \
        --output="$SARIF_FILE" \
        --sarif-add-query-help \
        --sarif-category=cpp-analysis \
        --compilation-cache="$PROJECT_DIR/.codeql-cache" \
        -- "$CODEQL_QUERIES/cpp/ql/src/codeql-suites/cpp-security-and-quality.qls"
fi

echo ""
echo "Step 3: Formatting SARIF file for readability..."

# Check if jq is installed for JSON formatting
if command -v jq &> /dev/null; then
    echo "Using jq to format SARIF file..."
    TEMP_FILE="$SARIF_FILE.tmp"
    jq '.' "$SARIF_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$SARIF_FILE"
    echo "SARIF file formatted with jq"
elif command -v python3 &> /dev/null; then
    echo "Using Python to format SARIF file..."
    python3 -m json.tool "$SARIF_FILE" "$SARIF_FILE.formatted"
    mv "$SARIF_FILE.formatted" "$SARIF_FILE"
    echo "SARIF file formatted with Python"
else
    echo "Warning: Neither jq nor python3 found. SARIF file not formatted."
    echo "Install jq with: sudo apt-get install jq"
fi

echo ""
echo "=== Analysis Complete ==="
echo "Database location: $DB_DIR"
echo "Results location: $SARIF_FILE"
echo ""
echo "View results with:"
echo "  less $SARIF_FILE"
echo "  cat $SARIF_FILE | jq '.runs[0].results[] | {ruleId, message, locations}'"
echo ""
echo "To view suppressed results:"
echo "  cat $SARIF_FILE | jq '.runs[0].results[] | select(.suppressions != null) | {ruleId, message}'"
echo ""
echo "To count total vs suppressed alerts:"
echo "  Total: \$(cat $SARIF_FILE | jq '.runs[0].results | length')"
echo "  Suppressed: \$(cat $SARIF_FILE | jq '[.runs[0].results[] | select(.suppressions != null)] | length')"