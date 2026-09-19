# shellcheck shell=bash
# finops.sh — Хуҗалыкчыллык / thrift (a Tatar virtue as a feature, not a stereotype).
# Артык реплика соралса — йомшак кисәтү: «Акчаны әрәм итмә!».
# If too many replicas are requested, gently nag about wasting resources.

# tat_finops_replicas ARGS… → артык реплика санын кайтара (rc 0), юкса rc 1.
# Echoes the replica count if it exceeds the threshold, else returns 1.
tat_finops_replicas() {
  local threshold="${AYDA_FINOPS_MAX:-10}" reps="" prev="" a
  for a in "$@"; do
    case "$a" in
      --replicas=*) reps="${a#*=}" ;;
      -r=*)         reps="${a#*=}" ;;
      --replicas|-r) prev=1 ;;
      *) if [ -n "$prev" ]; then reps="$a"; prev=""; fi ;;
    esac
  done
  [ -z "$reps" ] && return 1
  case "$reps" in *[!0-9]*) return 1 ;; esac
  [ "$reps" -gt "$threshold" ] && { printf '%s' "$reps"; return 0; }
  return 1
}
