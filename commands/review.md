# /review - Strategic Project Assessment

Queen command. Run every few hours or when the beekeeper requests it. Higher-level than /buzz — reads plan files, not just issue state.

## How it differs from /buzz

- `/buzz` is tactical: status sync, progress checks, triage. Frequent. Reads beads state only.
- `/review` is strategic: project health, drift detection, deliverable progress. Infrequent. Reads beads state AND plan markdown files. Higher context cost.

## Steps

1. **Read all state:**
   ```bash
   bd list --all --json                 # All issues including closed
   bd blocked                           # Blocked issues
   bd ready                             # Available work
   ```

2. **Read active plan files** — for each `in_progress` epic, read the plan markdown

3. **Assess project health:**
   - **Staleness** — any issue not updated in > 7 days? (`bd stale` if available)
   - **Scope creep** — too many open items relative to team capacity?
   - **Blocked items** — anything blocked that could be unblocked with information you have?
   - **Deliverable progress** — how are epics tracking against their Done Criteria?
   - **Plan quality** — are active plans still well-scoped? Do Done Criteria match actual work?

4. **Check for drift:**
   - Is any agent working on something not tracked in beads?
   - Are plan tasks diverging from the original objective?
   - Are there implicit dependencies that should be explicit? (`bd dep add`)

5. **Add review comment** — Pick a relevant epic or create a standalone note:
   ```bash
   bd comments add <epic-id> "Review: 3 active items, 1 stale (bd-xyz no update in 8 days), 2 ready for assignment. Plan on track. Recommend reassigning bd-xyz."
   ```

6. **Report to beekeeper** — Summarize findings and any recommended actions
