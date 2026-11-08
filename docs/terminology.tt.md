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
| **сәламәтлек тикшерүе** | кузак исәнме-түгелме тикшерү | health/liveness probe |
| **әзерлек тикшерүе** | кузак хезмәткә әзерме | readiness probe |
| **үлчәм үзгәртү** | реплика санын арттыру/киметү | scaling |
| **үзидарә үлчәү** | йөккә карап автомат үлчәм | autoscaling |
| **яңарту җәю** | иске кузакларны акрынлап яңага күчерү | rolling update |
| **кире кайтару** | алдагы версиягә кайту | rollback |
| **бүленеш** | төркем икегә аерылу (куркыныч) | split-brain |
| **сайлау** | лидер төенне сайлау | leader election |

## Headlamp менюсы / Headlamp menu

*Яңа тәкъдимнәр: Headlamp 0.46 менюсын
([tatarnetes-ui](https://github.com/tatar-ncf/tatarnetes-ui) плагины) тәрҗемә
иткәндә барлыкка килде. Бу өлкәдә урнашкан татар терминнары юк; югарыдагы
кагыйдәләр буенча төзелде: мәгънәле татар сүзе булса — тәрҗемә (*сыйныф* —
class, *сәясәт* — policy, *калып* — template), юк икән — татар телендә инде
кулланыла торган халыкара сүз (*шлюз*, *маршрут*, *роль*, *аренда*). Барысы
да бәхәсле, носителләр һәм белгечләр төзәтмәсен көтә. «төркем» cluster өчен
алынган, шуңа PodGroup — **кузак берләшмәсе**.*

*New proposals, made while translating the Headlamp 0.46 menu (the
tatarnetes-ui plugin). There are no established Tatar terms for these; they
follow the rules above — a meaningful Tatar word where one fits, otherwise an
international word already used in Tatar. All are open to correction.*

| Татарча | Мәгънә / motivation | English | Тип |
|---|---|---|---|
| **эш җыелмасы** | бергә идарә ителгән эшләр җыелмасы | jobset | тәрҗемә |
| **җитәкче-эшче җыелмасы** | бер җитәкче һәм эшче кузаклар төркеме | leaderworkerset | тәрҗемә |
| **сыйныф** | бер төрдәге объектлар өчен үрнәк-класс | class | тәрҗемә |
| **саклагыч сыйныфы** | күләмнәр нинди саклагычтан бирелә | storageclass | тәрҗемә |
| **күләм үзлекләре сыйныфы** | күләмнең үзгәртелә торган үзлекләре (тизлек һ.б.) | volumeattributesclass | тәрҗемә |
| **ахыргы нокта** | хезмәт артындагы кузак адресы | endpoints | тәрҗемә |
| **ахыргы нокта кисәге** | ахыргы нокталар исемлегенең бер кисәге | endpointslice | тәрҗемә |
| **капка сыйныфы** | капканы кайсы контроллер хезмәт итә | ingressclass | тәрҗемә |
| **порт юнәлтү** | җирле портны кузак портына юнәлтү | port-forward | тәрҗемә |
| **челтәр сәясәте** | кузаклар арасында кемгә кем белән сөйләшергә ярый | networkpolicy | тәрҗемә |
| **шлюз** | Gateway API кереме; «капка» ingress өчен алынган | gateway | үзләштерү |
| **шлюз сыйныфы** | шлюзны кайсы контроллер хезмәт итә | gatewayclass | үзләштерү |
| **маршрут** | соратуны хезмәткә илтүче кагыйдә (HTTP, GRPC, TCP, UDP) | httproute / grpcroute / tcproute / udproute | үзләштерү |
| **сылтама рөхсәте** | башка мәйдандагы объектка сылтарга рөхсәт | referencegrant | тәрҗемә |
| **арткы як** | соратуны чынлап хезмәт итүче (backend) | backend | тәрҗемә |
| **хезмәт хисабы** | кузак яки программа өчен хисап язмасы | serviceaccount | тәрҗемә |
| **роль** | хокуклар җыелмасы | role | үзләштерү |
| **роль бәйләнеше** | рольне кулланучыга яки хезмәт хисабына бәйләү | rolebinding | тәрҗемә |
| **горизонталь үлчәү** | кузаклар санын йөккә карап үзгәртү (HPA) | horizontalpodautoscaler | үзләштерү |
| **вертикаль үлчәү** | кузакның ресурсларын йөккә карап үзгәртү (VPA) | verticalpodautoscaler | үзләштерү |
| **өзелү чиге** | бер юлы ничә кузакны туктатырга ярый (PDB) | poddisruptionbudget | тәрҗемә |
| **ресурс өлеше** | мәйданга бирелгән ресурс квотасы | resourcequota | тәрҗемә |
| **чик аралыгы** | савыт ресурсларының иң аз һәм иң күп чикләре | limitrange | тәрҗемә |
| **өстенлек сыйныфы** | кузакның чиратта өстенлеге | priorityclass | тәрҗемә |
| **башкару сыйныфы** | савытларны нинди мохиттә башкарырга | runtimeclass | тәрҗемә |
| **аренда** | вакытлыча биләү хокукы (лидер сайлау, йөрәк тибеше) | lease | үзләштерү |
| **вебхук** | API-сервер чакыра торган тышкы тикшерүче/үзгәртүче | webhook | үзләштерү |
| **җайланма** | төендәге җиһаз (GPU һ.б.), DRA аша бүленә | device | тәрҗемә |
| **ресурс таләбе** | кузакның җайланмага таләбе | resourceclaim | тәрҗемә |
| **калып** | шуннан яңа объектлар ясала торган үрнәк | template | тәрҗемә |
| **кузак берләшмәсе** | бергә бүленергә тиешле кузаклар | podgroup | тәрҗемә |
| **махсус ресурс** | кулланучы өстәгән ресурс төре (CRD) | customresource | тәрҗемә |
| **нөсхә** | ресурс төренең бер объекты | instance | тәрҗемә |

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
are welcome via pull request. The "Headlamp menu" section holds the terms first
proposed for the Headlamp plugin's menu (gateway, role, storage class, ...). It aims to be a genuine contribution to Tatar-language
IT terminology, which currently barely exists for this domain.
