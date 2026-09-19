# Архитектура / Architecture

*Татарча беренче, аннары инглизчә.*

## Татарча

Татарнетес — Kubernetes'ны яңадан язмый. Ул `kubectl` өстендәге **юка кабык**
(thin wrapper): татарча әмерне ала, `kubectl` теленә тәрҗемә итә, чакыра, һәм
җавапны милли бизәкләр белән төрә.

```
  кулланучы                 ayda (bash)                     kubectl
 ┌──────────┐   татарча   ┌──────────────────────────┐   ┌──────────┐
 │ ayda     │────────────▶│ 1. фигыльне тәрҗемә       │   │          │
 │ күрсәт   │             │    translate_verb()      │   │  чын     │
 │ кузаклар │             │ 2. асылны тәрҗемә        │──▶│ Kubernetes│
 │          │◀────────────│    translate_noun()      │   │  API     │
 └──────────┘  бизәкле    │ 3. чәй капкасы (tea gate)│   │          │
               җавап      │ 4. башкару + йөз/шигырь  │   └──────────┘
                          └──────────────────────────┘
```

### Кисәкләр / components

| Файл | Эш |
|---|---|
| `bin/ayda` | төп агым: тәрҗемә, башкару, бизәк / main flow |
| `lib/dictionary.sh` | фигыль һәм асыл сүзлеге (case-нигезле) |
| `lib/faces.sh` | түбәтәйле йөзләр (шат/ачулы/чәй) ASCII |
| `lib/phrases.sh` | шелтә, мактау, ризык, Тукай юллары |
| `lib/teatime.sh` | чәй тәнәфесе графигы (детерминистик) |
| `lib/render.sh` | төсләр, келәм бүлгече, тыныч режим |

### Чәй тәнәфесе / tea break

График — көнгә бәйле, детерминистик: `YYYYMMDD` нигезендә 3 тәрәзә исәпләнә.
Шуңа консоль (`lib/teatime.sh`) һәм браузер (`ui/app.js`) **бер үк** вакытны
күрсәтә. Тәнәфестә `ayda` кластерга кермичә чәй экранын чыгара (exit 42).
`AYDA_NO_TEA=1` — узып китә.

### Дизайн принциплары / design principles

- **Юка кабык** — Kubernetes'ны форк итеп йөкләми; чын `kubectl` эшли.
- **Торба-куркынычсыз** — бизәк `stderr`'га; `stdout` чиста (jq белән эшли).
- **Bash 3.2** — macOS'та эшли, assoc-массивларсыз, `case` аша.
- **Билгесез сүз — үзгәрешсез** — под исемнәре, флаг кыйммәтләре сакланá.

## English

Tatarnetes does not rewrite Kubernetes. It is a **thin wrapper** over `kubectl`:
it takes a Tatar command, translates it into `kubectl`, invokes it, and wraps the
response in national decorations.

**Components** — see the table above: `bin/ayda` orchestrates; `lib/*.sh` provide
the dictionary, faces, phrases, tea schedule, and rendering.

**Tea break** — the schedule is deterministic, derived from `YYYYMMDD`, so the CLI
(`lib/teatime.sh`) and the browser (`ui/app.js`) agree on the exact windows. During
tea, `ayda` shows the tea screen instead of reaching the cluster (exit code 42);
`AYDA_NO_TEA=1` bypasses it.

**Design principles** — thin wrapper (real `kubectl` under the hood); pipe-safe
(decorations to `stderr`, clean `stdout`); Bash 3.2 compatible (no associative
arrays, `case`-based translation); unknown tokens pass through unchanged so pod
names and flag values survive.
