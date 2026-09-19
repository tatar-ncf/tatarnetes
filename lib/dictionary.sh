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
    # --- инглизчә kubectl фигыльләре (passthrough) ---
    get|describe|create|apply|delete|logs|exec|scale|autoscale|edit|rollout|\
    expose|run|port-forward|config|label|annotate|patch|top|wait|explain|\
    api-resources|api-versions|cluster-info|set|cordon|uncordon|drain|taint|\
    proxy|cp|auth|certificate|attach|debug|events|version|completion|kustomize|\
    diff|replace|rollback|apply-view-last-applied|options|plugin)
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
resolve_verb() {
  local v="$1" r
  r="$(translate_verb "$v")"; [ -n "$r" ] && { printf '%s' "$r"; return 0; }
  translate_verb "$(printf '%s' "$v" | latin_to_cyrl)"
}
resolve_noun() {
  local n="$1" r c
  r="$(translate_noun "$n")"; [ "$r" != "$n" ] && { printf '%s' "$r"; return 0; }
  c="$(printf '%s' "$n" | latin_to_cyrl)"
  r="$(translate_noun "$c")"
  if [ "$r" != "$c" ]; then printf '%s' "$r"; else printf '%s' "$n"; fi
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
