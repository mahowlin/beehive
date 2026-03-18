# Commands

Slash commands for agents. Copied to `.claude/commands/` on `beehive --init`.

## Files

| Command | Primary | Purpose |
|---------|---------|---------|
| `/buzz` | Any | Check in: plan hygiene, self-check, completion. Queen also coordinates hive. |
| `/report` | Any | Submit out-of-scope discoveries to inbox.jsonl |
| `/bedtime` | Any | Save state to claims file before break or session end |
| `/session-report` | Queen | Write end-of-session report to sessions.jsonl |
| `/deep-plan` | Queen | Structured exploration before plan creation |
| `/review` | Queen | Strategic project assessment |

## Customization

Edit `.claude/commands/` in your project to customize behavior for that project only.
