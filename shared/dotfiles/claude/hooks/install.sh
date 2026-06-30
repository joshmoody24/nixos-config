#!/bin/sh
# Installs the comment-guard PreToolUse hook into ~/.claude/settings.json.
# Deps: curl, jq, node. Safe to re-run (won't duplicate or clobber other hooks).
set -eu

repo="https://raw.githubusercontent.com/joshmoody24/nixos-config/main"
hooks_dir="$HOME/.claude/hooks"
settings="$HOME/.claude/settings.json"
command="node $hooks_dir/comment-guard.js"

mkdir -p "$hooks_dir"
rm -f "$hooks_dir/comment-guard.js"
curl -fsSL "$repo/shared/dotfiles/claude/hooks/comment-guard.js" -o "$hooks_dir/comment-guard.js"

[ -f "$settings" ] || echo '{}' >"$settings"

jq --arg c "$command" '
  .hooks.PreToolUse |= ((. // []) |
    if any(.[]?.hooks[]?; .command == $c) then .
    else . + [{matcher: "Edit|Write|MultiEdit", hooks: [{type: "command", command: $c}]}]
    end)
' "$settings" >"$settings.tmp" && mv "$settings.tmp" "$settings"

echo "comment-guard installed -> $command"
