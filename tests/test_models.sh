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
# Isolate copilot discovery from the real login/session store of this machine
mkdir -p "$TMP/no-ghc" "$TMP/no-copilot"
GITHUB_COPILOT_HOME="$TMP/no-ghc"
COPILOT_HOME="$TMP/no-copilot"

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

# --- per-CLI custom usage command (no shell evaluation)
CONF_USAGE_CMD_CURSOR="printf {\"used\":3}"
assert_eq "$(usage_json cursor "$proj" | jq -c '.custom')" '{"used":3}'
assert_eq "$(usage_json copilot "$proj" | jq -c '.custom')" 'null'
CONF_USAGE_CMD_CURSOR=""
assert_eq "$(run_usage_cmd "echo 42% used")" '"42% used\n"'

# --- CONF_MODELS applies to the default CLI only; CONF_MODELS_<CLI> to that CLI
DEFAULT_CLI=claude CONF_MODELS="shared-1" CONF_MODELS_CODEX="gpt-5.1-codex"
assert_eq "$(CODEX_HOME="$TMP/none" available_models_json codex "$proj" "" | jq -r '[.[].model] | join(",")')" "gpt-5.1-codex"
assert_contains "$(available_models_json claude "$proj" "" | jq -r '[.[].model] | join(",")')" "shared-1"
DEFAULT_CLI="" CONF_MODELS="" CONF_MODELS_CODEX=""

# --- config: per-Bee and per-CLI keys are loaded, unknown keys ignored
mkdir -p "$TMP/conf"
cat > "$TMP/conf/.beehive.conf" <<'CONF'
CONF_CLI_BEE_2=codex
CONF_MODEL_BEE_2=gpt-5.1-codex
CONF_CLI_QUEEN=claude
CONF_CLI_CMD_CODEX=/opt/codex
CONF_USAGE_CMD_CLAUDE=ccusage blocks --json
CONF_EVIL=1
CONF_CLI_BEE_9=codex
CONF
load_config "$TMP/conf" > /dev/null
assert_eq "$CONF_CLI_BEE_2|$CONF_MODEL_BEE_2|$CONF_CLI_QUEEN|$CONF_CLI_CMD_CODEX|$CONF_USAGE_CMD_CLAUDE" \
    "codex|gpt-5.1-codex|claude|/opt/codex|ccusage blocks --json"
[[ -z "${CONF_EVIL:-}" && -z "${CONF_CLI_BEE_9:-}" ]] || fail "unknown config keys loaded"
unset CONF_CLI_BEE_2 CONF_MODEL_BEE_2 CONF_CLI_QUEEN CONF_CLI_CMD_CODEX CONF_USAGE_CMD_CLAUDE

# --- command resolution per CLI
mkdir -p "$TMP/bin"
for c in claude codex copilot; do printf '#!/bin/bash\n' > "$TMP/bin/$c"; chmod +x "$TMP/bin/$c"; done
PATH="$TMP/bin:$PATH"
DEFAULT_CLI=claude CLI_CMD_OVERRIDE="$TMP/bin/claude"
assert_eq "$(resolve_agent_cmd claude)" "$TMP/bin/claude"
assert_eq "$(resolve_agent_cmd codex)" "codex"
CONF_CLI_CMD_CODEX="$TMP/bin/copilot"
assert_eq "$(resolve_agent_cmd codex)" "$TMP/bin/copilot"
CONF_CLI_CMD_CODEX=""
if (resolve_agent_cmd no-such-cli > /dev/null); then fail "missing CLI resolved"; fi

# --- vibe aliases: inline table form must be parsed, non-alias keys ignored
printf 'models = [\n    { thinking = "max", alias = "glm-5-3" },\n]\ndefault_agent = "ask"\nx-alias = "nope"\n' > "$TMP/proj/.vibe/config.toml"
aliases=$(vibe_config_aliases "$TMP/proj/.vibe/config.toml" | tr '\n' ' ')
assert_eq "$aliases" "glm-5-3 "

# --- copilot catalog parse: only chat models with a picker category
cat > "$TMP/catalog.json" <<'JSON'
{"data":[
 {"id":"claude-sonnet-5.5","name":"Claude Sonnet 5.5","capabilities":{"type":"chat"},"model_picker_category":"versatile"},
 {"id":"gpt-6.1-sol","name":"GPT-6.1 Sol","capabilities":{"type":"chat"},"model_picker_category":"powerful"},
 {"id":"text-embedding-3-small","capabilities":{"type":"embeddings"},"model_picker_category":null},
 {"id":"gpt-6-luna-decisions","capabilities":{"type":"decisions"},"model_picker_category":null},
 {"id":"copilot-search-a","capabilities":{"type":"chat"},"model_picker_category":null}
]}
JSON
parsed=$(copilot_catalog_parse < "$TMP/catalog.json" | tr '\n' ' ')
assert_eq "$parsed" "claude-sonnet-5.5 gpt-6.1-sol "

# --- copilot recent models from the session store
if command -v sqlite3 >/dev/null; then
    mkdir -p "$TMP/copilot-home"
    sqlite3 "$TMP/copilot-home/session-store.db" \
        "create table assistant_usage_events (model text, created_at text);
         insert into assistant_usage_events values ('gpt-5.4-mini','2026-01-01'),('claude-opus-5.5','2026-01-02'),('','2026-01-03'),(null,'2026-01-04');"
    recent=$(COPILOT_HOME="$TMP/copilot-home" copilot_recent_models | tr '\n' ' ')
    assert_eq "$recent" "claude-opus-5.5 gpt-5.4-mini "
fi

# --- copilot catalog via API (stubbed curl) feeds list_available_models with source copilot-api
mkdir -p "$TMP/ghc"
printf '{"https://github.com/login/oauth":[{"accessToken":"fake-oauth"}]}' > "$TMP/ghc/oauth.json"
curl() {
    case "$*" in
        *copilot_internal*) echo '{"token":"fake-cp-token"}' ;;
        *api.githubcopilot.com/models*) cat "$TMP/catalog.json" ;;
        *) return 1 ;;
    esac
}
GITHUB_COPILOT_HOME="$TMP/ghc" COPILOT_HOME="$TMP/no-copilot"
api_models=$(GITHUB_COPILOT_HOME="$TMP/ghc" COPILOT_HOME="$TMP/no-copilot" list_available_models copilot "$TMP/proj" "" | awk -F'\t' '$1=="copilot-api"{print $2}' | tr '\n' ' ')
assert_eq "$api_models" "claude-sonnet-5.5 gpt-6.1-sol "
unset -f curl
GITHUB_COPILOT_HOME="$TMP/no-ghc"

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
        list-panes) printf '%%1|bee-1|copilot|gpt-5-mini|/opt/bin/copilot\n%%2|bee-2|copilot||/opt/bin/copilot\n%%3|queen|||\n' ;;
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

agents=$(hive_agents_json hive claude /opt/bin/claude)
assert_eq "$(jq -c 'map([.actor, .cli, .command])' <<< "$agents")" \
    '[["bee-1","copilot","/opt/bin/copilot"],["bee-2","copilot","/opt/bin/copilot"],["queen","claude","/opt/bin/claude"]]'

# --- switch a Bee to another CLI
: > "$TMUX_LOG"
do_switch_model "$proj" "hive" "bee-1" "gpt-5.1-codex" "codex" > /dev/null 2>&1
log=$(cat "$TMUX_LOG")
assert_contains "$log" "set-option -p -t %1 @beehive_cli codex"
assert_contains "$log" "set-option -p -t %1 @beehive_cli_cmd codex"
assert_contains "$log" "codex --sandbox workspace-write"
assert_contains "$log" "--model gpt-5.1-codex"
[[ "$log" != *"ANTHROPIC_MODEL=gpt-5.1-codex"* ]] || fail "codex model passed via ANTHROPIC_MODEL"
missing_cli=""
for f in $SUPPORTED_CLIS; do
    if ! resolve_agent_cmd "$f" > /dev/null 2>&1; then missing_cli="$f"; break; fi
done
if [[ -n "$missing_cli" ]] && (do_switch_model "$proj" "hive" "bee-1" "x" "$missing_cli" > /dev/null 2>&1); then
    fail "switch to missing CLI ($missing_cli) allowed"
fi
if (do_switch_model "$proj" "hive" "bee-1" "x" "nope" > /dev/null 2>&1); then fail "unknown CLI allowed"; fi

# --- --models reports every CLI in use plus installed ones (machine-independent)
JSON_OUTPUT=true
report=$(CLAUDE_CONFIG_DIR="$TMP/claude" CODEX_HOME="$TMP/codex" do_models "$proj" hive "")
assert_eq "$(jq -r '.clis[] | select(.cli=="copilot") | .in_use' <<< "$report")" "true"
for f in $SUPPORTED_CLIS; do
    if resolve_agent_cmd "$f" > /dev/null 2>&1; then
        jq -e --arg f "$f" '.clis[] | select(.cli==$f)' <<< "$report" > /dev/null \
            || fail "installed CLI $f missing from report"
    fi
done
assert_eq "$(jq -r '.clis[] | select(.cli == "codex") | .usage.builtin.rate_limits.primary.used_percent' <<< "$report")" "37.5"

# --- launch with mixed CLIs sets per-pane CLI, command and model
mkdir -p "$TMP/hive"; touch "$TMP/hive/CLAUDE.md"
bd() { return 0; }
: > "$TMUX_LOG"
SESSION_NAME=hive DEFAULT_CLI=claude CLI_CMD_OVERRIDE="" APPROVAL_MODE=auto QUEEN_CLI=claude
BEE_CLIS=("" claude codex) BEE_MODELS=("" sonnet gpt-5.1-codex)
do_launch "$TMP/hive" "sonnet" "opus" 2 true claude > /dev/null 2>&1
log=$(cat "$TMUX_LOG")
assert_contains "$log" "set-option -p -t hive:0.0 @beehive_cli claude"
assert_contains "$log" "set-option -p -t hive:0.1 @beehive_cli codex"
assert_contains "$log" "set-option -p -t hive:0.1 @beehive_model gpt-5.1-codex"
assert_contains "$log" "set-option -p -t hive:0.2 @beehive_actor queen"
grep -q "send-keys -t hive:0.1 .*codex --sandbox workspace-write" "$TMUX_LOG" || fail "bee-2 not launched with codex"
grep -q "send-keys -t hive:0.0 .*ANTHROPIC_MODEL=sonnet .*claude --permission-mode auto" "$TMUX_LOG" || fail "bee-1 not launched with claude"
grep -q "send-keys -t hive:0.2 .*ANTHROPIC_MODEL=opus .*claude --permission-mode auto" "$TMUX_LOG" || fail "queen not launched with claude"

BEE_CLIS=("" claude agy)
# force agy to be unresolvable regardless of what is installed on this machine
if (CONF_CLI_CMD_AGY=/nonexistent-agy do_launch "$TMP/hive" "" "" 2 true claude > /dev/null 2>&1); then fail "launch with missing CLI succeeded"; fi

echo "model tests passed"
