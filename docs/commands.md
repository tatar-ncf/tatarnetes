# Әмерләр сүзлеге / Command dictionary

*Татарча беренче, аннары инглизчә. / Tatar first, then English.*

Татарнетес татарча әмерне алып, аны `kubectl` теленә тәрҗемә итә. Гадәти
инглизчә `kubectl` әмерләре дә эшли (passthrough).

Tatarnetes takes a Tatar command and translates it into `kubectl`. Plain English
`kubectl` verbs also work (passthrough).

## Фигыльләр / Verbs

| Татарча | English | → kubectl |
|---|---|---|
| күрсәт · кара · ал | show / list | `get` |
| сөйлә · тасвирла | describe | `describe` |
| аңлат | explain (глоссарий + схема) | `explain` — [аста кара / see below](#аңлат--татарча-kubectl-explain) |
| төзе · яса | create | `create` |
| кулла · куй | apply | `apply` |
| бетер · ю | delete | `delete` |
| көндәлек · язма | logs | `logs` |
| кер | exec | `exec` |
| күпәйт · зурайт | scale | `scale` |
| төзәт | edit | `edit` |
| яңарт | rollout | `rollout` |
| ач | expose | `expose` |
| җибәр · эшләт | run | `run` |
| порт · тоташтыр | port-forward | `port-forward` |
| контекст · көйлә | config | `config` |
| өскә · йөк | top | `top` |
| көт | wait | `wait` |
| асыллар | api-resources | `api-resources` |

## Асыллар / Resources

| Татарча | Мәгънә / meaning | English | → kubectl |
|---|---|---|---|
| кузак(лар) | стручок / pea-pod | pod | `pods` |
| төен(нәр) | узел / knot | node | `nodes` |
| хезмәт(ләр) | услуга / service | service | `svc` |
| урнаштыру · җәю | размещение | deployment | `deploy` |
| мәйдан · аймак | площадь / area | namespace | `ns` |
| капка | ворота / gate | ingress | `ingress` |
| сер(ләр) | тайна / secret | secret | `secrets` |
| көйләмә | настройка | configmap | `cm` |
| күләм | объём / volume | volume | `pv` |
| таләп | требование | pvc | `pvc` |
| эш(ләр) | работа / job | job | `jobs` |
| вакытлы-эш | по времени | cronjob | `cronjobs` |
| күчермә | копия / copy | replicaset | `rs` |
| көтү | стадо / herd | daemonset | `ds` |
| тезмә | вереница | statefulset | `statefulset` |
| вакыйга(лар) | событие / event | event | `events` |
| барысы · һәммәсе | всё / all | all | `all` |

## Мисаллар / Examples

```bash
ayda күрсәт кузаклар                 # kubectl get pods
ayda күрсәт кузаклар -n tatar-tozem  # kubectl get pods -n tatar-tozem
ayda сөйлә төен tatar-node-1         # kubectl describe node tatar-node-1
ayda көндәлек ecpocmak-web           # kubectl logs ecpocmak-web
ayda кер ecpocmak-web -- sh          # kubectl exec ecpocmak-web -- sh  («--» мәҗбүри / required)
ayda күпәйт урнаштыру web --replicas=3
                                     # kubectl scale deploy web --replicas=3
ayda бетер хезмәт cakcak-api         # kubectl delete svc cakcak-api
ayda күрсәт барысы -A                # kubectl get all -A
```

## «аңлат» — татарча kubectl explain

`ayda аңлат <төшенчә>[.юл]` башта [глоссарийдан](terminology.tt.md) татарча
аңлатма бирә (мәгълүмат `data/glossary.tsv`та, `scripts/build-glossary.sh`
аны `docs/terminology.tt.md`дан җыя), аннары чын `kubectl explain` белән кыр
схемасын күрсәтә. `--кыскача` — глоссарий гына (кластерсыз). `kubectl explain`
флаглары (`-R`, `--max-depth`, `--api-version`) үткәрелә.

`ayda аңлат <term>[.path]` first prints the Tatar explanation from the
[glossary](terminology.tt.md) (data in `data/glossary.tsv`, generated from
`docs/terminology.tt.md` by `scripts/build-glossary.sh`), then the field schema
from the real `kubectl explain`. `--кыскача` (or `--brief`) prints the glossary
entry only, offline. `kubectl explain` flags (`-R`, `--max-depth`,
`--api-version`) are passed through.

```bash
ayda аңлат                        # глоссарий исемлеге / list all terms
ayda аңлат кузак                  # кузак — pod … + kubectl explain pods
ayda аңлат кузак.spec.containers  # kubectl explain pods.spec.containers
ayda аңлат урнаштыру -R --max-depth=2
ayda аңлат бүлүче                 # гомуми төшенчә (scheduler) — схемасыз
```

> **v3.0.0 үзгәреше / breaking change:** элек `аңлат` = `describe` иде. Хәзер
> объектны тасвирлау өчен `сөйлә` яки `тасвирла` куллан. Formerly `аңлат` meant
> `describe`; use `сөйлә` / `тасвирла` for that now. `ayda аңлат кузак my-pod`
> (ике сүз) кисәтү белән туктый / stops with a hint.

## Эчке әмерләр / Built-ins

| Әмер | Эш |
|---|---|
| `ayda ярдәм` / `help` | ярдәм / help |
| `ayda сүзлек` | бу сүзлек / this dictionary |
| `ayda аңлат [төшенчә]` | татарча explain / Tatar explain |
| `ayda версия` | версия / version |
| `ayda тукай` | Тукайдан бер шигырь / a Tukay verse |
| `ayda чәй` | чәй тәнәфесе графигы / tea schedule |
| `ayda сәлам` | сәлам! / hello |
