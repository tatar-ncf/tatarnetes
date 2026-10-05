# shellcheck shell=bash
# errors.sh — kubectl хаталарын татарча аңлату / translate kubectl error output.
# Кубернетес хатасы инглизчә кала, ләкин без татарча киңәш өстибез.
# We keep the original kubectl error and add a Tatar hint below it.

# tat_error_hint TEXT → каталог ачкычы (err.hint.*) яки буш.
# Maps common kubectl error phrases to a hint catalog-key.
tat_error_hint() {
  local text="$1"
  # Тәртип мөһим: «could not find the requested resource» — асыл төре юк, объект түгел.
  # Order matters: the "unknown resource type" phrases contain "could not find",
  # so they must be matched before the generic not-found ones.
  case "$text" in
    *"doesn't have a resource type"*|*"the server doesn't have"*|*"unknown resource"*|*"the server could not find the requested resource"*) printf 'err.hint.nomatch' ;;
    *NotFound*|*"not found"*|*"could not find"*)         printf 'err.hint.notfound' ;;
    *Forbidden*|*forbidden*)                             printf 'err.hint.forbidden' ;;
    *"AlreadyExists"*|*"already exists"*)                printf 'err.hint.exists' ;;
    *timeout*|*"timed out"*|*"Timeout exceeded"*|*"context deadline"*) printf 'err.hint.timeout' ;;
    *"connection refused"*|*"unable to connect"*|*"dial tcp"*|*"was refused"*|*"couldn't get"*|*"no such host"*) printf 'err.hint.conn' ;;
    *) printf '' ;;
  esac
}
