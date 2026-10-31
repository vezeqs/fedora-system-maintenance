#!/usr/bin/env bash
set -euo pipefail

readme=${1:-README.md}

grep -q '^## Verify it yourself' "$readme"
grep -q '^## Limits' "$readme"
grep -q '^## License' "$readme"
grep -q 'cleanup -b' README.md

echo "ok README sections and claims"
