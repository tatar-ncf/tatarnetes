#!/usr/bin/env bash
# sync-shared.sh — уртак модульләрне tatarnetes'тан tataros'ка күчерә.
# tatarnetes — уртак кисәкләрнең КАНОНИК чыганагы. Sync shared engine to tataros.
# Куллану / usage:  bash scripts/sync-shared.sh [../tataros]
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
DST="${1:-$SRC/../tataros}"
[ -d "$DST" ] || { echo "tataros табылмады: $DST"; exit 1; }

# dictionary.sh — АЕРЫМ (talos ≠ kubectl); finops.sh — ayda гына. Күчермибез.
LIBS="render alif catalog i18n phrases teatime calendar errors faces"
for l in $LIBS; do cp "$SRC/lib/$l.sh" "$DST/lib/$l.sh"; done
mkdir -p "$DST/data" "$DST/locale" "$DST/scripts"
cp "$SRC"/data/*.tt "$SRC"/data/VERIFICATION.tt.md "$DST/data/"
cp "$SRC"/locale/*.po "$SRC"/locale/README.md      "$DST/locale/"
cp "$SRC"/scripts/build-catalog.sh                 "$DST/scripts/"
cp "$SRC/LICENSE" "$SRC/MANIFESTO.md" "$SRC/CODE_OF_CONDUCT.md" "$DST/"

echo "◆ Уртак модульләр tataros'ка күчерелде / shared engine synced → $DST"
echo "  Хәзер: cd $DST && bash scripts/build-catalog.sh && bash tests/unit.sh"
