#!/usr/bin/env bash
# unit.sh — Татарнетес берәмлек тестлары / self-contained unit tests (no bats dep).
# Куллану / usage:  bash tests/unit.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
cd "$HERE" || exit 1
export AYDA_LANG=tt AYDA_ALIF=cyrl AYDA_PLAIN=1

# shellcheck source=/dev/null
for m in render alif catalog i18n dictionary phrases teatime errors skctl; do . "lib/$m.sh"; done

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
STUB="$(mktemp -d)"; LOG="$STUB/calls"; trap 'rm -rf "$STUB"' EXIT
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

echo
echo "Йомгак / result: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
