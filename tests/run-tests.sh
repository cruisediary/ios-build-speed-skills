#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_MD="$REPO_ROOT/skills/ios-build-speed/SKILL.md"
REFERENCES_DIR="$REPO_ROOT/skills/references"
TEST_CASES="$SCRIPT_DIR/trigger-tests.md"

PASS=0
FAIL=0
FAILURES=()

pass() { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); FAILURES+=("$1"); }

# ---------------------------------------------------------------------------
# Parse routing table from SKILL.md ## Available skills section
# Extracts bare stems from File column: `references/build-timeline.md` -> build-timeline
# ---------------------------------------------------------------------------
parse_routing_table() {
  # Range: from "## Available skills" to next "##" heading (exclusive).
  # Uses a flag variable to avoid the start-line matching the stop pattern.
  awk '/^## Available skills/{found=1; next} found && /^##/{exit} found' "$SKILL_MD" \
    | grep -o '`references/[^.]*\.md`' \
    | sed 's/`references\///;s/\.md`//'
}

# ---------------------------------------------------------------------------
# --static mode
# ---------------------------------------------------------------------------
run_static() {
  echo "Trigger Static Tests"
  echo "===================="
  echo ""

  if [ ! -f "$SKILL_MD" ]; then
    echo "ERROR: SKILL.md not found at $SKILL_MD"
    exit 1
  fi

  # Check 1: Routing table completeness
  echo "Check 1: Routing table completeness"
  EXPECTED_STEMS=(build-timeline build-settings explicit-modules concurrency-settings xcode-settings \
    script-phases link-settings modular-architecture protocol-separation \
    type-annotations preview-isolation pods-settings xcode-cache ci-cache ci-workflow)

  ROUTING_STEMS=$(parse_routing_table)
  for stem in "${EXPECTED_STEMS[@]}"; do
    if echo "$ROUTING_STEMS" | grep -qx "$stem"; then
      pass "$stem in routing table"
    else
      fail "$stem MISSING from routing table"
    fi
  done

  echo ""
  # Check 2: File existence
  echo "Check 2: File existence"
  while IFS= read -r stem; do
    file="$REFERENCES_DIR/$stem.md"
    if [ -f "$file" ]; then
      pass "$stem.md exists"
    else
      fail "$stem.md NOT FOUND at $file"
    fi
  done <<< "$ROUTING_STEMS"

  echo ""
  # Check 3: Orphan detection
  echo "Check 3: Orphan detection"
  shopt -s nullglob
  for file in "$REFERENCES_DIR"/*.md; do
    stem=$(basename "$file" .md)
    if echo "$ROUTING_STEMS" | grep -qx "$stem"; then
      pass "$stem.md listed in routing table"
    else
      fail "$stem.md is an ORPHAN (in references/ but not in routing table)"
    fi
  done
  shopt -u nullglob

  echo ""
  summary
}

summary() {
  echo "Results: $PASS passed, $FAIL failed"
  if [ $FAIL -gt 0 ]; then
    echo ""
    echo "Failures:"
    for f in "${FAILURES[@]}"; do echo "  - $f"; done
    exit 1
  fi
  exit 0
}

# ---------------------------------------------------------------------------
# Interactive mode (shared by --quick and --manual)
# ---------------------------------------------------------------------------
QUICK_IDS=(T01 T03 T11 T14 N01)

run_interactive() {
  local mode="$1"  # "quick" or "manual"
  local title ids=()

  if [ "$mode" = "quick" ]; then
    title="iOS Build Speed — Quick Trigger Test (5 cases)"
    ids=("${QUICK_IDS[@]}")
  else
    title="iOS Build Speed — Full Trigger Test (17 cases)"
    # Read all non-comment IDs from trigger-tests.md
    while IFS=$'\t' read -r id phrase ref; do
      [[ "$id" =~ ^# ]] && continue
      [ -z "$id" ] && continue
      ids+=("$id")
    done < "$TEST_CASES"
  fi

  echo "$title"
  printf '%0.s=' $(seq 1 ${#title})
  echo ""
  echo "Run each prompt in the chat and confirm the result."
  echo ""

  # Lookup helpers (bash 3 compatible — no associative arrays)
  lookup_phrase() { awk -F'\t' -v id="$1" '$1==id{print $2; exit}' "$TEST_CASES"; }
  lookup_ref()    { awk -F'\t' -v id="$1" '$1==id{print $3; exit}' "$TEST_CASES"; }

  for id in "${ids[@]}"; do
    phrase="$(lookup_phrase "$id")"
    ref="$(lookup_ref "$id")"
    echo "[$id] Prompt : \"$phrase\""
    if [ "$ref" = "NONE" ]; then
      echo "     Expect : ios-build-speed does NOT activate"
    else
      echo "     Expect : ios-build-speed activates → reads references/$ref.md"
    fi
    printf "     Result : [Enter = pass / f = fail] "
    read -r input
    if [ "$input" = "f" ]; then
      fail "$id: $phrase"
    else
      pass "$id"
    fi
    echo ""
  done

  summary
}

# ---------------------------------------------------------------------------
# --ci mode
# ---------------------------------------------------------------------------
run_ci() {
  if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "SKIP: ANTHROPIC_API_KEY not set"
    exit 2
  fi

  echo "Trigger Integration Tests (Claude API)"
  echo "======================================="
  echo ""

  SKILL_CONTENT=$(cat "$SKILL_MD")
  SYSTEM_PROMPT="${SKILL_CONTENT}

After identifying the right skill for the user's request, respond ONLY with valid JSON on a single line:
{\"reference\": \"<filename-stem-without-extension>\"}
If no ios-build-speed skill applies, respond with:
{\"reference\": \"none\"}"

  MODEL="claude-haiku-4-5-20251001"

  call_api() {
    local phrase="$1"
    local response
    # Use || true so a curl error does not abort under set -e.
    # An empty or error response is caught by the python3 parse below.
    response=$(curl -s https://api.anthropic.com/v1/messages \
      -H "x-api-key: $ANTHROPIC_API_KEY" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d "{
        \"model\": \"$MODEL\",
        \"max_tokens\": 64,
        \"system\": $(printf '%s' "$SYSTEM_PROMPT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
        \"messages\": [{\"role\": \"user\", \"content\": $(printf '%s' "$phrase" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}]
      }" || true)
    if [ -z "$response" ]; then
      echo "PARSE_ERROR"
      return
    fi
    echo "$response" | python3 -c "
import json, sys
data = json.load(sys.stdin)
text = data['content'][0]['text'].strip()
parsed = json.loads(text)
print(parsed['reference'])
" 2>/dev/null || echo "PARSE_ERROR"
  }

  while IFS=$'\t' read -r id phrase ref; do
    [[ "$id" =~ ^# ]] && continue
    [ -z "$id" ] && continue

    printf "[%s] %-55s " "$id" "\"$phrase\""

    run1=$(call_api "$phrase")
    run2=$(call_api "$phrase")

    if [ "$run1" = "PARSE_ERROR" ] || [ "$run2" = "PARSE_ERROR" ]; then
      fail "$id: API response parse error (run1=$run1, run2=$run2)"
      continue
    fi

    if [ "$run1" != "$run2" ]; then
      fail "$id: FLAKY (run1=$run1, run2=$run2)"
      continue
    fi

    if [ "$ref" = "NONE" ]; then
      if [ "$run1" = "none" ]; then
        pass "$id"
      else
        fail "$id: expected none, got $run1"
      fi
    else
      if [ "$run1" = "$ref" ]; then
        pass "$id"
      else
        fail "$id: expected $ref, got $run1"
      fi
    fi
  done < "$TEST_CASES"

  echo ""
  summary
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
case "${1:-}" in
  --static)    run_static ;;
  --quick|"")  run_interactive quick ;;
  --manual)    run_interactive manual ;;
  --ci)        run_ci ;;
  *)
    echo "Usage: $0 [--quick | --manual | --static | --ci]"
    exit 1
    ;;
esac
