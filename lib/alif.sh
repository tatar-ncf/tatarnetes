# shellcheck shell=bash
# alif.sh — Язу тәртипләре / Tatar writing systems.
#   AYDA_ALIF=cyrl  — кирилл (гадәти) / Cyrillic (default)
#   AYDA_ALIF=latin — Яңалиф/Заманәлиф (латин 1927–39 / хәзерге латин)
#   AYDA_ALIF=arab  — Иске имля (гарәп язуы, бизәкле — шамаил стиле)
#
# Транслитерация — чыгарылыш өчен (cyrl→latin/arab) һәм керемне латиннан кире
# кирилга (latin→cyrl), клавиатурада кирилл булмаганнар өчен.
# Bash 3.2 + sed (UTF-8). Гарәп варианты — бизәкле, орфографик төгәл түгел.

# --- Кирилл → Латин (Заманәлиф) -----------------------------------------
cyrl_to_latin() {
  sed -e 's/Къ/Q/g; s/къ/q/g; s/Гъ/Ğ/g; s/гъ/ğ/g' \
      -e 's/Я/Ya/g; s/я/ya/g; s/Ю/Yu/g; s/ю/yu/g; s/Ё/Yo/g; s/ё/yo/g' \
      -e 's/Щ/Şç/g; s/щ/şç/g; s/Ц/Ts/g; s/ц/ts/g' \
      -e 's/А/A/g; s/а/a/g; s/Ә/Ä/g; s/ә/ä/g; s/Б/B/g; s/б/b/g' \
      -e 's/В/W/g; s/в/w/g; s/Г/G/g; s/г/g/g; s/Д/D/g; s/д/d/g' \
      -e 's/Е/E/g; s/е/e/g; s/Ж/J/g; s/ж/j/g; s/Җ/C/g; s/җ/c/g' \
      -e 's/З/Z/g; s/з/z/g; s/И/İ/g; s/и/i/g; s/Й/Y/g; s/й/y/g' \
      -e 's/К/K/g; s/к/k/g; s/Л/L/g; s/л/l/g; s/М/M/g; s/м/m/g' \
      -e 's/Н/N/g; s/н/n/g; s/Ң/Ñ/g; s/ң/ñ/g; s/О/O/g; s/о/o/g' \
      -e 's/Ө/Ö/g; s/ө/ö/g; s/П/P/g; s/п/p/g; s/Р/R/g; s/р/r/g' \
      -e 's/С/S/g; s/с/s/g; s/Т/T/g; s/т/t/g; s/У/U/g; s/у/u/g' \
      -e 's/Ү/Ü/g; s/ү/ü/g; s/Ф/F/g; s/ф/f/g; s/Х/X/g; s/х/x/g' \
      -e 's/Һ/H/g; s/һ/h/g; s/Ч/Ç/g; s/ч/ç/g; s/Ш/Ş/g; s/ш/ş/g' \
      -e 's/Ы/I/g; s/ы/ı/g; s/Э/E/g; s/э/e/g' \
      -e "s/Ъ//g; s/ъ//g; s/Ь//g; s/ь//g"
}

# --- Кирилл → Гарәп (Иске имля, бизәкле/якынча) --------------------------
cyrl_to_arab() {
  sed -e 's/Къ/ق/g; s/къ/ق/g; s/Гъ/غ/g; s/гъ/غ/g' \
      -e 's/[Яя]/يا/g; s/[Юю]/يو/g; s/[Ёё]/يو/g; s/[Щщ]/شچ/g; s/[Цц]/تس/g' \
      -e 's/[Аа]/ا/g; s/[Әә]/ٱ/g; s/[Бб]/ب/g; s/[Вв]/و/g; s/[Гг]/گ/g' \
      -e 's/[Дд]/د/g; s/[Ее]/ﻩ/g; s/[Жж]/ژ/g; s/[Җҗ]/ج/g; s/[Зз]/ز/g' \
      -e 's/[Ии]/ی/g; s/[Йй]/ي/g; s/[Кк]/ک/g; s/[Лл]/ل/g; s/[Мм]/م/g' \
      -e 's/[Нн]/ن/g; s/[Ңң]/ڭ/g; s/[Оо]/و/g; s/[Өө]/ۇ/g; s/[Пп]/پ/g' \
      -e 's/[Рр]/ر/g; s/[Сс]/س/g; s/[Тт]/ت/g; s/[Уу]/و/g; s/[Үү]/ۇ/g' \
      -e 's/[Фф]/ف/g; s/[Хх]/خ/g; s/[Һһ]/ه/g; s/[Чч]/چ/g; s/[Шш]/ش/g' \
      -e 's/[Ыы]/ی/g; s/[Ээ]/ﺍ/g' \
      -e 's/[Ъъ]//g; s/[Ьь]//g'
}

# --- Латин → Кирилл (керем өчен) / input transliteration ----------------
# Латинча язылган әмерне кирилга кайтара, аннары сүзлек таба.
latin_to_cyrl() {
  sed -e 's/Ya/Я/g; s/ya/я/g; s/Yu/Ю/g; s/yu/ю/g; s/Yo/Ё/g; s/yo/ё/g' \
      -e 's/Şç/Щ/g; s/şç/щ/g; s/Ts/Ц/g; s/ts/ц/g' \
      -e 's/ä/ә/g; s/Ä/Ә/g; s/ö/ө/g; s/Ö/Ө/g; s/ü/ү/g; s/Ü/Ү/g' \
      -e 's/ñ/ң/g; s/Ñ/Ң/g; s/ç/ч/g; s/Ç/Ч/g; s/ş/ш/g; s/Ş/Ш/g' \
      -e 's/ğ/гъ/g; s/Ğ/Гъ/g; s/q/къ/g; s/Q/Къ/g' \
      -e 's/c/җ/g; s/C/Җ/g; s/j/ж/g; s/J/Ж/g; s/x/х/g; s/X/Х/g' \
      -e 's/w/в/g; s/W/В/g' \
      -e 's/ı/ы/g; s/I/Ы/g; s/İ/И/g; s/i/и/g' \
      -e 's/a/а/g; s/A/А/g; s/b/б/g; s/B/Б/g; s/d/д/g; s/D/Д/g' \
      -e 's/e/е/g; s/E/Е/g; s/f/ф/g; s/F/Ф/g; s/g/г/g; s/G/Г/g' \
      -e 's/h/һ/g; s/H/Һ/g; s/k/к/g; s/K/К/g; s/l/л/g; s/L/Л/g' \
      -e 's/m/м/g; s/M/М/g; s/n/н/g; s/N/Н/g; s/o/о/g; s/O/О/g' \
      -e 's/p/п/g; s/P/П/g; s/r/р/g; s/R/Р/g; s/s/с/g; s/S/С/g' \
      -e 's/t/т/g; s/T/Т/g; s/u/у/g; s/U/У/g; s/y/й/g; s/Y/Й/g' \
      -e 's/z/з/g; s/Z/З/g'
}

# --- Чыгарылышны сайланган язуга күчерү / render to the chosen script ----
# Кабул итә: stdin. Тик татар (кирилл) тексты өчен. Инглиз режимда тими.
alif_render() {
  case "${AYDA_ALIF:-cyrl}" in
    latin) cyrl_to_latin ;;
    arab)  cyrl_to_arab ;;
    *)     cat ;;
  esac
}

# Керемне (әмер) кирилга нормальләштерү: латин булса — кире кирилга.
# Normalise a command token to Cyrillic if it was typed in Latin.
alif_normalize_in() {
  case "$1" in
    -*) printf '%s' "$1" ;;                         # флаг / flag — тимә
    *[а-яәөүҗңһА-ЯӘӨҮҖҢҺ]*) printf '%s' "$1" ;;   # инде кирилл / already Cyrillic
    *[a-zA-ZäöüñçşğıÄÖÜÑÇŞĞİ]*) printf '%s' "$1" | latin_to_cyrl ;;
    *) printf '%s' "$1" ;;                          # сан/флаг / number/flag
  esac
}
