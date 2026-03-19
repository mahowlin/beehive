# Beehive Development Guide

## What is Beehive?

Multi-agent orchestration tool for Claude Code. Launches 3 worker agents + 1 orchestrator in tmux panes. Users direct agents interactively (not autonomous).

## Code Structure

```
beehive              # Main script (~1150 lines bash)
├── Helpers          # die(), warn(), info(), success()
├── Config           # load_config() - parses .beehive.conf safely
├── Detection        # detect_clipboard(), find_claude(), detect_mode()
├── Init             # do_init(), init_jsonl(), init_repo(), init_workspace()
├── Upgrade          # do_upgrade(), _migrate_markdown()
├── Status           # do_status() - JSONL-based project status
├── Launch           # do_launch() - tmux session setup
└── Main             # Argument parsing, dispatch

skills/              # Agent behavior rules
├── bee.md           # Bee claim workflow (JSONL)
└── queen.md         # Queen coordination (owns work.jsonl)

commands/            # Slash commands for agents
├── buzz.md          # Check-in and coordination
├── report.md        # Out-of-scope discovery → inbox.jsonl
├── bedtime.md       # Save state to claims file
├── session-report.md # End-of-session → sessions.jsonl
├── deep-plan.md     # Structured exploration before planning
└── review.md        # Strategic project assessment

templates/           # Project scaffolding
├── plan.md          # Plan template (<1KB)
├── master-plan.md   # Multi-deliverable grouping doc
├── schemas.md       # JSONL schema reference for agents
└── gitignore        # Default .gitignore entries
```

## Design Principles

1. **Interactive, not autonomous** - User directs agents, approves steps
2. **File-based coordination** - JSONL state files + markdown plan content
3. **No write conflicts** - Each agent owns specific files (Queen → work.jsonl, Bee N → claims/bee-N.jsonl)
4. **Minimal dependencies** - bash + tmux + claude CLI + jq
5. **Structured over fragile** - JSONL for state tracking, markdown for plan content

## Coordination Files (plans/_meta/)

```
plans/_meta/
├── work.jsonl       # Work items — plans and tasks (Queen owns)
├── inbox.jsonl      # Out-of-scope reports (Bees append, Queen processes)
├── sessions.jsonl   # Session reports (Queen owns)
├── archive.jsonl    # Completed/archived work items
└── claims/          # Agent state (gitignored)
    ├── bee-{1,2,3}.jsonl
    └── queen.jsonl
```

See `templates/schemas.md` for full JSONL schema documentation.

## Bash Conventions

- `set -e` at top (fail fast)
- Functions use `local` for variables
- Config parsing without `source` (security)
- Colors via escape codes (RED, GREEN, YELLOW, CYAN, NC)
- Helper functions: `die()`, `warn()`, `info()`, `success()`
- jq required at startup (hard fail if missing)

## Testing Changes

```bash
# Test init (single repo)
mkdir /tmp/test-repo && cd /tmp/test-repo
git init
/path/to/beehive --init
ls plans/_meta/  # Should have work.jsonl, inbox.jsonl, sessions.jsonl, archive.jsonl, claims/

# Test init (workspace)
mkdir /tmp/test-ws && cd /tmp/test-ws
mkdir repo-a repo-b
git -C repo-a init && git -C repo-b init
/path/to/beehive --init
ls -la  # Should have CLAUDE.md, plans/, plans/_meta/

# Test status
beehive --status  # Should show work items, agent states, inbox

# Test upgrade (with markdown migration)
beehive --upgrade  # Migrates old TRACKER.md/.hive/ → JSONL if present

# Test launch (will open tmux)
beehive --yes  # Skip confirmation

# Test config loading
echo "CONF_SESSION=test-session" > .beehive.conf
beehive --yes  # Should use "test-session" as tmux session name

# Test model overrides
echo -e "CONF_MODEL_BEE=test-bee\nCONF_MODEL_QUEEN=test-queen" > .beehive.conf
beehive --yes  # Should show "Bee model: test-bee" and "Queen model: test-queen"

# Test CLI model precedence
beehive --bee-model cli-bee --yes  # CLI overrides config
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `load_config()` | Parse .beehive.conf without sourcing (stores as CONF_* prefix) |
| `resolve_setting()` | 4-tier precedence: role CLI → global CLI → role config → global config |
| `build_pane_command()` | Assemble per-pane shell command with env vars and model via printf %q |
| `detect_mode()` | Determine workspace vs single repo |
| `init_jsonl()` | Create plans/_meta/ JSONL files and claims/ |
| `init_repo()` | Create CLAUDE.md, plans/, JSONL state files |
| `init_workspace()` | Create CLAUDE.md (with repo table) + per-repo CLAUDE.md |
| `do_upgrade()` | Update skills, commands, template; migrate markdown → JSONL; supports --dry-run |
| `_migrate_markdown()` | Parse old TRACKER.md/.hive/ into JSONL; writes migration-report.md |
| `do_status()` | Display work items, agent states, inbox from JSONL; supports --json |
| `do_validate()` | Validate all JSONL files for schema correctness and cross-references |
| `do_launch()` | Set up tmux session with 4 panes |

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
- **Upgrade existing projects**: `beehive --upgrade` (overwrites skills/commands/template, migrates markdown)

## Version

Current: v0.5.0 (see `VERSION` variable at top of script)
