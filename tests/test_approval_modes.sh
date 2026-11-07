#!/bin/bash
# shellcheck disable=SC1091,SC2034
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BEEHIVE_SOURCE_ONLY=true
source "$ROOT_DIR/beehive"

AWS_PROFILE=""
AWS_REGION=""
ANTHROPIC_BASE_URL=""
ANTHROPIC_API_KEY=""

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_contains() {
    [[ "$1" == *"$2"* ]] || fail "expected command to contain: $2"
}

assert_not_contains() {
    [[ "$1" != *"$2"* ]] || fail "command must not contain: $2"
}

build_for() {
    CLI_FAMILY="$1"
    APPROVAL_MODE="$2"
    AGENT_CMD="$3"
    build_pane_command "prompt with spaces" "" "bee-1"
}

claude_auto=$(build_for claude auto /opt/bin/claude)
assert_contains "$claude_auto" "/opt/bin/claude --permission-mode auto"
assert_contains "$claude_auto" "BD_ACTOR=bee-1"
assert_contains "$claude_auto" "prompt\\ with\\ spaces"

codex_auto=$(build_for codex auto /opt/bin/codex)
assert_contains "$codex_auto" "/opt/bin/codex --sandbox workspace-write"
assert_contains "$codex_auto" "--ask-for-approval on-request"
assert_contains "$codex_auto" "approvals_reviewer=auto_review"

manual=$(build_for claude manual /opt/bin/claude)
assert_not_contains "$manual" "--permission-mode"
assert_not_contains "$manual" "--ask-for-approval"
assert_not_contains "$manual" "approvals_reviewer"

cursor_auto=$(build_for cursor auto /opt/bin/agent)
assert_not_contains "$cursor_auto" "--permission-mode"
assert_not_contains "$cursor_auto" "--ask-for-approval"
assert_not_contains "$cursor_auto" "approvals_reviewer"

copilot_auto=$(build_for copilot auto /opt/bin/copilot)
assert_contains "$copilot_auto" "/opt/bin/copilot --allow-tool write -i prompt\\ with\\ spaces"
assert_not_contains "$copilot_auto" "--allow-all"

agy_auto=$(build_for agy auto /opt/bin/agy)
assert_contains "$agy_auto" "/opt/bin/agy --mode accept-edits -i prompt\\ with\\ spaces"

vibe_auto=$(build_for vibe auto /opt/bin/vibe)
assert_contains "$vibe_auto" "/opt/bin/vibe --agent accept-edits prompt\\ with\\ spaces"
assert_not_contains "$vibe_auto" "auto-approve"

copilot_manual=$(build_for copilot manual /opt/bin/copilot)
assert_not_contains "$copilot_manual" "--allow-tool"
assert_contains "$copilot_manual" "/opt/bin/copilot -i prompt"

# Model handling per CLI family
CLI_FAMILY=copilot APPROVAL_MODE=manual AGENT_CMD=/opt/bin/copilot
copilot_model=$(build_pane_command "p" "gpt-5" "queen")
assert_contains "$copilot_model" "--model gpt-5 -i p"
assert_not_contains "$copilot_model" "ANTHROPIC_MODEL"

CLI_FAMILY=agy AGENT_CMD=/opt/bin/agy
agy_model=$(build_pane_command "p" "gemini-3-pro" "queen")
assert_contains "$agy_model" "--model gemini-3-pro -i p"

CLI_FAMILY=vibe AGENT_CMD=/opt/bin/vibe
vibe_model=$(build_pane_command "p" "devstral-2" "queen")
assert_contains "$vibe_model" "VIBE_ACTIVE_MODEL=devstral-2"
assert_not_contains "$vibe_model" "ANTHROPIC_MODEL"

CLI_FAMILY=codex AGENT_CMD=/opt/bin/codex
codex_model=$(build_pane_command "p" "gpt-5.1-codex" "bee-1")
assert_contains "$codex_model" "--model gpt-5.1-codex"
assert_not_contains "$codex_model" "ANTHROPIC_MODEL"

CLI_FAMILY=claude AGENT_CMD=/opt/bin/claude
claude_model=$(build_pane_command "p" "claude-opus-4-6" "queen")
assert_contains "$claude_model" "ANTHROPIC_MODEL=claude-opus-4-6"
assert_not_contains "$claude_model" "--model"

for command in "$claude_auto" "$codex_auto" "$manual" "$cursor_auto" "$copilot_auto" "$agy_auto" "$vibe_auto"; do
    assert_not_contains "$command" "bypassPermissions"
    assert_not_contains "$command" "dangerously-skip-permissions"
    assert_not_contains "$command" "danger-full-access"
    assert_not_contains "$command" "--yolo"
    assert_not_contains "$command" "approval_policy=never"
    assert_not_contains "$command" "--allow-all-tools"
    assert_not_contains "$command" "--auto-approve"
done

if (resolve_approval_args claude invalid >/dev/null 2>&1); then
    fail "invalid approval mode was accepted"
fi

echo "approval mode tests passed"
