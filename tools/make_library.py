#!/usr/bin/env python3
"""Write library.properties and the library edition of the examples.

The library examples are the drop-in ones with three lines added, so the two editions cannot drift:
`examples/<name>/<name>.pde` stays the single source, and this derives
`library/examples/<name>/<name>.pde` from it - the imports, the BMML field, and the constructor
call that hands the sketch over.

Run:  python3 tools/make_library.py     (after make_java.py; build_library.sh runs both)
"""

import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
EXAMPLES = ROOT / "examples"
OUT = ROOT / "library"

# `version` is read with Integer.parseInt, so it is a whole number: "1.0.0" or even "1.0" makes
# Processing print "The version number ... is not a number", drop the library, and then report every
# one of its classes as "not visible". `prettyVersion` is what people see, and is free.
VERSION = "1"
PRETTY_VERSION = "1.0.0"

PROPERTIES = f"""# Processing library descriptor. BitMapMathLib has no PApplet subclass to install, so it needs no
# `core=` line: the jar is plain classes, and a sketch makes one with `new BMML(this)`.
name=BitMapMathLib
authors=MoonFingerRF
url=https://github.com/MoonFingerRF/BitMapMathLib
categories=Math
sentence=A small 1-bit drawing library: patterns and shading, fractals, L-systems, Voronoi, cells.
paragraph=BitMapMathLib is the drawing mathematics behind the Nostalgia art pieces, on a 240 x 128 canvas of one bit per pixel: threshold patterns and dithering, escape-time fractals, IFS point clouds and strange attractors, cellular automata and Game of Life, L-systems and space-filling curves, Voronoi and Delaunay, circle packing and Truchet tiles, and text as an image. Every function draws with the current stroke and fill, exactly as Processing does. The reference is in reference/BMML-reference.txt.
version={VERSION}
prettyVersion={PRETTY_VERSION}
license=MIT
"""

HEADER = """// {name} - the library edition of this example.
// Installed BitMapMathLib (Sketch > Import Library... > Add Library, then restart Processing).
// The drop-in edition in the repository does the same thing without the imports: see README.md.

import bmml.*;
import static bmml.BMML.*;

BMML bmml;

"""


def library_edition(text, name):
    """The drop-in example with the imports, the BMML field and the constructor call added."""
    if "BMML bmml;" in text:
        return text
    body = HEADER.format(name=name) + text
    # the constructor has to be the first thing setup() does
    m = re.search(r"(void setup\(\)\s*\{\n)", body)
    if not m:
        sys.exit(f"{name}: no setup() to put the BMML constructor in")
    return body[:m.end()] + "  bmml = new BMML(this);\n" + body[m.end():]


def main():
    (OUT / "library").mkdir(parents=True, exist_ok=True)
    (OUT / "library.properties").write_text(PROPERTIES)

    # generated, so a renamed or dropped example must not leave its old copy behind - a stale
    # example is still an example to verify_library.sh, and it fails there for no visible reason
    examples = OUT / "examples"
    if examples.exists():
        shutil.rmtree(examples)

    count = 0
    for sketch in sorted(EXAMPLES.glob("*/*.pde")):
        name = sketch.stem
        # Processing builds a sketch in a folder named after it, and a folder whose name is not a
        # Java identifier (a leading digit, say) makes the command line die with an
        # ArrayIndexOutOfBoundsException from Sketch.getMainName, with nothing to say why.
        if not re.match(r"^[A-Za-z_]\w*$", name):
            sys.exit(f"{sketch}: {name!r} is not a valid sketch name, so Processing cannot build it")
        text = sketch.read_text()
        if "void draw()" not in text or "void setup()" not in text:
            sys.exit(f"{sketch} needs both setup() and draw() to be an example")
        target = OUT / "examples" / name / f"{name}.pde"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(library_edition(text, name))
        count += 1
    print(f"wrote {OUT}/library.properties and {count} library examples")


if __name__ == "__main__":
    main()