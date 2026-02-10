# Commands

Slash commands for agents. Copied to `.claude/commands/` on `beehive --init`.

## Files

| Command | Primary | Purpose |
|---------|---------|---------|
| `/sting` | Bees | Self-check: on track? status updated? done? |
| `/buzz` | Queen | Consolidate status, process INBOX |
| `/report` | Any | Submit out-of-scope discoveries to INBOX |
| `/bedtime` | Any | Save status and plan state before break or session end |
| `/refresh` | Any | Mid-session plan hygiene (update tasks, context, session state) |
| `/session-report` | Queen | Write end-of-session report to SESSION_LOG.md |
| `/deep-plan` | Queen | Structured exploration before plan creation |

## Customization

Edit `.claude/commands/` in your project to customize behavior for that project only.
