# /session-report - Queen End-of-Session Report

Queen command. Write a dated section to `plans/_meta/SESSION_LOG.md`.

Perform these steps:

1. **Gather state** — Read `.hive/bee-*.md`, `.hive/queen.md`, `plans/_meta/TRACKER.md`, `plans/INBOX.md`

2. **Write a new dated section** at the top of `plans/_meta/SESSION_LOG.md` (below the `# Session Log` heading):

```markdown
## YYYY-MM-DD (Queen Session)

### Summary
[1-2 sentences: what happened this session]

### Hive Status
| Bee | Plan | Status | Last Updated | Notes |
|-----|------|--------|-------------|-------|
| Bee 1 | [plan or -] | [status] | [timestamp] | [notes] |
| Bee 2 | [plan or -] | [status] | [timestamp] | [notes] |
| Bee 3 | [plan or -] | [status] | [timestamp] | [notes] |
| Queen | [plan or -] | [status] | [timestamp] | [notes] |

### TRACKER Changes
- [Plans added, status changes, completions]

### Key Discoveries
- [Notable findings from Bees or Queen]

### INBOX Processed
- [Approved/rejected/deferred items and reasons]

### Blockers
- [Current blockers across the hive]

### Ready Plans
- [Plans available for assignment next session]

### User Actions Required
- [Decisions needed, approvals pending]

### Resume Prompt
[Instructions for cold-starting the next session: what to read, what's in progress, what to do first]
```

3. **Trim old entries** — Keep only the last 7 days of session logs

4. **Update your status file** (`.hive/queen.md`)
   - Update Last /session-report timestamp
   - Add session notes

5. **Confirm** — Tell the user the session report has been written
