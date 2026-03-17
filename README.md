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

Works best with **Claude Opus 4.6**.

## Quick Start

```bash
# 1. Install prerequisites (see Requirements above)

# 2. Clone and install beehive
git clone https://github.com/mahowlin/beehive.git ~/beehive
sudo ln -sf ~/beehive/beehive /usr/local/bin/beehive

# 3. Initialize your project
cd ~/myproject
beehive --init

# 4. (Optional) Configure a backend
cat > .beehive.conf << 'EOF'
# API proxy (e.g. local proxy to Anthropic API)
CONF_ANTHROPIC_BASE_URL=http://localhost:8090
CONF_ANTHROPIC_API_KEY=sk-ant-your-key

# Optional shared fallback model for all panes
CONF_MODEL=claude-opus-4-6
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
│   ├── buzz.md
│   ├── report.md
│   ├── bedtime.md
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
4. Agents execute, update status, run `/buzz` when done
5. Queen verifies and archives completed plans

**Creating plans:** Queen uses `plans/TEMPLATE.md` and `/deep-plan` for complex work. See `templates/example-plan.md` for a complete example with Objective, Why This Approach, Technical Context, Implementation Strategy, Tasks, and Done Criteria.

## Commands

Slash commands keep agents on track:

| Command | Who | Purpose |
|---------|-----|---------|
| `/buzz` | Any | Check in: plan hygiene, self-check, completion. Queen also coordinates hive. |
| `/report` | Any | Submit out-of-scope discoveries to INBOX |
| `/bedtime` | Any | Save status and plan state before break or session end |
| `/session-report` | Queen | Write end-of-session report to SESSION_LOG.md |
| `/deep-plan` | Queen | Structured exploration before plan creation |

## Configuration

Claude Code works without configuration. Create `.beehive.conf` in your project root to customize:

**API proxy** (recommended for per-agent models):
```bash
CONF_ANTHROPIC_BASE_URL=http://localhost:8090
CONF_ANTHROPIC_API_KEY=sk-ant-your-key

# Shared fallback for every pane
CONF_MODEL=claude-opus-4-6

# Optional per-agent overrides
CONF_MODEL_BEE_1=gpt-5.4
CONF_MODEL_BEE_2=gpt-5.4
CONF_MODEL_BEE_3=gpt-5.4
CONF_MODEL_QUEEN=claude-opus-4-6
```

Beehive resolves models with this precedence:
1. Per-agent CLI flag (`--bee-1-model`, `--bee-2-model`, `--bee-3-model`, `--queen-model`)
2. Global CLI flag (`--model`)
3. Per-agent config key (`CONF_MODEL_BEE_1`, etc.)
4. Global config key (`CONF_MODEL`)

Before starting `claude` in each tmux pane, Beehive exports that pane's `ANTHROPIC_MODEL`. When you use an API proxy, it also exports `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` in each pane.

**AWS Bedrock:**
```bash
CONF_AWS_PROFILE=my-profile
CONF_AWS_REGION=us-west-2
CONF_MODEL=us.anthropic.claude-sonnet-4-20250514-v1:0
```

**General options:**
```bash
CONF_SESSION=my-session          # Custom tmux session name
CONF_CLAUDE_CMD=/path/to/claude  # Custom claude path
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
    --session NAME       Session name (default: folder name)
    --model MODEL        Anthropic model fallback for all panes
    --bee-1-model MODEL  Anthropic model override for Bee 1
    --bee-2-model MODEL  Anthropic model override for Bee 2
    --bee-3-model MODEL  Anthropic model override for Bee 3
    --queen-model MODEL  Anthropic model override for Queen
    --profile PROF       AWS profile for Bedrock
    --region REGION      AWS region for Bedrock
    --base-url URL       Anthropic API base URL (for API proxies)
    --api-key KEY        Anthropic API key
    --yes                Skip confirmation
    --version            Show version
    --help               Show this help
```

Example:
```bash
beehive \
  --model claude-opus-4-6 \
  --bee-1-model claude-sonnet-4-6 \
  --queen-model claude-opus-4-6 \
  --base-url http://localhost:8090 \
  --api-key sk-ant-your-key
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

**"Cannot reach API proxy"**
- Ensure your API proxy is running and accessible at the configured URL
- Check the URL in `.beehive.conf` or `--base-url` flag
- Beehive checks `{base_url}/health` with a 5-second timeout

## License

MIT
