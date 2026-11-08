# shellcheck shell=bash
# kullama.sh — «ayda куллама»: чыгарылыш савыты / the release as one dish.
#
# Кулламада ит, салма һәм кишер-суган туравы аерым пешә, аннары бер савытта
# кушыла. Татарнетес кисәкләре дә аерым пешә; kullama/recipe.yaml (kubepkg
# мета-пакеты) — аларның бергә эшли торган версияләре. Бу модуль савытны
# укый һәм һәр кисәк өчен күрсәтә: салынган, урнашкан, соңгы релиз, хөкем,
# апстримнан артта калу («артык пешкән»).
# Kullama's meat, salma and dressing are cooked apart and put together in one
# pan; kullama/recipe.yaml pins the Tatarnetes components that work together.
# This prints, per ingredient: pinned, installed, latest release, verdict, and
# whether its upstream moved on ("overcooked"), as upstream-watch would say.
#
# Bash 3.2. Env: AYDA_CURL (curl), GITHUB_TOKEN (optional, rate limits),
# AYDA_KULLAMA_FILE (another dish), AYDA_KULLAMA_OFFLINE=1 (no GitHub calls).

KULLAMA_PREFIX="kullama.tatar-ncf.github.io/"

kullama_file() { printf '%s' "${AYDA_KULLAMA_FILE:-$AYDA_HOME/kullama/recipe.yaml}"; }

# kullama_get KEY — kullama.tatar-ncf.github.io/KEY искәрмәсе (кавычкасыз).
kullama_get() {
  local key="$1"
  sed -n "s|^ *${KULLAMA_PREFIX}${key}: *||p" "$(kullama_file)" | sed 's/^"//; s/"$//' | head -1
}

# kullama_version — савыт версиясе, тамга рәвешендә (v1.37.2-tatar.1).
kullama_version() {
  local v
  v="$(sed -n 's/^  version: *//p' "$(kullama_file)" | sed 's/^"//; s/"$//' | head -1)"
  [ -n "$v" ] && printf 'v%s' "$v"
}

# kullama_latest REPO — GitHub'тагы соңгы релиз тамгасы. rc 2: релиз юк (404);
# rc 1: белеп булмый (челтәр, лимит, AYDA_KULLAMA_OFFLINE).
kullama_latest() {
  local repo="$1" out code body tag
  [ "${AYDA_KULLAMA_OFFLINE:-}" = 1 ] && return 1
  local -a auth=()
  [ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
  out="$("${AYDA_CURL:-curl}" -sS --max-time 5 -H 'Accept: application/vnd.github+json' \
    ${auth[@]+"${auth[@]}"} -w '\n%{http_code}' "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null)" || return 1
  code="$(printf '%s' "$out" | tail -1)"
  body="$(printf '%s' "$out" | sed '$d')"
  case "$code" in
    200) tag="$(printf '%s' "$body" | tr ',' '\n' | sed -n 's/^[{ ]*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)"
         [ -n "$tag" ] || return 1
         printf '%s' "$tag" ;;
    404) return 2 ;;
    *)   return 1 ;;
  esac
}

# kullama_installed NAME — урнашкан версия, күренсә. ayda — үзе килгән савыт;
# тыю вебхугы — кластердагы образ тамгасы (чәй вакытында сорамыйбыз).
kullama_installed() {
  local img
  case "$1" in
    ayda) kullama_version ;;
    tatarnetes-freeze)
      [ "${AYDA_BACKEND:-kubectl}" = kubectl ] || return 1
      tea_now && return 1
      img="$("${KUBECTL_BIN:-kubectl}" get deployments -A -l app.kubernetes.io/name=tatarnetes-freeze \
        -o jsonpath='{.items[0].spec.template.spec.containers[0].image}' --request-timeout=5s 2>/dev/null)" || return 1
      case "$img" in *:*) printf '%s' "${img##*:}" ;; *) return 1 ;; esac ;;
    *) return 1 ;;
  esac
}

# kullama_show — савытны бас. rc 1, урнашкан кисәк савыттагыдан аерылса.
kullama_show() {
  local f name pin repo up inst latest lrc up_repo up_ver up_latest urc swapped=""
  f="$(kullama_file)"
  if [ ! -f "$f" ]; then
    printf '%s\n' "$(t kullama.missing "$f")" >&2
    return 1
  fi
  tat_carpet
  printf '  🍲 %s\n' "$(t kullama.title "$(kullama_version)")"
  printf '  %s\n\n' "$(t kullama.recipe)"
  for name in $(kullama_get ingredients); do
    pin="$(kullama_get "$name")"; repo="$(kullama_get "$name.repo")"; up="$(kullama_get "$name.upstream")"
    printf '  %s%s%s  (%s)\n' "${TAT_BOLD:-}" "$name" "${TAT_RESET:-}" "$repo"
    printf '    %s\n' "$(t kullama.pinned "$pin")"

    if inst="$(kullama_installed "$name")" && [ -n "$inst" ]; then
      if [ "$inst" = "$pin" ]; then
        printf '    %s — %s\n' "$(t kullama.installed "$inst")" "$(t kullama.ok)"
      else
        printf '    %s — %s\n' "$(t kullama.installed "$inst")" "$(t kullama.differs)"
        swapped="$swapped $name"
      fi
    else
      printf '    %s\n' "$(t kullama.installed "$(t kullama.unseen)")"
    fi

    lrc=0; latest="$(kullama_latest "$repo")" || lrc=$?
    case "$lrc" in
      0) printf '    %s\n' "$(t kullama.latest "$latest")" ;;
      2) printf '    %s\n' "$(t kullama.latest "$(t kullama.no_releases)")" ;;
      *) printf '    %s\n' "$(t kullama.latest "$(t kullama.unknown)")" ;;
    esac

    if [ -z "$up" ]; then
      printf '    %s\n' "$(t kullama.no_upstream)"
    else
      up_repo="${up%%@*}"; up_ver="${up#*@}"
      urc=0; up_latest="$(kullama_latest "$up_repo")" || urc=$?
      case "$urc" in
        0) if [ "$up_latest" = "$up_ver" ]; then
             printf '    %s — %s\n' "$(t kullama.upstream "$up")" "$(t kullama.fresh)"
           else
             printf '    %s — %s\n' "$(t kullama.upstream "$up")" "$(t kullama.overcooked "$up_latest")"
           fi ;;
        2) printf '    %s — %s\n' "$(t kullama.upstream "$up")" "$(t kullama.upstream_no_releases)" ;;
        *) printf '    %s — %s\n' "$(t kullama.upstream "$up")" "$(t kullama.unknown)" ;;
      esac
    fi
    echo
  done
  if [ -n "$swapped" ]; then
    printf '  %s\n' "$(t kullama.verdict.swapped "${swapped# }")"
    printf '  %s\n' "$(t kullama.swap_hint)"
    tat_carpet
    return 1
  fi
  printf '  %s\n' "$(t kullama.verdict.ok)"
  tat_carpet
  return 0
}
