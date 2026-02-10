# /bedtime - Save Status Before Break

Save your current state. Use anytime:
- Mid-task (preserve progress before connection drops)
- End of session (clean handoff)
- Before rebasing on the plan (save state, then re-read plan)

Applies to both Bees and Queen.

Perform these steps:

1. **Update your plan file** (if working on one)
   - Check off completed tasks
   - Update **Session State**: current task, next step, context notes, timestamp
   - Prune stale data from Technical Context / Notes

   **Permitted plan edits:** Task checkboxes, Session State, Completion Summary.

2. **Update your status file** (`.hive/bee-N.md` or `.hive/queen.md`)
   - Set Status to `Ready` if between tasks, or `Working` if mid-task
   - Update the `Updated:` timestamp
   - Add notes about current progress in the Notes section

3. **If mid-task**, document in Notes:
   - What you were working on
   - Next step to resume
   - Any context that would help you (or another agent) pick up later

4. **Verify resumability** — "Could a fresh agent pick this up cold?"

5. **Confirm** — Tell the user your state has been saved

**Example plan Session State update:**
```markdown
## Session State

**Last Updated:** 2026-01-21 14:30
**Current Task:** Task 4 — JWT validation
**Next Step:** Add token refresh logic in auth.ts:45
**Context Notes:** Tasks 1-3 complete. Using RS256 per project conventions.
```

**Example status file update:**
```markdown
## Current
**Plan:** plans/add-auth.md
**Status:** Working
**Started:** 2026-01-20
**Updated:** 2026-01-21

## Notes
- Completed Tasks 1-3
- Currently on Task 4: implementing JWT validation
- Next: Add token refresh logic in auth.ts:45
```
