#!/bin/sh
# Prove the installable library, the way a visitor uses it.
#
#  1. installs library/ into the Processing sketchbook's libraries/ folder (an existing
#     BitMapMathLib is moved aside for the run and put back afterwards),
#  2. builds every example in library/examples with the Processing command line,
#  3. builds AND runs tools/probe/probe.pde, which calls every group of the reference and then exits,
#     and checks the lines it printed.
#
# Usage: sh tools/verify_library.sh [path-to-Processing-cli]
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PROC=${1:-/Applications/Processing.app/Contents/MacOS/Processing}
[ -x "$PROC" ] || { echo "Processing CLI not found; pass it as the first argument"; exit 2; }
[ -d "$ROOT/library/library" ] || { echo "no library/ tree: run sh tools/build_library.sh first"; exit 2; }

SKETCHBOOK=${PROCESSING_SKETCHBOOK:-"$HOME/Documents/Processing"}
LIBS="$SKETCHBOOK/libraries"
[ -d "$LIBS" ] || { echo "no libraries folder at $LIBS (set PROCESSING_SKETCHBOOK)"; exit 2; }

TARGET="$LIBS/BitMapMathLib"
BACKUP=""
if [ -e "$TARGET" ]; then
  BACKUP=$(mktemp -d)/BitMapMathLib
  mv "$TARGET" "$BACKUP"
  echo "note: an existing $TARGET was moved aside for the run"
fi

WORK=$(mktemp -d)
cleanup() {
  rm -rf "$TARGET" "$WORK"
  [ -n "$BACKUP" ] && mv "$BACKUP" "$TARGET"
  return 0
}
trap cleanup EXIT

mkdir -p "$TARGET"
cp -R "$ROOT/library/." "$TARGET/"
echo "installed : $TARGET"

fail=0
for dir in "$ROOT"/library/examples/*/; do
  name=$(basename "$dir")
  sketch="$WORK/$name"
  mkdir -p "$sketch"
  cp "$dir$name.pde" "$sketch/$name.pde"
  if "$PROC" cli --sketch="$sketch" --output="$sketch/out" --force --build >"$WORK/$name.log" 2>&1; then
    echo "build ok  $name"
  else
    echo "build FAIL  $name"
    sed 's/^/      /' "$WORK/$name.log"
    fail=1
  fi
done

mkdir -p "$WORK/probe"
cp "$ROOT/tools/probe/probe.pde" "$WORK/probe/probe.pde"
if "$PROC" cli --sketch="$WORK/probe" --output="$WORK/probe/out" --force --run >"$WORK/probe.log" 2>&1; then
  grep '^PROBE' "$WORK/probe.log" | sed 's/^/run  /'
  grep -q '^PROBE ok$' "$WORK/probe.log" \
    && grep -q 'PROBE callbacks fy=true fr=true shade=true nope=false' "$WORK/probe.log" \
    || { echo "run FAIL  the probe did not finish as expected"; fail=1; }
else
  echo "run FAIL  the probe did not run"
  sed 's/^/      /' "$WORK/probe.log"
  fail=1
fi

[ "$fail" = 0 ] && echo "every example builds and the installed library runs" \
                || { echo "library verification failed"; exit 1; }