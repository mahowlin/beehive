# Changelog

All notable changes to Beehive are documented here.

## [0.5.0] — 2026-03-17

**Major structural overhaul: markdown → JSONL coordination.**

### Changed
- **Coordination files are now JSONL** — `work.jsonl`, `inbox.jsonl`, `sessions.jsonl`, `archive.jsonl` replace TRACKER.md, INBOX.md, SESSION_LOG.md
- **Agent state uses claims/** — `plans/_meta/claims/{agent}.jsonl` replaces `.hive/{agent}.md`
- **Skills rewritten** — `bee.md` and `queen.md` updated for JSONL read/append protocol
- **Commands updated** — `/buzz`, `/bedtime`, `/report`, `/session-report`, `/deep-plan` all use JSONL
- **Plan template simplified** — removed markdown status sections; Session State kept for in-plan context
- **`beehive --status`** reads JSONL and displays work items, agent states, and inbox
- **Bee claim files are session-scoped** — `do_launch()` creates `bee-N.jsonl` for active bees; `--init` only creates `queen.jsonl`

### Added
- **`--bees N` flag** — configurable agent count (3-5 bees, default 3). `CONF_BEES` config key. 3x2 grid layout for 5+1 agents.
- **Automatic migration** — `beehive --upgrade` converts TRACKER.md → work.jsonl/archive.jsonl, .hive/ → claims/, INBOX.md/SESSION_LOG.md → migrated/
- **Per-role model overrides** — `--bee-model` / `--queen-model` CLI flags and `CONF_MODEL_BEE` / `CONF_MODEL_QUEEN` config keys with 4-tier precedence (role CLI → global CLI → role config → global config). Based on PR #3 by @pleseer.
- **`beehive --validate`** — validates all JSONL files for schema correctness, field presence, status/action enum values, and cross-references (working items without claims). Exit 1 on errors.
- **`beehive --upgrade --dry-run`** — preview what upgrade and migration would change without modifying files
- **`beehive --status --json`** — machine-readable JSON output for CI/automation, with `has_errors` flag and exit code 1 on malformed data
- **Migration report** — `beehive --upgrade` writes `plans/_meta/migrated/migration-report.md` documenting what was migrated, fallback assumptions (defaulted points, normalized statuses), and unresolved file paths
- **Migrated file path normalization** — migration resolves plan names to actual `plans/*.md` paths; sets empty string when no match found
- **`/review` command** — new slash command for code review workflows
- **WORKSPACE.md cleanup** — upgrade migrates stale WORKSPACE.md to `plans/_meta/migrated/`
- **Stale `.hive/` gitignore cleanup** — upgrade removes dead `.hive/` entry from .gitignore

### Fixed
- **Legacy tracker discovery** — migration now finds TRACKER.md at all 3 historical locations (v0.2.0 repo `plans/TRACKER.md`, v0.2.0 workspace `TRACKER.md`, v0.2.1+ `_meta/TRACKER.md`)
- **Transactional migration** — TRACKER migration writes to temp files and validates before committing; partial failure leaves no corrupt state
- **Inbox hard-fail on malformed** — `--status` inbox display now skips malformed lines with warnings instead of crashing
- **Flags accepted as values** — `--model --bee-model` no longer silently treats `--bee-model` as the model name; flags starting with `-` are rejected as values
- **TRACKER pipe-in-cells** — migration now checks column count and skips unparseable rows
- **Claim trailing blank lines** — `--status` now finds last valid JSON line, ignoring trailing blanks
- **Cross-ref accepts terminal claims** — validation now checks latest action per item (not just any historical claim)
- **`/deep-plan` template drift** — removed "Risks / Open Questions" reference that no longer exists in plan template
- `((line_num++))` crash on bash 5+ (Linux) in `--status` — now uses `$((line_num + 1))`
- `((git_count++))` crash on bash 5+ (Linux) in mode detection — same fix
- `jq` dependency required unconditionally after arg parsing (no longer skipped for bare launch)
- `--help` and `--version` still work without jq installed (exit before check)
- Stale TRACKER.md reference in example-plan.md → now references work.jsonl
- `.hive/` gitignore cleanup anchored to line start (`^\.hive/`) to avoid matching comments

### Removed
- `templates/TRACKER.md`, `templates/INBOX.md`, `templates/SESSION_LOG.md`, `templates/DEPENDENCIES.md`
- `templates/bee-status.md`, `templates/queen-status.md`
- `.hive/` directory structure (replaced by `plans/_meta/claims/`)

## [0.4.0] — 2025-03-15

**API proxy support and docs cleanup.**

### Added
- `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` support for local API proxies
- Config keys: `CONF_ANTHROPIC_BASE_URL`, `CONF_ANTHROPIC_API_KEY`
- CLI flags: `--base-url`, `--api-key`
- Health check before launch when using custom API endpoint
- Backend-aware startup display (shows proxy URL or Bedrock profile)

### Removed
- `/sting` and `/refresh` commands (consolidated into other commands)
- Internal jargon from script comments

### Fixed
- README model reference updated to Claude Opus 4
- CLAUDE.md variable names corrected (bee_prompt/queen_prompt)
- "Agent Teams teammates" redundant phrasing in skills and commands
- Added copyright holder and date range to LICENSE

## [0.3.1] — 2025-03-14

**Queen works on plans, Agent Teams, upgrade command.**

### Changed
- Queen now claims and executes plans from TRACKER, not just coordinates
- Expanded `/bedtime` to update plan Session State, not just status files

### Added
- `beehive --upgrade` command to update skills/commands/templates in existing projects
- Agent Teams as optional execution tool for Bees and Queen
- `/refresh`, `/session-report`, `/deep-plan` commands
- Richer plan template: Why This Approach, Technical Context, Implementation Strategy, Risks/Open Questions, Session State
- Queen status file (`.hive/queen.md`) with Mode tracking
- README expanded with CLI usage, upgrade instructions, new commands

## [0.2.1] — 2025-03-13

**File structure reorganization.**

### Changed
- Introduced `_meta/` directory under `plans/` to organize coordination files
- Moved `TRACKER.md`, `SESSION_LOG.md`, `DEPENDENCIES.md` to `plans/_meta/`
- Updated all commands and documentation to reference new file paths

## [0.2.0] — 2025-03-12

**Initial public release.**

### Added
- Tmux-based 4-pane layout: 3 Bees + 1 Queen
- File-based coordination: TRACKER.md, .hive/bee-N.md, INBOX.md
- Slash commands: `/sting`, `/buzz`, `/report`, `/bedtime`
- Single repo and workspace auto-detection
- AWS Bedrock support via `.beehive.conf`
- Symlink-safe `SCRIPT_DIR` resolution
