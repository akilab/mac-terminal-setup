#!/bin/bash
# Claude Code custom status line (2 lines, Nerd Font, Starship-like dark palette)
#   line 1: model │ effort │ directory │ git branch
#   line 2: context bar + % │ 5h limit remaining │ 7d limit remaining
#
# Env overrides:
#   STATUSLINE_NERD_FONT=0   disable Nerd Font icons
#   STATUSLINE_COLS=<n>      force the width used for layout decisions

export LC_ALL=en_US.UTF-8

# Claude Code may start without the interactive shell's Homebrew PATH.
if ! command -v jq >/dev/null 2>&1; then
  export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
fi

input=$(cat)

# ---------- colors (bold ANSI, same as starship.toml) ----------
RST=$'\033[0m'
PURPLE=$'\033[1;35m'
BLUE=$'\033[1;34m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[1;31m'
CYAN=$'\033[1;36m'
DIM=$'\033[90m'

# ---------- width detection ----------
cols=${STATUSLINE_COLS:-}
if [ -z "$cols" ] && [ -n "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
  cols=$(tmux display-message -p ${TMUX_PANE:+-t "$TMUX_PANE"} '#{pane_width}' 2>/dev/null)
fi
if [ -z "$cols" ]; then
  cols=$( { stty size </dev/tty; } 2>/dev/null | awk '{print $2}')
fi
[ -z "$cols" ] && cols=${COLUMNS:-}
case $cols in ''|*[!0-9]*) cols=120 ;; esac

# full >= 70, compact 45-69, mini < 45
if [ "$cols" -ge 70 ]; then
  tier=full
elif [ "$cols" -ge 45 ]; then
  tier=compact
else
  tier=mini
fi

# ---------- icons ----------
if [ "${STATUSLINE_NERD_FONT:-1}" != 0 ] && [ "$tier" != mini ]; then
  I_MODEL=$'\xf3\xb0\x9a\xa9 '   # nf-md-robot
  I_EFFORT=$'\xf3\xb0\xa7\x91 '  # nf-md-brain
  I_DIR=$'\xef\x81\xbc '         # nf-fa-folder_open
  I_BRANCH=$'\xee\x82\xa0 '      # nf-pl-branch
  I_CTX=$'\xf3\xb0\x8d\x9b '     # nf-md-memory
  I_5H=$'\xf3\xb0\x94\x9f '      # nf-md-timer_sand
  I_7D=$'\xf3\xb0\x83\xad '      # nf-md-calendar
else
  I_MODEL='' I_EFFORT='' I_DIR='' I_BRANCH='' I_CTX='' I_5H='' I_7D=''
fi

if [ "$tier" = mini ]; then
  SEP="${DIM}│${RST}"
else
  SEP=" ${DIM}│${RST} "
fi

# ---------- parse JSON (single jq call) ----------
fields=$(printf '%s' "$input" | jq -r --arg effenv "${CLAUDE_CODE_EFFORT_LEVEL:-}" '
  def num: if type == "number" then . elif type == "string" then (tonumber? // null) else null end;
  def epoch:
    if type == "number" then .
    elif type == "string" then ((tonumber?) // (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601?) // null)
    else null end;
  def dur:
    if . == null then ""
    else ((. - now) | floor) as $s
      | if $s <= 0 then ""
        elif $s >= 86400 then "\($s / 86400 | floor)d\(($s % 86400) / 3600 | floor)h"
        elif $s >= 3600  then "\($s / 3600 | floor)h\(($s % 3600) / 60 | floor)m"
        else "\($s / 60 | floor)m" end
    end;
  def ctxpct:
    (.context_window.used_percentage | num)
    // (.context_window as $c
        | ($c.current_usage // null) as $u
        | ($c.context_window_size | num) as $size
        | if $u != null and $size != null and $size > 0 then
            ((($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0)
              + ($u.cache_read_input_tokens // 0)) * 100 / $size)
          else null end);
  def remain: (.used_percentage | num) as $p
    | if $p == null then "" else ([100 - $p, 0] | max | round | tostring) end;
  def effort:
    ((.effort.level?) // (.effort?) // (.reasoning_effort?) // (.model.reasoning_effort?) // null)
    | if type == "string" and . != "" then . else $effenv end;
  [
    (.model.display_name // .model.id // "Claude"),
    effort,
    (.workspace.current_dir // .cwd // ""),
    (ctxpct | if . == null then "" else (round | tostring) end),
    (.rate_limits.five_hour // {} | remain),
    (.rate_limits.five_hour.resets_at // null | epoch | dur),
    (.rate_limits.seven_day // {} | remain),
    (.rate_limits.seven_day.resets_at // null | epoch | dur)
  ] | map(if . == null then "" else tostring end) | join("\u001f")
' 2>/dev/null)

IFS=$'\x1f' read -r model effort dir ctx r5 r5t r7 r7t <<<"$fields"
[ -z "$model" ] && model=Claude

# effort fallback: user settings
if [ -z "$effort" ] && [ -f "$HOME/.claude/settings.json" ]; then
  effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi

# ---------- helpers ----------
trunc() { # trunc <string> <max>
  local s=$1 max=$2
  if [ "${#s}" -gt "$max" ]; then
    printf '%s…' "${s:0:$((max - 1))}"
  else
    printf '%s' "$s"
  fi
}

pct_color() { # used% -> color
  if [ "$1" -ge 90 ]; then printf '%s' "$RED"
  elif [ "$1" -ge 70 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

remain_color() { # remaining% -> color
  if [ "$1" -le 10 ]; then printf '%s' "$RED"
  elif [ "$1" -le 30 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$CYAN"; fi
}

# ---------- line 1 ----------
[ -z "$dir" ] && dir=$PWD
if [ "$dir" = "$HOME" ]; then dirname='~'; else dirname=${dir##*/}; fi
[ -z "$dirname" ] && dirname='/'

branch=''
if [ -d "$dir" ]; then
  branch=$(git -C "$dir" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null \
    || git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

case $tier in
  full)    maxdir=30 maxbr=30 ;;
  compact) maxdir=20 maxbr=18 ;;
  mini)    maxdir=14 maxbr=12 ;;
esac

line1="${PURPLE}${I_MODEL}${model}${RST}"
if [ -n "$effort" ] && [ "$tier" != mini ]; then
  line1+="${SEP}${DIM}${I_EFFORT}${RST}${CYAN}${effort}${RST}"
fi
line1+="${SEP}${BLUE}${I_DIR}$(trunc "$dirname" "$maxdir")${RST}"
if [ -n "$branch" ]; then
  line1+="${SEP}${GREEN}${I_BRANCH}$(trunc "$branch" "$maxbr")${RST}"
fi

# ---------- line 2 ----------
if [ -n "$ctx" ]; then
  [ "$ctx" -gt 100 ] && ctx=100
  filled=$(( (ctx + 5) / 10 ))
  [ "$filled" -gt 10 ] && filled=10
  c=$(pct_color "$ctx")
  label="${ctx}%"
else
  filled=0
  c=$DIM
  label='--%'
fi
bar=''
i=0
while [ $i -lt 10 ]; do
  if [ $i -lt $filled ]; then bar+="${c}█"; else bar+="${DIM}░"; fi
  i=$((i + 1))
done
line2="${DIM}${I_CTX}${RST}${bar}${RST} ${c}${label}${RST}"

if [ -n "$r5" ]; then
  seg="${DIM}${I_5H}5h${RST} $(remain_color "$r5")${r5}%${RST}"
  [ "$tier" = full ] && [ -n "$r5t" ] && seg+=" ${DIM}(${r5t})${RST}"
  line2+="${SEP}${seg}"
fi
if [ -n "$r7" ] && [ "$tier" != mini ]; then
  seg="${DIM}${I_7D}7d${RST} $(remain_color "$r7")${r7}%${RST}"
  [ "$tier" = full ] && [ -n "$r7t" ] && seg+=" ${DIM}(${r7t})${RST}"
  line2+="${SEP}${seg}"
fi

printf '%s\n%s\n' "$line1" "$line2"
