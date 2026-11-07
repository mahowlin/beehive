#!/bin/bash
# shellcheck disable=SC1091,SC2034
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BEEHIVE_SOURCE_ONLY=true
source "$ROOT_DIR/beehive"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
assert_eq() { [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'"; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "expected output to contain: $2"; }

AWS_PROFILE="" AWS_REGION="" ANTHROPIC_BASE_URL="" ANTHROPIC_API_KEY=""
CONF_MODELS="" CONF_MODELS_CMD="" CONF_USAGE_CMD=""

# --- model name validation
valid_model_name "claude-opus-4-6[1m]" || fail "bracket suffix rejected"
valid_model_name "gpt-5.1-codex" || fail "dotted model rejected"
if valid_model_name 'x; rm -rf /'; then fail "unsafe model accepted"; fi

# --- filter drops headers and keeps model-like first fields
filtered=$(printf 'Available models:\n  gemini-3-pro   (default)\n* gemini-3-flash\n\n' | filter_model_names | tr '\n' ' ')
assert_eq "$filtered" "gemini-3-pro gemini-3-flash "

# --- vibe aliases from project and home config
mkdir -p "$TMP/proj/.vibe" "$TMP/vibehome"
printf '[[models]]\nname = "mistral-large"\nalias = "large"\n' > "$TMP/proj/.vibe/config.toml"
printf '[[models]]\nalias = "devstral-2"\n' > "$TMP/vibehome/config.toml"
vibe_models=$(VIBE_HOME="$TMP/vibehome" available_models_json vibe "$TMP/proj" "")
assert_eq "$(jq -r '[.[].model] | sort | join(",")' <<< "$vibe_models")" "devstral-2,large"

# --- copilot --help choices
cat > "$TMP/copilot" <<'SH'
#!/bin/bash
cat <<'HELP'
  --model <model>   Set the AI model to use (choices: "claude-sonnet-4.5",
                    "gpt-5", "gpt-5-mini")
  --other           Something else
HELP
SH
chmod +x "$TMP/copilot"
copilot_models=$(available_models_json copilot "$TMP/proj" "$TMP/copilot")
assert_eq "$(jq -r '[.[].model] | join(",")' <<< "$copilot_models")" "claude-sonnet-4.5,gpt-5,gpt-5-mini"

# --- CONF_MODELS applies to any CLI, invalid entries dropped
CONF_MODELS="model-a, model-b bad;name"
cursor_models=$(available_models_json cursor "$TMP/proj" "")
assert_eq "$(jq -r '[.[].model] | join(",")' <<< "$cursor_models")" "model-a,model-b"
CONF_MODELS=""

# --- Claude usage aggregation from project logs
proj="$TMP/my.proj"
mkdir -p "$proj"
slug=$(printf '%s' "$proj" | sed 's/[^A-Za-z0-9]/-/g')
logdir="$TMP/claude/projects/$slug"
mkdir -p "$logdir"
recent=$(date -u +%Y-%m-%dT%H:%M:%S.123Z)
old=$(jq -nr 'now - 86400 | todate')
{
    printf '{"type":"assistant","timestamp":"%s","requestId":"r1","message":{"id":"m1","model":"claude-opus-4-6","usage":{"input_tokens":10,"output_tokens":5,"cache_read_input_tokens":100}}}\n' "$recent"
    printf '{"type":"assistant","timestamp":"%s","requestId":"r1","message":{"id":"m1","model":"claude-opus-4-6","usage":{"input_tokens":10,"output_tokens":5,"cache_read_input_tokens":100}}}\n' "$recent"
    printf '{"type":"assistant","timestamp":"%s","requestId":"r2","message":{"id":"m2","model":"claude-sonnet-4-6","usage":{"input_tokens":7,"output_tokens":3}}}\n' "$old"
    printf '{"type":"user","timestamp":"%s"}\n' "$recent"
    printf 'not json\n'
} > "$logdir/session.jsonl"
usage=$(CLAUDE_CONFIG_DIR="$TMP/claude" claude_usage_json "$proj")
assert_eq "$(jq -c '.window_5h | map({model, messages, input_tokens})' <<< "$usage")" '[{"model":"claude-opus-4-6","messages":1,"input_tokens":10}]'
assert_eq "$(jq -c '.window_7d | map(.model)' <<< "$usage")" '["claude-opus-4-6","claude-sonnet-4-6"]'

# --- Codex rate limits from newest session log
mkdir -p "$TMP/codex/sessions/2026/11/07"
printf '{"timestamp":"t","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"total_tokens":42}},"rate_limits":{"primary":{"used_percent":37.5,"window_minutes":300}}}}\n' \
    > "$TMP/codex/sessions/2026/11/07/rollout-a.jsonl"
codex_usage=$(CODEX_HOME="$TMP/codex" codex_usage_json)
assert_eq "$(jq -r '.rate_limits.primary.used_percent' <<< "$codex_usage")" "37.5"

# --- custom usage command (no shell evaluation)
CONF_USAGE_CMD="printf {\"used\":3}"
assert_eq "$(usage_json cursor "$proj" | jq -c '.custom')" '{"used":3}'
CONF_USAGE_CMD=""

# --- switch-model restarts only the target pane with the new model
TMUX_LOG="$TMP/tmux.log"
tmux() {
    echo "$*" >> "$TMUX_LOG"
    case "$1" in
        has-session) return 0 ;;
        show-options)
            case "${!#}" in
                @beehive_cli) echo "copilot" ;;
                @beehive_cli_cmd) echo "/opt/bin/copilot" ;;
                @beehive_approval) echo "auto" ;;
                @beehive_path) echo "$proj" ;;
            esac ;;
        list-panes) printf '%%1|bee-1|gpt-5-mini\n%%2|bee-2|\n%%3|queen|gpt-5\n' ;;
    esac
}
sleep() { :; }
TMUX=""
out=$(do_switch_model "$proj" "hive" "bee-2" "gpt-5" 2>&1)
log=$(cat "$TMUX_LOG")
assert_contains "$log" "respawn-pane -k -t %2"
assert_contains "$log" "set-option -p -t %2 @beehive_model gpt-5"
assert_contains "$log" "send-keys -t %2"
assert_contains "$log" "/opt/bin/copilot --allow-tool write --model gpt-5 -i"
assert_contains "$log" "BD_ACTOR=bee-2"
[[ "$log" != *"-t %1"* && "$log" != *"-t %3"* ]] || fail "other panes touched"

if (do_switch_model "$proj" "hive" "queen" "gpt-5" >/dev/null 2>&1); then fail "queen switch allowed"; fi
if (do_switch_model "$proj" "hive" "bee-2" 'x;y' >/dev/null 2>&1); then fail "unsafe model allowed"; fi

agents=$(hive_agents_json hive)
assert_eq "$(jq -c 'map(.actor)' <<< "$agents")" '["bee-1","bee-2","queen"]'

echo "model tests passed"
