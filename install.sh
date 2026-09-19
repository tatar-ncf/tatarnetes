#!/usr/bin/env bash
# install.sh — Татарнетесне урнаштыру / install the `ayda` CLI.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BIN_DIR="${AYDA_PREFIX:-$HOME/.local/bin}"

mkdir -p "$BIN_DIR"
ln -sf "$HERE/bin/ayda" "$BIN_DIR/ayda"

echo "◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆"
echo "  Татарнетес урнаштырылды! / Tatarnetes installed!"
echo "  → $BIN_DIR/ayda"
echo
case ":$PATH:" in
  *":$BIN_DIR:"*) : ;;
  *)
    echo "  PATH'ка өстә / add to PATH:"
    echo "    export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac
echo
echo "  Сынап кара / try it:   ayda ярдәм"
echo "◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆"
