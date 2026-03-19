# /session-report - Queen End-of-Session Report

Queen command. Append a session entry to `plans/_meta/sessions.jsonl`.

Perform these steps:

1. **Gather state** — Read `plans/_meta/claims/*.jsonl`, `plans/_meta/work.jsonl`, `plans/_meta/inbox.jsonl`

2. **Append a session entry** to `plans/_meta/sessions.jsonl`:

```json
{"date":"2026-01-20","summary":"Completed auth plan, started API refactor","agents":{"bee-1":{"item":"P-001","status":"complete"},"bee-2":{"item":"T-005","status":"working"},"bee-3":{"item":"","status":"idle"},"queen":{"item":"P-002","status":"working"}},"changes":["P-001 done","P-002 started","T-005 assigned to bee-2"],"blockers":[],"ready_items":["T-006","T-007"],"resume":"Queen working on P-002 task 2. Bee-2 on T-005. Assign T-006/T-007 to free agents.","ts":"2026-01-20T18:00:00Z"}
```

**Fields:**
- `date` — session date
- `summary` — 1-2 sentences of what happened
- `agents` — object with each active agent's current item and status (include all agents in the session, e.g. bee-1..bee-N + queen)
- `changes` — array of notable changes this session
- `blockers` — array of current blockers (empty if none)
- `ready_items` — array of unassigned work item ids
- `resume` — cold-start instructions for next session
- `ts` — ISO 8601 timestamp

3. **Append a `checkpoint` entry** to your `claims/queen.jsonl` with session notes

4. **Confirm** — Tell the user the session report has been written
