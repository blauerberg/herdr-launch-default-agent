# herdr-launch-default-agent

[![CI](https://github.com/blauerberg/herdr-launch-default-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/blauerberg/herdr-launch-default-agent/actions/workflows/ci.yml)

Inspired by Omarchy Linux's default-agent workflow, this plugin provides a
quick way to reach a preferred agent in Herdr.

When triggered, it focuses a configured tab and launches the configured agent
only when that tab has no active agent. If the tab does not exist, the plugin
creates it first.

The shared plugin can be used across Linux and macOS while the tab name and
agent command remain user-specific.

## Requirements

- Herdr 0.9.0 or later
- `bash`
- `jq`
- Linux or macOS
- The configured `agent_command` available in the target pane's shell

## Install from GitHub

```sh
herdr plugin install blauerberg/herdr-launch-default-agent
```

Bind the action in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+a"
type = "plugin_action"
command = "herdr-launch-default-agent.open"
description = "focus or open Default Agent"
```

## Configuration

Get the per-plugin configuration directory:

```sh
config_dir="$(herdr plugin config-dir herdr-launch-default-agent)"
"${EDITOR:-vi}" "$config_dir/config.json"
```

Edit `config.json`:

```json
{
  "tab_label": "Default Agent",
  "agent_command": "a"
}
```

Both values are optional. The defaults are `Default Agent` and `a`.
The command is passed as one command argument to `herdr pane run`.

The configuration is read when the action runs, so changing `config.json` does
not require a Herdr reload.

For local development, link the checkout instead:

```sh
herdr plugin link /path/to/herdr-launch-default-agent
```

## Example configuration

For an Omarchy-style dedicated agent tab, configure the plugin directly:

```json
{
  "tab_label": "🤖 Agent",
  "agent_command": "codex --cd \"$HOME/Work\" --model gpt-5.6-luna -c model_reasoning_effort=max"
}
```

After changing the keybinding, check and reload Herdr:

```sh
herdr config check
herdr server reload-config
```
