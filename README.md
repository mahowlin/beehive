# Beehive

Multi-agent orchestration for Claude Code.

```
┌──────────┬──────────┐
│ 🐝 Bee 1 │ 🐝 Bee 2 │
├──────────┼──────────┤
│ 🐝 Bee 3 │ 🐝 Queen │
└──────────┴──────────┘
```

**3 Bees** execute plans. **1 Queen** works on plans and coordinates. **You** (the Beekeeper) direct traffic.

**Who is this for?** Developers who want to run multiple Claude Code agents in parallel on a single codebase, with file-based coordination and interactive oversight.

Inspired by [Gas Town](https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04).

## Requirements

| Dependency | macOS | Linux (Debian/Ubuntu) |
|------------|-------|----------------------|
| tmux | `brew install tmux` | `sudo apt install tmux` |
| Claude Code | [Install guide](https://docs.anthropic.com/en/docs/claude-code) | [Install guide](https://docs.anthropic.com/en/docs/claude-code) |
| Clipboard | `pbcopy` (built-in) | `sudo apt install xclip` or `xsel` |

Works best with **Claude Opus 4.5**.

## Quick Start

```bash
# 1. Install prerequisites (see Requirements above)

# 2. Clone and install beehive
git clone https://github.com/mahowlin/beehive.git ~/beehive
sudo ln -sf ~/beehive/beehive /usr/local/bin/beehive

# 3. Initialize your project
cd ~/myproject
beehive --init

# 4. (Optional) Configure for AWS Bedrock
cat > .beehive.conf << 'EOF'
CONF_AWS_PROFILE=my-profile
CONF_AWS_REGION=us-west-2
CONF_MODEL=us.anthropic.claude-sonnet-4-20250514-v1:0
EOF

# 5. Launch
beehive
```

**Upgrading an existing project:**

```bash
# After updating beehive (git pull), upgrade your project files
beehive --upgrade
```

This overwrites skills, commands, and the plan template with the latest versions. Your plans, status files, TRACKER, and CLAUDE.md are preserved.

**Install note:** Symlink goes to `/usr/local/bin` (works on macOS and Linux). Use `sudo` if needed. On Apple Silicon, `/opt/homebrew/bin` also works.

## What `beehive --init` Creates

```
myproject/
├── CLAUDE.md                    # Project instructions for agents
├── .skills/
│   ├── bee.md                   # Bee behavior rules
│   └── queen.md                 # Queen behavior rules
├── .hive/                       # Agent status files (gitignored)
│   ├── bee-1.md
│   ├── bee-2.md
│   ├── bee-3.md
│   └── queen.md
├── .claude/commands/            # Slash commands
│   ├── sting.md
│   ├── buzz.md
│   ├── report.md
│   ├── bedtime.md
│   ├── refresh.md
│   ├── session-report.md
│   └── deep-plan.md
└── plans/
    ├── INBOX.md                 # Plan requests from agents
    ├── TEMPLATE.md              # Template for new plans
    ├── completed/               # Archived plans
    └── _meta/
        ├── TRACKER.md           # Plan status (Queen owns)
        ├── SESSION_LOG.md       # Session notes (trimmed regularly)
        └── DEPENDENCIES.md      # Dependency graph (Mermaid)
```

**Workspace mode** (multiple git repos in one directory) also creates `WORKSPACE.md` and a workspace tracker at `plans/_meta/TRACKER.md`.

## How It Works

```
                              ┌─────────────┐
                              │  Beekeeper  │◄─────────────────────────────┐
                              │    (you)    │                              │
                              └──────┬──────┘                              │
                                     │ directs                             │
            ┌────────────────────────┼────────────────────────┐            │
            │                        │                        │            │
            ▼                        ▼                        ▼            │
      ┌───────────┐            ┌───────────┐            ┌───────────┐      │
      │   Bee 1   │            │   Bee 2   │            │   Bee 3   │      │
      └─────┬─────┘            └─────┬─────┘            └─────┬─────┘      │
            │                        │                        │            │
            │ writes                 │ writes                 │ writes     │
            ▼                        ▼                        ▼            │
      ┌───────────┐            ┌───────────┐            ┌───────────┐      │
      │  .hive/   │            │  .hive/   │            │  .hive/   │      │
      │ bee-1.md  │            │ bee-2.md  │            │ bee-3.md  │      │
      └─────┬─────┘            └─────┬─────┘            └─────┬─────┘      │
            │                        │                        │            │
            └────────────────────────┼────────────────────────┘            │
                                     │                                     │
                                     │ Queen reads (.hive/bee-*.md)        │
                                     ▼                                     │
                              ┌─────────────┐                              │
                              │    Queen    │──────────────────────────────┘
                              └──────┬──────┘
                                     │
               ┌─────────────────────┼─────────────────────┐
               │ writes              │ reads               │ writes
               ▼                     ▼                     ▼
        ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
        │ TRACKER.md  │       │  INBOX.md   │       │   plans/    │
        │  (status)   │       │(discoveries)│       │(task files) │
        └─────────────┘       └──────┬──────┘       └──────┬──────┘
                                     ▲                     │
                                     │                     │
                      Bees /report ──┘                     │ Bees read
                                                           │
            ┌──────────────────────────────────────────────┘
            │
            ▼
      ┌───────────┐            ┌───────────┐            ┌───────────┐
      │   Bee 1   │            │   Bee 2   │            │   Bee 3   │
      └───────────┘            └───────────┘            └───────────┘
```

**Roles:**
- **Queen** — Works on plans, coordinates hive, tracks progress in `plans/_meta/TRACKER.md`, verifies completion
- **Bees** — Execute plans, update status in `.hive/bee-N.md`, report discoveries
- **Beekeeper (you)** — Direct agents, copy messages between panes, approve major steps

**Workflow:**
1. Tell Queen what to build
2. Queen creates plans in `plans/`, updates `plans/_meta/TRACKER.md`
3. Direct each Bee to claim a plan (Queen can also claim plans)
4. Agents execute, update status, run `/sting` when done
5. Queen verifies and archives completed plans

**Creating plans:** Queen uses `plans/TEMPLATE.md` and `/deep-plan` for complex work. See `templates/example-plan.md` for a complete example with Objective, Why This Approach, Technical Context, Implementation Strategy, Tasks, and Done Criteria.

## Commands

Slash commands keep agents on track:

| Command | Who | Purpose |
|---------|-----|---------|
| `/sting` | Bees | Self-check: on track? status updated? done? |
| `/buzz` | Queen | Consolidate status from agent files, process INBOX |
| `/report` | Any | Submit out-of-scope discoveries to INBOX |
| `/bedtime` | Any | Save status and plan state before break or session end |
| `/refresh` | Any | Mid-session plan hygiene (update tasks, context, session state) |
| `/session-report` | Queen | Write end-of-session report to SESSION_LOG.md |
| `/deep-plan` | Queen | Structured exploration before plan creation |

## Configuration

Claude Code works without configuration. For **AWS Bedrock**, create `.beehive.conf` in your project root:

```bash
CONF_AWS_PROFILE=my-profile
CONF_AWS_REGION=us-west-2
CONF_MODEL=us.anthropic.claude-sonnet-4-20250514-v1:0
CONF_CLAUDE_CMD=/path/to/claude  # Optional: custom claude path
```

**Tmux controls:**

| Key | Action |
|-----|--------|
| Click | Switch panes |
| Scroll | Scroll in pane |
| Ctrl+b, z | Zoom pane |
| Ctrl+b, d | Detach (keeps running) |

## CLI Usage

```
Usage: beehive [options] [path]

Commands:
    beehive [path]           Launch agents (default: current directory)
    beehive --init [path]    Initialize repo/workspace structure
    beehive --upgrade [path] Upgrade skills, commands, and template (preserves data)

Options:
    --session NAME    Session name (default: folder name)
    --model MODEL     Anthropic model override
    --profile PROF    AWS profile for Bedrock
    --region REGION   AWS region for Bedrock
    --yes             Skip confirmation
    --version         Show version
    --help            Show this help
```

## Troubleshooting

**Stuck in tmux?**
- Press `Ctrl+b`, then `d` to detach (beehive keeps running in background)
- Run `tmux attach` to get back in
- Run `tmux kill-server` to kill everything and start fresh

**"Claude CLI not found"**
- Ensure `claude` is installed and in your PATH
- Or set `CONF_CLAUDE_CMD=/path/to/claude` in `.beehive.conf`

**"tmux required"**
- macOS: `brew install tmux`
- Linux: `sudo apt install tmux`

**Clipboard not working**
- macOS: Should work out of the box (`pbcopy`)
- Linux: Install `xclip` or `xsel`, then restart beehive

**Permission denied on symlink**
- Use `sudo ln -sf ~/beehive/beehive /usr/local/bin/beehive`
- Or symlink to `~/.local/bin` (add to PATH if needed)

## License

MIT
