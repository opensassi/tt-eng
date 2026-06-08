#!/bin/bash
# apply_audit_fixes.sh - Apply audit findings to ISA detail files
#
# Prerequisites:
#   1. Create a fixer session:
#      opencode run "Read and understand the ISA documentation fixer" \
#          --file prompts/isa-audit-fixer.md \
#          --title "ISA fixer"
#   2. Export FIXER_SESSION:
#      export FIXER_SESSION="ses_..."
#      bash scripts/apply_audit_fixes.sh
#
# Relies on result_*.json files in LOG_DIR from a completed audit run.
#
# Options:
#   PARALLEL_JOBS=4    parallel fix calls (default 4)
#   LOG_DIR=./logs     directory with audit results (default PROJECT_ROOT/audit_logs)

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DOCS_DIR="$PROJECT_ROOT/docs/blackhole"
SOURCE_DIR="$PROJECT_ROOT/external/tt-isa-documentation"
FIXER_FILE="$PROJECT_ROOT/prompts/isa-audit-fixer.md"
PARALLEL_JOBS="${PARALLEL_JOBS:-4}"
LOG_DIR="${LOG_DIR:-$PROJECT_ROOT/audit_logs}"
FIXER_SESSION="${FIXER_SESSION:-}"

OP=$(command -v opencode || echo "./opencode")

# Known ISA categories with underscores in their directory names
CATEGORIES_WS="tensix_vector tensix_matrix data_movement circular_buffer"

# --- Validate FIXER_SESSION ---
if [[ -z "$FIXER_SESSION" ]]; then
    cat >&2 <<-EOF
ERROR: FIXER_SESSION is not set.

Create the fixer session:
  opencode run "Read and understand the ISA documentation fixer" \\
      --file prompts/isa-audit-fixer.md \\
      --title "ISA fixer"

Then:
  export FIXER_SESSION="ses_xxx"
  bash scripts/apply_audit_fixes.sh
EOF
    exit 1
fi

if ! $OP session list --format json 2>/dev/null | grep -q "$FIXER_SESSION"; then
    echo "ERROR: Session $FIXER_SESSION not found." >&2
    exit 1
fi

echo "Using fixer session: $FIXER_SESSION"
echo ""

# --- Decode safe_base back to rel_path ---
# safe_base is rel_path with / → _, e.g. isa_tensix_vector_vadd → isa/tensix_vector/vadd
decode_path() {
    local safe_base="$1"
    local rest="${safe_base#isa_}"
    local category=""
    local filepart=""

    for cat in $CATEGORIES_WS; do
        if [[ "$rest" == "$cat"* ]]; then
            category="$cat"
            filepart="${rest#$cat}"
            filepart="${filepart#_}"
            break
        fi
    done

    if [[ -z "$category" ]]; then
        category="${rest%%_*}"
        filepart="${rest#*_}"
    fi

    echo "isa/$category/$filepart.md"
}

# --- Process one result file ---
process_result() {
    local result_file="$1"
    local result_name=$(basename "$result_file" .json)
    local safe_base="${result_name#result_}"
    local session_file="$LOG_DIR/${safe_base}.session"

    # Incremental: skip if session already recorded for this file
    if [[ -f "$session_file" ]]; then
        echo "  Skipping $safe_base (fix already applied)"
        return
    fi

    # Decode the original file path
    local rel_path=$(decode_path "$safe_base")
    local orig_file="$DOCS_DIR/$rel_path"

    if [[ ! -f "$orig_file" ]]; then
        echo "WARNING: Original file not found: $orig_file" >> "$LOG_DIR/fix_errors.log"
        return
    fi

    # Read issues from result JSON
    local issues=$(jq '.issues' "$result_file" 2>/dev/null)
    local issue_count=$(echo "$issues" | jq 'length' 2>/dev/null || echo 0)

    if [[ "$issue_count" -eq 0 ]]; then
        echo "  Skipping $safe_base (no issues to fix)"
        return
    fi

    echo "  Processing $rel_path ($issue_count issues)..."

    # Re-derive instr_name and source files
    local instr_name=""
    if grep -q '^\*\*\(SFPU\|FPU\) mnemonic:' "$orig_file"; then
        instr_name=$(grep -m1 '^\*\*\(SFPU\|FPU\) mnemonic:' "$orig_file" | sed -n 's/.*`\([^`]*\)`.*/\1/p')
    fi
    if [[ -z "$instr_name" ]]; then
        local base=$(basename "$orig_file" .md)
        instr_name=$(echo "$base" | tr -cd '[:alnum:]' | tr '[:lower:]' '[:upper:]')
    fi

    local source_files=()
    if [[ -n "$instr_name" ]]; then
        mapfile -t source_files < <(find "$SOURCE_DIR" -path '*/TensixTile/TensixCoprocessor/*' -name "${instr_name}.md" 2>/dev/null || true)
    fi

    # Build fix prompt
    local prompt_file="$LOG_DIR/fix_prompt_${safe_base}.txt"
    local raw_file="$LOG_DIR/fix_result_${safe_base}_raw.txt"
    local corrected_file="$LOG_DIR/fix_result_${safe_base}.md"
    local TS=$(date +%s)

    cat > "$prompt_file" <<-PROMPT
Apply fixes to this ISA detail file based on these audit findings.

**Original file**: $rel_path
**Current content**:
$(cat "$orig_file")

**Audit findings**:
$issues

**Source file(s)**:
$(cat "${source_files[@]}" 2>/dev/null | head -200)

Output ONLY the complete corrected markdown inside a \`\`\`markdown ... \`\`\` block.

IMPORTANT: Do NOT call any tools. Do NOT read any files. Do NOT write any files. All necessary content is provided above. Any tool calls will be rejected and will corrupt the output. Your response must contain ONLY the \`\`\`markdown block.
PROMPT

    # Fork the fixer session
    $OP run --session "$FIXER_SESSION" --fork --title "fix-$safe_base-$TS" "$(cat "$prompt_file")" > "$raw_file" 2>&1

    # Capture the forked session ID
    sleep 1
    local fork_sid=$($OP session list --format json 2>/dev/null | jq -r ".[] | select(.title == \"fix-$safe_base-$TS\") | .id")
    echo "$fork_sid" > "$session_file"

    # Extract corrected markdown from response
    sed -i 's/\x1b\[[0-9;]*m//g' "$raw_file"
    sed -n '/^```markdown$/,/^```$/p' "$raw_file" | sed '1d;$d' > "$corrected_file"

    # Fallback: try plain ``` (no language tag)
    if [[ ! -s "$corrected_file" ]]; then
        sed -n '/^```$/,/^```$/p' "$raw_file" | sed '1d;$d' > "$corrected_file"
    fi

    # Fallback: try bare JSON extraction via python
    if [[ ! -s "$corrected_file" ]]; then
        python3 -c "
import sys
with open('$raw_file') as f:
    content = f.read()
start = content.find('\`\`\`')
if start >= 0:
    start += 3
    end = content.find('\`\`\`', start)
    if end >= 0:
        print(content[start:end].strip())
" > "$corrected_file" 2>/dev/null
    fi

    # Fallback to raw, stripping everything before first # heading via awk
    if [[ ! -s "$corrected_file" ]]; then
        awk '/^# /{found=1} found' "$raw_file" > "$corrected_file"
        if [[ ! -s "$corrected_file" ]]; then
            cp "$raw_file" "$corrected_file"
        fi
        echo "WARNING: No markdown block found for $safe_base, extracted from raw" >> "$LOG_DIR/fix_errors.log"
    fi

    # Validate: check it has at least the first heading from the original
    local orig_heading=$(grep -m1 '^# ' "$orig_file" 2>/dev/null || echo "")
    local fix_heading=$(grep -m1 '^# ' "$corrected_file" 2>/dev/null || echo "")
    if [[ -z "$fix_heading" ]]; then
        echo "WARNING: Corrected output for $safe_base has no heading, skipping apply" >> "$LOG_DIR/fix_errors.log"
        return
    fi

    # Apply: write corrected content to original file
    cp "$corrected_file" "$orig_file"
    echo "  Applied fixes to $rel_path (session: $fork_sid)"
}

export -f process_result decode_path
export DOCS_DIR SOURCE_DIR LOG_DIR OP FIXER_SESSION CATEGORIES_WS

# --- Main ---
find "$LOG_DIR" -name 'result_isa_*.json' | sort > /tmp/fix_files_all.txt
total=$(wc -l < /tmp/fix_files_all.txt)
echo "Found $total audit result files to process"

if command -v parallel >/dev/null 2>&1; then
    cat /tmp/fix_files_all.txt | parallel -j "$PARALLEL_JOBS" 'process_result {}'
else
    cat /tmp/fix_files_all.txt | xargs -P "$PARALLEL_JOBS" -I {} bash -c 'process_result "$@"' _ {}
fi

echo ""
echo "==== Fix apply complete ===="
echo "  Applied:  $(find "$LOG_DIR" -name '*.session' | wc -l)"
echo "  Errors:   $(wc -l < "$LOG_DIR/fix_errors.log" 2>/dev/null || echo 0)"
