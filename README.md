# Beehive

Multi-agent orchestration for Claude Code.

```
┌──────────┬──────────┐
│ 🐝 Bee 1 │ 🐝 Bee 2 │
├──────────┼──────────┤
│ 🐝 Bee 3 │ 🐝 Queen │
└──────────┴──────────┘
```

**3-5 Bees** execute plans. **1 Queen** works on plans and coordinates. **You** (the Beekeeper) direct traffic.

**Who is this for?** Developers who want to run multiple Claude Code agents in parallel on a single codebase, with structured coordination and interactive oversight.

Inspired by [Gas Town](https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04).

## Requirements

| Dependency | macOS | Linux (Debian/Ubuntu) |
|------------|-------|----------------------|
| tmux | `brew install tmux` | `sudo apt install tmux` |
| jq | `brew install jq` | `sudo apt install jq` |
| [beads](https://github.com/steveyegge/beads) | `brew install steveyegge/tap/beads` | See [beads install](https://github.com/steveyegge/beads#installation) |
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

# OR: AWS Bedrock
# CONF_AWS_PROFILE=my-profile
# CONF_AWS_REGION=us-west-2
# CONF_MODEL=us.anthropic.claude-sonnet-4-20250514-v1:0
EOF

# 5. Launch
beehive
```

**Upgrading an existing project:**

```bash
# After updating beehive (git pull), upgrade your project files
beehive --upgrade
```

This overwrites skills, commands, and the plan template with the latest versions. If your project still uses legacy markdown tracking (`TRACKER.md`, `.hive/`, `INBOX.md`, `SESSION_LOG.md`), `--upgrade` migrates it directly to beads and preserves the originals in `plans/_meta/migrated/`.

**Install note:** Symlink goes to `/usr/local/bin` (works on macOS and Linux). Use `sudo` if needed. On Apple Silicon, `/opt/homebrew/bin` also works.

## What `beehive --init` Creates

Source templates live in `skills/` and `commands/` in the beehive repo; `--init` copies them into your project as `.skills/` and `.claude/commands/`.

```
myproject/
├── CLAUDE.md                    # Project instructions for agents
├── .beads/                      # Beads issue tracker (Dolt database, gitignored)
├── .skills/
│   ├── bee.md                   # Bee behavior rules
│   └── queen.md                 # Queen behavior rules
├── .claude/commands/            # Slash commands
│   ├── buzz.md
│   ├── report.md
│   ├── bedtime.md
│   ├── session-report.md
│   ├── deep-plan.md
│   └── review.md
└── plans/
    ├── TEMPLATE.md              # Template for new plans
    ├── completed/               # Archived plans
    └── _meta/
        └── sessions.jsonl       # Session reports (Queen owns)
```

**Workspace mode** (multiple git repos in one directory) creates a CLAUDE.md with a repository inventory table. Git worktrees are fully supported.

## How It Works

```
                              ┌─────────────┐
                              │  Beekeeper  │◄──────────────────────┐
                              │    (you)    │                       │
                              └──────┬──────┘                       │
                                     │ directs                      │
            ┌────────────────────────┼────────────────────────┐     │
            ▼                        ▼                        ▼     │
      ┌───────────┐            ┌───────────┐            ┌───────────┐
      │   Bee 1   │            │   Bee 2   │            │   Bee 3   │
      └─────┬─────┘            └─────┬─────┘            └─────┬─────┘
            │ bd commands            │ bd commands            │ bd commands
            └────────────────────────┼────────────────────────┘
                                     │
                                     ▼
                              ┌─────────────┐
                              │   .beads/   │ ← Dolt database
                              │  (bd CLI)   │   Atomic claims,
                              └──────┬──────┘   dependencies,
                                     │          audit trail
                                     ▼
                              ┌─────────────┐
                              │    Queen    │───────────────────────┘
                              └──────┬──────┘
                                     │ creates issues, verifies,
                                     │ closes, coordinates
                                     ▼
                              ┌─────────────┐
                              │   plans/    │
                              │(plan files) │
                              └─────────────┘
```

**Roles:**
- **Queen** — Works on plans, coordinates hive, creates/assigns work, verifies completion
- **Bees** — Execute plans/tasks, claim work atomically via `bd update --claim`, report discoveries
- **Beekeeper (you)** — Direct agents, copy messages between panes, approve major steps

**Work items** are **beads issues**: either **epics** (with a markdown plan file in `plans/`) or **tasks** (with acceptance criteria in the issue description). Tasks are for lightweight work; epics are for complex multi-step work.

**Workflow:**
1. Tell Queen what to build
2. Queen creates epics/tasks via `bd create` (and plan files in `plans/`)
3. Agents claim work: `bd update <id> --claim` (atomic, no conflicts)
4. Agents execute, add progress comments, run `/buzz` when done
5. Queen verifies and closes: `bd close <id>`

## Commands

| Command | Who | Purpose |
|---------|-----|---------|
| `/buzz` | Any | Check in: plan hygiene, self-check, completion. Queen also coordinates hive. |
| `/report` | Any | Report out-of-scope discoveries (creates beads issue) |
| `/bedtime` | Any | Save state before break or session end |
| `/session-report` | Queen | Write end-of-session report to session metadata log |
| `/deep-plan` | Queen | Structured exploration before plan creation |
| `/review` | Queen | Strategic project assessment (every few hours) |

## Configuration

Claude Code works without configuration. Create `.beehive.conf` in your project root to customize:

**API Proxy** (local proxy to Anthropic API):
```bash
CONF_ANTHROPIC_BASE_URL=http://localhost:8090
CONF_ANTHROPIC_API_KEY=sk-ant-your-key
```

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
CONF_BEES=5                      # Number of Bees (3-5, default: 3)
```

**Per-role model overrides:**
```bash
CONF_MODEL=claude-opus-4-6           # Fallback for all agents
CONF_MODEL_BEE=claude-sonnet-4-6     # Override for all Bees
CONF_MODEL_QUEEN=claude-opus-4-6     # Override for Queen
```

Precedence: role CLI (`--bee-model`) → global CLI (`--model`) → role config (`CONF_MODEL_BEE`) → global config (`CONF_MODEL`)

**Scaling up:**

```bash
beehive --bees 5    # 5 bees + Queen (6 agents)
```

```
┌──────────┬──────────┬──────────┐
│ 🐝 Bee 1 │ 🐝 Bee 2 │ 🐝 Bee 3 │
├──────────┼──────────┼──────────┤
│ 🐝 Bee 4 │ 🐝 Bee 5 │ 🐝 Queen │
└──────────┴──────────┴──────────┘
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
    beehive [path]              Launch agents (default: current directory)
    beehive --init [path]       Initialize repo/workspace structure
    beehive --upgrade [path]    Upgrade skills, commands, and template (preserves data)
    beehive --status [path]     Show work items, agent states, and ready queue
    beehive --validate [path]   Validate beads health and session metadata log

Options:
    --session NAME       Session name (default: folder name)
    --model MODEL        Anthropic model override
    --bee-model MODEL    Model override for all Bees
    --queen-model MODEL  Model override for Queen
    --bees N             Number of Bees (3-5, default: 3)
    --profile PROF       AWS profile for Bedrock
    --region REGION      AWS region for Bedrock
    --base-url URL       Anthropic API base URL (for API proxies)
    --api-key KEY        Anthropic API key
    --dry-run            Preview upgrade changes without modifying files
    --json               Machine-readable JSON output for --status
    --yes                Skip confirmation
    --version            Show version
    --help               Show this help
```

## Troubleshooting

**Stuck in tmux?**
- Press `Ctrl+b`, then `d` to detach (beehive keeps running in background)
- Run `tmux attach` to get back in
- Run `tmux kill-server` to kill everything and start fresh

**"jq required"**
- macOS: `brew install jq`
- Linux: `sudo apt install jq`

**"bd (beads) required"**
- macOS: `brew install steveyegge/tap/beads`
- See [beads installation](https://github.com/steveyegge/beads#installation) for other platforms

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
