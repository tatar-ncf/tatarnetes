# Корпус чыганаклары һәм тикшерү / corpus sources & verification

Бу проектта китерелгән барлык шигырь юллары чыганаклар буенча тикшерелде.
All poetry lines in this project were verified against sources (Sept 2026).
Носителеләр һәм әдәбиятчылар өстәмә тикшерүен PR аша көтәбез.

## Тикшерелгән / Verified (`data/poetry.tt`)

| Автор | Әсәр | Чыганак | Ышаныч |
|---|---|---|---|
| Габдулла Тукай | «Туган тел» (1–3 строфа) | gabdullatukay.ru/works/poem/1909/tugan-tel/ | ✅ югары |
| Габдулла Тукай | «Туган авыл» (баш юл) | tatarica.org; kitaphane.tatarstan.ru | ✅ югары |
| Дәрдмәнд | «Кораб» | milliard.tatar; tatarica.org | ✅ югары |
| Муса Җәлил | «Җырларым» (Моабит) | kitap.net.ru/moabit.php; tatarica.org | ✅ югары |
| Муса Җәлил | «Җырлап үтәм» (Моабит) | Моабит дәфтәре | ✅ югары |
| Сибгат Хәким | «Бу кырлар, бу үзәннәрдә» | erlar.ru/node/737 | ✅ югары |

> Искәрмә: «Туган тел»нең 4нче (дога) строфасы корпуска кертелмәде — юмористик
> контекстта дини юлларны очраклы «гарнир» итеп чыгару хөрмәтсезлек булмасын өчен.
> Note: the prayer stanza of «Туган тел» is intentionally omitted from the random
> pool — a reverent prayer should not surface as a joke garnish.

## Мәкальләр / Proverbs (`data/proverbs.tt`)

Чыганак: Нәкый Исәнбәт, «Татар халык мәкальләре» (kitap.net.ru/poslov.php),
milliard.tatar подборкасы. Барысы да киң таралган, классик формалар. ✅

## Тикшерелергә тиеш / Pending verification (TODO)

- Тукай «Пар ат» — икенче юлда бәхәсле вариантлар булганга, хәзергә кертелмәде
  (баш юл дөрес, дәвамы басма буенча ачыкланырга тиеш).

Яңа авторлар/юллар өстәү — теләсә кем PR аша. Adding poets/verses — PRs welcome.

## Ничек өстәргә / How to contribute a verse

1. `data/poetry.tt`гә яңа язма өстә (ике процент билгесе аергыч буларак).
2. Соңгы юлда авторлык: `— Автор, «Әсәр»`.
3. Бу файлга чыганак һәм ышаныч дәрәҗәсен яз.
4. PR ач. Рәхмәт! / Open a PR. Thank you!

## Бәйрәм даталары / Holiday dates (`data/holidays.tt`)

Бары рәсми чыганаклар / official sources only: the decree of the Rais of
Tatarstan for Uraza and Qorban (pravo.tatarstan.ru, rais.tatarstan.ru), and
tatarstan.ru or the Kazan city administration for the Kazan Sabantuy. Dates
announced earlier (Spiritual Administration of Muslims, Ministry of Labour
calendars) are preliminary and are not added.

| Ел | Бәйрәм | Дата | Чыганак | Халәт |
|---|---|---|---|---|
| 2026 | Ураза / Uraza | 2026-03-20 | Указ Раиса РТ от 17.01.2026 N 17, pravo.tatarstan.ru/president/ukaz.htm/?npa_id=1776529 | ✅ |
| 2026 | Корбан / Qorban | 2026-05-27 | шул ук указ / same decree | ✅ |
| 2026 | Сабантуй (Казан) | 2026-06-20 | Kazan Sabantuy 2026 | ✅ |
| 2027 | Ураза, Корбан | — | Rais decree for 2027 not published as of 2026-11-09 (the 2026 one was signed in January). Preliminary: 2027-03-09 and 2027-05-16 (Spiritual Administration of Muslims of Tatarstan, via the Ministry of Labour's 2027 calendar, Oct 2026) — not added | ⏳ |
| 2027 | Сабантуй (Казан) | — | not announced as of 2026-11-09 | ⏳ |

`.github/workflows/holidays-watch.yml` opens an issue when a year (or, from
December, the next one) has no verified dates.

