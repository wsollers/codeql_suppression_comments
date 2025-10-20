# CodeQL C++ Analysis Demo

This project demonstrates CodeQL security analysis on C++ code with intentional vulnerabilities, including examples of suppressed alerts using `lgtm` comments.

## Prerequisites

- Ubuntu (current version)
- `clang++` compiler
- `make`
- `git`
- `curl`
- `unzip`
- `jq` (optional, for pretty-printing SARIF)

### Install Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y clang make git curl unzip jq
```

## Project Structure

```
.
├── main.cpp              # C++ code with security vulnerabilities
├── Makefile              # Build configuration
├── setup-codeql.sh       # Downloads and installs CodeQL
├── run-codeql.sh         # Runs CodeQL analysis
├── AlertSuppression.ql   # Custom suppression query
├── qlpack.yml            # Query pack definition for custom query
├── runAnalysis.sh        # Wrapper around the entire process
└── README.md             # This file
```

## Vulnerabilities Included

The `main.cpp` file contains the following intentional security issues:

**NOTE:** The `lgtm` comments in the code are **legacy LGTM.com syntax** and do not work with the CodeQL CLI. To implement working suppressions, you need to:
1. Write custom alert-suppression queries (with `@kind alert-suppression`)
2. Run them alongside your analysis queries
3. Or dismiss alerts through GitHub's UI if using GitHub Code Scanning

### Vulnerabilities in the Code
- Buffer overflow (`strcpy` without bounds checking)
- Command injection (unsanitized user input in `system()`)
- Use after free
- Memory leak
- Unvalidated array index
- Division by zero
- Path traversal

The `lgtm` comments in the code demonstrate the **intended** suppression syntax from LGTM.com, but they won't actually suppress alerts when running CodeQL CLI locally.

## Usage

### 1. Setup CodeQL

First, make the scripts executable:

```bash
chmod +x setup-codeql.sh run-codeql.sh
```

Then run the setup script to download and install CodeQL:

```bash
./setup-codeql.sh
```

This will:
- Remove any previous CodeQL installation
- Download the latest CodeQL CLI
- Clone the CodeQL queries repository
- Install everything to `~/codeql-home/`

### 2. Enable Alert Suppressions (Optional)

To make suppression comments work, you need:

1. **AlertSuppression.ql** - A custom suppression query that recognizes:
   - `// codeql[rule-id]` (recommended format)
   - `// lgtm[rule-id]` (legacy LGTM.com format)

2. **qlpack.yml** - A query pack definition file that declares the dependencies

Both files must be in the project directory. The `run-codeql.sh` script will automatically detect and use them.

### 3. Run CodeQL Analysis

Execute the analysis script:

```bash
./run-codeql.sh
```

This will:
- Create a CodeQL database from the C++ code
- Run security and quality analysis
- If `AlertSuppression.ql` exists, include it to process suppression comments
- Generate a SARIF file with results
- Format the SARIF file for readability

**Finding the Correct Rule IDs:**

To suppress an alert, you need to use the exact rule ID from CodeQL. To find rule IDs:

```bash
# View all rule IDs in the results
cat results/cpp-results.sarif | jq '.runs[0].results[].ruleId' | sort | uniq

# View a specific alert with its rule ID
cat results/cpp-results.sarif | jq '.runs[0].results[] | {ruleId, message: .message.text, line: .locations[0].physicalLocation.region.startLine}'
```

Then use the exact rule ID in your suppression comment:
```cpp
// codeql[cpp/unbounded-write]
strcpy(buffer, input);
```

### 3. View Results

The SARIF results are saved to `results/cpp-results.sarif`

**View all results:**
```bash
cat results/cpp-results.sarif | jq '.runs[0].results[] | {ruleId, message, locations}'
```

**View only suppressed results:**
```bash
cat results/cpp-results.sarif | jq '.runs[0].results[] | select(.suppressions != null) | {ruleId, message}'
```

**Count alerts:**
```bash
# Total alerts
cat results/cpp-results.sarif | jq '.runs[0].results | length'

# Suppressed alerts
cat results/cpp-results.sarif | jq '[.runs[0].results[] | select(.suppressions != null)] | length'
```

**View SARIF in a pager:**
```bash
less results/cpp-results.sarif
```

## Expected Results

You should see:
- Multiple security vulnerabilities detected
- Some alerts marked as suppressed in the SARIF file (those with `lgtm` comments)
- The suppressions array populated for suppressed alerts

## SARIF Structure

The generated SARIF file contains:
- `runs[0].results[]` - All detected issues
- `results[].suppressions[]` - Present for suppressed alerts
- `results[].ruleId` - The CodeQL rule that triggered
- `results[].message` - Description of the issue
- `results[].locations[]` - Where the issue was found

## Cleaning Up

Remove generated files:
```bash
make clean
rm -rf codeql-db results
```

Remove CodeQL installation:
```bash
rm -rf ~/codeql-home
```

## Additional Resources

- [CodeQL Documentation](https://codeql.github.com/docs/)
- [CodeQL for C/C++](https://codeql.github.com/docs/codeql-language-guides/codeql-for-cpp/)
- [SARIF Format](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)