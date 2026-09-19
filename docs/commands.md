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
| сөйлә · аңлат · тасвирла | describe | `describe` |
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
ayda күпәйт урнаштыру web --replicas=3
                                     # kubectl scale deploy web --replicas=3
ayda бетер хезмәт cakcak-api         # kubectl delete svc cakcak-api
ayda күрсәт барысы -A                # kubectl get all -A
```

## Эчке әмерләр / Built-ins

| Әмер | Эш |
|---|---|
| `ayda ярдәм` / `help` | ярдәм / help |
| `ayda сүзлек` | бу сүзлек / this dictionary |
| `ayda версия` | версия / version |
| `ayda тукай` | Тукайдан бер шигырь / a Tukay verse |
| `ayda чәй` | чәй тәнәфесе графигы / tea schedule |
| `ayda сәлам` | сәлам! / hello |
