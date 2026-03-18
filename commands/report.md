# /report - Report Out-of-Scope Work

**When NOT to use:** For status updates (use your claims file instead).

Append to `plans/_meta/inbox.jsonl`:

```json
{"from":"bee-1","issue":"Login page has no rate limiting","scope":"Add rate limiting to POST /login","urgency":"Soon","found_in":"P-001","status":"pending","ts":"2026-01-20T15:00:00Z"}
```

**Fields:**
- `from` — your agent id (bee-1, bee-2, bee-3, queen)
- `issue` — one sentence description
- `scope` — what should be done
- `urgency` — `Blocking` | `Soon` | `Debt`
- `found_in` — work item id or context where you discovered it
- `status` — always `"pending"` (Queen will process)
- `ts` — current ISO 8601 timestamp

Then continue your current work. **Do not act on this issue.**
