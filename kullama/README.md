# Куллама / Kullama

*Татарча беренче, аннары инглизчә. / Tatar first, then English.*

## Татарча

### Аш

Куллама — татар һәм башкорт ашы. Төп өлешләре — шулпада пешкән ит, салма
(камырдан ясалган кисәкләр) һәм кишер белән суган. Чыганакларда:

- 24СМИ язмасындагы рецептта ([«Суп с ароматом башкирских и татарских
  традиций»](https://24smi.org/news/378074-sup-s-aromatom-bashkirskikh-i-tatarskikh-traditsii.html),
  Сергей Васильев, 12.09.2024; рецепт «Повар.ру» порталыннан алынган) сыер ите
  белән йөрәге ике аерым казанда пешә; салма аерым тозлы суда, өскә калыкканчы
  пешә һәм эретелгән май белән аерым савытта болгатыла; суган белән кишер
  шулпаның бер өлешендә, май белән 20 минут бөрештерелә. Аннары ит
  кисәкләре, салма, калган шулпа һәм кишер-суган соусы бер табада кушыла,
  капкач астында 15 минут бөрештерелә; яшелчә сибеп бирелә. Салма монда
  «колакчык» рәвешендә.
- Sobaka.ru язмасында ([Уфа, 05.04.2019](https://www.sobaka.ru/ufa/bars/chtogdeest/88630))
  куллама — «башкирское и татарское национальное блюдо, которое готовится из
  жирного отварного мяса»; Уфадагы Gastro Gallery ресторанында ул сарык
  итеннән, кәбестә, кишер һәм суган белән куе шулпа, салма — нечкә ромб
  кисәкләр.

Ягъни рецептлар аерыла (ит төре, кәбестә, салманың рәвеше); без алардан
бер нәрсә генә алабыз: өлешләр аерым пешә, аннары бер савытта шулпа белән
кушыла.

### Метафора

Татарнетес кисәкләре дә аерым пешә, һәрберсенең үз версиясе бар:

| Кисәк | Репозиторий | Нәрсә |
|---|---|---|
| `ayda` | tatar-ncf/tatarnetes | милли kubectl |
| `tatarnetes-freeze` | tatar-ncf/tatarnetes | бәйрәмдә үзгәрешләрне тыю вебхугы |
| `tatarnetes-ui` | tatar-ncf/tatarnetes-ui | идарә панеле, Headlamp плагины |
| `tataros` | tatar-ncf/tataros | TatarOS Linux |
| `kuberoot` | kuberoot-dev/kuberoot | TatarOS нигезе (коммит) |

Ә савыт — [`recipe.yaml`](recipe.yaml): `kullama` исемле kubepkg мета-пакеты,
бергә эшли торган версияләр җыелмасы. Релиз тамгасы шушы савытка куела:
`spec.version` тамгадан «v»сыз (`v1.37.2-tatar.1` → `1.37.2-tatar.1`);
`release.yml` аларның тигезлеген тикшерә һәм `recipe.yaml`ны релизга беркетә.

- Кластердагы кисәк (тыю вебхугы) — `requires`та, kubepkg аны куя.
- Кластердан тыш кисәкләр — `kullama.tatar-ncf.github.io/*` искәрмәләрендә:
  `<кисәк>` — версия, `<кисәк>.repo` — репозиторий, `<кисәк>.upstream` —
  нигез (`репозиторий@версия`), upstream-watch шуны апстрим белән чагыштыра.

### `ayda куллама`

```bash
ayda куллама        # латинча: ayda kullama · гарәпчә: ayda كوللاما · инглизчә: ayda dish
```

Һәр кисәк өчен күрсәтә:

- **савытта** — `recipe.yaml`дагы версия;
- **урнашкан** — күренсә: `ayda` — үзе килгән савыт, тыю вебхугы — кластердагы
  образ тамгасы; калганнары күренми;
- **соңгы релиз** — GitHub'тан (`GITHUB_TOKEN` булса, шуның белән);
- **хөкем** — урнашканы савыттагыча яки аерыла;
- **артык пешкән** — нигезнең апстримында яңарак релиз чыккан (upstream-watch
  кебек: тамга тигез түгел).

Чыгу коды 1 — урнашкан кисәк савыттагыдан аерылса. Чәй вакытында савыт
күрсәтелә, кластерга гына сорау бирелми. `AYDA_KULLAMA_OFFLINE=1` — GitHub'ка
сорау юк; `AYDA_KULLAMA_FILE` — башка савыт.

### Бер кисәкне алмаштыру яки кире кайтару

Моны kubepkg эшли, `ayda` түгел:

```bash
kubepkg install kullama@1.37.2-tatar.1          # бөтен савыт
kubepkg plan tatarnetes-freeze@=1.37.1-tatar.0  # бер кисәкне алмаштырсаң, нәрсә үзгәрә
kubepkg rollback tatarnetes-freeze              # алдагы ревизиягә кайту
kubepkg history tatarnetes-freeze
```

Мета-пакет үз кисәгенә `=` чикләвен куя, шуңа кисәкне аның версиясеннән
читкә алмаштырсаң, kubepkg аны `kullama`ның канәгатьләнмәгән таләбе дип
күрсәтә; `ayda куллама` исә
кисәкне «савыттагыдан аерыла» дип күрсәтә. Кластердан тыш кисәкләр (ayda,
TatarOS, kuberoot, Headlamp плагины) үз юллары белән алмаштырыла: релиз
тарболы яки krew, TatarOS образы, Headlamp плагиннары папкасы.

## English

### The dish

Kullama is a Tatar and Bashkir dish: meat cooked in broth, salma (pieces of
dough) and carrot with onion. In the sources:

- A recipe on 24SMI (["Суп с ароматом башкирских и татарских
  традиций"](https://24smi.org/news/378074-sup-s-aromatom-bashkirskikh-i-tatarskikh-traditsii.html),
  Sergey Vasilyev, 12 September 2024, citing the Povar.ru portal): beef and
  beef heart are boiled in two separate pots; the salma is boiled on its own
  in salted water until it floats, then dressed with melted butter in a
  separate bowl; onion and carrot are stewed in part of the broth with butter
  for 20 minutes. Then the meat in pieces, the salma, the rest of the broth
  and the carrot-and-onion sauce go into one pan, covered, for 15 minutes;
  served with chopped herbs. The salma there is shaped like little ears.
- Sobaka.ru ([Ufa, 5 April 2019](https://www.sobaka.ru/ufa/bars/chtogdeest/88630)):
  kullama is "a Bashkir and Tatar national dish made of fatty boiled meat"; at
  Gastro Gallery in Ufa it is mutton in a rich broth with cabbage, carrot and
  onion, the salma cut into thin diamonds.

The recipes differ (the meat, cabbage or not, the shape of the salma); we
take one thing from them: the parts are cooked separately and then put
together in one pan with the broth.

### The metaphor

Tatarnetes' components are cooked separately too, each with its own version
(see the table above). The pan is [`recipe.yaml`](recipe.yaml): a kubepkg
meta package named `kullama`, the set of versions that work together. The
release tag goes on the dish: `spec.version` is the tag without its "v", and
`release.yml` checks they agree and attaches `recipe.yaml` to the release.

- The in-cluster ingredient, the change freeze, is a `requires` entry that
  kubepkg installs.
- The others are pinned in `kullama.tatar-ncf.github.io/*` annotations:
  `<name>` the version, `<name>.repo` the repository, `<name>.upstream` what
  it is built on (`repository@version`), the data upstream-watch compares
  with upstream.

### `ayda куллама`

`ayda куллама` (also `kullama`, `كوللاما`, and `dish`) prints, per
ingredient: the version in the dish; the installed one where visible (ayda's
own dish, the change freeze's image tag in the cluster); the latest GitHub
release (with `GITHUB_TOKEN` if set); whether the installed version matches;
and whether it is **overcooked**: its upstream has released something newer
than what it is built on (as upstream-watch decides: the tags differ). Exit
code 1 when an installed ingredient differs from the dish. During tea the
dish is still served, only the cluster is not asked. `AYDA_KULLAMA_OFFLINE=1`
skips GitHub; `AYDA_KULLAMA_FILE` reads another dish.

### Swapping or rolling back one ingredient

That is kubepkg's job, not ayda's: `kubepkg install kullama@<version>` for the
whole dish, `kubepkg plan tatarnetes-freeze@=<version>` to see what swapping
one would change, `kubepkg rollback tatarnetes-freeze` to go back a
revision, `kubepkg history tatarnetes-freeze`. The meta package pins its
ingredient with `=`, so after a swap away from it kubepkg reports an unmet
requirement of `kullama`, and `ayda куллама` reports the ingredient as differing from the dish.
Ingredients outside the cluster are swapped their own way: the release
tarball or krew, the TatarOS image, Headlamp's plugin directory.
