# Beehive

Run a small team of Claude Code agents in tmux.

```text
┌──────────┬──────────┐
│ 🐝 Bee 1 │ 🐝 Bee 2 │
├──────────┼──────────┤
│ 🐝 Bee 3 │ 🐝 Queen │
└──────────┴──────────┘
```

**3-5 Bees** do the work. **1 Queen** coordinates. **You** direct the hive.

Beehive works well for:
- a single repository
- a multi-repo workspace with sibling repos under one root

Inspired by [Gas Town](https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04).

## Requirements

| Dependency | macOS | Linux (Debian/Ubuntu) |
|------------|-------|----------------------|
| tmux | `brew install tmux` | `sudo apt install tmux` |
| jq | `brew install jq` | `sudo apt install jq` |
| [beads](https://github.com/steveyegge/beads) | `brew install steveyegge/tap/beads` | See [beads install](https://github.com/steveyegge/beads#installation) |
| Claude Code | [Install guide](https://docs.anthropic.com/en/docs/claude-code) | [Install guide](https://docs.anthropic.com/en/docs/claude-code) |
| Clipboard | `pbcopy` (built-in) | `sudo apt install xclip` or `xsel` |

Clipboard support is for tmux copy-mode, so you can mouse-select text in an agent pane and copy it to your system clipboard.

Works best with **Claude Opus 4.6**.

## Quick Start

### Single repository

```bash
# 1. Clone and install beehive
git clone https://github.com/mahowlin/beehive.git ~/beehive
sudo ln -sf ~/beehive/beehive /usr/local/bin/beehive

# 2. Initialize your repo
cd ~/myproject
beehive --init

# 3. Optional: configure backend
cat > .beehive.conf << 'EOF'
CONF_ANTHROPIC_BASE_URL=http://localhost:8090
CONF_ANTHROPIC_API_KEY=sk-ant-your-key
EOF

# 4. Launch
beehive
```

### Multi-repo workspace

```bash
# 1. Create or enter a workspace root
mkdir -p ~/practice-workspace
cd ~/practice-workspace

# 2. Add multiple sibling repos
git clone git@github.com:example/platform-a.git
git clone git@github.com:example/platform-b.git
git clone git@github.com:example/infra.git
git clone git@github.com:example/docs.git

# 3. Initialize from the workspace root
beehive --init

# 4. Optional: configure backend for the whole workspace
cat > .beehive.conf << 'EOF'
CONF_ANTHROPIC_BASE_URL=http://localhost:8090
CONF_ANTHROPIC_API_KEY=sk-ant-your-key
EOF

# 5. Launch from the workspace root
beehive
```

In workspace mode, keep `.beehive.conf` in the workspace root so all panes share the same configuration.

If you use a shared `plans/` directory across several repos, give plans clear repo-prefixed names like `platform-a-auth.md` or `infra-deploy-pipeline.md`.

## What `beehive --init` Creates

Beehive installs its working files into your repo or workspace.

### Single repository

```text
myproject/
├── CLAUDE.md
├── .beads/
├── .skills/
├── .claude/commands/
└── plans/
    ├── TEMPLATE.md
    ├── completed/
    └── _meta/
        └── sessions.jsonl
```

### Multi-repo workspace

```text
practice-workspace/
├── CLAUDE.md
├── .beads/
├── .skills/
├── .claude/commands/
├── plans/
│   ├── TEMPLATE.md
│   ├── completed/
│   └── _meta/
│       └── sessions.jsonl
├── platform-a/
│   └── CLAUDE.md    # added if missing
├── platform-b/
│   └── CLAUDE.md    # added if missing
├── infra/
│   └── CLAUDE.md    # added if missing
└── docs/
    └── CLAUDE.md    # added if missing
```

Workspace mode is detected automatically when a directory contains multiple sibling git repos.

In workspace mode, agents start in the workspace root and move into the relevant repo when needed.

## How It Works

- You tell the Queen what to do
- The Queen breaks work into plans or tasks
- Bees pick up work and execute it
- You review progress and direct traffic between panes

For most users, that's the important part. Beehive installs the agent instructions and coordination files it needs during `--init`.

## Commands

| Command | Who | Purpose |
|---------|-----|---------|
| `/buzz` | Any | Check in and coordinate progress |
| `/report` | Any | Report out-of-scope discoveries |
| `/bedtime` | Any | Save state before a break or session end |
| `/session-report` | Queen | Write end-of-session metadata |
| `/deep-plan` | Queen | Explore before writing a plan |
| `/review` | Queen | Strategic project review |

## Configuration

Create `.beehive.conf` in your project or workspace root.

```bash
CONF_SESSION=my-session
CONF_CLAUDE_CMD=/path/to/claude
CONF_BEES=5

CONF_MODEL=claude-opus-4-6
CONF_MODEL_BEE=claude-sonnet-4-6
CONF_MODEL_QUEEN=claude-opus-4-6

# Optional API proxy
CONF_ANTHROPIC_BASE_URL=http://localhost:8090
CONF_ANTHROPIC_API_KEY=sk-ant-your-key

# Optional AWS Bedrock
# CONF_AWS_PROFILE=my-profile
# CONF_AWS_REGION=us-west-2
```

CLI flags override config values.

## Upgrade

After updating Beehive itself, refresh an existing project or workspace with:

```bash
beehive --upgrade
```

Run that from the workspace root if you are using Beehive across multiple repos.

## CLI Usage

```text
Usage: beehive [options] [path]

Commands:
    beehive [path]              Launch agents (default: current directory)
    beehive --init [path]       Initialize repo/workspace structure
    beehive --upgrade [path]    Upgrade skills, commands, and template
    beehive --status [path]     Show work items, agent states, and ready queue
    beehive --validate [path]   Validate beads health and session metadata log

Options:
    --session NAME
    --model MODEL
    --bee-model MODEL
    --queen-model MODEL
    --bees N
    --profile PROF
    --region REGION
    --base-url URL
    --api-key KEY
    --dry-run
    --json
    --yes
    --version
    --help
```

## Troubleshooting

**Stuck in tmux?**
- `Ctrl+b`, then `d` to detach
- `tmux attach` to get back in
- `tmux kill-server` to start fresh

**Missing dependencies?**
- `jq`: install from the Requirements table above
- `bd` (beads): install from the Requirements table above
- `tmux`: install from the Requirements table above
- `claude`: ensure Claude Code is installed and in your PATH

**Clipboard not working?**
- macOS: `pbcopy` should work out of the box
- Linux: install `xclip` or `xsel`, then restart Beehive
- Make sure the tmux session was started by Beehive

**API proxy not reachable?**
- Check `.beehive.conf` or `--base-url`
- Make sure the proxy is running and reachable
- Beehive checks `{base_url}/health`

## License

MIT
