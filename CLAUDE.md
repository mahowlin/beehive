# Beehive Development Guide

## What is Beehive?

Multi-agent orchestration tool for Claude Code. Launches 3 worker agents + 1 orchestrator in tmux panes. Users direct agents interactively (not autonomous).

## Code Structure

```
beehive              # Main script (~550 lines bash)
├── Helpers          # die(), warn(), info(), success()
├── Config           # load_config() - parses .beehive.conf safely
├── Detection        # detect_clipboard(), find_claude(), detect_mode()
├── Init             # do_init(), init_repo(), init_workspace()
├── Upgrade          # do_upgrade() - update skills/commands/template
├── Launch           # do_launch() - tmux session setup
└── Main             # Argument parsing, dispatch

README.md            # User documentation
```

## Design Principles

1. **Interactive, not autonomous** - User directs agents, approves steps
2. **File-based coordination** - plans/_meta/TRACKER.md, plans/, CLAUDE.md
3. **No write conflicts** - Each agent owns specific files
4. **Minimal dependencies** - Just bash + tmux + claude CLI
5. **Simple over clever** - Plain markdown, no JSON, no daemons

## Bash Conventions

- `set -e` at top (fail fast)
- Functions use `local` for variables
- Config parsing without `source` (security)
- Colors via escape codes (RED, GREEN, YELLOW, CYAN, NC)
- Helper functions: `die()`, `warn()`, `info()`, `success()`

## Testing Changes

```bash
# Test init (single repo)
mkdir /tmp/test-repo && cd /tmp/test-repo
git init
/path/to/beehive --init
ls -la  # Should have CLAUDE.md, plans/, plans/_meta/TRACKER.md

# Test init (workspace)
mkdir /tmp/test-ws && cd /tmp/test-ws
mkdir repo-a repo-b
git -C repo-a init && git -C repo-b init
/path/to/beehive --init
ls -la  # Should have WORKSPACE.md, plans/, plans/_meta/TRACKER.md

# Test upgrade
beehive --upgrade  # Should overwrite skills/commands/template, preserve data

# Test launch (will open tmux)
beehive --yes  # Skip confirmation

# Test config loading
echo "CONF_SESSION=test-session" > .beehive.conf
beehive --yes  # Should use "test-session" as tmux session name
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `load_config()` | Parse .beehive.conf without sourcing |
| `detect_mode()` | Determine workspace vs single repo |
| `init_repo()` | Create CLAUDE.md, plans/, plans/_meta/TRACKER.md |
| `init_workspace()` | Create WORKSPACE.md + per-repo CLAUDE.md |
| `do_upgrade()` | Update skills, commands, template (preserves data) |
| `do_launch()` | Set up tmux session with 4 panes |

## Tmux Layout

```
┌──────────┬──────────┐
│ Worker 1 │ Worker 2 │  (panes 0, 1)
├──────────┼──────────┤
│ Worker 3 │ Orchestr │  (panes 2, 3)
└──────────┴──────────┘
```

Created with: `split-window -h`, `split-window -v` (x2), `select-layout tiled`

## Adding Features

1. Check if it aligns with design principles (interactive, minimal)
2. Update the bash script
3. Update README.md if user-facing
4. Update skills/commands docs if coordination behavior changes

## Common Tasks

- **Add CLI flag**: Update `main()` case statement + `usage()`
- **Change prompts**: Edit `bee_prompt` / `queen_prompt` in `do_launch()`
- **Add config option**: Update `load_config()` case statement
- **Change layout**: Modify tmux commands in `do_launch()`
- **Upgrade existing projects**: `beehive --upgrade` (overwrites skills/commands/template)

## Version

Current: v0.3.1 (see `VERSION` variable at top of script)
