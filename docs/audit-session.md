# ISA Documentation Audit Pipeline — Session Retrospective

## Pipeline Structure

The audit pipeline consists of two stages, each with a priming session and a parallel forking script.

```
┌────────────────────────────────────────────────────────────┐
│                    Stage 1: Audit                          │
│                                                            │
│  prompts/isa-audit-rubric.md  ──────  opencode run         │
│       (12-category rubric)         creates rubric session  │
│                                                            │
│  scripts/audit_isa_files.sh                                │
│       ├── Iterates 62 result_*.json files                  │
│       ├── Forks rubric session per file                    │
│       │   └── Per-file prompt includes:                    │
│       │       ├── generated doc content                    │
│       │       ├── source files (head -200)                 │
│       │       └── deterministic section check              │
│       ├── Model returns JSON with status, issues, fixes     │
│       └── Post-processing:                                 │
│           ├── sed -i 's/\x1b\[[0-9;]*m//g'  (ANSI strip)   │
│           ├── sed -n '/^```json$/,/^```$/p'  (extract)     │
│           ├── python3 fallback for bare JSON               │
│           └── cp raw as final fallback                     │
│                                                            │
│  Output: audit_logs/result_isa_<path>.json                 │
│          audit_logs/result_isa_<path>_raw.txt              │
└────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────┐
│                  Stage 2: Apply Fixes                      │
│                                                            │
│  prompts/isa-audit-fixer.md  ──────  opencode run           │
│       (fixer priming)            creates fixer session     │
│                                                            │
│  scripts/apply_audit_fixes.sh                               │
│       ├── Decodes safe_base back to rel_path                │
│       │   └── isa_tensix_vector_vadd → isa/tensix_vector/  │
│       ├── Re-derives instr_name from .md file              │
│       ├── Re-derives source files from TensixTile/         │
│       ├── Forks fixer session per file                     │
│       │   └── Per-file prompt includes:                    │
│       │       ├── current file content                     │
│       │       ├── audit findings (all issues)              │
│       │       ├── source file content                      │
│       │       └── "Output ONLY ```markdown block"          │
│       ├── Model returns corrected markdown                 │
│       ├── Post-processing:                                 │
│       │   ├── sed -n '/^```markdown$/,/^```$/p'            │
│       │   ├── sed -n '/^```$/,/^```$/p'  (no lang tag)    │
│       │   ├── awk '/^# /{found} found'  (heading fallback) │
│       │   └── cp raw as last resort                        │
│       └── Validate heading exists before overwriting       │
│                                                            │
│  Recording:                                                │
│       ├── $LOG_DIR/<safe_base>.session  (fork session ID)  │
│       └── --title "fix-<safe_base>-<timestamp>"            │
│                                                            │
│  Output: Overwrites original .md files                     │
└────────────────────────────────────────────────────────────┘
```

## Issues Discovered During Creation

### Session Management

| Issue | Symptom | Root Cause | Fix |
|-------|---------|------------|-----|
| `Session not found` in parallel | 44/50 files got 106-byte error stubs | Session expired or too many concurrent forks | Create fresh session; reduce `PARALLEL_JOBS` |
| `--fork` seemed fire-and-forget | `opencode run` returned immediately with no output | Running outside a git repo (`[project-id] No .git found`) | Ensure project has `.git` — opencode uses it for session identity |
| Session titles not unique | Couldn't identify which fork produced which result | All forks inherit title from parent | Use `--title "fix-<safe_base>-$(date +%s)"` |
| `opencode session list` unreliable | Couldn't find fork sessions by position | Session ordering is unpredictable under parallelism | Use unique `--title` per fork + `jq 'select(.title == "fix-...")'` |

### Script Bugs

| Issue | Symptom | Root Cause | Fix |
|-------|---------|------------|-----|
| Incremental skip broken | All 62 files reprocessed instead of just the missing ones | `safe_base` computed AFTER the incremental check, which used old `$base` | Move `safe_base` + `result_file` before the skip check |
| JSON extraction truncated | Valid JSON truncated at line 40 | Unanchored sed `/```json/,/```/p` matched inline ``` in `suggested_example` | Use anchored `'/^```json$/,/^```$/p'` |
| README naming collision | `result_README.json` overwritten by 4 different READMEs | Filename derived from `$base` only | Use `$safe_base` (directory path with `/` → `_`) |
| ANSI codes in extracted files | Raw TUI output in result files | `2>&1` captured terminal escape sequences | `sed -i 's/\x1b\[[0-9;]*m//g'` before extraction |
| `sed` unterminated address regex | `sed: -e expression #1, char 9` on 3 files | `\$p` in heredoc — `$` treated as variable | Use `awk '/^# /{found} found'` instead |
| `export -f` missing function | `decode_path: command not found` in parallel subprocess | Shell function not exported for `parallel`/`xargs` | Add `export -f decode_path` alongside `process_result` |

### Model Behavior

| Issue | Symptom | Root Cause | Fix |
|-------|---------|------------|-----|
| Model ignores JSON output instruction | Plain text list instead of JSON | Rubric instruction not repeated near the output point | Add `"You MUST output ONLY a JSON object"` at end of per-file prompt |
| Model tries to read/write files | `File not found` or `permission rejected` errors in output | Model sees file paths and attempts tool calls | Add `"Do NOT call any tools. Do NOT read or write any files."` |
| Model wraps markdown in wrong fence | No ````markdown` block found, falls back to raw | Some models use ```` ` without language tag | Add fallback for ```` ``` ` without language tag |
| Model goes rogue | Created `UNPACR.md` from scratch, tried to delete `vunpack.md` | Fixer prompt didn't forbid tool use strongly enough | Updated fixer priming with explicit tool call prohibition |

### Path Handling

| Issue | Symptom | Root Cause | Fix |
|-------|---------|------------|-----|
| `MODE=clean` deleted good results | Lost 50+ valid audit results | User expectation mismatch — should use incremental during iteration | Keep `MODE=clean` but document: only use clean when starting a fresh run with a verified session |
| `safe_base` design ambiguity | Hard to reverse `isa_tensix_vector_vadd` back to original path | Encoding collapses all `/` → `_`, losing directory structure boundaries | Known multi-word categories (`tensix_vector`, `data_movement`) hardcoded in `decode_path()` |
| `git checkout -- docs/blackhole/` didn't restore all files | 3 files remained modified after restore | First apply run modified files while `git checkout` ran concurrently | Sequential operations only; check `git status` after restore |

## Recommendations

### For Session Management

1. **Never use `MODE=clean` during iteration.** Always use `MODE=incremental` (the default). When you need a clean slate, manually `rm -rf audit_logs/` and verify the rubric session is healthy first.

2. **Create a fresh rubric session for each major run.** Sessions have limited lifespan. Title them with a unique identifier (`isa-rubric-$TS`). Verify with a single fork before the batch:
   ```bash
   opencode run "Read rubric" --file isa-audit-rubric.md --title "isa-rubric-$(date +%s)"
   SID=$(opencode session list --format json | jq -r '.[0].id')
   opencode run --session "$SID" --fork "Reply: OKTEST"
   ```

3. **Cap `PARALLEL_JOBS` at 4.** Higher values cause session exhaustion and `"Session not found"` errors. 8 is possible if the model/session backend is fast, but 4 is safer.

4. **Use `--title` with a unique suffix for every fork.** This is the only reliable way to identify forked sessions:
   ```bash
   TS=$(date +%s%N)  # nanosecond precision
   --title "audit-$safe_base-$TS"
   ```

### For Script Reliability

1. **Always anchor sed patterns.** `/^```json$/` not `/```json/`. One missing `^` or `$` can match inline content and truncate the extraction.

2. **Use `awk` instead of `sed` for range patterns** when `$` (last-line address) is involved. `awk` avoids the heredoc escaping issues that plague `$` in `sed`:
   ```bash
   # Instead of:
   sed -n '/^# /,$p'
   # Use:
   awk '/^# /{found=1} found'
   ```

3. **Always use path-based safe filenames** when processing multiple files from different directories. `$base` alone leads to collisions:
   ```bash
   safe_base=$(echo "$rel_path" | sed 's/\//_/g' | sed 's/\.md$//')
   ```

4. **Validate the output before overwriting.** Check that the corrected markdown has the same heading structure as the original:
   ```bash
   orig_heading=$(grep -m1 '^# ' "$orig_file")
   fix_heading=$(grep -m1 '^# ' "$corrected_file")
   if [[ -z "$fix_heading" ]]; then
       echo "WARNING: Skipping $file — output has no heading"
       return
   fi
   ```

5. **Write to temp file first, then rename.** Prevents partial writes from corrupting the original:
   ```bash
   cp "$corrected_file" "$orig_file.tmp" && mv "$orig_file.tmp" "$orig_file"
   ```

### For Prompt Engineering

1. **Repeat critical instructions at the END of the prompt.** Models give more weight to text near the output:
   ```markdown
   ...all content above...
   
   You MUST output ONLY a JSON object. Do NOT include any text before or after the JSON.
   ```

2. **Explicitly forbid tool calls.** If the model sees file paths in the prompt, it will try to `Read` them:
   ```markdown
   IMPORTANT: Do NOT call any tools. Do NOT read any files. Do NOT write any files.
   All necessary content is provided in the prompt above. Any tool calls will be
   rejected and will corrupt the output.
   ```

3. **For fixer prompts, request a specific fence tag.** Makes extraction deterministic:
   ```markdown
   Output ONLY the complete corrected markdown inside a ```markdown ... ``` block.
   ```

### For Workflow

1. **Checkpoint with jq validity, not file size.** A valid "PASS" with 0 issues could be any size:
   ```bash
   # Delete invalid results after an interrupted run
   for f in audit_logs/result_*.json; do
     jq -e '.status' "$f" >/dev/null 2>&1 || rm "$f"
   done
   # Then rerun with incremental mode — only deleted files reprocessed
   ```

2. **Restore corrupted docs from git immediately** if the apply script produces bad output:
   ```bash
   git checkout -- docs/blackhole/
   ```

3. **Commit fixes in batches.** First commit the pipeline scripts + the bulk of fixes. Then fix the remaining failures in a second commit:
   ```bash
   git add scripts/ prompts/ docs/blackhole/  # bulk
   git commit -m "59/62 files fixed"
   # fix remaining 3, then
   git add docs/blackhole/  # remaining
   git commit -m "Remaining 3 files"
   ```

## Re-running the Audit

### Prerequisites

- Project has a `.git` directory (opencode requires it for session identity)
- Source ISA docs at `external/tt-isa-documentation/`
- Generated docs at `docs/blackhole/isa/`
- `opencode` in `$PATH`

### Full Re-run

```bash
# 1. Create rubric session
opencode run "Read and understand the ISA audit rubric" \
    --file prompts/isa-audit-rubric.md \
    --title "isa-rubric-$(date +%s)"

# 2. Capture session ID
export SESSION_ID=$(opencode session list --format json | \
    jq -r '.[0].id')

# 3. Verify fork works
opencode run --session "$SESSION_ID" --fork "Reply: OK"

# 4. Run full audit (clean slate)
MODE=clean PARALLEL_JOBS=4 bash scripts/audit_isa_files.sh

# 5. Validate all results
for f in audit_logs/result_*.json; do
  jq -e '.status' "$f" >/dev/null 2>&1 || echo "BAD: $f"
done

# 6. Create fixer session
opencode run "Read and understand the ISA documentation fixer" \
    --file prompts/isa-audit-fixer.md \
    --title "isa-fixer-$(date +%s)"

# 7. Capture fixer session ID
export FIXER_SESSION=$(opencode session list --format json | \
    jq -r '.[0].id')

# 8. Apply fixes
MODE=clean PARALLEL_JOBS=4 bash scripts/apply_audit_fixes.sh

# 9. Check for errors
cat audit_logs/fix_errors.log

# 10. If any files failed, delete their .session files and rerun incrementally:
#     rm -f audit_logs/<safe_base>.session
#     PARALLEL_JOBS=1 bash scripts/apply_audit_fixes.sh
```

### Incremental Re-run (after interruption)

```bash
export SESSION_ID="ses_..."
export FIXER_SESSION="ses_..."

# Remove only bad result files
for f in audit_logs/result_*.json; do
  jq -e '.status' "$f" >/dev/null 2>&1 || rm "$f"
done

# Remove failed fix sessions
find audit_logs -name '*.session' | while read s; do
  base=$(basename "$s" .session)
  if [[ ! -f "audit_logs/result_$base.json" ]]; then
    rm "$s"
  fi
done

# Process only the missing files (incremental is the default)
PARALLEL_JOBS=4 bash scripts/audit_isa_files.sh
PARALLEL_JOBS=4 bash scripts/apply_audit_fixes.sh
```
