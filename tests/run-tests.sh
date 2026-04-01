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
  EXPECTED_STEMS=(build-timeline build-settings concurrency-settings xcode-settings \
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
# Entry point
# ---------------------------------------------------------------------------
case "${1:-}" in
  --static)    run_static ;;
  --quick|"")  run_interactive quick ;;
  --manual)    run_interactive manual ;;
  --ci)        echo "TODO: --ci mode"; exit 1 ;;
  *)
    echo "Usage: $0 [--quick | --manual | --static | --ci]"
    exit 1
    ;;
esac
