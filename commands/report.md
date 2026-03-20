# /report - Report Out-of-Scope Work

**When NOT to use:** For status updates (use `bd comments add` instead).

Create a beads issue for the discovery:

```bash
bd create "Login page has no rate limiting" \
  --type bug \
  -p 1 \
  --description "Discovered while working on <current-id>: POST /login has no rate limiting. Should add rate limiting middleware."
```

Then link it to your current work:
```bash
bd dep relate <new-id> <current-id>
```

**Fields to include in the description:**
- What you discovered
- Where you found it (which issue/file/context)
- Suggested scope of the fix

**Priority guidance:**
- `0` — Critical (security, data loss)
- `1` — High (important bug, major gap)
- `2` — Medium (nice to have)
- `3` — Low (polish, optimization)

Then continue your current work. **Do not act on this issue.**
