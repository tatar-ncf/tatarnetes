# shellcheck shell=bash
# ayda.bash — Tab-тулыландыру (bash) / bash completion for `ayda`.
# Урнаштыру / install:   source /path/to/tatarnetes/completion/ayda.bash
# Бөтен логика `ayda __complete` эчендә; монда — юка күпер (bash 3.2 тә эшли).
# All logic lives in `ayda __complete`; this is a thin bridge (bash 3.2 safe).
_ayda_complete() {
  local line
  COMPREPLY=()
  while IFS= read -r line; do
    [ -n "$line" ] && COMPREPLY+=("$line")
  done <<EOF_AYDA
$("${COMP_WORDS[0]}" __complete "${COMP_WORDS[@]:1:COMP_CWORD}" 2>/dev/null)
EOF_AYDA
}
complete -F _ayda_complete ayda
