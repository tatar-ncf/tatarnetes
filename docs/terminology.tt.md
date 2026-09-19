# Kubernetes терминологиясе татарча / Tatar glossary of Kubernetes terms

*Татарча беренче, аннары инглизчә. Бу — Татарнетес проектының милли терминология
тәкъдиме. Максат — көлке түгел, ә телне цифрлаштыруга керткән чын өлеш: болыт-
инфраструктура төшенчәләренә татарча, эчтәлеге ачык атамалар.*

*A Tatar-first glossary of cloud-native concepts — a serious attempt at national
IT terminology, not parody. Community feedback welcome via PR.*

> **Статус:** тәкъдим (draft). Носителеләр һәм белгечләр төзәтмәләрен PR аша көтәбез.
> Терминнар ике төркемгә бүленә: **тәрҗемә** (мәгънәле татар сүзе) һәм
> **үзләштерү** (халыкара термин кирилл язуда, тәрҗемәсе уңайсыз булганда).

## Асыл төшенчәләр / Core objects

| Татарча | Мәгънә / motivation | English | Тип |
|---|---|---|---|
| **кузак** | борчак кузагы — эчендә «бөртекләр» (савытлар) | pod | тәрҗемә |
| **савыт** | эчендә эш барган контейнер-савыт | container | тәрҗемә |
| **төен** | челтәр төене (узел) | node | тәрҗемә |
| **төркем** | төеннәр җыелмасы | cluster | тәрҗемә |
| **урнаштыру** | кушымтаны кластерга урнаштыру | deployment | тәрҗемә |
| **күчермә** | бертөрле кузаклар күчермәләре | replicaset | тәрҗемә |
| **тезмә** | тәртипле, хәлле кузаклар тезмәсе | statefulset | тәрҗемә |
| **көтү** | һәр төендә бер — «көтү» кебек | daemonset | тәрҗемә |
| **хезмәт** | кузакларга тотрыклы керү хезмәте | service | тәрҗемә |
| **капка** | тыштан эчкә керү капкасы | ingress | тәрҗемә |
| **мәйдан** | исемнәр мәйданы (аеру киңлеге) | namespace | тәрҗемә |
| **эш** | бер тапкыр үтәлә торган эш | job | тәрҗемә |
| **вакытлы эш** | билгеле вакытта кабатлана | cronjob | тәрҗемә |
| **сер** | яшерен мәгълүмат | secret | тәрҗемә |
| **көйләмә** | көйләү мәгълүматы (config) | configmap | тәрҗемә |
| **күләм** | даими саклагыч күләме | volume / persistentvolume | тәрҗемә |
| **таләп** | саклагычка таләп | persistentvolumeclaim | тәрҗемә |
| **тамга** | билге/этикет (сайлау өчен) | label | тәрҗемә |
| **искәрмә** | өстәмә мәгълүмат-искәрмә | annotation | тәрҗемә |

## Процесслар һәм механизмнар / Processes & mechanisms

| Татарча | Мәгълүмат | English |
|---|---|---|
| **тәңгәлләштерү** | асылны теләгән халәткә китерү (даими цикл) | reconciliation |
| **теләк халәте** | кулланучы теләгән халәт | desired state |
| **чын халәт** | кластердагы хәзерге халәт | actual/current state |
| **бүлүче** | кузакны кайсы төенгә куярга хәл итә | scheduler |
| **күзәтче** | асыл артыннан күзәтеп, тәңгәлләштерә | controller |
| **сакчы** | төендәге агент (кузакларны карый) | kubelet |
| **баш идарә** | кластерның идарә катламы | control plane |
| **сәламәтлек тикшүе** | кузак исәнме-түгелме тикшерү | health/liveness probe |
| **әзерлек тикшүе** | кузак хезмәткә әзерме | readiness probe |
| **үлчәм үзгәртү** | реплика санын арттыру/кимайту | scaling |
| **үзидарә үлчәү** | йөккә карап автомат үлчәм | autoscaling |
| **яңарту җәю** | иске кузакларны акрынлап яңага күчерү | rolling update |
| **кире кайтару** | алдагы версиягә кайту | rollback |
| **бүленеш** | төркем икегә аерылу (куркыныч) | split-brain |
| **сайлау** | лидер төенне сайлау | leader election |

## Мисаллар / Usage in Tatarnetes

```bash
ayda күрсәт кузаклар          # get pods
ayda күрсәт төеннәр           # get nodes
ayda сөйлә хезмәт web         # describe service web
ayda күпәйт урнаштыру web --replicas=3   # scale deployment
```

## English (summary)

This glossary proposes Tatar terminology for Kubernetes / cloud-native concepts.
Two kinds of entries: **translations** (a meaningful Tatar word, e.g. *кузак* “pea
pod” = pod, *капка* “gate” = ingress, *сер* “secret”, *тамга* “mark/tag” = label)
and **loanwords** (the international term in Cyrillic where a translation would be
forced). The list is a draft; corrections from native speakers and practitioners
are welcome via pull request. It aims to be a genuine contribution to Tatar-language
IT terminology, which currently barely exists for this domain.
