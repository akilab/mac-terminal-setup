#!/usr/bin/env bash
set -euo pipefail

# Run from extracted kit directory. Default: keep existing configuration by
# backing up and installing managed files without replacing ~/.zshrc.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.mac-terminal-kit-backups/$(date +%Y%m%d-%H%M%S)-$$"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo 'ERROR: macOS only.' >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo 'Homebrew is required. Install from https://brew.sh/ then rerun this script.' >&2
  exit 1
fi

# Make existing Homebrew executables reachable in this shell.
eval "$(brew shellenv)"

echo '==> Installing required tools (Homebrew Bundle)'
brew bundle --file="$SCRIPT_DIR/Brewfile"

mkdir -p "$HOME/.config" "$BACKUP_DIR"

backup_and_install() {
  local source="$1" destination="$2"
  if [[ -e "$destination" || -L "$destination" ]]; then
    if cmp -s "$source" "$destination"; then
      echo "==> Already current: $destination"
      return
    fi
    cp -p "$destination" "$BACKUP_DIR/$(basename "$destination")"
    echo "==> Backup: $destination"
  fi
  cp "$source" "$destination"
  echo "==> Installed: $destination"
}

backup_and_install "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
backup_and_install "$SCRIPT_DIR/zsh-extra.zsh" "$HOME/.config/zsh-extra.zsh"
backup_and_install "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"

# Validate before installing Claude files; never replace unrelated settings.
CLAUDE_DIR="$HOME/.claude"
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"
mkdir -p "$CLAUDE_DIR"
if [[ -e "$CLAUDE_SETTINGS" || -L "$CLAUDE_SETTINGS" ]]; then
  jq -e -s 'length == 1 and (.[0] | type == "object")' "$CLAUDE_SETTINGS" >/dev/null
fi
CLAUDE_TEMP=$(mktemp "$CLAUDE_DIR/.settings.json.XXXXXX")
trap 'rm -f "$CLAUDE_TEMP"' EXIT
if [[ -e "$CLAUDE_SETTINGS" ]]; then
  jq --slurpfile managed "$SCRIPT_DIR/claude/settings.json" \
    '.statusLine = $managed[0].statusLine' "$CLAUDE_SETTINGS" > "$CLAUDE_TEMP"
else
  jq '{statusLine}' "$SCRIPT_DIR/claude/settings.json" > "$CLAUDE_TEMP"
fi
backup_and_install "$SCRIPT_DIR/claude/statusline.sh" "$CLAUDE_DIR/statusline.sh"
chmod +x "$CLAUDE_DIR/statusline.sh"
if [[ -e "$CLAUDE_SETTINGS" ]] && \
  jq -e --slurpfile merged "$CLAUDE_TEMP" '. == $merged[0]' "$CLAUDE_SETTINGS" >/dev/null; then
  echo "==> Already current: $CLAUDE_SETTINGS"
else
  if [[ -e "$CLAUDE_SETTINGS" ]]; then
    cp -p "$CLAUDE_SETTINGS" "$BACKUP_DIR/claude-settings.json"
    chmod 600 "$BACKUP_DIR/claude-settings.json"
  fi
  # Write through an existing symlink rather than replacing the link.
  if [[ -e "$CLAUDE_SETTINGS" ]]; then
    cat "$CLAUDE_TEMP" > "$CLAUDE_SETTINGS"
  else
    mv "$CLAUDE_TEMP" "$CLAUDE_SETTINGS"
  fi
  echo "==> Merged statusLine: $CLAUDE_SETTINGS"
fi
rm -f "$CLAUDE_TEMP"
trap - EXIT

ZSHRC="$HOME/.zshrc"
START_MARKER='# >>> mac-terminal-kit >>>'
END_MARKER='# <<< mac-terminal-kit <<<' 
if [[ ! -e "$ZSHRC" ]]; then
  touch "$ZSHRC"
else
  cp -p "$ZSHRC" "$BACKUP_DIR/zshrc"
fi

if ! grep -Fqx "$START_MARKER" "$ZSHRC"; then
  cat >> "$ZSHRC" <<'ZSHBLOCK'

# >>> mac-terminal-kit >>>
# Load custom shell settings; earlier unrelated ~/.zshrc lines are preserved.
[[ -f "$HOME/.config/zsh-extra.zsh" ]] && source "$HOME/.config/zsh-extra.zsh"
# <<< mac-terminal-kit <<<
ZSHBLOCK
  echo "==> Added managed block to $ZSHRC"
else
  echo "==> Managed block already exists in $ZSHRC"
fi

# macOS Terminal profile/keyboard settings are not changed by this script.
echo
printf 'Complete. Backups (if any): %s\n' "$BACKUP_DIR"
echo 'Open a new Terminal window (or run: exec zsh).'
echo 'Inside an existing tmux session, run: tmux source-file ~/.tmux.conf'
echo 'In Terminal > Settings > Profiles > Text, choose MesloLGS Nerd Font Mono (14 pt).'
