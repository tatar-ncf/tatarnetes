# shellcheck shell=bash
# calendar.sh — Милли көнтәртип / national calendar behaviour.
# Билгеле көннәрдә бәйрәм баннеры кайтара: Нәүрүз, Сабантуй, җомга, һ.б.
# Returns a festival catalog-key for special days (Nauruz, Sabantuy, Friday…).
# Күчмә (ислам) даталар — data/holidays.tt файлында (MM-DD key), кулдан тутырыла.

_HOLIDAYS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../data" 2>/dev/null && pwd)/holidays.tt"

# tat_festival → каталог ачкычы яки буш / echoes a festival key or empty.
tat_festival() {
  local md dow
  md="$(date +%m-%d)"
  dow="$(date +%u)"   # 1=дүшәмбе … 7=якшәмбе / 1=Mon … 7=Sun

  # 1) Кулдан кертелгән күчмә бәйрәмнәр (Корбан/Ураза) / manual movable holidays.
  if [ -f "$_HOLIDAYS_FILE" ]; then
    local hkey
    hkey="$(grep -E "^${md}[[:space:]]" "$_HOLIDAYS_FILE" 2>/dev/null | awk '{print $2}' | head -1)"
    [ -n "$hkey" ] && { printf '%s' "$hkey"; return 0; }
  fi

  # 2) Тотрыклы даталар / fixed dates.
  case "$md" in
    03-21|03-22) printf 'festival.nauruz'; return 0 ;;
  esac

  # 3) Җомга / Friday.
  [ "$dow" = "5" ] && { printf 'friday.greeting'; return 0; }

  return 1
}
