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

for command in "$claude_auto" "$codex_auto" "$manual" "$cursor_auto"; do
    assert_not_contains "$command" "bypassPermissions"
    assert_not_contains "$command" "dangerously-skip-permissions"
    assert_not_contains "$command" "danger-full-access"
    assert_not_contains "$command" "--yolo"
    assert_not_contains "$command" "approval_policy=never"
done

if (resolve_approval_args claude invalid >/dev/null 2>&1); then
    fail "invalid approval mode was accepted"
fi

echo "approval mode tests passed"
