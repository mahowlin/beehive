# Beehive Development Guide

## What is Beehive?

Multi-agent orchestration tool for Claude Code. Launches 3-5 worker agents + 1 orchestrator in tmux panes. Users direct agents interactively (not autonomous). Coordination via [beads](https://github.com/steveyegge/beads) (`bd` CLI) — a distributed issue tracker backed by Dolt.

## Code Structure

```
beehive              # Main script (~1200 lines bash)
├── Helpers          # die(), warn(), info(), success(), require_jq(), require_bd()
├── Config           # load_config() - parses .beehive.conf safely
├── Detection        # detect_clipboard(), find_claude(), detect_mode()
├── Init             # do_init(), init_beads_metadata(), init_repo(), init_workspace()
├── Upgrade          # do_upgrade(), _migrate_markdown_to_beads()
├── Status           # do_status() - wraps bd list/ready
├── Validate         # do_validate() - bd doctor + session metadata log check
├── Launch           # do_launch() - tmux session setup with BD_ACTOR per pane
└── Main             # Argument parsing, dispatch

skills/              # Agent behavior rules
├── bee.md           # Bee workflow (bd ready → claim → execute → close)
└── queen.md         # Queen coordination (bd create, list, close, verify)

commands/            # Slash commands for agents
├── buzz.md          # Check-in and coordination
├── report.md        # Out-of-scope discovery → bd create + bd dep relate
├── bedtime.md       # Save state via bd comments add
├── session-report.md # End-of-session → session metadata log
├── deep-plan.md     # Structured exploration before planning
└── review.md        # Strategic project assessment

templates/           # Project scaffolding
├── plan.md          # Plan template (<1KB)
├── master-plan.md   # Multi-deliverable grouping doc
└── gitignore        # Default .gitignore entries
```

## Design Principles

1. **Interactive, not autonomous** - User directs agents, approves steps
2. **Beads-backed coordination** - All task state in `.beads/` via `bd` CLI
3. **No write conflicts** - Atomic claims (`bd update --claim`), Dolt transactions
4. **Minimal dependencies** - bash + tmux + claude CLI + jq + bd
5. **Structured over fragile** - SQL-backed state tracking, markdown for plan content

## Coordination Architecture

```
Agents (tmux panes)  ──→  bd CLI  ──→  .beads/ (Dolt database)
                                        ├── Issues (tasks, epics, bugs)
                                        ├── Dependencies
                                        ├── Comments
                                        └── Audit trail

plans/_meta/
└── session metadata log   # Session reports (beehive-specific, not in beads)
```

Key `bd` commands used by agents:
- `bd ready` — find available work (unblocked, unassigned)
- `bd update <id> --claim` — atomically claim (sets assignee + in_progress)
- `bd close <id>` — mark complete
- `bd create "title" --type epic|task|bug` — create work
- `bd comments add <id> "note"` — progress/checkpoint notes
- `bd dep add <issue> <depends-on>` — set dependencies
- `bd list --json` — full state for status display
- `bd prime` — AI-optimized workflow context (injected via hooks)

## Safe bd Mutations

- Treat `bd update`, `bd close`, and other write operations as coordination-state changes
- Before any bulk mutation, test the exact command on one issue and verify with `bd show`
- If correct, expand to a small batch and verify again before any full rollout
- For description content loaded from a file, use `bd update <id> --body-file <path>`
- Do not assume `--description @file` dereferences file content
- Do not batch-close or batch-update issues you have not individually verified
- If a mutation fails unexpectedly, stop and verify state before continuing


## Bash Conventions

- `set -e` at top (fail fast)
- Functions use `local` for variables
- Config parsing without `source` (security)
- Colors via escape codes (RED, GREEN, YELLOW, CYAN, NC)
- Helper functions: `die()`, `warn()`, `info()`, `success()`
- jq required at startup (hard fail if missing)
- bd v0.61.0+ required at startup (hard fail with install instructions)

## Testing Changes

```bash
# Test init (single repo)
mkdir /tmp/test-repo && cd /tmp/test-repo
git init
/path/to/beehive --init
ls .beads/        # Should exist (Dolt database)
ls plans/_meta/   # Should have session metadata log

# Test init (workspace)
mkdir /tmp/test-ws && cd /tmp/test-ws
mkdir repo-a repo-b
git -C repo-a init && git -C repo-b init
/path/to/beehive --init
ls -la  # Should have CLAUDE.md, plans/, .beads/

# Test status
beehive --status  # Should show work items from bd list, ready queue

# Test upgrade (with legacy markdown migration)
beehive --upgrade  # Migrates old TRACKER.md/.hive files to beads if present

# Test launch (will open tmux)
beehive --yes  # Skip confirmation

# Test config loading
echo "CONF_SESSION=test-session" > .beehive.conf
beehive --yes  # Should use "test-session" as tmux session name

# Test model overrides
echo -e "CONF_MODEL_BEE=test-bee\nCONF_MODEL_QUEEN=test-queen" > .beehive.conf
beehive --yes  # Should show "Bee model: test-bee" and "Queen model: test-queen"
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `load_config()` | Parse .beehive.conf without sourcing (stores as CONF_* prefix) |
| `resolve_setting()` | 4-tier precedence: role CLI → global CLI → role config → global config |
| `require_bd()` | Check bd CLI exists and version >= 0.61.0 |
| `build_pane_command()` | Assemble per-pane shell command with env vars, model, BD_ACTOR via printf %q |
| `detect_mode()` | Determine workspace vs single repo |
| `init_beads_metadata()` | Create plans/_meta/session metadata log + run bd init |
| `init_repo()` | Create CLAUDE.md, plans/, beads database |
| `init_workspace()` | Create CLAUDE.md (with repo table) + per-repo CLAUDE.md |
| `do_upgrade()` | Update skills, commands, template; migrate legacy markdown tracking → beads; supports --dry-run |
| `_migrate_markdown_to_beads()` | Parse old TRACKER.md directly into beads issues and archive legacy files |
| `do_status()` | Display issues, agents, ready queue from bd list/ready; supports --json |
| `do_validate()` | Run bd doctor + validate session metadata log |
| `do_launch()` | Set up tmux session with N+1 panes, set BD_ACTOR per pane |

## Tmux Layout

Default (3 bees):
```
┌──────────┬──────────┐
│ Bee 1    │ Bee 2    │  (panes 0, 1)
├──────────┼──────────┤
│ Bee 3    │ Queen    │  (panes 2, 3)
└──────────┴──────────┘
```

With `--bees 5` (6 agents, 3x2 grid):
```
┌──────────┬──────────┬──────────┐
│ Bee 1    │ Bee 2    │ Bee 3    │
├──────────┼──────────┼──────────┤
│ Bee 4    │ Bee 5    │ Queen    │
└──────────┴──────────┴──────────┘
```

Created with: dynamic pane creation loop + `select-layout tiled` (works for any pane count)

## Adding Features

1. Check if it aligns with design principles (interactive, minimal)
2. Update the bash script
3. Update README.md if user-facing
4. Update skills/commands docs if coordination behavior changes

## Common Tasks

- **Add CLI flag**: Update `main()` case statement + `usage()`
- **Change prompts**: Edit `bee_prompt` / `queen_prompt` in `do_launch()`
- **Add config option**: Update `load_config()` case statement
- **Change layout**: Modify tmux commands in `do_launch()` (dynamic pane count via `num_bees`)
- **Upgrade existing projects**: `beehive --upgrade` (overwrites skills/commands/template, migrates to beads)

## Version

Current: v0.5.0 (see `VERSION` variable at top of script)
