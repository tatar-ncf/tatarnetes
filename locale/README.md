# Локализация / Localization

Татарнетес интерфейс юллары монда, **gettext `.po`** форматында. Кодны
үзгәртмичә, тәрҗемәне PR аша кертеп була.

Interface strings live here as **gettext `.po`** files. Translate without touching
code — just edit `.po` and open a PR.

## Ничек / How

1. `.po` файлында **`msgstr`** юлын гына үзгәрт (`msgid` — тотрыклы ачкыч, тимә).
   Edit only `msgstr` (never `msgid` — it's a stable key).
2. Каталогны яңадан җый / rebuild the runtime catalog:
   ```bash
   bash scripts/build-catalog.sh    # → lib/catalog.sh
   ```
3. Сына / test: `AYDA_LANG=<lang> ayda ярдәм`
4. PR ач / open a PR.

## Файллар / Files

| Файл | Тел / language |
|---|---|
| `tt.po` | Татар (кирилл) — каноник чыганак / canonical source |
| `en.po` | English |

Латин (`Яңалиф`) һәм гарәп язулары `tt.po`дан автоматик транслитерацияләнә
(`lib/alif.sh`) — аерым файл кирәкми. Latin and Arabic scripts are transliterated
automatically from `tt.po`; no separate files needed.

Яңа тел өстәү / adding a new language: `cp tt.po <lang>.po`, тәрҗемә ит, каталогны
җый. Рәхмәт! / Thank you!
