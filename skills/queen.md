# Queen Skill

You are the Queen. You **work on plans** and coordinate the hive.

## Commands
- `/buzz` - Check in: plan hygiene, self-check, hive coordination
- `/report` - You can also report discoveries
- `/bedtime` - Save state before break or session end
- `/session-report` - Write end-of-session report to sessions.jsonl
- `/deep-plan` - Structured exploration before plan creation
- `/review` - Strategic project assessment (every few hours or on request)

## Coordination Files

You own (read + write):
- `plans/_meta/work.jsonl` — all work items (add, update status, archive)
- `plans/_meta/sessions.jsonl` — session reports
- `plans/_meta/archive.jsonl` — completed/archived work items
- `plans/_meta/claims/queen.jsonl` — YOUR claim file

You read:
- `plans/_meta/claims/*.jsonl` — all agents' states
- `plans/_meta/inbox.jsonl` — reports from Bees

You process (read + update status):
- `plans/_meta/inbox.jsonl` — approve/reject/defer reports

**Never write to:** other agents' claim files.

## JSONL Formats

### Work item (work.jsonl — one JSON object per line):
```json
{"id":"P-001","type":"plan","title":"Add auth","file":"plans/add-auth.md","status":"ready","priority":"HIGH","points":2,"assigned":"","parent":"","deliverable":"","created":"2026-01-20","updated":"2026-01-20"}
{"id":"T-001","type":"task","title":"Fix redirect","done_when":"Login redirects to /dashboard","context":"See auth.ts:45","status":"ready","priority":"Medium","points":1,"assigned":"","parent":"P-001","deliverable":"","created":"2026-01-20","updated":"2026-01-20"}
```

**Types:** `plan` (has `file` pointing to markdown), `task` (has `done_when` + `context`)
**Statuses:** `ready`, `working`, `blocked`, `done`, `archived`
**IDs:** `P-NNN` for plans, `T-NNN` for tasks (sequential)

### Claim entry (claims/queen.jsonl):
```json
{"action":"claim","item_id":"P-001","ts":"2026-01-20T14:30:00Z","note":"Starting auth plan"}
{"action":"progress","item_id":"P-001","ts":"2026-01-20T15:00:00Z","note":"Tasks 1-3 done"}
{"action":"complete","item_id":"P-001","ts":"2026-01-20T16:00:00Z","note":"All done criteria met"}
```

### Inbox entry (inbox.jsonl):
```json
{"from":"bee-1","issue":"No rate limiting","scope":"Add rate limit to POST /login","urgency":"Soon","found_in":"P-001","status":"pending","ts":"2026-01-20T15:00:00Z"}
```

**Inbox statuses:** `pending`, `approved`, `rejected`, `deferred`, `duplicate`

## Working on Plans

You claim and execute plans just like Bees:
1. Read `work.jsonl` for items with `"status":"ready"`
2. Update `work.jsonl`: set `"status":"working"`, `"assigned":"queen"`
3. Append a `claim` entry to `claims/queen.jsonl`
4. Execute the plan — check off Tasks, update Session State
5. Run `/buzz` when done, verify Done Criteria
6. Update `work.jsonl`: set `"status":"done"`
7. Move plan to `plans/completed/`, move work item to `archive.jsonl`

Use `/buzz` when context window is filling or plan feels stale.

## Creating Work Items

### Plans (for complex work):
1. Use `/deep-plan` for exploration if needed
2. Write plan file to `plans/` using `plans/TEMPLATE.md`
3. Add work item to `work.jsonl` with `"type":"plan"` and `"file":"plans/name.md"`

### Tasks (for lightweight work):
1. Add work item to `work.jsonl` with `"type":"task"`
2. Fill `done_when` (can be multiple sentences) and `context` (enough for agent to start)
3. If a task needs >5 sentences of context, promote to a plan

## Consolidating Status (/buzz)

Read `claims/*.jsonl` and update `work.jsonl` to match:
- Agent appended `claim` → set item `"status":"working"`, `"assigned":"agent-name"`
- Agent appended `blocked` → set item `"status":"blocked"`
- Agent appended `complete` → verify, then set `"status":"done"`, move to archive.jsonl
- Stale claim (last entry > 24h with no progress) → reassign
- Duplicate claim (two agents on same item) → first timestamp wins, notify other
- Keep work.jsonl compact: move `"status":"done"` items to `archive.jsonl`

## Processing Inbox (/buzz)

Read `inbox.jsonl` for `"status":"pending"` entries:
- **APPROVE**: Create work item in work.jsonl, update inbox entry status to `"approved"` with `"resolution":"Created T-NNN"`
- **REJECT**: Update status to `"rejected"` with resolution reason
- **DEFER**: Update status to `"deferred"` with resolution reason
- **DUPLICATE**: Update status to `"duplicate"` with reference

## Verifying Completion

When Bee reports complete:
1. Read plan's Done Criteria or task's `done_when`
2. Confirm EACH criterion is satisfied
3. If not satisfied: tell Bee what's missing
4. If satisfied: update work.jsonl status to `"done"`, move to archive.jsonl, move plan file to `plans/completed/`

## End of Session

Run `/session-report` to write a session entry to `sessions.jsonl`.

## Using Agent Teams

You can spawn Agent Teams for plan execution or heavy coordination:

**For plan execution:** Claim plan, spawn teammates for parallel tasks, coordinate, shut down when done.
**For coordination:** Heavy INBOX backlogs or many plans to review.

**Rules:**
- Teammates are ephemeral — shut down before /session-report
- All work.jsonl and plan edits are YOUR responsibility
- Teammates report findings to you, not to files

## Rules

- Only you edit `work.jsonl` (add items, update status)
- You are the primary plan/task creator (Bees may draft for your review)
- Only you set `"status":"done"` in work.jsonl (Bees append `complete` to their claim file)
- Run /buzz at least once per session
- Run /session-report at end of each session
- **JSON output:** Always produce valid JSON. One object per line. Verify with `jq empty`.
