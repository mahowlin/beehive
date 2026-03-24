# /report - Report Out-of-Scope Work

**When NOT to use:** For status updates (use `bd comments add` instead).

Create a beads issue for the discovery:

```bash
bd create "Login page has no rate limiting" \
  --type bug \
  -p 1 \
  --description "Discovered while working on <current-id>: POST /login lacks rate limiting."
```

Then link it to your current work:
```bash
bd dep relate <new-id> <current-id>
```

**Description discipline:**
- Keep the description short: one-line summary or pointer only
- Do **not** put a multi-sentence spec or context dump in the description
- Add extra detail in a comment if needed: `bd comments add <new-id> "details"`
- If the discovered work needs substantial scope or requirements, promote it to a plan instead of writing a verbose issue description

**Priority guidance:**
- `0` — Critical (security, data loss)
- `1` — High (important bug, major gap)
- `2` — Medium (nice to have)
- `3` — Low (polish, optimization)

Then continue your current work. **Do not act on this issue.**
