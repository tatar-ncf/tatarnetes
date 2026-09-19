#!/usr/bin/env bash
# unit.sh — Татарнетес берәмлек тестлары / self-contained unit tests (no bats dep).
# Куллану / usage:  bash tests/unit.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
cd "$HERE"
export AYDA_LANG=tt AYDA_ALIF=cyrl AYDA_PLAIN=1

# shellcheck source=/dev/null
for m in render alif catalog i18n dictionary phrases teatime; do . "lib/$m.sh"; done

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

echo "── resolve_noun ──"
eq "кузак→pods"      "pods"   "$(resolve_noun кузак)"
eq "kuzaklar→pods"   "pods"   "$(resolve_noun kuzaklar)"
eq "pods→pods"       "pods"   "$(resolve_noun pods)"
eq "my-pod→my-pod"   "my-pod" "$(resolve_noun my-pod)"
eq "эш→jobs"         "jobs"   "$(resolve_noun эш)"

echo "── i18n t() ──"
case "$(t err.unknown_verb foobar)" in *foobar*) ok "t interpolates arg";; *) bad "t interpolates arg" "*foobar*" "$(t err.unknown_verb foobar)";; esac
eq "en tagline" "A national container orchestrator" "$(AYDA_LANG=en t version.tagline)"

echo "── tea schedule ──"
eq "3 tea windows/day" "3" "$(tea_windows | grep -c .)"

echo
echo "Йомгак / result: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
