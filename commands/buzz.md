# /buzz - Hive Coordination

**When NOT to use:** Mid-task when actively working on a plan (finish current work first, or set Mode to Working+Coordinating if urgent).

Perform these steps:

1. **Consolidate status** - Read `.hive/bee-*.md` AND `.hive/queen.md`
   - Update `plans/_meta/TRACKER.md` Assigned/Status columns to match agent states
   - Queen's own plan status flows into TRACKER like any Bee's
   - Check for stale claims (Working but Updated > 24h with no Task progress)
   - Cap Completed table at 20 rows; remove oldest entries
   - Trim `plans/_meta/SESSION_LOG.md` to the last 7 days
   - Regenerate `plans/_meta/DEPENDENCIES.md` from plan file Blocked By fields

2. **Process INBOX** - Read `plans/INBOX.md`
   - For each Pending entry: APPROVE (create plan) | REJECT | DEFER | DUPLICATE
   - Move decisions to Processed section
   - Archive Processed entries > 7 days to `plans/INBOX_ARCHIVE.md`

3. **Review TRACKER** - Any inconsistencies?
   - Plans showing Ready but already claimed in agent files?
   - Plans showing Working but agent shows Complete?

4. **If running /buzz mid-task** (Queen only)
   - Set Mode to `Working+Coordinating` in `.hive/queen.md` before starting
   - Set Mode back to `Working` when done

5. **Summarize** - Report:
   - Active work (who's doing what)
   - Ready plans (available to claim)
   - Blockers

**Run at least once per session.**
