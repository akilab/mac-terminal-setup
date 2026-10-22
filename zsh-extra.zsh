# Managed by mac-terminal-kit. Loaded from ~/.zshrc.
# Preserve existing shell settings; do not use this as a full ~/.zshrc.

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Homebrew bin may be /opt/homebrew (Apple Silicon) or /usr/local (Intel).
if command -v brew >/dev/null 2>&1; then
  _mac_terminal_brew_prefix="$(brew --prefix)"

  if [[ -f "$_mac_terminal_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$_mac_terminal_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  fi
fi

# fzf: key bindings (Ctrl-R/Ctrl-T/Alt-C) and completions
if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border=rounded --info=inline'
  source <(fzf --zsh)
fi

# Jump to frequently visited directories
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

alias ls='eza --icons'
alias ll='eza -lah --icons --git'
alias la='eza -a --icons'
alias tree='eza --tree --icons'
alias cat='bat --paging=never'

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Load highlighting after shell widgets / prompt integrations.
if [[ -n "${_mac_terminal_brew_prefix:-}" && -f "$_mac_terminal_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$_mac_terminal_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
unset _mac_terminal_brew_prefix
