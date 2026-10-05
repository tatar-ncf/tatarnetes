# Релиз циклы / Release cycle — Татарнетес

*Татарча беренче, аннары инглизчә. / Tatar first, then English.*

## Татарча

Татарнетес — үзаллы проект түгел, ә **Kubernetes өстендәге милли кабык**.
Шуңа безнең релиз циклы турыдан-туры Kubernetes'ның **тотрыклы (stable)**
чыгарылышларына бәйле. Без яңа нәрсә уйлап тапмыйбыз — без тотрыклы апстримны
эзлибез, аны татарлаштырабыз, сынап карыйбыз һәм чыгарабыз.

### Версия схемасы

```
    v<АПСТРИМ>-tatar.<N>
    │  │        │
    │  │        └── татар патчы: тәрҗемә, түбәтәй, чәй тәнәфесе төзәтмәләре
    │  └────────── чын Kubernetes тотрыклы версиясе (мәс. 1.31.4)
    └───────────── тег префиксы
```

**Мисал:** `v1.31.4-tatar.2` — Kubernetes 1.31.4 нигезендә, икенче татар патчы.

### Принциплар

1. **Тотрыклы апстрим гына.** alpha / beta / rc версияләрне алмыйбыз —
   бары тик Kubernetes'ның рәсми тотрыклы патч-релизларын.
2. **N-1 сәясәте.** Kubernetes кебек, соңгы ике минор версияне саклыйбыз
   (мәс. 1.31.x һәм 1.30.x). Иске версияләр архивка күчә.
3. **Кабык — юка.** Татар катламы (`bin/`, `lib/`) апстримга бәйсез; апстрим
   яңарганда безгә күп үзгәреш кирәкми. Сүзлек (`lib/dictionary.sh`) апстрим
   `kubectl` фигыльләре үзгәргәндә генә карала.
4. **Семантик.** Татар катламындагы каршылыклы (breaking) үзгәрешләр
   `-tatar.<N>` санын түгел, ә аерым `MAJOR` тамгасын арттыра (кара: тамгалар).

### Каналлар

| Канал | Ни ул | Тег |
|---|---|---|
| `stable` | тотрыклы апстримга бәйле, көндәлек куллану өчен | `v1.31.4-tatar.1` |
| `edge` | апстрим яңа минорны чыгаргач, беренче татарлаштыру | `v1.32.0-tatar.0` |

### Процесс (адымлап)

1. **Күзәтү.** `.github/workflows/upstream-watch.yml` атна саен Kubernetes'ның
   иң соңгы тотрыклы релизын тикшерә. Яңасы чыкса — автоматик рәвештә tracking
   issue ача («Upstream Kubernetes vX.Y.Z available»).
2. **Татарлаштыру.** `blog/`… юк, `release/vX.Y.Z-tatar` тармагы ачыла;
   `lib/dictionary.sh` карала (яңа `kubectl` фигыльләре бармы), CHANGELOG языла.
3. **Сынау.** `.github/workflows/ci.yml` — shellcheck + smoke-тестлар.
4. **Тег.** `vX.Y.Z-tatar.N` тамгасы куела → `release.yml` GitHub Release ясый.
5. **Игълан.** Релиз ноталары ике телдә языла.

### Тамгалар / issue label'лары

- `upstream` — апстрим яңарту белән бәйле
- `tatar-layer` — тәрҗемә/бизәк/чәй катламы
- `breaking` — каршылыклы үзгәреш

### Хәзерге апстрим һәм туры килү

| | |
|---|---|
| Апстрим | Kubernetes **v1.37.1** (`.upstream-version`) |
| Киләсе тег | `v1.37.1-tatar.0` (edge: 1.37 минорының беренче татарлаштыруы) |
| Тикшерелгән kubectl | v1.37.1 (чын бинар белән сыналды) |
| Kubernetes кластеры | kubectl рәсми рәвештә apiserver'дан бер минорга кадәр аерыла ала: 1.36, 1.37, 1.38 |
| TatarOS | Talos v1.14.1 — эчендә Kubernetes 1.37 |

**v1.31.0 → v1.37.1: `ayda` өчен нәрсә үзгәрде**

- `kubectl exec <кузак> <әмер>` 1.35 версиясеннән эшләми — `--` мәҗбүри:
  `ayda кер <кузак> -- <әмер>`. Хата чыкса, `ayda` татарча киңәш бирә.
- `kuberc` (1.33) — яңа kubectl фигыле, үзгәрешсез үткәрелә.
- `rollback` һәм `apply-view-last-applied` сүзлектән алынды — kubectl'да андый
  фигыльләр юк.
- kubectl 1.37 плагинга үз юлын `KUBECTL_PATH` аша бирә; `kubectl ayda` шул
  kubectl'ны куллана.
- `kubectl explain --max-depth` (1.37) — `ayda аңлат` аша да эшли.

## English

Tatarnetes is not a standalone project — it is a **national wrapper over
Kubernetes**. Our release cycle therefore tracks Kubernetes **stable** releases
directly. We do not invent; we follow stable upstream, Tatarise it, test, ship.

### Version scheme

```
    v<UPSTREAM>-tatar.<N>
```
`v1.31.4-tatar.2` = based on Kubernetes 1.31.4, second Tatar patch.

### Principles

1. **Stable upstream only** — no alpha/beta/rc, only official Kubernetes stable
   patch releases.
2. **N-1 policy** — like Kubernetes, we maintain the two most recent minors.
3. **Thin shell** — the Tatar layer (`bin/`, `lib/`) is upstream-independent;
   the dictionary is revisited only when upstream `kubectl` verbs change.
4. **Semantics** — breaking changes in the Tatar layer bump a separate `MAJOR`
   marker, not the `-tatar.<N>` counter.

### Channels

| Channel | Meaning | Tag |
|---|---|---|
| `stable` | pinned to stable upstream, for daily use | `v1.31.4-tatar.1` |
| `edge` | first Tatarisation of a fresh upstream minor | `v1.32.0-tatar.0` |

### Process

1. **Watch** — `upstream-watch.yml` checks the latest Kubernetes stable weekly and
   opens a tracking issue when a new one appears.
2. **Tatarise** — branch `release/vX.Y.Z-tatar`; revisit the dictionary; write the
   changelog.
3. **Test** — `ci.yml` runs shellcheck + smoke tests.
4. **Tag** — pushing `vX.Y.Z-tatar.N` triggers `release.yml` → a GitHub Release.
5. **Announce** — bilingual release notes.

### Current upstream and compatibility

| | |
|---|---|
| Upstream | Kubernetes **v1.37.1** (`.upstream-version`) |
| Next tag | `v1.37.1-tatar.0` (edge: first Tatarisation of the 1.37 minor) |
| Verified kubectl | v1.37.1 (checked against the real binary) |
| Clusters | kubectl's official skew is one minor either way: 1.36, 1.37, 1.38 |
| TatarOS | Talos v1.14.1 — ships Kubernetes 1.37 |

**v1.31.0 → v1.37.1: what changed for `ayda`**

- Since 1.35 `kubectl exec <pod> <cmd>` is rejected; `--` is required:
  `ayda кер <pod> -- <cmd>`. `ayda` adds a Tatar hint when this happens.
- `kuberc` (1.33) is a new kubectl verb and is passed through.
- `rollback` and `apply-view-last-applied` were removed from the dictionary —
  kubectl has no such top-level commands.
- kubectl 1.37 exports `KUBECTL_PATH` to plugins; `kubectl ayda` uses it.
- `kubectl explain --max-depth` (1.37) also works through `ayda аңлат`.

---

> Бер үк принцип **tataros** (Talos'ка бәйле) һәм **tatarnetes-ui** (Kubernetes
> Dashboard'ка бәйле) өчен дә кулланыла. The same policy applies to `tataros`
> (tracks Talos) and `tatarnetes-ui` (tracks Kubernetes Dashboard).
