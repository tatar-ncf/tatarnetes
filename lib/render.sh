# shellcheck shell=bash
# render.sh — Татарнетес төсләре һәм чыгарылыш / colours and rendering helpers.
# Bash 3.2 compatible (macOS default).

# --- Тыныч режим / quiet detection --------------------------------------
# Бизәкләрне stderr'га гына чыгарабыз, шуңа торба (pipe) чиста кала.
# Decorations go to stderr so stdout stays pipe-clean.
tat_fun_enabled() {
  [ -n "${AYDA_QUIET:-}" ] && return 1
  [ -n "${AYDA_PLAIN:-}" ] && return 1
  [ -n "${AYDA_FORCE_FUN:-}" ] && return 0
  # stderr торбага киткәндә (CI, |) бизәкне сүндерәбез.
  [ -t 2 ] || return 1
  return 0
}

tat_color_enabled() {
  [ -n "${NO_COLOR:-}" ] && return 1
  [ -n "${AYDA_PLAIN:-}" ] && return 1
  [ -t 2 ] || return 1
  return 0
}

# --- Татар палитрасы / Tatar palette (Tatarstan flag: green/white/red + gold)
if tat_color_enabled; then
  TAT_GREEN=$'\033[38;5;29m'
  TAT_RED=$'\033[38;5;160m'
  TAT_GOLD=$'\033[38;5;178m'
  TAT_WHITE=$'\033[38;5;231m'
  TAT_DIM=$'\033[38;5;244m'
  TAT_BOLD=$'\033[1m'
  TAT_RESET=$'\033[0m'
else
  TAT_GREEN=''; TAT_RED=''; TAT_GOLD=''; TAT_WHITE=''
  TAT_DIM=''; TAT_BOLD=''; TAT_RESET=''
fi

# Татар келәме бизәге / a woven-carpet divider
tat_carpet() {
  tat_fun_enabled || return 0
  printf '%b\n' "${TAT_RED}◆${TAT_GREEN}◇${TAT_GOLD}◆${TAT_GREEN}◇${TAT_RED}◆${TAT_GREEN}◇${TAT_GOLD}◆${TAT_GREEN}◇${TAT_RED}◆${TAT_GREEN}◇${TAT_GOLD}◆${TAT_GREEN}◇${TAT_RED}◆${TAT_GOLD}◇${TAT_RED}◆${TAT_GREEN}◇${TAT_GOLD}◆${TAT_GREEN}◇${TAT_RED}◆${TAT_RESET}" >&2
}

tat_say()  { tat_fun_enabled && printf '%b\n' "$*" >&2; }
tat_dim()  { tat_fun_enabled && printf '%b\n' "${TAT_DIM}$*${TAT_RESET}" >&2; }
tat_bold() { printf '%b\n' "${TAT_BOLD}$*${TAT_RESET}" >&2; }
