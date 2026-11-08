#!/bin/bash

set -euo pipefail

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin"

FLUTTER="/opt/homebrew/bin/flutter"
IPA_DIR="build/ios/ipa"
ARCHIVE="build/ios/archive/Runner.xcarchive"

echo "Flutter: $("$FLUTTER" --version | head -n 1)"
echo "CocoaPods: $(pod --version)"
echo "rsync usato: $(command -v rsync)"
echo "Versione rsync:"
rsync --version | head -n 2

echo
echo "Rimuovo i vecchi artefatti IPA..."
rm -rf "$IPA_DIR"

echo "Avvio build IPA..."
"$FLUTTER" build ipa --release

echo
if [[ ! -d "$IPA_DIR" ]]; then
  echo "ERRORE: l'archive è stato creato, ma la cartella IPA non esiste."
  echo
  echo "Apri l'archive in Xcode con:"
  echo "open \"$ARCHIVE\""
  exit 1
fi

IPA_FILE="$(find "$IPA_DIR" -maxdepth 1 -type f -name '*.ipa' -print -quit)"

if [[ -z "$IPA_FILE" ]]; then
  echo "ERRORE: l'archive è stato creato, ma non è stato generato alcun IPA."
  echo
  echo "Apri l'archive in Xcode con:"
  echo "open \"$ARCHIVE\""
  exit 1
fi

echo "Build IPA completata:"
ls -Flarth "$IPA_DIR"

echo
echo "IPA generato: $IPA_FILE"
open "$IPA_DIR"
