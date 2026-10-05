# shellcheck shell=bash
# skctl.sh — Sheeternetes нигезе / Sheeternetes backend (SNCF × TNCF).
# AYDA_BACKEND=skctl булганда татарча әмерләр kubectl урынына skctl'га күчә.
# With AYDA_BACKEND=skctl, Tatar commands drive skctl (the Sheeternetes CLI).
#
# skctl kubectl'ның кечкенә өлешен генә белә; калганы өчен намуслы хата бирәбез,
# бернәрсә дә эшләтмичә. skctl knows a small subset of kubectl: anything it
# cannot do exactly as typed is rejected, and nothing is executed.
#
#   get pods|nodes|deployments|events      → skctl get <kind>
#   apply -f <file.json>                   → skctl apply <file.json>
#   scale deploy <name> --replicas=<n>     → skctl scale <name> <n>
#   delete deploy <name>                   → skctl delete <name>
#   cordon|uncordon|drain <node>           → skctl <verb> <node>
#   label|taint nodes <node> <spec>        → skctl <verb> <node> <spec>
#   migrate|күчер <pod> <node>             → skctl migrate <pod> <node>
# Requires: alif.sh (latin_to_cyrl).
# SKARGS / SKERR / SKERR_ARGS — bin/ayda өчен чыгыш / outputs read by bin/ayda.
# shellcheck disable=SC2034

# skctl_resolve_verb WORD — kubectl'да булмаган, skctl'ның гына фигыльләре.
# Verbs only skctl has (kubectl has no `migrate`). Prints "" if none.
skctl_resolve_verb() {
  local v="$1"
  case "$v" in
    migrate|күчер|кучер) printf 'migrate'; return 0 ;;
  esac
  case "$(printf '%s' "$v" | latin_to_cyrl)" in
    күчер|кучер) printf 'migrate' ;;
    *) printf '' ;;
  esac
}

# _sk_kind WORD — kubectl асылын skctl төренә / normalise a kubectl kind.
_sk_kind() {
  case "$1" in
    pods|pod|po)                       printf 'pods' ;;
    nodes|node|no)                     printf 'nodes' ;;
    deployments|deployment|deploy)     printf 'deployments' ;;
    events|event|ev)                   printf 'events' ;;
    *)                                 printf '' ;;
  esac
}

# Хата / failure: SKERR = каталог ачкычы, SKERR_ARGS = printf аргументлары.
_sk_fail() { SKERR="$1"; shift; SKERR_ARGS=("$@"); return 1; }

# _sk_target WANT ALLOW_BARE ARGS… — «kind name», «kind/name» яки (рөхсәт булса)
# ялгыз исем. Sets _SK_NAME. WANT is the only kind skctl accepts for the verb.
_sk_target() {
  local want="$1" bare="$2" raw="" name=""; shift 2
  case "$#" in
    1) case "$1" in
         */*) raw="${1%%/*}"; name="${1#*/}" ;;
         *)   if [ "$bare" -eq 1 ] && [ -z "$(_sk_kind "$1")" ]; then name="$1"; else return 2; fi ;;
       esac ;;
    2) case "$1" in */*) return 2 ;; esac
       raw="$1"; name="$2" ;;
    *) return 2 ;;
  esac
  if [ -n "$raw" ] && [ "$(_sk_kind "$raw")" != "$want" ]; then
    _SK_RAW="$raw"; return 3
  fi
  case "$name" in ''|*/*) return 2 ;; esac
  _SK_NAME="$name"
}

# skctl_map VERB ARGS… — kubectl рәвешендәге әмерне skctl аргументларына.
# On success fills SKARGS (rc 0). On failure sets SKERR/SKERR_ARGS (rc 1) and
# fills nothing — the caller must not run anything.
skctl_map() {
  SKARGS=(); SKERR=""; SKERR_ARGS=(); _SK_NAME=""; _SK_RAW=""
  local verb="$1"; shift
  local -a pos=()
  local file="" reps="" want="" a usage rc

  case "$verb" in
    get)                    usage="get pods|nodes|deployments|events" ;;
    apply)                  usage="apply -f <file.json>" ;;
    scale)                  usage="scale deploy <name> --replicas=<n>" ;;
    delete)                 usage="delete deploy <name>" ;;
    cordon|uncordon|drain)  usage="$verb <node>" ;;
    label)                  usage="label nodes <node> key=value  (key- to remove)" ;;
    taint)                  usage="taint nodes <node> key=value:Effect  (key- to remove)" ;;
    migrate)                usage="migrate <pod> <node>" ;;
    *) _sk_fail skctl.unsupported.verb "$verb"; return 1 ;;
  esac

  for a in "$@"; do
    if [ -n "$want" ]; then
      case "$want" in file) file="$a" ;; reps) reps="$a" ;; esac
      want=""; continue
    fi
    case "$verb:$a" in
      apply:-f|apply:--filename)          want='file' ;;
      apply:-f=*|apply:--filename=*)      file="${a#*=}" ;;
      scale:--replicas)                   want='reps' ;;
      scale:--replicas=*)                 reps="${a#*=}" ;;
      *:-*)  _sk_fail skctl.unsupported.flag "$a"; return 1 ;;
      *)     pos+=("$a") ;;
    esac
  done
  [ -n "$want" ] && { _sk_fail skctl.usage "$usage"; return 1; }

  local n=${#pos[@]}
  case "$verb" in
    get)
      [ "$n" -eq 1 ] || { _sk_fail skctl.usage "$usage"; return 1; }
      local kind; kind="$(_sk_kind "${pos[0]}")"
      [ -n "$kind" ] || { _sk_fail skctl.unsupported.kind get "${pos[0]}" "pods, nodes, deployments, events"; return 1; }
      SKARGS=(get "$kind") ;;
    apply)
      if [ -z "$file" ] && [ "$n" -eq 1 ]; then file="${pos[0]}"; n=0; fi
      { [ -n "$file" ] && [ "$n" -eq 0 ]; } || { _sk_fail skctl.usage "$usage"; return 1; }
      SKARGS=(apply "$file") ;;
    scale|delete)
      _sk_target deployments 0 ${pos[@]+"${pos[@]}"}; rc=$?
      [ "$rc" -eq 3 ] && { _sk_fail skctl.unsupported.kind "$verb" "$_SK_RAW" "deployments"; return 1; }
      [ "$rc" -eq 0 ] || { _sk_fail skctl.usage "$usage"; return 1; }
      if [ "$verb" = scale ]; then
        case "$reps" in ''|*[!0-9]*) _sk_fail skctl.usage "$usage"; return 1 ;; esac
        SKARGS=(scale "$_SK_NAME" "$reps")
      else
        SKARGS=(delete "$_SK_NAME")
      fi ;;
    cordon|uncordon|drain)
      _sk_target nodes 1 ${pos[@]+"${pos[@]}"}; rc=$?
      [ "$rc" -eq 3 ] && { _sk_fail skctl.unsupported.kind "$verb" "$_SK_RAW" "nodes"; return 1; }
      [ "$rc" -eq 0 ] || { _sk_fail skctl.usage "$usage"; return 1; }
      SKARGS=("$verb" "$_SK_NAME") ;;
    label|taint|migrate)
      [ "$n" -ge 2 ] || { _sk_fail skctl.usage "$usage"; return 1; }
      local last="${pos[$((n-1))]}" wantkind=nodes bare=0
      [ "$verb" = migrate ] && { wantkind=pods; bare=1; }
      _sk_target "$wantkind" "$bare" "${pos[@]:0:$((n-1))}"; rc=$?
      [ "$rc" -eq 3 ] && { _sk_fail skctl.unsupported.kind "$verb" "$_SK_RAW" "$wantkind"; return 1; }
      [ "$rc" -eq 0 ] || { _sk_fail skctl.usage "$usage"; return 1; }
      SKARGS=("$verb" "$_SK_NAME" "$last") ;;
  esac
  return 0
}

# skctl_error_hint TEXT — skctl/curl хаталары өчен киңәш ачкычы, юкса буш.
# Hints for skctl's own failure modes (it reports via curl, not kubectl).
skctl_error_hint() {
  case "$1" in
    *"WEBAPP_URL"*)                                         printf 'skctl.hint.env' ;;
    *"error: 401"*|*unauthorized*)                          printf 'skctl.hint.token' ;;
    *"Failed to connect"*|*"Could not resolve host"*|*"Couldn't connect"*) printf 'err.hint.conn' ;;
    *"unknown kind"*)                                       printf 'err.hint.nomatch' ;;
    *) printf '' ;;
  esac
}
