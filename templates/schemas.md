# JSONL Schemas

Reference doc for agents. All coordination state is JSONL — one JSON object per line.

## work.jsonl — Work Items (Queen-owned)

```json
{"id":"P-001","type":"plan","title":"Add auth","file":"plans/add-auth.md","status":"ready","priority":"HIGH","points":2,"assigned":"","parent":"","deliverable":"","created":"2026-01-20","updated":"2026-01-20"}
{"id":"T-001","type":"task","title":"Fix login redirect","done_when":"Login redirects to /dashboard after successful auth","context":"The redirect currently goes to / instead of /dashboard. See src/auth.ts:45","status":"ready","priority":"Medium","points":1,"assigned":"","parent":"P-001","deliverable":"","created":"2026-01-20","updated":"2026-01-20"}
```

| Field | Required | Values | Notes |
|-------|----------|--------|-------|
| `id` | yes | `P-NNN` (plan) or `T-NNN` (task) | Queen assigns, sequential |
| `type` | yes | `plan`, `task` | |
| `title` | yes | string | Short description |
| `file` | plan only | path | Relative path to plan markdown |
| `done_when` | task only | string | Can be multiple sentences |
| `context` | task only | string | Enough for agent to start. If >5 sentences, promote to plan |
| `status` | yes | `ready`, `working`, `blocked`, `done`, `archived` | |
| `priority` | yes | `HIGH`, `Medium`, `Low` | |
| `points` | yes | `1`, `2`, `3` | 1=Small, 2=Medium, 3=Large |
| `assigned` | yes | `""`, `bee-1`, `bee-2`, `bee-3`, `queen` | Empty = unassigned |
| `parent` | no | `""` or parent id | Links task→plan or plan→master-plan |
| `deliverable` | no | `""` or string | From master plan deliverable registry |
| `created` | yes | `YYYY-MM-DD` | |
| `updated` | yes | `YYYY-MM-DD` | |

## claims/{agent}.jsonl — Agent State (each agent owns their own)

```json
{"action":"claim","item_id":"P-001","ts":"2026-01-20T14:30:00Z","note":"Starting auth plan"}
{"action":"progress","item_id":"P-001","ts":"2026-01-20T15:00:00Z","note":"Tasks 1-3 done, starting task 4"}
{"action":"blocked","item_id":"P-001","ts":"2026-01-20T15:30:00Z","note":"Need DB migration approval","blocker":"waiting on user"}
{"action":"complete","item_id":"P-001","ts":"2026-01-20T16:00:00Z","note":"All done criteria met"}
{"action":"checkpoint","item_id":"P-001","ts":"2026-01-20T16:30:00Z","note":"Mid-session save. On task 4, next: token refresh logic"}
```

| Field | Required | Values | Notes |
|-------|----------|--------|-------|
| `action` | yes | `claim`, `progress`, `blocked`, `complete`, `checkpoint` | |
| `item_id` | yes | work item id | What they're working on |
| `ts` | yes | ISO 8601 | |
| `note` | yes | string | What happened, what's next |
| `blocker` | blocked only | string | What's blocking |

## inbox.jsonl — Reports (Bees append, Queen processes)

```json
{"from":"bee-1","issue":"Login page has no rate limiting","scope":"Add rate limiting to POST /login","urgency":"Soon","found_in":"P-001","status":"pending","ts":"2026-01-20T15:00:00Z"}
{"from":"bee-2","issue":"Dead code in utils.ts","scope":"Remove unused functions","urgency":"Debt","found_in":"T-003","status":"approved","resolution":"Created T-010","ts":"2026-01-20T14:00:00Z"}
```

| Field | Required | Values | Notes |
|-------|----------|--------|-------|
| `from` | yes | agent id | Who reported |
| `issue` | yes | string | One sentence |
| `scope` | yes | string | What should be done |
| `urgency` | yes | `Blocking`, `Soon`, `Debt` | |
| `found_in` | yes | work item id or context | Where discovered |
| `status` | yes | `pending`, `approved`, `rejected`, `deferred`, `duplicate` | |
| `resolution` | processed only | string | What Queen decided |
| `ts` | yes | ISO 8601 | |

## sessions.jsonl — Session Reports (Queen-owned)

```json
{"date":"2026-01-20","summary":"Completed auth plan, started API refactor","agents":{"bee-1":{"item":"P-001","status":"complete"},"bee-2":{"item":"T-005","status":"working"},"bee-3":{"item":"","status":"ready"},"queen":{"item":"P-002","status":"working"}},"changes":["P-001 Done","P-002 started"],"blockers":[],"ready_items":["T-006","T-007"],"resume":"Queen working on P-002 task 2. Bee-2 on T-005. Assign T-006/T-007 to free agents.","ts":"2026-01-20T18:00:00Z"}
```

| Field | Required | Notes |
|-------|----------|-------|
| `date` | yes | Session date |
| `summary` | yes | 1-2 sentences |
| `agents` | yes | Object with agent states at session end |
| `changes` | yes | Array of notable changes |
| `blockers` | yes | Array of current blockers |
| `ready_items` | yes | Array of unassigned item ids |
| `resume` | yes | Cold-start instructions for next session |
| `ts` | yes | ISO 8601 |

## archive.jsonl — Completed/Archived Work Items

Same schema as work.jsonl. Queen moves items here from work.jsonl when done and verified. Keeps work.jsonl compact.
