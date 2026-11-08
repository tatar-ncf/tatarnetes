# shellcheck shell=bash
# faces.sh — Түбәтәйле татар йөзләре / Tatar faces in a tюбетейка (skullcap).
# Өч халәт: шат (уңыш), ачулы (хата), чәй (тәнәфес).
# Three moods: happy (success), angry (error), tea (break).
#
# Йөз ике баганадан җыела: йөз үзе (тигез киңлектәге блок) һәм ян язмалар
# (түбәтәй исеме, чәй чынаягы). Язулар t() аша — AYDA_LANG/AYDA_ALIF буенча.
# A face is composed of two columns: the face block (every line padded to
# TAT_FACE_W) and an aside column (captions, teacup). Captions go through t(),
# so they follow AYDA_LANG and AYDA_ALIF. Requires: i18n.sh (t) sourced.

TAT_FACE_W=26

# tat_width STR — экрандагы киңлек (UTF-8 символлар саны; бу сурәтләрдә
# барлык символлар бер баганалы). Locale'дан бәйсез.
# Display width = number of UTF-8 code points (all glyphs here are single-cell);
# counts lead bytes only, so it does not depend on the caller's locale.
tat_width() {
  local n
  n=$(printf '%s' "$1" | LC_ALL=C tr -d '\200-\277' | wc -c)
  printf '%d' "$n"
}

# Йөз сурәте (кисәлмәгән) / raw face art, one mood.
_tat_face_art() {
  local top band brim chin
  top='        .:*~*:._.:*~*:.'
  band="      .'   ◆◇◆◇◆◇◆◇◆   '."
  brim="     /___________________\\"
  chin='      \_________________/'
  printf '%s\n%s\n%s\n' "$top" "$band" "$brim"
  case "$1" in
    happy)
      printf '%s\n' '     |    ^         ^    |' \
                    '     |         ᵕ         |' \
                    '     |     \  ‿‿‿  /     |' ;;
    angry)
      printf '%s\n' '     |    ╲         ╱    |' \
                    '     |     ◣       ◢     |' \
                    '     |      ╱‾‾‾‾‾╲      |' ;;
    tea)
      printf '%s\n' '     |    -         -    |' \
                    '     |         ‿         |' \
                    '     |     \  ___  /     |' ;;
  esac
  printf '%s\n' "$chin"
}

# tat_face_lines MOOD — йөз блогы, һәр юл TAT_FACE_W киңлегенә кадәр тутырылган
# (кисмичә: артык киң юл киң килеш кала, тест аны тота).
# The face block, each line right-padded to TAT_FACE_W (never truncated, so an
# over-wide line stays visible to tests).
tat_face_lines() {
  local l w
  while IFS= read -r l; do
    w=$(tat_width "$l")
    if [ "$w" -lt "$TAT_FACE_W" ]; then
      printf '%s%*s\n' "$l" $((TAT_FACE_W - w)) ''
    else
      printf '%s\n' "$l"
    fi
  done <<EOF
$(_tat_face_art "$1")
EOF
}

# Ян багана: йөз юллары белән бер рәттә / aside column, row-aligned with the face.
_tat_face_aside() {
  printf '\n%s\n' "   $(t face.skullcap)"
  [ "$1" = tea ] || return 0
  printf '\n%s\n%s\n%s\n%s\n%s\n%s\n' \
    '        ( (' \
    '         ) )' \
    '       ........' \
    "       |      |]   $(t face.milktea)" \
    '       \      /' \
    "        \`----'"
}

# tat_face MOOD — йөзне ян язмалар белән stdout'ка чыгара.
# Prints the face with its aside column to stdout.
tat_face() {
  local -a body=() aside=()
  local l i n b a blank
  blank=$(printf '%*s' "$TAT_FACE_W" '')
  while IFS= read -r l; do body+=("$l"); done <<EOF
$(tat_face_lines "$1")
EOF
  while IFS= read -r l; do aside+=("$l"); done <<EOF
$(_tat_face_aside "$1")
EOF
  n=${#body[@]}; [ "${#aside[@]}" -gt "$n" ] && n=${#aside[@]}
  for ((i = 0; i < n; i++)); do
    b="${body[$i]:-}"; a="${aside[$i]:-}"
    if [ -z "$a" ]; then
      printf '%s\n' "${b%"${b##*[! ]}"}"
    else
      printf '%s%s\n' "${b:-$blank}" "$a"
    fi
  done
}

tat_face_happy() { tat_face happy >&2; }
tat_face_angry() { tat_face angry >&2; }
tat_face_tea()   { tat_face tea >&2; }
