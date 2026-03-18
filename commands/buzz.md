# /buzz - Check In

Check yourself. Check your plan. If you're Queen, check the hive.

## All Agents — Self-Check & Plan Hygiene

1. **Re-read your plan or task** — Are you following it?
2. **Update your plan file** (if working on a plan)
   - Check off completed tasks, remove irrelevant ones, add discovered sub-tasks
   - Update Session State (timestamp, current task, next step, context notes)
   - Update Technical Context with new learnings
   - Update Risks / Open Questions
3. **Append a `progress` entry** to your `claims/{role}.jsonl`
4. **Report discoveries** — Any out-of-scope work? Run `/report` first.

### If you're done with the work item:

5. **Verify Done Criteria** (plans) or `done_when` (tasks) — Is EACH one satisfied?
   - If NO: get back to work
   - If YES: continue
6. **Append a `complete` entry** to your `claims/{role}.jsonl` with summary
7. **Shut down teammates** — If you spawned an Agent Team, shut them all down. Verify their work.
8. **Tell Queen** — "[item_id] complete" with 1-sentence summary

**Bees: Do NOT edit work.jsonl.** If you're a Bee, you're done here.

---

## Queen Only — Hive Coordination

9. **Consolidate status** — Read `claims/*.jsonl` for all agents
    - Update `work.jsonl` assigned/status to match agent claim states
    - Check for stale claims (last entry > 24h with no progress)
    - Move `"status":"done"` items from work.jsonl to archive.jsonl
10. **Process inbox** — Read `inbox.jsonl` for `"status":"pending"` entries
    - For each: APPROVE (create work item) | REJECT | DEFER | DUPLICATE
    - Update the inbox entry's status and resolution fields
11. **Review work.jsonl** — Any inconsistencies?
    - Items showing `"status":"ready"` but already claimed?
    - Items showing `"status":"working"` but agent shows complete?
12. **Summarize** — Report: active work, ready items, blockers

If running /buzz mid-task: append a `progress` note first, do coordination, then resume.

---

## Permitted plan edits during /buzz

- Tasks (checkboxes, add/remove)
- Session State
- Technical Context
- Risks / Open Questions

## Never edit during /buzz

- Objective
- Done Criteria (flag to Queen via `/report` if these need changes)

**Run /buzz at least once per session.**
