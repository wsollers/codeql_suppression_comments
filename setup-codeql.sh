#!/bin/bash
set -e

echo "=== CodeQL Setup Script ==="

# Configuration
CODEQL_DIR="$HOME/codeql-home"
CODEQL_CLI_DIR="$CODEQL_DIR/codeql-cli"
CODEQL_QUERIES_DIR="$CODEQL_DIR/codeql-queries"

# Remove previous installation if it exists
if [ -d "$CODEQL_DIR" ]; then
    echo "Removing previous CodeQL installation at $CODEQL_DIR"
    # rm -rf "$CODEQL_DIR"
fi

# Create fresh directory
mkdir -p "$CODEQL_DIR"
cd "$CODEQL_DIR"

echo "Fetching latest CodeQL CLI release info..."

# Get the latest release information from GitHub API
LATEST_RELEASE=$(curl -s https://api.github.com/repos/github/codeql-cli-binaries/releases/latest)

# Extract the download URL for Linux64
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o "https://github.com/github/codeql-cli-binaries/releases/download/[^\"]*linux64.zip" | head -1)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not find download URL for CodeQL CLI"
    exit 1
fi

echo "Downloading CodeQL CLI from: $DOWNLOAD_URL"
# curl -L -o codeql-linux64.zip "$DOWNLOAD_URL"

echo "Extracting CodeQL CLI..."
unzip -q codeql-linux64.zip
mv codeql "$CODEQL_CLI_DIR"
rm codeql-linux64.zip

echo "Cloning CodeQL queries repository..."
git clone --depth 1 https://github.com/github/codeql.git "$CODEQL_QUERIES_DIR"

echo "Verifying CodeQL installation..."
"$CODEQL_CLI_DIR/codeql" version

echo ""
echo "=== CodeQL Setup Complete ==="
echo "CodeQL CLI installed at: $CODEQL_CLI_DIR"
echo "CodeQL queries installed at: $CODEQL_QUERIES_DIR"
echo ""
echo "Add CodeQL to your PATH with:"
echo "export PATH=\"$CODEQL_CLI_DIR:\$PATH\""
echo ""
echo "Or use the full path in your scripts:"
echo "$CODEQL_CLI_DIR/codeql"