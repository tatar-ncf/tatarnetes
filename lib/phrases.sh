# shellcheck shell=bash
# phrases.sh — Мәдәни корпус йөкләүче / cultural corpus loader.
# Эчтәлек хәзер data/*.tt файлларында (носителеләр PR аша тулыландыра ала).
# Content now lives in data/*.tt so native speakers can contribute via PR,
# without touching code. Чыгарылыш AYDA_ALIF буенча транслитерацияләнә.
# Requires: alif.sh sourced (for alif_render). Bash 3.2.

_CORPUS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../data" 2>/dev/null && pwd)"

# Файлдагы мәгънәле юллар (# һәм буш юлларны калдырып).
_corpus_lines() { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null; }

# Файлдан очраклы юл / random meaningful line from a file.
_rand_line() {
  local f="$_CORPUS_DIR/$1" IFS=$'\n'
  local -a a=()
  a=($(_corpus_lines "$f"))
  local n=${#a[@]}
  [ "$n" -eq 0 ] && return 0
  printf '%s' "${a[$((RANDOM % n))]}" | alif_render
}

# «%%» белән аерылган очраклы язма (күп юллы) / random %%-separated record.
_rand_record() {
  local f="$_CORPUS_DIR/$1"
  [ -f "$f" ] || return 0
  awk -v seed="$RANDOM" '
    BEGIN{ RS="%%"; srand(seed) }
    { gsub(/^\n+|\n+$/,""); if (length($0) && $0 !~ /^[[:space:]]*#/) recs[n++]=$0 }
    END{ if (n>0) print recs[int(rand()*n)] }
  ' "$f" | grep -vE '^[[:space:]]*#' | alif_render
}

tat_random_curse()   { _rand_line curses.tt; }
tat_random_praise()  { _rand_line praise.tt; }
tat_random_food()    { _rand_line foods.tt; }
tat_random_proverb() { _rand_line proverbs.tt; }
tat_random_poem()    { _rand_record poetry.tt; }
tat_random_name()    { _rand_line names.tt; }

# Иске исем туры килсен өчен (кире яраклылык) / back-compat alias.
tat_random_tukay()   { tat_random_poem; }

# Уңышта бизәк: чиратлап шигырь / мәкаль / ризык.
# Success garnish: rotate poem / proverb / dish.
tat_random_garnish() {
  case $(( RANDOM % 3 )) in
    0) tat_random_food ;;
    1) tat_random_proverb ;;
    *) tat_random_poem ;;
  esac
}
