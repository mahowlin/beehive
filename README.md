# Beehive

Run a small team of CLI-backed coding agents in tmux.

```text
┌──────────┬──────────┐
│ 🐝 Bee 1 │ 🐝 Bee 2 │
├──────────┼──────────┤
│ 🐝 Bee 3 │ 🐝 Queen │
└──────────┴──────────┘
```

**2-5 Bees** do the work. **1 Queen** coordinates. **You** direct the hive.

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
| Agent CLI | Claude Code, Codex CLI, or Cursor `agent` | Claude Code, Codex CLI, or Cursor `agent` |
| Clipboard | `pbcopy` (built-in) | `sudo apt install xclip` or `xsel` |

Clipboard support is for tmux copy-mode, so you can mouse-select text in an agent pane and copy it to your system clipboard. Beehive also configures tmux for `tmux-256color`, truecolor, focus events, styled pane borders, and a compact status bar so Claude/Codex/Cursor terminal UIs keep their richer appearance inside panes.

## Quick Start

### Single repository

```bash
# 1. Clone and install beehive
git clone https://github.com/mahowlin/beehive.git ~/beehive
sudo ln -sf ~/beehive/beehive /usr/local/bin/beehive

# 2. Initialize your repo
cd ~/myproject
beehive --init

# 3. Optional: configure agent CLI and backend
cat > .beehive.conf << 'EOF'
CONF_CLI=claude
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
CONF_CLI=codex
CONF_APPROVAL_MODE=auto
CONF_ANTHROPIC_BASE_URL=http://localhost:8090
CONF_ANTHROPIC_API_KEY=sk-ant-your-key
EOF

# 5. Launch from the workspace root
beehive
```

In workspace mode, keep `.beehive.conf` in the workspace root so all panes share the same configuration.

## Agent CLI Selection

Use one CLI family per hive launch:

```bash
beehive --cli claude          # executable: claude
beehive --cli codex           # executable: codex
beehive --cli cursor          # executable: agent
beehive --cli copilot         # executable: copilot (GitHub Copilot CLI)
beehive --cli agy             # executable: agy (Google Antigravity CLI)
beehive --cli vibe            # executable: vibe (Mistral Vibe CLI)
```

Configuration equivalents:

```bash
CONF_CLI=claude|codex|cursor|copilot|agy|vibe
CONF_CLI_CMD=/custom/path      # optional explicit command override
CONF_APPROVAL_MODE=auto|manual # default: auto
```

`auto` keeps each CLI's filesystem sandbox and delegates routine approval decisions to its
built-in reviewer. Claude launches with `--permission-mode auto`; Codex launches with
`workspace-write`, `on-request`, and `auto_review`. Cursor currently receives no approval
override because it has no equivalent supported flag. The edit-only profiles auto-approve file
edits while shell commands still prompt: Copilot launches with `--allow-tool write`, Antigravity
with `--mode accept-edits`, and Vibe with `--agent accept-edits`. Use `manual` to retain the
CLI's normal interactive approval behavior.

Startup prompts are passed positionally for Claude, Codex, Cursor, and Vibe, and via `-i` for
Copilot and Antigravity so the session stays interactive. Model overrides (`--model`,
`--bee-model`, `--queen-model`) are passed as `ANTHROPIC_MODEL` for Claude, as `--model` for
Codex, Cursor, Copilot, and Antigravity, and as `VIBE_ACTIVE_MODEL` for Vibe (the model must be
an alias from your Vibe `config.toml`).

Beehive never enables unrestricted bypass modes. Automatic CLI approval does not replace the
Beads intention, mutation, live-system, or human-review gates. Restart the affected Queen or Bee
session after changing the approval mode.

`--no-queen` remains the mechanism for launching Bees only when Queen runs separately:

```bash
beehive --cli codex --bees 2 --no-queen
```

Use `--queen-only` to launch one Queen directly in the current terminal without tmux:

```bash
beehive --queen-only
beehive --cli cursor --queen-only
```

### Mixing CLIs and subscriptions

Each agent can run a different CLI, so a hive can spread its work across several subscriptions
(Claude Pro/Max, ChatGPT, GitHub Copilot, Google, Mistral). Every CLI uses the login you set up
for it (`claude` → `/login`, `codex login`, `copilot` → `/login`, ...). Do not set
`--api-key`/`CONF_ANTHROPIC_API_KEY` if Claude Code should use your subscription instead of API
billing.

```bash
beehive --bee-cli codex --queen-cli claude   # all Bees on Codex, Queen on Claude Code
```

```bash
# .beehive.conf
CONF_CLI=claude                 # default for every agent
CONF_CLI_BEE_2=codex            # bee-2 on Codex
CONF_MODEL_BEE_2=gpt-5.1-codex  # model for bee-2 only
CONF_CLI_BEE_3=copilot          # bee-3 on Copilot (CLI default model)
CONF_CLI_QUEEN=claude
CONF_CLI_CMD_CODEX=/opt/codex/bin/codex   # optional per-CLI executable
```

Precedence: `CONF_CLI_BEE_N` → `--bee-cli`/`CONF_CLI_BEE` → `--cli`/`CONF_CLI`, and
`--queen-cli`/`CONF_CLI_QUEEN` → `--cli`/`CONF_CLI`. Model settings shared by several agents
(`--model`, `CONF_MODEL`) only apply to agents on the default CLI, and `--bee-model`/
`CONF_MODEL_BEE` only to Bees on the Bee CLI, so a Claude model name never reaches Codex.
`CONF_MODEL_BEE_N` always applies to its Bee. `--cli-cmd`/`CONF_CLI_CMD` apply to the default CLI;
use `CONF_CLI_CMD_<CLI>` for the others.

Each pane or direct session receives `BD_ACTOR` (`bee-1`, `bee-2`, ..., `queen`) and a short startup prompt. The detailed operating rules live in `CLAUDE.md`, `.skills/`, `.claude/commands/`, and `bd prime`.

## Model Selection by the Queen

The Queen can read each agent's CLI and model, the models and usage of every CLI in use or
installed, and restart individual Bees with a better-suited model or on another CLI (and with
it another subscription):

```bash
beehive --models               # per-agent CLI/model, models and usage per CLI
beehive --models --json        # same, machine-readable (used by the Queen)
beehive --switch-model bee-2 opus                      # restart bee-2 with another model
beehive --switch-model bee-2 gpt-5.1-codex --cli codex # move bee-2 to Codex
beehive --switch-model bee-2 default                   # back to the CLI default model
```

Available models are discovered per CLI:

| CLI | Source |
|-----|--------|
| claude | `GET /v1/models` when an Anthropic API key is configured, plus the aliases `opus`, `sonnet`, `haiku` |
| codex | `model = ...` entries in `~/.codex/config.toml` |
| copilot | the Copilot models API catalog (same list as the interactive `/model` picker, via the logged-in GitHub token), plus recently used models from `~/.copilot/session-store.db` |
| agy | `agy models` |
| vibe | `alias = ...` entries in `.vibe/config.toml` and `~/.vibe/config.toml` (both `[[models]]` tables and inline `models = [{ alias = ... }]`) |
| any | `CONF_MODELS_<CLI>` (comma-separated) and the output of `CONF_MODELS_CMD_<CLI>`; `CONF_MODELS`/`CONF_MODELS_CMD` apply to the default CLI |

Usage is read from local CLI logs where available: Claude Code token totals for this project
directory over the last 5 hours and 7 days (`~/.claude/projects/`), and Codex's latest
account-wide rate-limit snapshot (`~/.codex/sessions/`). For any CLI, `CONF_USAGE_CMD_<CLI>`
can point to a command whose output (JSON or text) is passed to the Queen, for example
`CONF_USAGE_CMD_CLAUDE=ccusage blocks --active --json`; `CONF_USAGE_CMD` reports hive-wide usage.
All `*_CMD` settings are split on whitespace and run without a shell (no pipes or
substitutions), with a 20-second timeout.

Switching restarts the Bee's CLI in its pane, so its conversation context is lost; Beads state
is kept. The Queen skill only switches idle or checkpointed Bees, asks the user first, and
records the decision as a bead comment. The Queen itself is never restarted. Launch settings
are stored as tmux session and pane options (relaunch hives started with older versions); the API key is not stored and is re-read from
`.beehive.conf` or the environment.

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

Workspace mode is detected automatically when a directory contains multiple sibling git repos. In workspace mode, agents start in the workspace root and move into the relevant repo when needed.

`plans/` is retained for archive/session metadata compatibility. New work should live in Beads epics and child beads; assigned executable beads are the plan.

## How It Works

- The Queen maintains the critical path, dispatch, and verification.
- Bees execute only assigned executable beads.
- Bees do not self-dispatch from `bd ready` unless Queen opens a scoped free-pick window.
- Out-of-scope discoveries are created and related in Beads, then Queen triages them.
- You review progress and direct traffic between panes.

For most users, that's the important part. Beehive installs the agent instructions and coordination files it needs during `--init`.

## Command Procedures

Claude Code exposes Beehive procedures as slash commands. Codex/Cursor may reject literal slash commands; use the procedure name in natural language instead (for example, “run buzz procedure”) or perform the equivalent `bd` reads/comments/updates from `.claude/commands/<name>.md`.

| Procedure | Claude Code | Who | Purpose |
|-----------|-------------|-----|---------|
| `buzz` | `/buzz` | Any | Tactical check-in and coordination refresh |
| `report` | `/report` | Any | Report out-of-scope discoveries |
| `bedtime` | `/bedtime` | Any | Save resumable state before a break or session end |
| `board` | `/board` | Queen | Concise project board and dispatch view |
| `health` | `/health` | Queen | Beads operating-model health audit |
| `session-report` | `/session-report` | Queen | Write end-of-session progress metadata |
| `deep-plan` | `/deep-plan` | Queen | Create/refresh Beads-native epics for unscoped work |
| `review` | `/review` | Queen | Strategic project review |

## Configuration

Create `.beehive.conf` in your project or workspace root.

```bash
CONF_SESSION=my-session
CONF_CLI=claude              # claude, codex, cursor, copilot, agy, or vibe
CONF_CLI_CMD=/path/to/cli    # optional explicit command override
CONF_APPROVAL_MODE=auto      # auto or manual
CONF_CLI_BEE=codex           # optional CLI for all Bees (CONF_CLI_BEE_N for one Bee)
CONF_CLI_QUEEN=claude        # optional CLI for the Queen
CONF_MODEL_BEE_2=gpt-5.1-codex  # optional model for one Bee
CONF_CLI_CMD_CODEX=          # optional executable per CLI
CONF_MODELS=opus,sonnet      # optional extra models for the default CLI (CONF_MODELS_<CLI> per CLI)
CONF_MODELS_CMD=             # optional command that prints model names (CONF_MODELS_CMD_<CLI>)
CONF_USAGE_CMD_CLAUDE=       # optional command that prints usage for one CLI (JSON or text)
CONF_USAGE_CMD=              # optional command that prints hive-wide usage
CONF_BEES=2
CONF_QUEEN=true

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
    --cli claude|codex|cursor|copilot|agy|vibe
    --cli-cmd CMD
    --bee-cli NAME              # CLI for all Bees
    --queen-cli NAME            # CLI for the Queen
    --models                    # show CLIs, models + usage (add --json)
    --switch-model bee-N MODEL [--cli NAME]  # restart one Bee with another model/CLI
    --approval-mode MODE       # auto or manual (default: auto)
    --bees N                    # 2-5
    --no-queen
    --queen-only
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
- `claude`, `codex`, or `agent`: ensure the selected CLI is installed and in your PATH

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
