#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fake_herdr="$tmp_dir/fake-herdr"
cat > "$fake_herdr" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

printf '%s\n' "$*" >> "$FAKE_LOG"

case "$1 $2" in
  "tab list")
    case "$FAKE_SCENARIO" in
      missing)
        printf '%s\n' '{"result":{"tabs":[]}}'
        ;;
      stopped)
        printf '%s\n' '{"result":{"tabs":[{"tab_id":"tab-default","label":"Default Agent","agent_status":"unknown"}]}}'
        ;;
      working)
        printf '%s\n' '{"result":{"tabs":[{"tab_id":"tab-default","label":"Default Agent","agent_status":"working"}]}}'
        ;;
    esac
    ;;
  "tab create")
    printf '%s\n' '{"result":{"root_pane":{"pane_id":"pane-new"}}}'
    ;;
  "pane list")
    printf '%s\n' '{"result":{"panes":[{"pane_id":"pane-default","tab_id":"tab-default"}]}}'
    ;;
  *)
    printf '%s\n' '{}'
    ;;
esac
EOF
chmod +x "$fake_herdr"

config_dir="$tmp_dir/config"
mkdir -p "$config_dir"
log_file="$tmp_dir/commands.log"

run_plugin() {
  : > "$log_file"
  HERDR_BIN_PATH="$fake_herdr" \
    HERDR_PLUGIN_CONFIG_DIR="$config_dir" \
    HERDR_WORKSPACE_ID="workspace-1" \
    FAKE_LOG="$log_file" \
    FAKE_SCENARIO="$1" \
    bash "$root_dir/bin/launch-default-agent"
}

assert_log_contains() {
  grep -Fqx -- "$1" "$log_file"
}

run_plugin missing
assert_log_contains 'tab list --workspace workspace-1'
assert_log_contains 'tab create --workspace workspace-1 --focus --label Default Agent'
assert_log_contains 'pane run pane-new a'

run_plugin stopped
assert_log_contains 'tab focus tab-default'
assert_log_contains 'pane list --workspace workspace-1'
assert_log_contains 'pane run pane-default a'

run_plugin working
assert_log_contains 'tab focus tab-default'
if grep -Fq 'pane run' "$log_file"; then
  printf '%s\n' 'working agent must not be started again' >&2
  exit 1
fi

printf '%s\n' '{"tab_label":"Other Agent","agent_command":"codex"}' > "$config_dir/config.json"
run_plugin missing
assert_log_contains 'tab create --workspace workspace-1 --focus --label Other Agent'
assert_log_contains 'pane run pane-new codex'

printf '%s\n' 'smoke test passed'
