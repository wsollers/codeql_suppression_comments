#/bin/sh

# Install prerequisites
sudo apt-get update
sudo apt-get install -y clang make git curl unzip jq

# Setup CodeQL
chmod +x setup-codeql.sh run-codeql.sh
./setup-codeql.sh

# Display CodeQL version
~/codeql-home/codeql-cli/codeql version

# Run analysis
./run-codeql.sh


# Check the SARIF output for suppressions
cat results/cpp-results.sarif | jq '[.runs[0].results[] | select(.suppressions != null)] | length'