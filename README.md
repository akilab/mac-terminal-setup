# macOS Terminal Kit

Recreate a zsh-based macOS Terminal development environment on another Mac.
Keep the directory structure when cloning or downloading this repository (including `claude/`).

## Included

| File | Purpose |
| --- | --- |
| `Brewfile` | Homebrew tool and Nerd Font dependencies |
| `install.sh` | Installs dependencies and configurations; backs up existing files |
| `starship.toml` | Two-line prompt, always show user@host and full directory |
| `zsh-extra.zsh` | zsh completions, suggestions, highlighting, fzf, zoxide, aliases |
| `claude/statusline.sh` | Claude Code two-line status line |
| `claude/settings.json` | Only the managed `statusLine` setting |
| `tmux.conf` | Mouse, menu (`Ctrl-B` then `m`), splits and clipboard copy |

## Install

1. Install [Homebrew](https://brew.sh/) if needed.
2. Download or clone these files into the **same local directory**, preserving subdirectories.
3. From that directory run:

   ```bash
   bash install.sh
   ```

4. Open a new Terminal window or run `exec zsh`.
5. In **Terminal → Settings → Profiles → Text**, choose **MesloLGS Nerd Font Mono**, Regular, **14 pt**. If it is missing, log out/in or restart once.
6. Inside a running tmux session, reload with `tmux source-file ~/.tmux.conf`.

The installer does not overwrite `.zshrc`; it appends **one** source block, preserving previous content. It replaces `~/.tmux.conf`, `~/.config/starship.toml`, and `~/.config/zsh-extra.zsh` after making backups under `~/.mac-terminal-kit-backups/`. Run a second time safely without duplicate `.zshrc` blocks. Review any existing `.zshrc` Starship/plugin init lines and remove duplicates yourself if relevant.

## tmux controls

| Action | Key / action |
| --- | --- |
| Menu | `Ctrl-B`, then `m` |
| Split left/right | `Ctrl-B`, then `|` |
| Split top/bottom | `Ctrl-B`, then `-` |
| Reload config | `Ctrl-B`, then `r` |
| Mouse select | Copy to tmux buffer + macOS clipboard (in supported tmux selection mode) |
| Paste | `Command-V` (macOS); middle-click pastes tmux buffer |
| Close pane | `exit` or menu → Close Pane |

**Right-click paste is intentionally not enabled.** It did not work consistently in the original macOS Terminal setup. Right click has no tmux menu; use `Command-V` or middle-click for now. Vim may capture mouse events itself.

## fzf and CLI shortcuts

- `Ctrl-R`: search history, `Ctrl-T`: select files, `Option-C`: jump to a directory (terminal Option/Meta behavior may need adjustment)
- `ls`, `ll`, `la`, `tree`: eza aliases
- `cat`: bat alias; use `/bin/cat` for standard behavior
- `z <fragment>` / `zi`: zoxide directory navigation

## Claude Code status line

Install Claude Code separately. `bash install.sh` installs `jq`, copies the script to
`~/.claude/statusline.sh`, and merges only `statusLine` into `~/.claude/settings.json`
using `jq`. Other settings are preserved. Invalid JSON or a non-object settings file
stops the Claude setup. Existing changed files are backed up under
`~/.mac-terminal-kit-backups/<timestamp>-<pid>/` (`statusline.sh` and
`claude-settings.json`). Backups can contain private settings; keep them local.
Unchanged Claude settings are not rewritten or backed up on repeat runs.

Restart Claude Code after installation. The first line shows model, effort (when
available), directory and Git branch; the second shows context usage and available
5-hour / 7-day quota remaining. Missing context is `--%`; unavailable branch and
quota segments are omitted. Detached HEAD shows a short commit ID.

The layout uses tmux pane width, terminal width, then `COLUMNS` (default 120).
Widths below 70 use compact mode; below 45 use mini mode. Long directory and branch
names are shortened. `STATUSLINE_COLS=80` overrides width;
`STATUSLINE_NERD_FONT=0` disables icons. Very narrow panes or long model names may
still wrap; resize the pane as needed. Homebrew `jq` is supported at both
`/opt/homebrew/bin` and `/usr/local/bin` when absent from the inherited PATH.

Quick check (expect two output lines):

```bash
printf '%s' '{"model":{"display_name":"Claude"},"context_window":{"used_percentage":42}}' | STATUSLINE_COLS=80 bash ~/.claude/statusline.sh
printf '{}' | bash ~/.claude/statusline.sh
```

In tmux, repeat without `STATUSLINE_COLS` at different pane widths and confirm
Nerd Font icons render correctly. See [the specification](docs/CLAUDE-STATUSLINE.md)
for validation and restore details. Gists cannot preserve this directory structure;
use a repository clone or an archive for installation.

## Limits

- macOS Terminal application settings (themes, fonts, pointer size, screenshot clipboard behavior, keyboard repeat) are **GUI/system settings**, not installed by these dotfiles.
- Installed tools are not permanently version-pinned; Homebrew will install versions available on the target Mac.
- `~/.zshrc` from another shell framework may already initialize completion or Starship; avoid double initialization if you use Oh My Zsh or similar.
- On Apple Silicon, Homebrew commonly resides at `/opt/homebrew`; on Intel at `/usr/local`. The zsh script detects the prefix.
