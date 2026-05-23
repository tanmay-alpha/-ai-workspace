# test.sh Template

Use this as a portable bash test runner template.

Adapt the marked sections for the selected repository, language, and evaluator
requirements.

```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="new"
OUTPUT_PATH=""

usage() {
  cat <<'USAGE'
Usage: ./test.sh [--mode base|new] [--output_path PATH]

Options:
  --mode          Select which tests to run. Use "base" for existing tests and
                  "new" for challenge-specific tests.
  --output_path   Optional path for JUnit XML output.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --output_path)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$MODE" != "base" && "$MODE" != "new" ]]; then
  echo "Invalid --mode value: $MODE" >&2
  exit 2
fi

if [[ -n "$OUTPUT_PATH" ]]; then
  mkdir -p "$(dirname "$OUTPUT_PATH")"
fi

run_base_tests() {
  # Adapt this section to run the repository's existing tests.
  #
  # Python pytest example:
  #   pytest
  #
  # Node test runner example:
  #   npm test
  :
}

run_new_tests() {
  # Adapt this section to run challenge-specific tests.
  #
  # Python pytest example with optional JUnit XML:
  #   if [[ -n "$OUTPUT_PATH" ]]; then
  #     pytest tests/challenge --junitxml "$OUTPUT_PATH"
  #   else
  #     pytest tests/challenge
  #   fi
  #
  # Node test runner examples:
  #   npm test -- --runInBand
  #   npm test -- --reporter=junit --outputFile="$OUTPUT_PATH"
  :
}

case "$MODE" in
  base)
    run_base_tests
    ;;
  new)
    run_new_tests
    ;;
esac
```

## Adaptation Notes

- Keep dependency installation out of this script when possible.
- Use the Docker build step for dependency installation.
- Preserve `set -euo pipefail`.
- Keep comments clear about repository-specific changes.
- Emit JUnit XML when the evaluator requires structured results.
