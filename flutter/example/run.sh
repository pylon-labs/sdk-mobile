#!/bin/bash
# Runs the demo with the values from .env passed through as --dart-define.
#
#   cp env.example .env    # then edit .env
#   ./run.sh               # any extra args go to `flutter run`, e.g. -d <device>

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ ! -f .env ]; then
  echo "No .env found. Copy env.example to .env and add your app ID:"
  echo "  cp env.example .env"
  exit 1
fi

defines=()
while IFS= read -r line || [ -n "$line" ]; do
  # Skip blanks and comments.
  [[ -z "${line// }" || "$line" == \#* ]] && continue
  defines+=("--dart-define=${line}")
done < .env

exec flutter run "${defines[@]}" "$@"
