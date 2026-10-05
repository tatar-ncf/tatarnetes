# shellcheck shell=bash
# complete.sh — Tab-тулыландыру өчен уртак ярдәмчеләр / shared shell-completion helpers.
# `ayda __complete …` һәм `tos __complete …` моны куллана; bash/zsh скриптлары
# (completion/) бары шуны чакыра. The shell scripts in completion/ only call
# `<tool> __complete <words…>`; all logic lives here and in each tool's dictionary.
# Requires: alif.sh. Bash 3.2.

# complete_filter CUR — stdin'нан CUR белән башланган буш булмаган юлларны калдыра.
# Keep the non-empty stdin lines that start with CUR.
complete_filter() {
  local cur="$1" c
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    case "$c" in "$cur"*) printf '%s\n' "$c" ;; esac
  done
}

# complete_words CUR WORD… — кирилл сүзләрне актив язуга күчереп, CUR буенча сайлый.
# Render Cyrillic WORDs in the active script (AYDA_ALIF) and filter by CUR.
complete_words() {
  local cur="$1"; shift
  [ "$#" -gt 0 ] || return 0
  # Әмерләр һәрвакыт AYDA_ALIF язуында (AYDA_LANG=en булса да) — кеше шулай яза.
  # Commands follow AYDA_ALIF even with AYDA_LANG=en: that is the script you type in.
  printf '%s\n' "$@" | alif_render | complete_filter "$cur"
}

# complete_raw CUR WORD… — транслитерациясез (исемнәр өчен) / no transliteration (names).
complete_raw() {
  local cur="$1"; shift
  [ "$#" -gt 0 ] || return 0
  printf '%s\n' "$@" | complete_filter "$cur"
}

# complete_to_cyrl WORD CANDIDATE… — латин/гарәп керемне кирилга кайтара.
# Normalise a typed word to Cyrillic: Latin via latin_to_cyrl, Arabic by matching
# the candidates' Yaña imlâ rendering. Unknown words come back unchanged.
complete_to_cyrl() {
  local w="$1" r; shift
  if alif_has_arab "$w"; then
    r="$(alif_arab_pick "$w" "$@")" && { printf '%s' "$r"; return 0; }
    printf '%s' "$w"; return 0
  fi
  alif_normalize_in "$w"
}

# complete_split VALUEFLAGS WORD… — алдагы сүзләрне позицион сүзләргә һәм флагларга бүлә.
# Split the words before the cursor into positionals (COMP_POS) and flags
# (COMP_FLAGS, each "--flag=value" or "-x value" kept as given). VALUEFLAGS is a
# space-separated list of flags that take a separate value (e.g. "-n --namespace").
# shellcheck disable=SC2034  # COMP_POS / COMP_FLAGS are read by the caller
complete_split() {
  local vflags=" $1 " w want=""; shift
  COMP_POS=(); COMP_FLAGS=()
  for w in "$@"; do
    if [ -n "$want" ]; then COMP_FLAGS+=("$w"); want=""; continue; fi
    case "$w" in
      --) break ;;
      -*) COMP_FLAGS+=("$w")
          case "$vflags" in *" $w "*) want=1 ;; esac ;;
      *)  COMP_POS+=("$w") ;;
    esac
  done
}
