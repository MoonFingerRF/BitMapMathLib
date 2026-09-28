#!/bin/sh
# Build the installable Processing library: the jar, the library tree, and the zip.
#
#   library/                     the tree as it is installed (Sketch > Import Library)
#     library.properties
#     library/BitMapMathLib.jar
#     examples/                  the same examples as examples/, with `import bmml.*;`
#     reference/BMML-reference.txt
#     README.md, LICENSE
#   dist/BitMapMathLib.zip       the whole tree, for the Releases page
#
# The jar is compiled against Processing's own core.jar, so the class files match the Processing
# that is installed here. Usage: sh tools/build_library.sh [path-to-core.jar]
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CORE=${1:-}
if [ -z "$CORE" ]; then
  for candidate in /Applications/Processing.app/Contents/app/core-4*.jar \
                   "$HOME"/Applications/Processing.app/Contents/app/core-4*.jar; do
    [ -f "$candidate" ] && CORE=$candidate && break
  done
fi
[ -n "$CORE" ] && [ -f "$CORE" ] || { echo "Processing core.jar not found; pass it as the first argument"; exit 2; }

JAVAC=$(command -v javac)
for candidate in /opt/homebrew/opt/openjdk@17/bin/javac /usr/local/opt/openjdk@17/bin/javac; do
  [ -x "$candidate" ] && JAVAC=$candidate && break
done
[ -n "$JAVAC" ] || { echo "javac not found"; exit 2; }

echo "core.jar : $CORE"
echo "javac    : $JAVAC ($("$JAVAC" -version 2>&1))"

python3 "$ROOT/tools/make_java.py"
python3 "$ROOT/tools/make_library.py"

BUILD="$ROOT/build/classes"
rm -rf "$ROOT/build" "$ROOT/library/library"   # make_library.py clears library/examples itself
mkdir -p "$BUILD"
"$JAVAC" -nowarn -cp "$CORE" -d "$BUILD" "$ROOT"/src/bmml/*.java

# A zip stores each file's mtime, and `jar` stamps the directory entries with the time of the run, so
# `jar cf` gives a different 21 KB every build and the committed jar churns for nothing. Every file
# is dated 1980-01-01 (the earliest a zip can hold) and the jar is written with `zip -X -D` - no
# directory entries, no extra attributes - which is the same jar every time. `zip` comes with macOS
# and every Linux; without it the build still works, it just is not reproducible.
find "$BUILD" -exec touch -t 198001010000 {} +

# the reference has to say the same thing in both places
mkdir -p "$ROOT/library/library" "$ROOT/library/reference"
cp "$ROOT/reference/BMML-reference.txt" "$ROOT/library/reference/"
cp "$ROOT/README.md" "$ROOT/LICENSE" "$ROOT/library/"

JAR_TOOL=$(dirname "$JAVAC")/jar
mkdir -p "$BUILD/META-INF"
printf 'Manifest-Version: 1.0\r\nImplementation-Title: BitMapMathLib\r\nImplementation-Version: 1.0.0\r\n\r\n' \
  > "$BUILD/META-INF/MANIFEST.MF"
touch -t 198001010000 "$BUILD/META-INF/MANIFEST.MF"

if command -v zip >/dev/null 2>&1; then
  # the manifest first, as a jar must have it, then the classes; -D drops the directory entries,
  # which are the only part `jar` timestamps with the time of the run
  ( cd "$BUILD" && zip -q -X -D "$ROOT/library/library/BitMapMathLib.jar" META-INF/MANIFEST.MF bmml/*.class )
else
  "$JAR_TOOL" cf "$ROOT/library/library/BitMapMathLib.jar" -C "$BUILD" .
fi

rm -rf "$ROOT/dist"
mkdir -p "$ROOT/dist/BitMapMathLib"
cp -R "$ROOT/library/." "$ROOT/dist/BitMapMathLib/"
( cd "$ROOT/dist" && "$JAR_TOOL" cfM BitMapMathLib.zip BitMapMathLib )

echo "jar      : $(wc -c < "$ROOT/library/library/BitMapMathLib.jar") bytes, $(ls "$BUILD"/bmml | wc -l | tr -d ' ') classes"
echo "zip      : $ROOT/dist/BitMapMathLib.zip ($(wc -c < "$ROOT/dist/BitMapMathLib.zip") bytes)"
echo "install  : unzip dist/BitMapMathLib.zip into your Processing sketchbook's libraries/ folder"
echo "verify   : sh tools/verify_library.sh"