# shellcheck shell=bash
# i18n.sh — Тәрҗемә катламы / translation layer.
# t <key> [printf-args...]   — сайланган телдә юлны кайтара (яңа юл кушмый).
# tn <word>                  — сингармонизм буенча күплек кушымтасы.
# Тел: AYDA_LANG=tt|en (default tt). Язу: AYDA_ALIF=cyrl|latin|arab (tt өчен).
# Requires: catalog.sh (generated), alif.sh sourced first.

: "${AYDA_LANG:=tt}"

# t KEY [ARGS] — каталогтан юл ал, printf аша тутыр, кирәк булса транслитерация.
t() {
  local key="$1"; shift
  local fmt; fmt="$(catalog_lookup "$AYDA_LANG" "$key")"
  local out; out="$(printf "$fmt" "$@")"
  if [ "$AYDA_LANG" = "tt" ]; then
    printf '%s' "$out" | alif_render
  else
    printf '%s' "$out"
  fi
}

# tn WORD — татар күплек кушымтасын сингармонизм кагыйдәсе буенча ясый.
# Front/back vowel harmony + nasal assimilation (м/н/ң → -нар/-нәр).
# кузак→кузаклар · төен→төеннәр · хезмәт→хезмәтләр · мәйдан→мәйданнар · сер→серләр
tn() {
  local w="$1" lastvow lastch front=0 nas=0 out
  lastvow="$(printf '%s' "$w" | grep -oE '[аәоөуүыиеэюёяАӘОӨУҮЫИЕЭЮЁЯ]' | tail -1)"
  lastch="$(printf '%s' "$w" | grep -oE '.$')"
  case "$lastvow" in ә|ө|ү|е|и|э|ю|ё|Ә|Ө|Ү|Е|И|Э|Ю|Ё) front=1 ;; esac
  case "$lastch" in м|н|ң|М|Н|Ң) nas=1 ;; esac
  if [ "$front" -eq 1 ]; then
    if [ "$nas" -eq 1 ]; then out="${w}нәр"; else out="${w}ләр"; fi
  else
    if [ "$nas" -eq 1 ]; then out="${w}нар"; else out="${w}лар"; fi
  fi
  if [ "$AYDA_LANG" = "tt" ]; then printf '%s' "$out" | alif_render; else printf '%s' "$out"; fi
}
