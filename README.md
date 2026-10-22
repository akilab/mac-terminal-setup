# macOS Terminal Kit

Recreate a zsh-based macOS Terminal development environment on another Mac.
The files are **flat**, so they can be uploaded to **GitHub Gist** together.

## Included

| File | Purpose |
| --- | --- |
| `Brewfile` | Homebrew tool and Nerd Font dependencies |
| `install.sh` | Installs dependencies and configurations; backs up existing files |
| `starship.toml` | Two-line prompt, always show user@host and full directory |
| `zsh-extra.zsh` | zsh completions, suggestions, highlighting, fzf, zoxide, aliases |
| `tmux.conf` | Mouse, menu (`Ctrl-B` then `m`), splits and clipboard copy |

## Install

1. Install [Homebrew](https://brew.sh/) if needed.
2. Download or clone these files into the **same local directory**.
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

## Add files to GitHub Gist

Gists are flat collections of files (unlike regular GitHub repositories). With GitHub CLI (`gh`) installed and authenticated, in the kit directory:

```bash
gh auth login
gh gist create --desc 'macOS terminal development setup' README.md Brewfile install.sh starship.toml zsh-extra.zsh tmux.conf
```

By default, this creates an unlisted (secret) Gist, **not** an access-controlled private repository; anyone with its URL may view it. Add `--public` only if you want it publicly discoverable. Gist IDs and URLs are returned by `gh` after successful creation. `gh gist clone <GIST_ID>` on another Mac, then run `bash install.sh` in the cloned directory. You can also keep this kit as a conventional GitHub repository.

## Limits

- macOS Terminal application settings (themes, fonts, pointer size, screenshot clipboard behavior, keyboard repeat) are **GUI/system settings**, not installed by these dotfiles.
- Installed tools are not permanently version-pinned; Homebrew will install versions available on the target Mac.
- `~/.zshrc` from another shell framework may already initialize completion or Starship; avoid double initialization if you use Oh My Zsh or similar.
- On Apple Silicon, Homebrew commonly resides at `/opt/homebrew`; on Intel at `/usr/local`. The zsh script detects the prefix.
