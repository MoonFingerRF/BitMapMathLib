#!/bin/sh
# Build every drop-in example with the stock Processing command line.
#
# Processing wants the sketch folder named after the sketch, and BitMapMathLib.pde next to it as a
# second tab, so each example is assembled in a scratch folder rather than committed twice.
#
# Usage: sh tools/build_examples.sh [path-to-Processing-cli]
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PROC=${1:-/Applications/Processing.app/Contents/MacOS/Processing}
if [ -x "$PROC" ]; then :; else
  PROC=$(command -v processing || true)
fi
[ -n "$PROC" ] && [ -x "$PROC" ] || { echo "Processing CLI not found; pass it as the first argument"; exit 2; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
fail=0

for dir in "$ROOT"/examples/*/; do
  name=$(basename "$dir")
  # a folder name that is not a Java identifier makes Processing die inside Sketch.getMainName
  case "$name" in
    [A-Za-z_]*) ;;
    *) echo "FAIL  $name: not a valid sketch name (must start with a letter or _)"; fail=1; continue;;
  esac
  sketch="$WORK/$name"
  mkdir -p "$sketch"
  cp "$dir$name.pde" "$sketch/$name.pde"
  cp "$ROOT/BitMapMathLib.pde" "$sketch/BitMapMathLib.pde"
  rm -rf "$sketch/out"
  if "$PROC" cli --sketch="$sketch" --output="$sketch/out" --force --build >"$WORK/$name.log" 2>&1; then
    echo "ok    $name"
  else
    echo "FAIL  $name"
    sed 's/^/      /' "$WORK/$name.log"
    fail=1
  fi
done

[ "$fail" = 0 ] && echo "every example builds" || { echo "some examples did not build"; exit 1; }

# ...and one of them runs: a probe that calls every group of the reference and then exits, so the
# tests do not depend on anyone looking at a window.
mkdir -p "$WORK/probe_dropin"
cp "$ROOT/tools/probe_dropin/probe_dropin.pde" "$WORK/probe_dropin/probe_dropin.pde"
cp "$ROOT/BitMapMathLib.pde" "$WORK/probe_dropin/BitMapMathLib.pde"
if "$PROC" cli --sketch="$WORK/probe_dropin" --output="$WORK/probe_dropin/out" --force --run \
     >"$WORK/probe_dropin.log" 2>&1; then
  grep '^PROBE' "$WORK/probe_dropin.log" | sed 's/^/run  /'
  grep -q '^PROBE ok$' "$WORK/probe_dropin.log" \
    && grep -q 'PROBE callbacks fy=true fr=true shade=true nope=false' "$WORK/probe_dropin.log" \
    || { echo "run FAIL  the drop-in probe did not finish as expected"; exit 1; }
else
  echo "run FAIL  the drop-in probe did not run"
  sed 's/^/      /' "$WORK/probe_dropin.log"
  exit 1
fi
echo "and the drop-in edition runs"