#!/usr/bin/env bash
# Consolidated CPU + RAM status for the tmux status bar.
# Replaces the 24 individual #(...) script calls that the
# tmux-cpu plugin injects, cutting process spawns from 24/s to 1/s.

set -u

# --- CPU percentage ----------------------------------------------------------
get_cpu_pct() {
  local pct=""
  if command -v iostat &>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
      pct=$(iostat -c 2 2>/dev/null | sed '/^\s*$/d' | tail -n 1 \
        | awk '{printf "%.1f", 100-$NF}')
    else
      pct=$(iostat -c 1 2 2>/dev/null | sed '/^\s*$/d' | tail -n 1 \
        | awk '{printf "%.1f", 100-$NF}')
    fi
  fi
  if [[ -z "$pct" ]]; then
    # Linux: read /proc/stat twice with a 1 s gap for an accurate rate.
    if [[ -r /proc/stat ]]; then
      local c1 c2 idle1 idle2
      read -r _ user1 nice1 sys1 idle1 iowait1 irq1 softirq1 steal1 _ < /proc/stat
      c1=$((user1 + nice1 + sys1 + iowait1 + irq1 + softirq1 + steal1))
      sleep 1
      read -r _ user2 nice2 sys2 idle2 iowait2 irq2 softirq2 steal2 _ < /proc/stat
      c2=$((user2 + nice2 + sys2 + iowait2 + irq2 + softirq2 + steal2))
      local total=$((c2 - c1))
      local idle_diff=$((idle2 - idle1))
      if [[ $total -gt 0 ]]; then
        pct=$(awk -v u=$((total - idle_diff)) -v t="$total" 'BEGIN {printf "%.1f", 100*u/t}')
      fi
    fi
  fi
  if [[ -z "$pct" ]]; then
    # Final fallback: ps snapshot (inaccurate but always available).
    local load cpus
    load=$(ps -aux 2>/dev/null | awk 'NR>1 {s+=$3} END {print s+0}')
    cpus=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 1)
    pct=$(awk -v l="${load:-0}" -v c="$cpus" 'BEGIN {printf "%.1f", l/c}')
  fi
  echo "${pct:-0.0}"
}

# --- RAM percentage ----------------------------------------------------------
get_ram_pct() {
  if command -v free &>/dev/null; then
    free 2>/dev/null | awk '/^Mem:/ {printf "%.1f", 100*$3/$2}'
  elif command -v vm_stat &>/dev/null; then
    vm_stat 2>/dev/null | awk '
      /Pages active/               { a += $NF * 4096 }
      /Pages inactive/             { i += $NF * 4096 }
      /Pages speculative/          { s += $NF * 4096 }
      /Pages wired down/           { w += $NF * 4096 }
      /Pages occupied by compressor/ { c += $NF * 4096 }
      /Pages purgeable/            { p += $NF * 4096 }
      /File-backed pages/          { f += $NF * 4096 }
      /Pages free/                { fr += $NF * 4096 }
      END {
        used  = a + i + s + w + c - p - f
        total = used + fr
        if (total > 0) printf "%.1f", 100 * used / total
      }'
  fi
}

# --- colour helpers (catppuccin-friendly) ------------------------------------
# Catppuccin Macchiato palette
color_for_pct() {
  local pct="$1"
  if   awk -v p="$pct" 'BEGIN {exit !(p >= 80)}'; then echo "#f38ba8"   # red
  elif awk -v p="$pct" 'BEGIN {exit !(p >= 30)}'; then echo "#f9e2af"   # yellow
  else echo "#a6e3a1"                                                   # green
  fi
}

cpu_icon_for() {
  local pct="$1"
  if   awk -v p="$pct" 'BEGIN {exit !(p >= 80)}'; then printf "≣"
  elif awk -v p="$pct" 'BEGIN {exit !(p >= 30)}'; then printf "≡"
  else printf "="
  fi
}

# --- main --------------------------------------------------------------------
CPU_PCT=$(get_cpu_pct)
RAM_PCT=$(get_ram_pct)
[[ -z "$RAM_PCT" ]] && RAM_PCT="0.0"

CPU_ICON=$(cpu_icon_for "$CPU_PCT")
CPU_COL=$(color_for_pct "$CPU_PCT")
RAM_COL=$(color_for_pct "$RAM_PCT")

# Single tmux-styled string, e.g.  ≡ 45.2%  🧠 67.8%
printf ' %s #[fg=%s]%s%%  #[fg=%s]%s%%' \
  "$CPU_ICON" "$CPU_COL" "$CPU_PCT" "$RAM_COL" "$RAM_PCT"
