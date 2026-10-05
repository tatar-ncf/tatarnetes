# shellcheck shell=bash
# explain.sh — «ayda аңлат <асыл>[.юл]»: татарча kubectl explain.
# Аңлатма глоссарийдан (data/glossary.tsv ← docs/terminology.tt.md) алына, аннары
# мөмкин булса чын `kubectl explain` кыр схемасын күрсәтә.
# A Tatar `kubectl explain`: the explanation comes from the glossary data
# (generated from docs/terminology.tt.md), then — if possible — the real
# `kubectl explain` prints the field schema. Requires: alif, i18n, dictionary.

GLOSSARY_FILE="${AYDA_GLOSSARY:-$AYDA_HOME/data/glossary.tsv}"

# _alif_out — татарча режимда сайланган язуга күчерү / render in the active script (tt only).
_alif_out() { if [ "$AYDA_LANG" = tt ]; then alif_render; else cat; fi; }

# _gl_rows — глоссарий юллары (аңлатмаларсыз) / glossary rows without comments.
_gl_rows() { [ -f "$GLOSSARY_FILE" ] && grep -v '^#' "$GLOSSARY_FILE"; }

# glossary_find WORD — WORD'ка туры килгән юлны бас (TSV), табылмаса rc 1.
# Match order: the Tatar term (spaces ≡ «-»; Latin/Arabic input normalised),
# the English name (also without a trailing "s"), then any dictionary synonym or
# plural that resolves to the same kubectl resource (кузаклар, борчак → кузак).
glossary_find() {
  local raw="$1" w key row term en kind k
  # shellcheck disable=SC2046  # glossary keys are single words by construction
  w="$(complete_to_cyrl "$raw" $(_glossary_keys) $(dict_nouns))"
  key="$(printf '%s' "$w" | sed 's/ /-/g')"
  while IFS= read -r row; do
    term="$(printf '%s' "$row" | cut -f1 | sed 's/ /-/g')"
    [ "$term" = "$key" ] && { printf '%s\n' "$row"; return 0; }
  done <<EOF
$(_gl_rows)
EOF
  while IFS= read -r row; do
    en="$(printf '%s' "$row" | cut -f2)"
    # «volume / persistentvolume», «actual/current state» — һәр вариант / every variant
    for k in $(printf '%s' "$en" | sed 's| */ *|/|g; s/ /_/g' | tr '/' ' '); do
      k="$(printf '%s' "$k" | tr '_' ' ')"
      if [ "$k" = "$raw" ] || [ "${k}s" = "$raw" ]; then printf '%s\n' "$row"; return 0; fi
    done
  done <<EOF
$(_gl_rows)
EOF
  kind="$(resolve_noun "$key")"
  [ "$kind" = "$key" ] && return 1
  while IFS= read -r row; do
    term="$(printf '%s' "$row" | cut -f1 | sed 's/ /-/g')"
    [ "$(translate_noun "$term")" = "$kind" ] && { printf '%s\n' "$row"; return 0; }
  done <<EOF
$(_gl_rows)
EOF
  return 1
}

# glossary_index — барлык төшенчәләр бүлекләр буенча / all terms grouped by section.
glossary_index() {
  local row term en sec last=""
  printf '%s\n\n' "$(AYDA_ALIF=cyrl t explain.index)"
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    term="$(printf '%s' "$row" | cut -f1)"; en="$(printf '%s' "$row" | cut -f2)"
    sec="$(printf '%s' "$row" | cut -f5)"
    if [ "$sec" != "$last" ]; then
      [ -n "$last" ] && printf '\n'
      printf '  %s\n' "$sec"; last="$sec"
    fi
    # printf %-Ns байт саный; кирилл өчен хәрефләр буенча тигезлибез.
    # printf pads by bytes; pad by characters so Cyrillic columns line up.
    local pad=$(( 24 - ${#term} )); [ "$pad" -lt 1 ] && pad=1
    printf '    %s%*s%s\n' "$term" "$pad" '' "$en"
  done <<EOF
$(_gl_rows)
EOF
  printf '\n%s\n' "$(AYDA_ALIF=cyrl t explain.index.hint)"
}

# _gl_print ROW KIND — бер төшенчәне бас / print one glossary entry.
_gl_print() {
  local row="$1" kind="$2" term en meaning type sec
  term="$(printf '%s' "$row" | cut -f1)";    en="$(printf '%s' "$row" | cut -f2)"
  meaning="$(printf '%s' "$row" | cut -f3)"; type="$(printf '%s' "$row" | cut -f4)"
  sec="$(printf '%s' "$row" | cut -f5)"
  {
    if [ "$AYDA_LANG" = en ]; then printf '%s — %s\n' "$en" "$term"
    else printf '%s — %s\n' "$term" "$en"; fi
    printf '  %s\n' "$meaning"
    [ -n "$type" ] && printf '  %s\n' "$(t explain.type "$type")"
    printf '  %s\n' "$sec"
    if [ -n "$kind" ]; then printf '  %s\n' "$(t explain.kubectl "$kind")"
    else printf '  %s\n' "$(t explain.concept)"; fi
  } | _alif_out
}

# _explain_hint ERRTEXT — kubectl explain хаталары өчен каталог ачкычы.
_explain_hint() {
  case "$1" in
    *"field \""*"does not exist"*)                       printf 'explain.no_field' ;;
    *"couldn't find resource"*|*"doesn't have a resource type"*) printf 'explain.unknown' ;;
    *) printf '' ;;
  esac
}

# explain_main ARGS… — «ayda аңлат» төп агымы; rc кайтара / returns the exit code.
#   ayda аңлат                      → глоссарий исемлеге / glossary index
#   ayda аңлат кузак                → глоссарий + kubectl explain pods
#   ayda аңлат кузак.spec -R        → глоссарий + kubectl explain pods.spec -R
#   ayda аңлат кузак --кыскача      → глоссарий гына / glossary only (offline)
explain_main() {
  local a brief=0 target head path="" row kind="" in_glossary=1
  local -a pos=() eflags=()
  for a in "$@"; do
    case "$a" in
      --кыскача|--kıskaça|--qısqaça|--brief) brief=1 ;;
      -*) eflags+=("$a") ;;
      *)  pos+=("$a") ;;
    esac
  done

  if [ "${#pos[@]}" -eq 0 ]; then glossary_index | _alif_out; return 0; fi
  if [ "${#pos[@]}" -gt 1 ]; then
    # Элек «аңлат» = describe иде / «аңлат» used to mean describe.
    printf '%s\n' "$(t explain.was_describe "${pos[*]}")" >&2
    return 64
  fi

  target="${pos[0]}"; head="${target%%.*}"
  [ "$target" != "$head" ] && path=".${target#*.}"

  if row="$(glossary_find "$head")"; then
    kind="$(resolve_noun "$(printf '%s' "$row" | cut -f1 | sed 's/ /-/g')")"
    [ "$kind" = "$(printf '%s' "$row" | cut -f1 | sed 's/ /-/g')" ] && kind=""
    _gl_print "$row" "$kind"
  else
    in_glossary=0
    kind="$(resolve_noun "$head")"
    if [ "$kind" = "$head" ]; then
      # Сүзлектә дә юк: кирилл/гарәп булса — хата; латин/инглиз — kubectl'га тапшырабыз.
      # Not a Tatar word we know: Cyrillic/Arabic → error; ASCII → let kubectl judge.
      case "$head" in
        *[!a-zA-Z0-9-]*|'') printf '%s\n' "$(t explain.unknown "$head")" >&2; return 64 ;;
      esac
    fi
    printf '%s\n' "$(t explain.not_in_glossary "$head")" >&2
  fi

  if [ -z "$kind" ]; then
    [ -n "$path" ] && { printf '%s\n' "$(t explain.no_schema "$head")" >&2; return 64; }
    return 0
  fi
  [ "$brief" -eq 1 ] && return 0

  if [ "${AYDA_BACKEND:-kubectl}" = skctl ]; then
    printf '%s\n' "$(t explain.skctl)" >&2
    [ -n "$path" ] && return 69
    return 0
  fi
  if tea_now; then show_tea_break; return 42; fi
  if ! command -v "$KUBECTL_BIN" >/dev/null 2>&1; then
    printf '%s\n' "$(t kubectl.notfound "$KUBECTL_BIN")" >&2
    return 127
  fi

  tat_dim "🐘 $(t run.translated "$KUBECTL_BIN explain $kind$path ${eflags[*]:-}")"
  local errtext rc hint
  { errtext="$("$KUBECTL_BIN" explain "$kind$path" ${eflags[@]+"${eflags[@]}"} 2>&1 1>&3 3>&-)"; rc=$?; } 3>&1
  if [ "$rc" -ne 0 ]; then
    [ -n "$errtext" ] && printf '%s\n' "$errtext" >&2
    hint="$(_explain_hint "$errtext")"
    case "$hint" in
      explain.no_field)
        # Ата юл: кузак.spec.zzz → кузак.spec / the parent path to list fields from.
        local parent="$head$path"; parent="${parent%.*}"
        printf '%s\n' "$(t explain.no_field "${path#.}" "$parent")" >&2 ;;
      explain.unknown)  printf '%s\n' "$(t explain.unknown "$head")" >&2 ;;
      *) hint="$(tat_error_hint "$errtext")"
         [ -n "$hint" ] && printf '%s\n' "$(t "$hint")" >&2
         [ "$in_glossary" -eq 1 ] && printf '%s\n' "$(t explain.schema_failed)" >&2 ;;
    esac
  fi
  return "$rc"
}
