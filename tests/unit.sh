#!/usr/bin/env bash
# unit.sh — Татарнетес берәмлек тестлары / self-contained unit tests (no bats dep).
# Куллану / usage:  bash tests/unit.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
cd "$HERE" || exit 1
export AYDA_LANG=tt AYDA_ALIF=cyrl AYDA_PLAIN=1

export AYDA_HOME="$HERE"
# shellcheck source=/dev/null
for m in render alif catalog i18n complete dictionary phrases teatime errors skctl; do . "lib/$m.sh"; done

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n      көтелгән=[%s] алынды=[%s]\n' "$1" "$2" "$3"; }
eq()   { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

echo "── alif: cyrl→latin ──"
eq "күрсәт→kürsät"   "kürsät"   "$(printf '%s' 'күрсәт'   | cyrl_to_latin)"
eq "кузаклар→kuzaklar" "kuzaklar" "$(printf '%s' 'кузаклар' | cyrl_to_latin)"
eq "җил→cil"         "cil"      "$(printf '%s' 'җил'      | cyrl_to_latin)"

echo "── alif: latin→cyrl ──"
eq "kürsät→күрсәт"   "күрсәт"   "$(printf '%s' 'kürsät'   | latin_to_cyrl)"
eq "töen→төен"       "төен"     "$(printf '%s' 'töen'     | latin_to_cyrl)"

echo "── synharmonic plural (tn) ──"
eq "кузак"   "кузаклар"   "$(tn кузак)"
eq "төен"    "төеннәр"    "$(tn төен)"
eq "хезмәт"  "хезмәтләр"  "$(tn хезмәт)"
eq "мәйдан"  "мәйданнар"  "$(tn мәйдан)"
eq "сер"     "серләр"     "$(tn сер)"

echo "── resolve_verb ──"
eq "get→get"       "get" "$(resolve_verb get)"
eq "күрсәт→get"    "get" "$(resolve_verb күрсәт)"
eq "kürsät→get"    "get" "$(resolve_verb kürsät)"
eq "zzz→(empty)"   ""    "$(resolve_verb zzz)"
eq "kuberc passthrough (kubectl ≥1.33)" "kuberc" "$(resolve_verb kuberc)"
eq "rollback is not a kubectl verb" "" "$(resolve_verb rollback)"

echo "── resolve_noun ──"
eq "кузак→pods"      "pods"   "$(resolve_noun кузак)"
eq "kuzaklar→pods"   "pods"   "$(resolve_noun kuzaklar)"
eq "pods→pods"       "pods"   "$(resolve_noun pods)"
eq "my-pod→my-pod"   "my-pod" "$(resolve_noun my-pod)"
eq "эш→jobs"         "jobs"   "$(resolve_noun эш)"

echo "── alif: cyrl→arab (Yaña imlâ) ──"
eq "Татарнетес→arab" "تاتارنېتېس" "$(printf '%s' 'Татарнетес' | cyrl_to_arab)"
eq "төен→arab (т-ө-е-н)" "تۆېن" "$(printf '%s' 'төен' | cyrl_to_arab)"
case "$(printf '%s' 'Исәнмесез' | cyrl_to_arab)" in ئ*) ok "word-initial hamza";; *) bad "word-initial hamza" "ئ…" "$(printf '%s' Исәнмесез | cyrl_to_arab)";; esac
if printf '%s' 'Исәнмесез, әйдә!' | cyrl_to_arab | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1; then ok "arab output is valid UTF-8"; else bad "arab output is valid UTF-8" "valid" "invalid"; fi

echo "── i18n t() ──"
case "$(t err.unknown_verb foobar)" in *foobar*) ok "t interpolates arg";; *) bad "t interpolates arg" "*foobar*" "$(t err.unknown_verb foobar)";; esac
eq "en tagline" "A national container orchestrator" "$(AYDA_LANG=en t version.tagline)"

echo "── tea schedule ──"
eq "3 tea windows/day" "3" "$(tea_windows | grep -c .)"

echo "── kubectl error hints (tat_error_hint) ──"
eq "unknown kind → nomatch"   "err.hint.nomatch"   "$(tat_error_hint 'error: the server could not find the requested resource')"
eq "no resource type → nomatch" "err.hint.nomatch" "$(tat_error_hint 'error: the server doesn'"'"'t have a resource type "kuzak"')"
eq "pod not found → notfound" "err.hint.notfound"  "$(tat_error_hint 'Error from server (NotFound): pods "x" not found')"
eq "forbidden"                "err.hint.forbidden" "$(tat_error_hint 'pods is forbidden: User "u" cannot list')"
eq "refused → conn"           "err.hint.conn"      "$(tat_error_hint 'dial tcp 127.0.0.1:6443: connect: connection refused')"
eq "exec without -- → dashdash" "err.hint.exec_dashdash" "$(tat_error_hint 'error: exec [POD] [COMMAND] is not supported anymore. Use exec [POD] -- [COMMAND] instead')"
eq "corpus line is non-empty" "1" "$([ -n "$(tat_random_praise)" ] && echo 1)"

echo "── skctl backend: mapping (skctl_map) ──"
# skm VERB ARGS… → "skctl args" on success, "!<error-key>" on refusal.
skm() { if skctl_map "$@"; then printf '%s' "${SKARGS[*]}"; else printf '!%s' "$SKERR"; fi; }
eq "get pods"                    "get pods"            "$(skm get pods)"
eq "get po → pods"               "get pods"            "$(skm get po)"
eq "get deploy → deployments"    "get deployments"     "$(skm get deploy)"
eq "get nodes"                   "get nodes"           "$(skm get nodes)"
eq "get events"                  "get events"          "$(skm get events)"
eq "apply -f f.json"             "apply f.json"        "$(skm apply -f f.json)"
eq "apply --filename=f.json"     "apply f.json"        "$(skm apply --filename=f.json)"
eq "scale deploy web --replicas=3" "scale web 3"       "$(skm scale deploy web --replicas=3)"
eq "scale deploy/web --replicas 2" "scale web 2"       "$(skm scale deploy/web --replicas 2)"
eq "delete deploy web"           "delete web"          "$(skm delete deploy web)"
eq "delete deployment/web"       "delete web"          "$(skm delete deployment/web)"
eq "cordon a"                    "cordon a"            "$(skm cordon a)"
eq "drain nodes a"               "drain a"             "$(skm drain nodes a)"
eq "uncordon node/a"             "uncordon a"          "$(skm uncordon node/a)"
eq "label nodes a disk=ssd"      "label a disk=ssd"    "$(skm label nodes a disk=ssd)"
eq "taint node/a gpu=true:NoSchedule" "taint a gpu=true:NoSchedule" "$(skm taint node/a gpu=true:NoSchedule)"
eq "migrate web-1 b"             "migrate web-1 b"     "$(skm migrate web-1 b)"
eq "migrate pods web-1 b"        "migrate web-1 b"     "$(skm migrate pods web-1 b)"
echo "── skctl backend: honest refusals ──"
eq "describe → unsupported verb" "!skctl.unsupported.verb"  "$(skm describe pods x)"
eq "logs → unsupported verb"     "!skctl.unsupported.verb"  "$(skm logs x)"
eq "get svc → unsupported kind"  "!skctl.unsupported.kind"  "$(skm get svc)"
eq "delete svc x → unsupported kind" "!skctl.unsupported.kind" "$(skm delete svc x)"
eq "label pods x a=b → unsupported kind" "!skctl.unsupported.kind" "$(skm label pods x a=b)"
eq "get pods -A → unsupported flag" "!skctl.unsupported.flag" "$(skm get pods -A)"
eq "get pods -o json → unsupported flag" "!skctl.unsupported.flag" "$(skm get pods -o json)"
eq "drain a --force → unsupported flag" "!skctl.unsupported.flag" "$(skm drain a --force)"
eq "get pods web-1 → usage (no by-name get)" "!skctl.usage" "$(skm get pods web-1)"
eq "get (no kind) → usage"       "!skctl.usage"             "$(skm get)"
eq "scale without --replicas → usage" "!skctl.usage"        "$(skm scale deploy web)"
eq "scale --replicas=x → usage"  "!skctl.usage"             "$(skm scale deploy web --replicas=x)"
eq "delete web (no kind) → usage" "!skctl.usage"            "$(skm delete web)"
eq "delete deploy a b → usage"   "!skctl.usage"             "$(skm delete deploy a b)"
eq "label a k=v (no kind) → usage" "!skctl.usage"           "$(skm label a k=v)"
eq "label nodes a k=v k2=v2 → usage" "!skctl.usage"         "$(skm label nodes a k=v k2=v2)"
eq "apply (no file) → usage"     "!skctl.usage"             "$(skm apply)"
echo "── skctl backend: verbs only skctl has ──"
eq "күчер→migrate"  "migrate" "$(skctl_resolve_verb күчер)"
eq "küçer→migrate"  "migrate" "$(skctl_resolve_verb küçer)"
eq "zzz→(empty)"    ""        "$(skctl_resolve_verb zzz)"
echo "── skctl backend: error hints ──"
eq "WEBAPP_URL unset → env hint" "skctl.hint.env"   "$(skctl_error_hint 'skctl: line 24: WEBAPP_URL: set WEBAPP_URL')"
eq "curl 401 → token hint"       "skctl.hint.token" "$(skctl_error_hint 'curl: (22) The requested URL returned error: 401')"
eq "curl conn → conn hint"       "err.hint.conn"    "$(skctl_error_hint 'curl: (7) Failed to connect to localhost port 8787')"

echo "── skctl backend: end-to-end through bin/ayda (stub skctl on PATH) ──"
STUB="$(mktemp -d)"; LOG="$STUB/calls"; trap 'rm -rf "$STUB" "${STUBK:-}"' EXIT
cat > "$STUB/skctl" <<'STUBEOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SKSTUB_LOG"
printf 'OUT %s\n' "$*"
exit "${SKSTUB_RC:-0}"
STUBEOF
chmod +x "$STUB/skctl"
# ay ARGS… → runs ayda on the skctl backend; stdout to $STUB/out, rc echoed.
ay() { : > "$LOG"; PATH="$STUB:$PATH" AYDA_BACKEND=skctl AYDA_NO_TEA=1 SKSTUB_LOG="$LOG" \
         bash bin/ayda "$@" >"$STUB/out" 2>"$STUB/err"; echo $?; }
eq "күрсәт кузаклар → rc 0"          "0"                   "$(ay күрсәт кузаклар)"
eq "  stub got 'get pods'"           "get pods"            "$(cat "$LOG")"
eq "  stdout is exactly skctl's"     "OUT get pods"        "$(cat "$STUB/out")"
eq "kürsät töennär → get nodes"      "0"                   "$(ay kürsät töennär)"
eq "  stub got 'get nodes'"          "get nodes"           "$(cat "$LOG")"
eq "күпәйт урнаштыру web --replicas=3" "0"                 "$(ay күпәйт урнаштыру web --replicas=3)"
eq "  stub got 'scale web 3'"        "scale web 3"         "$(cat "$LOG")"
eq "бетер урнаштыру web"             "0"                   "$(ay бетер урнаштыру web)"
eq "  stub got 'delete web'"         "delete web"          "$(cat "$LOG")"
eq "кулла -f lab/x.json"             "0"                   "$(ay кулла -f lab/x.json)"
eq "  stub got 'apply lab/x.json'"   "apply lab/x.json"    "$(cat "$LOG")"
eq "күчер web-1 b"                   "0"                   "$(ay күчер web-1 b)"
eq "  stub got 'migrate web-1 b'"    "migrate web-1 b"     "$(cat "$LOG")"
eq "сөйлә кузак x → rc 69"           "69"                  "$(ay сөйлә кузак x)"
eq "  stub NOT called"               ""                    "$(cat "$LOG")"
eq "  stdout empty"                  ""                    "$(cat "$STUB/out")"
eq "күрсәт кузаклар -A → rc 69"      "69"                  "$(ay күрсәт кузаклар -A)"
eq "  stub NOT called"               ""                    "$(cat "$LOG")"
eq "бетер хезмәт s → rc 69"          "69"                  "$(ay бетер хезмәт s)"
eq "  stub NOT called"               ""                    "$(cat "$LOG")"
eq "unknown verb still rc 64"        "64"                  "$(ay zzzz)"
eq "skctl rc 3 propagates"           "3"                   "$(SKSTUB_RC=3 ay күрсәт кузаклар)"
case "$(cat "$STUB/err")" in *"get, apply, scale"*) bad "rc 3 is not a refusal" "" "refusal text";; *) ok "rc 3 is not a refusal";; esac
eq "AYDA_BACKEND=bogus → rc 64"      "64"                  "$(PATH="$STUB:$PATH" AYDA_BACKEND=bogus AYDA_NO_TEA=1 bash bin/ayda get pods >/dev/null 2>&1; echo $?)"
eq "skctl missing → rc 127"          "127"                 "$(AYDA_BACKEND=skctl AYDA_SKCTL=/nonexistent/skctl AYDA_NO_TEA=1 bash bin/ayda get pods >/dev/null 2>&1; echo $?)"
case "$(AYDA_LANG=en PATH="$STUB:$PATH" AYDA_BACKEND=skctl AYDA_NO_TEA=1 bash bin/ayda logs x 2>&1 >/dev/null)" in
  *'has no "logs"'*"Nothing was run"*) ok "en refusal text" ;;
  *) bad "en refusal text" '*has no "logs"*Nothing was run*' "$(AYDA_LANG=en PATH="$STUB:$PATH" AYDA_BACKEND=skctl AYDA_NO_TEA=1 bash bin/ayda logs x 2>&1 >/dev/null)" ;;
esac

echo "── krew shim: KUBECTL_PATH (kubectl ≥1.37) ──"
printf '#!/usr/bin/env bash\nprintf "K %%s\\n" "$*"\n' > "$STUB/kk"; chmod +x "$STUB/kk"
eq "kubectl-ayda uses KUBECTL_PATH" "K get pods" "$(KUBECTL_PATH="$STUB/kk" AYDA_NO_TEA=1 bash bin/kubectl-ayda күрсәт кузаклар 2>/dev/null)"
eq "AYDA_KUBECTL wins over KUBECTL_PATH" "K get nodes" "$(KUBECTL_PATH=/nonexistent AYDA_KUBECTL="$STUB/kk" AYDA_NO_TEA=1 bash bin/kubectl-ayda күрсәт төеннәр 2>/dev/null)"

echo "── Яңа имля керем / Arabic-script input ──"
AR_KURSAT="$(printf '%s' күрсәт | cyrl_to_arab)"; AR_KUZAK="$(printf '%s' кузаклар | cyrl_to_arab)"
eq "arab күрсәт → get"     "get"  "$(resolve_verb "$AR_KURSAT")"
eq "arab кузаклар → pods"  "pods" "$(resolve_noun "$AR_KUZAK")"
eq "arab unknown → empty"  ""     "$(resolve_verb "$(printf '%s' җүләр | cyrl_to_arab)")"
eq "alif_has_arab cyrl"    "no"   "$(alif_has_arab күрсәт && echo yes || echo no)"

echo "── word lists resolve through the dictionary ──"
badv=""; for w in $(dict_verbs); do [ -n "$(translate_verb "$w")" ] || badv="$badv $w"; done
eq "every dict_verbs word is a verb" "" "$badv"
badn=""; for w in $(dict_nouns); do [ "$(translate_noun "$w")" != "$w" ] || badn="$badn $w"; done
eq "every dict_nouns word is a noun" "" "$badn"

echo "── completion (ayda __complete) ──"
export AYDA_NO_TEA=1
cmp_() { ayda_complete "$@" | tr '\n' ' ' | sed 's/ $//'; }
eq "күр<Tab> → күрсәт"         "күрсәт"              "$(cmp_ күр)"
eq "күрсәт ку<Tab>"            "кузак кузаклар"      "$(cmp_ күрсәт ку)"
eq "latin kür<Tab>"            "kürsät"              "$(AYDA_ALIF=latin cmp_ kür)"
eq "latin kürsät kuz<Tab>"     "kuzak kuzaklar"      "$(AYDA_ALIF=latin cmp_ kürsät kuz)"
eq "arab verb, then nouns"     "$(printf '%s\n' кузак | cyrl_to_arab)" "$(AYDA_ALIF=arab cmp_ "$AR_KURSAT" "$(printf '%s' куза | cyrl_to_arab)" | cut -d' ' -f1)"
eq "flags are left alone"      ""                    "$(cmp_ күрсәт -)"
eq "ярд<Tab> builtin"          "ярдәм"               "$(cmp_ ярд)"
STUBK="$(mktemp -d)"
cat > "$STUBK/kubectl" <<'KEOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$KLOG"
case "$*" in "get pods -o name"*) printf 'pod/ecpocmak-web\npod/cakcak-api\n' ;;
             "get nodes -o name"*) printf 'node/kazan\n' ;; esac
KEOF
chmod +x "$STUBK/kubectl"; export KLOG="$STUBK/log"
eq "names: күрсәт кузак e<Tab>" "ecpocmak-web" "$(KUBECTL_BIN="$STUBK/kubectl" cmp_ күрсәт кузак e)"
eq "  one read-only call with timeout" "get pods -o name --request-timeout=2s" "$(tail -1 "$KLOG")"
: > "$KLOG"
KUBECTL_BIN="$STUBK/kubectl" cmp_ -n tatar --context=kind-x сөйлә кузак "" >/dev/null
eq "  scope flags forwarded, nothing else" "get pods -o name --request-timeout=2s -n tatar --context=kind-x" "$(tail -1 "$KLOG")"
eq "names: көндәлек <Tab> → pods" "cakcak-api ecpocmak-web" "$(KUBECTL_BIN="$STUBK/kubectl" cmp_ көндәлек "" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')"
eq "names: cordon <Tab> → nodes" "kazan" "$(KUBECTL_BIN="$STUBK/kubectl" cmp_ cordon "")"
: > "$KLOG"
eq "tea time → no cluster call" "" "$(AYDA_NO_TEA='' AYDA_FORCE_TEA=1 KUBECTL_BIN="$STUBK/kubectl" cmp_ күрсәт кузак "")$(cat "$KLOG")"
eq "skctl backend → no kubectl call" "" "$(AYDA_BACKEND=skctl KUBECTL_BIN="$STUBK/kubectl" cmp_ күрсәт кузак "")$(cat "$KLOG")"

echo "── completion scripts & entry points ──"
bcomp() { ( complete() { :; }; . completion/ayda.bash; COMP_WORDS=("$HERE/bin/ayda" "$@"); COMP_CWORD=$#
            _ayda_complete; printf '%s ' "${COMPREPLY[@]}" | sed 's/ $//' ); }
eq "bash: ayda күр<Tab>"         "күрсәт"          "$(bcomp күр)"
eq "bash: ayda күрсәт төе<Tab>"  "төен төеннәр"    "$(bcomp күрсәт төе)"
eq "kubectl_complete-ayda"       "күрсәт :4"       "$(bash bin/kubectl_complete-ayda күр | tr '\n' ' ' | sed 's/ $//')"
ln -s "$HERE/bin/ayda" "$STUBK/ayda-link"; ln -s "$HERE/bin/kubectl-ayda" "$STUBK/kubectl-ayda"
eq "ayda via symlink (install.sh)" "күрсәт" "$("$STUBK/ayda-link" __complete күр)"
eq "kubectl-ayda via symlink (krew)" "0" "$(AYDA_PLAIN=1 "$STUBK/kubectl-ayda" ярдәм >/dev/null 2>&1; echo $?)"
if command -v zsh >/dev/null 2>&1; then
  if zsh -n completion/_ayda; then ok "zsh completion parses"; else bad "zsh completion parses" "ok" "syntax error"; fi
fi

echo
echo "Йомгак / result: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
