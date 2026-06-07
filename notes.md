## opencode init

/opensassi show-commands ---- then read all technical-specification.md files in their entirety. do not skip any technical-specificaton.md files or truncate them. do not load any .spec.md files.

read TUI-IMPLEMENTATION-SESSION.md and make a plan to implement the remaining issues

read PERSONA-IMPLEMENTATION.md

## Revise technical specification

/opensassi system-design --- we need to review all modified, added, and deleted files, from the current session and PERSONA-IMPLEMENTATION.md and review their corresponding .spec.md files, and use "opensassi system-design revise-technical-specification" to make the appropriate updates, and then update all sub-module technical-specification.md files, before finally making any required changes to the root ./technical-specification.md file

/opensassi system-design --- we need to do a full bottom-up update of all .spec.md and technical-specification.md files, to incorporate changes from the current session, and previous sessions. for each .spec.md file use git to check its last modification, and use git to check the last modification for its related source files. use "opensassing system-design revise-technical-specification" to update the .spec.md file for all changed source files. Add new .spec.md files for any source files that do not currently have them (.cpp/.h pairs, plain .h files). Create any new sub-module technical-specification.md files that are needed, and update all existing sub-module technical-specification.md files that have changes to their related .spec.md files. Then update the root level technical-specification.md. Use the "opensassing system-design revise-technical-specification" instructions for all .spec.md and technical-specification.md changes.

## session-evaluation

/opensassi session-evaluation generate and export --- use bash`npx @opensassi/opencode session-evaluation` to get the instructions. DO NOT read `sessions/session-evaluation-prompt.md` we are running in opencode not a0. so the command to list sessions is bash`opencode session list` then get the top session, which is the most recent and use bash`sessions/export-session.sh` to do the export. then use the "opensassi session-evaluation generate" instructions to create the session evaluation .md file with the session id (stripping the ses\_ prefix) in the file name. the run bash`sessions/session_stats.py`

## git finish session

/opensassi git finish-session --- the session evaluation was already created and tests have already been run so skip those steps

## Update implementation plan

read TUI-IMPLEMENTATION-SESSION.md and update it for the current session. Add any new "## Key Decisions Made". Remove any "## Remaining Issues" that were resolved. And add any newly disocvered issues to "## Remaining Issues"

## UI Design

I am going to work on enhancements to the TUI. The engineering documentation is in docs/tui-eng.md and the ui design documentation is docs/tui-design.md. When making changes I will use the terms from the docs/tui-design.md document to describe the changes that I want to make to the interface.

For testing these changes we will use test/e2e/test_tui_e2e.py which is run with test/e2e/test_tui_e2e.sh. try running this now to verify it works.
