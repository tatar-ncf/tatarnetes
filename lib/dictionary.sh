# shellcheck shell=bash
# dictionary.sh — Татарча әмерләрне һәм асылларны kubectl теленә тәрҗемә итү.
# Translate Tatar verbs & resource nouns into kubectl. Bash 3.2 (no assoc arrays):
# we use plain case statements — portable and fast.

# --- Фигыльләр / verbs --------------------------------------------------
# Татарча кертәсең — kubectl фигыле кайта. Инглизчә kubectl фигыле дә эшли (passthrough).
translate_verb() {
  case "$1" in
    күрсәт|курсат|кара|ал|күрсәтче)                 echo get ;;
    сөйлә|сойла|аңлат|аңлатма|тасвирла|тулы)         echo describe ;;
    төзе|тозе|яса|булдыр)                            echo create ;;
    кулла|урнаштыр|кертеп-куй|куй)                   echo apply ;;
    бетер|бетерә|юк-ит|юкит|ю)                       echo delete ;;
    көндәлек|кондалек|язма|журнал)                   echo logs ;;
    кер|эчкә-кер|эчкәкер)                            echo exec ;;
    күпәйт|купайт|зурайт|үлчә|улча)                  echo scale ;;
    төзәт|тозат|редакциялә)                          echo edit ;;
    яңарт|яңарту|янарт)                              echo rollout ;;
    ач|күрсәтмә-ач)                                  echo expose ;;
    җибәр|жибар|эшләт|эшлат)                         echo run ;;
    порт|тоташтыр|порт-күчер)                        echo port-forward ;;
    контекст|көйлә|койла|көйләү)                     echo config ;;
    тамгала)                                         echo label ;;
    искәрмә|искарма)                                 echo annotate ;;
    ямау|ямый|төзәтмә)                               echo patch ;;
    өскә|оска|йөк)                                   echo top ;;
    көт|кот)                                         echo wait ;;
    аңлатып-бир|аңлат-миңа)                          echo explain ;;
    асыллар|ресурслар)                              echo api-resources ;;
    төркем-хәбәре|кластер-хәбәре)                   echo cluster-info ;;
    # --- инглизчә kubectl фигыльләре (passthrough), kubectl v1.37 буенча ---
    # kubectl v1.37 top-level commands (checked against the real binary).
    get|describe|create|apply|delete|logs|exec|scale|autoscale|edit|rollout|\
    expose|run|port-forward|config|label|annotate|patch|top|wait|explain|\
    api-resources|api-versions|cluster-info|set|cordon|uncordon|drain|taint|\
    proxy|cp|auth|certificate|attach|debug|events|version|completion|kustomize|\
    diff|replace|options|plugin|kuberc)
                                                     echo "$1" ;;
    *)                                               echo "" ;;
  esac
}

# --- Асыллар / resource nouns -------------------------------------------
# Татар сүзе → kubectl ресурсы. Билгесез сүз үзгәрешсез кайта (исемнәр өчен).
# Unknown tokens pass through unchanged (so pod names / values survive).
translate_noun() {
  case "$1" in
    кузак|кузаклар|борчак|борчаклар)                 echo pods ;;      # под = кузак (стручок)
    төен|төеннәр|тоен|тоеннар)                        echo nodes ;;     # node = төен (узел)
    хезмәт|хезмәтләр|хезмат)                          echo svc ;;       # service = хезмәт
    урнаштыру|урнаштырулар|җәю|жаю)                   echo deploy ;;    # deployment = урнаштыру
    мәйдан|мәйданнар|майдан|аймак)                    echo ns ;;        # namespace = мәйдан
    капка|капкалар)                                   echo ingress ;;   # ingress = капка (ворота)
    сер|серләр|сер-саклагыч)                          echo secrets ;;   # secret = сер
    көйләмә|көйләмәләр|конфиг|конфиг-карта)           echo cm ;;        # configmap = көйләмә
    күләм|күләмнәр|кулам)                             echo pv ;;        # volume = күләм
    таләп|күләм-таләбе)                               echo pvc ;;       # pvc = күләм таләбе
    эш|эшләр)                                          echo jobs ;;      # job = эш
    вакытлы-эш|вакытлыэш|такмаклы-эш)                echo cronjobs ;;  # cronjob = вакытлы эш
    күчермә|күчермәләр|кучерма)                       echo rs ;;        # replicaset = күчермә
    көтү|көтү-урнаштыру)                              echo ds ;;        # daemonset = көтү (стадо)
    тезмә|тәртипле-тезмә)                             echo statefulset ;; # statefulset = тезмә
    хисап|хисап-язмасы)                              echo sa ;;        # serviceaccount
    роль|рольләр)                                     echo roles ;;
    вакыйга|вакыйгалар)                              echo events ;;    # events = вакыйгалар
    барысы|барлык|һәммәсе|бөтенесе)                  echo all ;;       # all
    *)                                                echo "$1" ;;
  esac
}

# resolve_verb/resolve_noun — башта сүзлек (кирилл/инглиз), аннары латин фолбэк.
# Try the dictionary as-is first (Cyrillic or English kubectl), then fall back to
# Latin→Cyrillic input. English kubectl verbs (get/pods) stay untouched.
# Гарәп язуы (Яңа имля) белән кертелгән сүз dict_verbs/dict_nouns аша таныла.
# Arabic-script input is recognised through the dict_verbs / dict_nouns lists.
resolve_verb() {
  local v="$1" r
  r="$(translate_verb "$v")"; [ -n "$r" ] && { printf '%s' "$r"; return 0; }
  if alif_has_arab "$v"; then
    # shellcheck disable=SC2046  # word lists are single words by construction
    r="$(alif_arab_pick "$v" $(dict_verbs))" && translate_verb "$r"
    return 0
  fi
  translate_verb "$(printf '%s' "$v" | latin_to_cyrl)"
}
resolve_noun() {
  local n="$1" r c
  r="$(translate_noun "$n")"; [ "$r" != "$n" ] && { printf '%s' "$r"; return 0; }
  if alif_has_arab "$n"; then
    # shellcheck disable=SC2046
    if r="$(alif_arab_pick "$n" $(dict_nouns))"; then translate_noun "$r"; else printf '%s' "$n"; fi
    return 0
  fi
  c="$(printf '%s' "$n" | latin_to_cyrl)"
  r="$(translate_noun "$c")"
  if [ "$r" != "$c" ]; then printf '%s' "$r"; else printf '%s' "$n"; fi
}

# --- Тулыландыру өчен исемлекләр / word lists for completion & Arabic input ---
# Төп (каноник) формалар гына; һәрберсе translate_verb/translate_noun аша
# танылырга тиеш (tests/unit.sh тикшерә). Canonical forms only; every word must
# resolve through the case tables above (enforced by tests/unit.sh).
dict_verbs() {
  printf '%s\n' күрсәт кара сөйлә тасвирла төзе яса кулла бетер көндәлек кер \
    күпәйт төзәт яңарт ач җибәр порт тоташтыр контекст тамгала искәрмә ямау \
    өскә көт аңлатып-бир асыллар төркем-хәбәре
}
dict_nouns() {
  printf '%s\n' кузак кузаклар төен төеннәр хезмәт хезмәтләр урнаштыру урнаштырулар \
    мәйдан мәйданнар капка капкалар сер серләр көйләмә көйләмәләр күләм күләмнәр \
    таләп эш эшләр вакытлы-эш күчермә күчермәләр көтү тезмә хисап роль рольләр \
    вакыйга вакыйгалар барысы
}

# Сүзлекне күрсәтү / print the dictionary as a table.
show_dictionary() {
  cat <<'TBL'

  ТАТАРНЕТЕС СҮЗЛЕГЕ / TATARNETES DICTIONARY
  ═══════════════════════════════════════════════════════════════

  ФИГЫЛЬЛӘР / VERBS            татарча            → kubectl
  ---------------------------------------------------------------
    күрсәт / кара / ал         show / list        → get
    сөйлә / аңлат              describe           → describe
    төзе / яса                 create             → create
    кулла / куй                apply              → apply
    бетер / ю                  delete             → delete
    көндәлек / язма            logs               → logs
    кер                        exec               → exec
    күпәйт / зурайт            scale              → scale
    төзәт                      edit               → edit
    яңарт                      rollout            → rollout
    ач                         expose             → expose
    җибәр / эшләт              run                → run
    порт / тоташтыр            port-forward       → port-forward
    өскә / йөк                 top                → top
    көт                        wait               → wait

  АСЫЛЛАР / RESOURCES          татарча            → kubectl
  ---------------------------------------------------------------
    кузак (стручок)            pod                → pods
    төен (узел)                node               → nodes
    хезмәт                     service            → svc
    урнаштыру / җәю            deployment         → deploy
    мәйдан / аймак             namespace          → ns
    капка (ворота)             ingress            → ingress
    сер                        secret             → secrets
    көйләмә                    configmap          → cm
    күләм                      volume             → pv
    эш                         job                → jobs
    вакытлы-эш                 cronjob            → cronjobs
    күчермә                    replicaset         → rs
    көтү (стадо)               daemonset          → ds
    тезмә                      statefulset        → statefulset
    вакыйга                    event              → events
    барысы / һәммәсе           all                → all

  Мисал / example:
    ayda күрсәт кузаклар            →  kubectl get pods
    ayda сөйлә төен  node-1         →  kubectl describe node node-1
    ayda бетер хезмәт  my-svc       →  kubectl delete svc my-svc
    ayda күрсәт барысы -A           →  kubectl get all -A

TBL
}

# --- Tab-тулыландыру / shell completion (`ayda __complete <words…>`) -----
# Соңгы сүз — курсор астындагы (буш булырга мөмкин). The last word is the one
# under the cursor (may be empty). Prints one candidate per line.

# Аерым кыйммәт ала торган kubectl флаглары / kubectl flags taking a separate value.
AYDA_VALUE_FLAGS="-n --namespace --context --kubeconfig --cluster --user -o --output \
-l --selector -f --filename -c --container --replicas --field-selector --request-timeout"

# ayda_names KIND — кластердан исемнәр: бары `kubectl get KIND -o name`, вакыт чиге белән.
# Names from the cluster through ONE read-only call: `kubectl get KIND -o name`
# with --request-timeout. Only scope flags the user typed (context, kubeconfig,
# namespace, -A) are forwarded; nothing else from the command line is.
ayda_names() {
  local kind="$1" f want=""
  local -a scope=()
  [ -n "$kind" ] || return 0
  case "$kind" in */*|all|-*) return 0 ;; esac
  [ "${AYDA_BACKEND:-kubectl}" = kubectl ] || return 0
  tea_now && return 0                       # чәй вакытында кластер җавап бирми / tea: no calls
  command -v "${KUBECTL_BIN:-kubectl}" >/dev/null 2>&1 || return 0
  for f in ${COMP_FLAGS[@]+"${COMP_FLAGS[@]}"}; do
    if [ -n "$want" ]; then scope+=("$want" "$f"); want=""; continue; fi
    case "$f" in
      -n|--namespace|--context|--kubeconfig|--cluster|--user) want="$f" ;;
      --namespace=*|--context=*|--kubeconfig=*|--cluster=*|--user=*|-A|--all-namespaces) scope+=("$f") ;;
      -n?*) scope+=("$f") ;;
    esac
  done
  "${KUBECTL_BIN:-kubectl}" get "$kind" -o name \
    --request-timeout="${AYDA_COMPLETE_TIMEOUT:-2s}" ${scope[@]+"${scope[@]}"} 2>/dev/null \
    | sed 's|^[^/]*/||'
}

# _glossary_keys — data/glossary.tsv'тагы төшенчәләр (буш урын → «-»).
_glossary_keys() {
  local f="$AYDA_HOME/data/glossary.tsv"
  [ -f "$f" ] || return 0
  grep -v '^#' "$f" | cut -f1 | sed 's/ /-/g'
}

ayda_complete() {
  local cur="" n verb kverb kind
  [ "$#" -gt 0 ] && cur="${!#}"
  case "$cur" in -*) return 0 ;; esac       # флаглар — kubectl'ның үз эше / flags: not ours
  local -a before=()
  [ "$#" -gt 1 ] && before=("${@:1:$(($# - 1))}")
  complete_split "$AYDA_VALUE_FLAGS" ${before[@]+"${before[@]}"}
  n=${#COMP_POS[@]}

  if [ "$n" -eq 0 ]; then
    # shellcheck disable=SC2046
    complete_words "$cur" $(dict_verbs) аңлат ярдәм сүзлек версия шигырь мәкаль чәй сәлам
    [ "${AYDA_BACKEND:-kubectl}" = skctl ] && complete_words "$cur" күчер
    return 0
  fi

  verb="$(complete_to_cyrl "${COMP_POS[0]}" аңлат)"
  if [ "$verb" = аңлат ]; then
    # shellcheck disable=SC2046
    [ "$n" -eq 1 ] && complete_words "$cur" $(_glossary_keys)
    return 0
  fi
  kverb="$(resolve_verb "${COMP_POS[0]}")"     # латин/гарәп керемне үзе таный
  case "$kverb" in
    get|describe|delete|edit|label|annotate|patch|scale|wait|expose|top|explain|taint)
      if [ "$n" -eq 1 ]; then
        # shellcheck disable=SC2046
        complete_words "$cur" $(dict_nouns)
      elif [ "$kverb" != explain ]; then
        kind="$(resolve_noun "${COMP_POS[1]}")"
        # shellcheck disable=SC2046
        complete_raw "$cur" $(ayda_names "$kind")
      fi ;;
    logs|exec|attach|port-forward)
      # shellcheck disable=SC2046
      [ "$n" -eq 1 ] && complete_raw "$cur" $(ayda_names pods) ;;
    cordon|uncordon|drain)
      # shellcheck disable=SC2046
      [ "$n" -eq 1 ] && complete_raw "$cur" $(ayda_names nodes) ;;
  esac
  return 0
}
