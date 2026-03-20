# /buzz - Check In

Check yourself. Check your plan. If you're Queen, check the hive.

## All Agents — Self-Check & Plan Hygiene

1. **Re-read your plan or task** — Are you following it?
2. **Update your plan file** (if working on a plan)
   - Check off completed tasks, remove irrelevant ones, add discovered sub-tasks
   - Update Session State (timestamp, current task, next step, context notes)
   - Update Technical Context with new learnings
3. **Add a progress comment** to your beads issue:
   ```bash
   bd comments add <id> "Tasks 1-3 done. Working on task 4."
   ```
4. **Report discoveries** — Any out-of-scope work? Run `/report` first.

### If you're done with the work item:

5. **Verify Done Criteria** (plans) or acceptance criteria (tasks) — Is EACH one satisfied?
   - If NO: get back to work
   - If YES: continue
6. **Close the issue**: `bd close <id> --reason "All done criteria met"`
7. **Shut down teammates** — If you spawned an Agent Team, shut them all down. Verify their work.
8. **Tell Queen** — "[id] complete" with 1-sentence summary

**Bees: you're done here after closing your issue.**

---

## Queen Only — Hive Coordination

9. **Check agent progress:**
   ```bash
   bd list --status in_progress         # See what's being worked on
   bd blocked                           # Check for blocked issues
   ```
   - Check for stale work (no progress comments in >24h)
   - Check for issues stuck in `in_progress` with no recent activity
10. **Triage ready work:**
    ```bash
    bd ready                            # Unblocked, unassigned work
    bd list --no-assignee               # All unassigned issues
    ```
    - Assign to agents or flag for beekeeper
11. **Review overall state** — Any inconsistencies?
    - Issues in `in_progress` but agent not actually working?
    - Duplicate or overlapping work?
12. **Summarize** — Report: active work, ready items, blockers

If running /buzz mid-task: add a progress comment first, do coordination, then resume.

---

## Permitted plan edits during /buzz

- Tasks (checkboxes, add/remove)
- Session State
- Technical Context

## Never edit during /buzz

- Objective
- Done Criteria (flag to Queen via `/report` if these need changes)

**Run /buzz at least once per session.**
