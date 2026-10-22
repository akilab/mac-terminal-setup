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
