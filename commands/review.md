# /review - Strategic Project Assessment

Queen command. Run every few hours or when the beekeeper requests it. Higher-level than /buzz — reads plan files, not just JSONL.

## How it differs from /buzz

- `/buzz` is tactical: status sync, claim checks, inbox processing. Frequent. Reads JSONL only.
- `/review` is strategic: project health, drift detection, deliverable progress. Infrequent. Reads JSONL AND plan markdown files. Higher context cost.

## Steps

1. **Read all state** — `work.jsonl`, `claims/*.jsonl`, `inbox.jsonl`, `archive.jsonl`

2. **Read active plan files** — for each `"status":"working"` plan in work.jsonl, read the plan markdown

3. **Assess project health:**
   - **Staleness** — any work item updated > 7 days ago?
   - **Scope creep** — too many open items relative to team capacity (3 bees + queen)?
   - **Blocked items** — anything blocked that could be unblocked with information you have?
   - **Deliverable progress** — if a master plan exists, how are deliverables tracking?
   - **Plan quality** — are active plans still well-scoped? Do Done Criteria match actual work?

4. **Check for drift:**
   - Is any agent working on something not in work.jsonl?
   - Are plan tasks diverging from the original objective?
   - Are there implicit dependencies between items that should be explicit?

5. **Write assessment** — Append a structured entry to your `claims/queen.jsonl`:
   ```json
   {"action":"progress","item_id":"review","ts":"2026-01-20T16:00:00Z","note":"Review: 3 active items, 1 stale (T-003 no update in 8 days), 2 ready for assignment. P-001 on track. Recommend reassigning T-003."}
   ```

6. **Report to beekeeper** — Summarize findings and any recommended actions
