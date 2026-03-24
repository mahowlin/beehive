# Changelog

All notable changes to Beehive are documented here.

## v0.5.1 — 2026-03-24

**Agent effectiveness improvements and workspace coordination polish.**

### Changed
- Workspace documentation now explains single-repo vs multi-repo setup more clearly.
- Shipped Bee and Queen skills now treat repo/domain labels as part of normal workspace hygiene when multiple repos share one beads queue.

### Added
- Generic README examples for umbrella-directory and multi-repo workspace usage.
- README guidance for tmux clipboard integration and why clipboard support is required.

### Notes
- Label guidance remains lightweight and generic: single-repo projects can stay unlabeled, while shared workspace queues benefit from consistent repo/domain labels.
- Run `beehive --upgrade` in an existing project or workspace to refresh the shipped skills and commands.

## v0.5.0 — 2026-03-20

**Markdown coordination replaced by beads-backed issue tracking.**

### Changed
- Coordination now uses **beads** (`bd`) as the authoritative backend for work state, dependency tracking, and audit history.
- Agent prompts, skills, and slash commands now use `bd ready`, `bd update --claim`, `bd create`, `bd close`, and `bd comments add`.
- `beehive --status` now reports work items and ready queues from beads.
- `beehive --validate` now runs `bd doctor` and validates only `plans/_meta/sessions.jsonl`.
- `do_launch()` sets `BD_ACTOR` per pane so beads records which bee or queen performed each action.
- Queen coordination no longer depends on a file-based claim workflow.

### Added
- `bd` (beads) as a required dependency with startup version gating for v0.61.0+.
- `bd init` during `beehive --init` to create `.beads/` alongside existing project scaffolding.
- Direct migration from legacy markdown tracking (`TRACKER.md`, `.hive/`, `INBOX.md`, `SESSION_LOG.md`) to beads via `beehive --upgrade`.
- `plans/_meta/migrated/id-mapping.json` and a migration report for upgrade traceability.
- `--status --json` for machine-readable status output.
- `--validate` for beads health and sessions metadata checks.
- `--upgrade --dry-run` preview mode.
- `--bees N` scaling for 3-5 bees plus queen.
- `--bee-model` and `--queen-model` per-role model overrides with 4-tier precedence.
- `/review` strategic review command.
- `templates/master-plan.md` for grouped deliverables.

### Removed
- Legacy markdown coordination files as active state: `TRACKER.md`, `INBOX.md`, `SESSION_LOG.md`, `DEPENDENCIES.md`, and `.hive/`.
- Internal JSONL coordination artifacts from the public release path.
- `templates/schemas.md`.

### Notes
- `plans/_meta/sessions.jsonl` remains and is only used for session reporting, not coordination state.
- Legacy tracker relationships are not reconstructed automatically during migration; migrated issues are imported flat and can be related afterward in beads.

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
