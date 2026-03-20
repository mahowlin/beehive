# /session-report - Queen End-of-Session Report

Queen command. Append a session-metadata entry to `plans/_meta/sessions.jsonl`.

Perform these steps:

1. **Gather state** — Run `bd list --json --all` to get full project state

2. **Append a session-metadata entry** to `plans/_meta/sessions.jsonl` (this is not coordination state):

```json
{"date":"2026-01-20","summary":"Completed auth plan, started API refactor","agents":{"bee-1":{"item":"bd-a1b2","status":"complete"},"bee-2":{"item":"bd-c3d4","status":"in_progress"},"bee-3":{"item":"","status":"idle"},"queen":{"item":"bd-e5f6","status":"in_progress"}},"changes":["bd-a1b2 closed","bd-e5f6 started","bd-c3d4 assigned to bee-2"],"blockers":[],"ready_count":2,"resume":"Queen working on bd-e5f6 task 2. Bee-2 on bd-c3d4. 2 ready items available.","ts":"2026-01-20T18:00:00Z"}
```

**Fields:**
- `date` — session date
- `summary` — 1-2 sentences of what happened
- `agents` — object with each active agent's current item and status (include all agents in the session, e.g. bee-1..bee-N + queen)
- `changes` — array of notable changes this session
- `blockers` — array of current blockers (empty if none)
- `ready_count` — number of items shown by `bd ready`
- `resume` — cold-start instructions for next session
- `ts` — ISO 8601 timestamp

3. **Confirm** — Tell the user the session report has been written
