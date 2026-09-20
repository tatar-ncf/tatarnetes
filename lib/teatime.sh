# shellcheck shell=bash
# teatime.sh — Сөтле чәй һәм кыстыбый тәнәфесе / the tea-with-milk break.
# Көненә берничә тапкыр кластер чәйгә туктый. График көнгә бәйле — детерминистик,
# шуңа консоль дә, браузер (UI) да бер үк вакытны күрсәтә.
#
# Several times a day the cluster stops for tea. The schedule is derived
# deterministically from the calendar day, so the CLI and the web UI agree.
# Mirror of this logic lives in ui/app.js (teaWindowsFor / isTeaNow).

TEA_BREAKS_PER_DAY="${AYDA_TEA_BREAKS:-3}"
TEA_BREAK_MIN="${AYDA_TEA_MINUTES:-7}"   # һәр тәнәфес озынлыгы, минут

# Бүгенге тәнәфес тәрәзәләре: "башлану_минуты озынлык" юллары.
tea_windows() {
  local today seed i m
  today=$(date +%Y%m%d)
  seed=$(( 10#$today ))
  i=1
  while [ "$i" -le "$TEA_BREAKS_PER_DAY" ]; do
    # Гади детерминистик таралту (0..1439 минут эчендә).
    m=$(( (seed * (i * 37 + 13) + i * 101) % 1440 ))
    echo "$m $TEA_BREAK_MIN"
    i=$(( i + 1 ))
  done
}

_now_minutes() { echo $(( 10#$(date +%H) * 60 + 10#$(date +%M) )); }

# Хәзер чәй вакытымы? 0 = әйе / returns 0 (true) if currently tea time.
# Тәнәфес ҺӘРКАЙДА эшли (торбада да, CI'да да) — кластер чәй эчә, вәссәлам.
# Кирәкмәсә — AYDA_NO_TEA=1. The break fires EVERYWHERE (pipes, CI too); the
# only opt-out is AYDA_NO_TEA=1. A cluster on a tea break is a cluster on a break.
tea_now() {
  [ -n "${AYDA_FORCE_TEA:-}" ] && return 0   # демо/тест өчен мәҗбүри чәй / force tea for demos
  [ -n "${AYDA_NO_TEA:-}" ] && return 1
  local now s d
  now=$(_now_minutes)
  while read -r s d; do
    [ -z "$s" ] && continue
    if [ "$now" -ge "$s" ] && [ "$now" -lt $(( s + d )) ]; then
      return 0
    fi
  done <<EOF
$(tea_windows)
EOF
  return 1
}

# Хәзерге тәнәфес тәмамланганчы ничә минут калды.
tea_minutes_left() {
  [ -n "${AYDA_FORCE_TEA:-}" ] && { echo "$TEA_BREAK_MIN"; return 0; }
  local now s d
  now=$(_now_minutes)
  while read -r s d; do
    [ -z "$s" ] && continue
    if [ "$now" -ge "$s" ] && [ "$now" -lt $(( s + d )) ]; then
      echo $(( s + d - now )); return 0
    fi
  done <<EOF
$(tea_windows)
EOF
  echo 0
}

# Киләсе тәнәфескә кадәр (HH:MM) — мәгълүмат өчен.
tea_next_hhmm() {
  local now best=1441 s d
  now=$(_now_minutes)
  while read -r s d; do
    [ -z "$s" ] && continue
    if [ "$s" -gt "$now" ] && [ "$s" -lt "$best" ]; then best=$s; fi
  done <<EOF
$(tea_windows)
EOF
  [ "$best" -eq 1441 ] && { echo "иртәгә"; return; }
  printf '%02d:%02d\n' $(( best / 60 )) $(( best % 60 ))
}
