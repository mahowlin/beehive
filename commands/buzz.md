# /buzz - Check In

Check yourself. Check your plan. If you're Queen, check the hive.

## All Agents — Self-Check & Plan Hygiene

1. **Re-read your plan** — Are you following it?
2. **Update your plan file**
   - Check off completed tasks, remove irrelevant ones, add discovered sub-tasks
   - Update Session State (timestamp, current task, next step, context notes)
   - Update Technical Context with new learnings
   - Update Risks / Open Questions
3. **Check your status file** — Is `.hive/bee-N.md` (or `.hive/queen.md`) up to date?
4. **Report discoveries** — Any out-of-scope work? Run `/report` first.

### If you're done with the plan:

5. **Verify Done Criteria** — Is EACH one satisfied?
   - If NO: get back to work
   - If YES: continue
6. **Fill Completion Summary** — Achieved, Resume Notes (blank if complete)
7. **Update status file** — Set Status: Complete
8. **Shut down teammates** — If you spawned an Agent Team, shut them all down. Verify their work is committed and correct.
9. **Tell Queen** — "[plan] complete" with 1-sentence summary

**Bees: Do NOT edit TRACKER.md.** If you're a Bee, you're done here.

---

## Queen Only — Hive Coordination

10. **Consolidate status** — Read `.hive/bee-*.md` AND `.hive/queen.md`
    - Update TRACKER Assigned/Status columns to match agent states
    - Check for stale claims (Working but Updated > 24h with no Task progress)
    - Cap Completed table at 20 rows; remove oldest entries
    - Trim SESSION_LOG.md to last 7 days
    - Regenerate DEPENDENCIES.md from plan Blocked By fields
11. **Process INBOX** — Read `plans/INBOX.md`
    - For each Pending entry: APPROVE (create plan) | REJECT | DEFER | DUPLICATE
    - Archive Processed entries > 7 days to INBOX_ARCHIVE.md
12. **Review TRACKER** — Any inconsistencies?
    - Plans showing Ready but already claimed?
    - Plans showing Working but agent shows Complete?
13. **Summarize** — Report: active work, ready plans, blockers

If running /buzz mid-task: set Mode to `Working+Coordinating`, run buzz, set back to `Working`.

---

## Permitted plan edits during /buzz

- Tasks (checkboxes, add/remove)
- Session State
- Technical Context
- Risks / Open Questions
- Completion Summary

## Never edit during /buzz

- Objective
- Why This Approach
- Implementation Strategy
- Done Criteria (flag to Queen via `/report` if these need changes)

**Run /buzz at least once per session.**
