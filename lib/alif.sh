# shellcheck shell=bash
# alif.sh — Язу тәртипләре / Tatar writing systems.
#   AYDA_ALIF=cyrl  — кирилл (гадәти) / Cyrillic (default)
#   AYDA_ALIF=latin — Яңалиф/Заманәлиф (латин 1927–39 / хәзерге латин)
#   AYDA_ALIF=arab  — Яңа имля (татар гарәп язуы, 1920нче еллар; фонематик)
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

# --- Кирилл → Гарәп (Яңа имля, 1920нче еллар) ----------------------------
# Фонематик татар гарәп язуы: һәр авазга — аерым хәреф (кыска сузыклар да языла).
# Phonemic Tatar Arabic (Yaña imlâ): every sound a distinct letter, all vowels
# written. Front/back pairs use distinct letters (о ۇ / ө ۆ, у و / ү ۈ).
# Логик тәртиптә чыгарыла — RTL һәм хәреф тоташуын терминал үзе башкара.
# Emitted in logical order; the terminal handles RTL + shaping (bidi).
# Сүз башындагы сузыкка ташучы hamza (ئ) awk аша өстәлә (byte-safe).
cyrl_to_arab() {
  # 1) Сүз башы сузыкларына ئ ташучысын өстәү (whitespace буенча, byte-safe).
  awk '{
    n = split($0, a, / /); o = ""
    for (i = 1; i <= n; i++) {
      w = a[i]
      if (w ~ /^(а|ә|о|ө|у|ү|ы|и|э|е|я|ю|ё|А|Ә|О|Ө|У|Ү|Ы|И|Э|Е|Я|Ю|Ё)/) w = "ئ" w
      o = o (i > 1 ? " " : "") w
    }
    print o
  }' \
  | sed -e 's/Къ/ق/g; s/къ/ق/g; s/Гъ/غ/g; s/гъ/غ/g' \
        -e 's/я/یا/g; s/Я/یا/g; s/ю/یو/g; s/Ю/یو/g; s/ё/یو/g; s/Ё/یو/g' \
        -e 's/щ/شچ/g; s/Щ/شچ/g; s/ц/تس/g; s/Ц/تس/g' \
        -e 's/а/ا/g;  s/А/ا/g;  s/ә/ە/g;  s/Ә/ە/g' \
        -e 's/б/ب/g;  s/Б/ب/g;  s/в/و/g;  s/В/و/g;  s/г/گ/g;  s/Г/گ/g' \
        -e 's/д/د/g;  s/Д/د/g;  s/е/ې/g;  s/Е/ې/g;  s/ж/ژ/g;  s/Ж/ژ/g' \
        -e 's/җ/ج/g;  s/Җ/ج/g;  s/з/ز/g;  s/З/ز/g;  s/и/ی/g;  s/И/ی/g' \
        -e 's/й/ی/g;  s/Й/ی/g;  s/к/ك/g;  s/К/ك/g;  s/л/ل/g;  s/Л/ل/g' \
        -e 's/м/م/g;  s/М/م/g;  s/н/ن/g;  s/Н/ن/g;  s/ң/ڭ/g;  s/Ң/ڭ/g' \
        -e 's/о/ۇ/g;  s/О/ۇ/g;  s/ө/ۆ/g;  s/Ө/ۆ/g;  s/п/پ/g;  s/П/پ/g' \
        -e 's/р/ر/g;  s/Р/ر/g;  s/с/س/g;  s/С/س/g;  s/т/ت/g;  s/Т/ت/g' \
        -e 's/у/و/g;  s/У/و/g;  s/ү/ۈ/g;  s/Ү/ۈ/g;  s/ф/ف/g;  s/Ф/ف/g' \
        -e 's/х/خ/g;  s/Х/خ/g;  s/һ/ھ/g;  s/Һ/ھ/g;  s/ч/چ/g;  s/Ч/چ/g' \
        -e 's/ш/ش/g;  s/Ш/ش/g;  s/ы/ى/g;  s/Ы/ى/g;  s/э/ې/g;  s/Э/ې/g' \
        -e 's/ъ//g;   s/Ъ//g;   s/ь//g;   s/Ь//g'
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
