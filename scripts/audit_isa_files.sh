#!/bin/bash
# audit_isa_files.sh - Parallel ISA documentation audit forking from a rubric session
#
# Prerequisites:
#   1. Create a session with the audit rubric loaded:
#      opencode run "Read and understand the ISA audit rubric" \
#          --file prompts/isa-audit-rubric.md \
#          --title "ISA audit rubric"
#   2. Get the session ID:  opencode session list
#   3. Set SESSION_ID below or export it:
#      export SESSION_ID="ses_..."
#      bash scripts/audit_isa_files.sh
#
# Each file forks the rubric session with only the generated doc + source files
# inline. The rubric is inherited from the parent session, so it doesn't need
# to be repeated. This means the model stays warm and each fork is fast.
#
# Usage:
#   SESSION_ID="ses_xxx" bash scripts/audit_isa_files.sh
#
# Options:
#   PARALLEL_JOBS=4    parallel inference calls (default 4)
#   LOG_DIR=./logs     output directory (default PROJECT_ROOT/audit_logs)

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DOCS_DIR="$PROJECT_ROOT/docs/blackhole"
SOURCE_DIR="$PROJECT_ROOT/external/tt-isa-documentation"
RUBRIC_FILE="$PROJECT_ROOT/prompts/isa-audit-rubric.md"
PARALLEL_JOBS="${PARALLEL_JOBS:-4}"
LOG_DIR="${LOG_DIR:-$PROJECT_ROOT/audit_logs}"
mkdir -p "$LOG_DIR"

OP=$(command -v opencode || echo "./opencode")

# --- Hardcode or pass via env ---
SESSION_ID="${SESSION_ID:-}"

if [[ -z "$SESSION_ID" ]]; then
    cat >&2 <<-EOF
ERROR: SESSION_ID is not set.

To create the rubric session:
  opencode run "Read and understand the ISA audit rubric" \\
      --file prompts/isa-audit-rubric.md \\
      --title "ISA audit rubric"

Then set the ID:
  export SESSION_ID="ses_\$(opencode session list --format json | python3 -c 'import sys,json; print(json.load(sys.stdin)[0][\"id\"])')"
  bash scripts/audit_isa_files.sh

Or set it directly:
  export SESSION_ID="ses_xxxxxxxxxxxxxxxxxxxx"
  bash scripts/audit_isa_files.sh
EOF
    exit 1
fi

# Verify session exists
if ! $OP session list --format json 2>/dev/null | grep -q "$SESSION_ID"; then
    echo "ERROR: Session $SESSION_ID not found. Create it first with:" >&2
    echo "  opencode run \"Read and understand the ISA audit rubric\" --file prompts/isa-audit-rubric.md --title \"ISA audit rubric\"" >&2
    exit 1
fi

echo "Using rubric session: $SESSION_ID"
echo ""

# --- Process a single file ---
process_file() {
    local isa_file="$1"
    local rel_path="${isa_file#$DOCS_DIR/}"
    local base=$(basename "$isa_file" .md)

    echo "Processing $rel_path ..."

    # 1. Extract mnemonic and locate source files
    local first_mnemonic=""
    # Try to get the actual instruction mnemonic (e.g., "SFPADD" from "**SFPU mnemonic:** `SFPADD`")
    local instr_name=""
    if grep -q '^\*\*\(SFPU\|FPU\) mnemonic:' "$isa_file"; then
        instr_name=$(grep -m1 '^\*\*\(SFPU\|FPU\) mnemonic:' "$isa_file" | sed -n 's/.*`\([^`]*\)`.*/\1/p')
    fi
    # Fallback: uppercase + strip non-alphanum (e.g., sfp-and → SFPAND, vadd → VADD)
    if [[ -z "$instr_name" ]]; then
        instr_name=$(echo "$base" | tr -cd '[:alnum:]' | tr '[:lower:]' '[:upper:]')
    fi

    # Search source files by exact filename match in TensixTile directories only
    local source_files=()
    if [[ -n "$instr_name" ]]; then
        mapfile -t source_files < <(find "$SOURCE_DIR" -path '*/TensixTile/TensixCoprocessor/*' -name "${instr_name}.md" 2>/dev/null || true)
    fi

    if [[ ${#source_files[@]} -eq 0 ]]; then
        echo "WARNING: No source file found for $rel_path (mnemonic: $instr_name)" >> "$LOG_DIR/missing_source.log"
    fi

    # 2. Deterministic checks (fast grep, no LLM)
    local needs_checklist=false
    if ! grep -q '^**Syntax:**' "$isa_file"; then needs_checklist=true; fi
    if ! grep -q '^**Latency:**' "$isa_file"; then needs_checklist=true; fi
    if ! grep -q '^**Example:**' "$isa_file"; then needs_checklist=true; fi
    if ! grep -q '^**Notes:**' "$isa_file"; then needs_checklist=true; fi

    # Always fork rubric session for the deep audit — even if section checks pass,
    # there may be semantic errors that only LLM evaluation can catch.
    local prompt_file="$LOG_DIR/prompt_$base.txt"
    local result_file="$LOG_DIR/result_$base.json"

    # 3. Build per-file prompt (just the data — rubric is inherited from session)
    cat > "$prompt_file" <<-PROMPT
Evaluate the generated ISA detail file against its source documentation.

**Generated file**: $rel_path
**Content**:
$(cat "$isa_file")

**Source file(s)**:
$(cat "${source_files[@]}" 2>/dev/null | head -200)

**Deterministic section check**:
$(
  if $needs_checklist; then
    echo "Missing in generated file:"
    ! grep -q '^**Syntax:**'   "$isa_file" && echo "  - **Syntax:** line"
    ! grep -q '^**Latency:**'  "$isa_file" && echo "  - **Latency:** line"
    ! grep -q '^**Example:**'  "$isa_file" && echo "  - **Example:** section"
    ! grep -q '^**Notes:**'    "$isa_file" && echo "  - **Notes:** section"
  else
    echo "All required sections present — evaluate for semantic accuracy."
  fi
)
PROMPT

    # 4. Fork the rubric session with this per-file prompt
    echo "  Forking rubric session for $rel_path ..."
    $OP run --session "$SESSION_ID" --fork "$(cat "$prompt_file")" > "$result_file" 2>&1
    echo "  Result saved to $(basename "$result_file")"
}

export -f process_file
export DOCS_DIR SOURCE_DIR LOG_DIR OP SESSION_ID

# --- Main ---
find "$DOCS_DIR/isa" -type f -name "*.md" > /tmp/isa_files_all.txt
total=$(wc -l < /tmp/isa_files_all.txt)
echo "Found $total ISA detail files to audit"
echo ""

if command -v parallel >/dev/null 2>&1; then
    cat /tmp/isa_files_all.txt | parallel -j "$PARALLEL_JOBS" 'process_file {}'
else
    cat /tmp/isa_files_all.txt | xargs -P "$PARALLEL_JOBS" -I {} bash -c 'process_file "$@"' _ {}
fi

echo ""
echo "==== Audit complete ===="
echo "  Results:     $(ls "$LOG_DIR"/result_*.json 2>/dev/null | wc -l)"
echo "  OK (noop):   $(wc -l < "$LOG_DIR/ok_files.log" 2>/dev/null || echo 0)"
echo "  No source:   $(wc -l < "$LOG_DIR/missing_source.log" 2>/dev/null || echo 0)"
echo ""
echo "Next step: review results and apply fixes:"
echo "  python3 scripts/apply_audit_fixes.py  (if that exists)"
