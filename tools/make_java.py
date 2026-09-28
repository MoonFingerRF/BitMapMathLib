#!/usr/bin/env python3
"""BitMapMathLib.pde -> the Java sources of the installable Processing library.

The drop-in edition (BitMapMathLib.pde) is written for a sketch tab: its functions are global and
already have the sketch's PApplet in scope. A library jar has neither, so each name the library
borrows from Processing has to be routed through a PApplet that the sketch hands over once, in the
constructor:

    import bmml.*;
    BMML m = new BMML(this);          // and, for the bare function names:
    import static bmml.BMML.*;

The rewrite is mechanical and checked by javac against Processing's own core.jar (the build script),
so nothing is renamed and the public surface is the same list as the .pde edition:
top-level functions and constants become `public static` members of bmml.BMML, the classes of the
.pde become classes in the bmml package, and every Processing member they touch is reached through
BMML.p.

Run:  python3 tools/make_java.py        (writes src/bmml/*.java)
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PDE = ROOT / "BitMapMathLib.pde"
OUT = ROOT / "src" / "bmml"

# Members of processing.core.PApplet / PGraphics that are *instance* members (javap of
# Processing 4.5.2's core.jar). Anything here is only reachable through the sketch object.
INSTANCE_FALLBACK = {n.rstrip("?") for n in """
abs? ambient ambientLight applyMatrix arc background beginContour beginShape bezier bezierPoint
bezierTangent bezierVertex blendMode box brightness camera circle clear colorMode createFont
createGraphics createImage createShape createSurface curve curvePoint curveTightness curveVertex
directionalLight displayHeight displayWidth ellipse ellipseMode emissive endContour endShape fill
filter focused frameCount frameRate frustum get hint hour image imageMode key keyCode lights line
loadFont loadImage loadPixels loadShader loadShape loop mag millis mouseButton mousePressed
mouseX mouseY noClip noCursor noFill noLights noLoop noSmooth noStroke noTexture noTint normal
noise noiseDetail noiseSeed ortho perspective pixelDensity pixelHeight pixelWidth pixels point
pointLight pop popMatrix popStyle push pushMatrix pushStyle quad quadraticVertex random
randomGaussian randomSeed rect rectMode redraw resetMatrix resetShader rotate rotateX rotateY
rotateZ saturation scale screenX screenY set shader shape shearX shearY shininess smooth specular
sphere sphereDetail spotLight stroke strokeCap strokeJoin strokeWeight text textAlign textAscent
textDescent textFont textLeading textMode textSize textWidth texture triangle updatePixels vertex
width
""".split() if not n.endswith("?")}

BORROWED_CLASSES = {"PApplet", "PConstants", "PGraphics", "PImage", "PFont", "PVector"}


def processing_core():
    """Processing's core.jar, if this machine has Processing 4 installed."""
    import glob
    import os
    env = os.environ.get("PROCESSING_CORE")
    if env and pathlib.Path(env).exists():
        return pathlib.Path(env)
    for pat in ("/Applications/Processing.app/Contents/app/core-4*.jar",
                os.path.expanduser("~/Applications/Processing.app/Contents/app/core-4*.jar"),
                os.path.expanduser("~/Documents/Processing/core/library/core-4*.jar"),
                "/usr/share/processing/core.jar"):
        hits = sorted(glob.glob(pat))
        if hits:
            return pathlib.Path(hits[-1])
    return None


def instance_members():
    """The instance members of PApplet/PGraphics, read straight out of core.jar with javap.

    Falls back to the list above when Processing (or a JDK) is not installed - the build script
    compiles against the real core.jar anyway, so a wrong entry shows up as a compile error.
    """
    core = processing_core()
    javap = None
    for candidate in ("javap", "/opt/homebrew/opt/openjdk@17/bin/javap",
                      "/usr/libexec/java_home -v 17 --exec javap"):
        try:
            import subprocess
            subprocess.run(candidate.split() + ["-version"], capture_output=True, check=True)
            javap = candidate
            break
        except Exception:
            continue
    if core is None or javap is None:
        print("note: core.jar or javap not found, using the built-in member list")
        return set(INSTANCE_FALLBACK)
    import subprocess
    names = set()
    for cls in ("processing.core.PApplet", "processing.core.PGraphics"):
        try:
            out = subprocess.run(javap.split() + ["-cp", str(core), cls],
                                 capture_output=True, text=True, check=True).stdout
        except Exception as e:
            print(f"note: javap failed on {cls} ({e}), using the built-in member list")
            return set(INSTANCE_FALLBACK)
        for line in out.splitlines():
            s = line.strip()
            if s.startswith(("public ", "private ", "protected ")) and " static " not in s \
                    and not s.startswith(("public static", "private static", "protected static")):
                head = re.sub(r"[;=].*$", "", s.split("(")[0]).strip()
                name = head.split()[-1] if head else ""
                if name and name.isidentifier():
                    names.add(name)
    return names or set(INSTANCE_FALLBACK)


INSTANCE = instance_members()


def is_instance_member(name):
    return name in INSTANCE



def float_literals(text):
    """`1.5` is a float in a sketch and a double in Java; Processing's preprocessor adds the f."""
    out, i = [], 0
    while i < len(text):
        c = text[i]
        if c == '"':
            j = i + 1
            while j < len(text):
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == '"':
                    j += 1
                    break
                j += 1
            out.append(text[i:j])
            i = j
            continue
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = len(text) if j < 0 else j
            out.append(text[i:j])
            i = j
            continue
        m = re.match(r"(?<![\w.])(\d+\.\d*|\.\d+)(?![\w.])", text[i:])
        if m and not re.match(r"[fFdD]$", text[i + m.end():i + m.end() + 1] or " "):
            out.append(m.group(1) + "f")
            i += m.end()
            continue
        out.append(c)
        i += 1
    return "".join(out)


def split_regions(lines):
    """(top-level text, [(class name, class text), ...]) - brace counting, comments ignored."""
    top, classes = [], []
    i = 0
    while i < len(lines):
        m = re.match(r"class\s+(\w+)\s*\{", lines[i])
        if not m:
            top.append(lines[i])
            i += 1
            continue
        depth, j = 0, i
        while j < len(lines):
            code = lines[j].split("//")[0]
            depth += code.count("{") - code.count("}")
            j += 1
            if depth <= 0 and j > i:
                break
        classes.append((m.group(1), "".join(lines[i:j])))
        i = j
    return "".join(top), classes


DECL_SKIP = ("if", "for", "while", "return", "else", "switch", "catch", "do")

CASTS = ("int", "float", "double", "long", "short", "byte", "boolean", "char", "String")


def convert_casts(text):
    """`int(x)` is Processing's cast, and only the sketch preprocessor rewrites it.

    A library jar is plain Java, so it has to be a Java cast: `(int)(x)`.
    """
    out = []
    i = 0
    while i < len(text):
        c = text[i]
        if c == '"' or (c == "/" and text.startswith("//", i)):
            j = i
            if c == '"':
                j = i + 1
                while j < len(text):
                    if text[j] == "\\":
                        j += 2
                        continue
                    if text[j] == '"':
                        j += 1
                        break
                    j += 1
            else:
                while j < len(text) and text[j] != "\n":
                    j += 1
            out.append(text[i:j])
            i = j
            continue
        m = re.match(r"(?<![\w.$])(int|float|double|long|short|byte|boolean|char|String)\s*\(", text[i:])
        if m:
            depth, j = 0, i + m.end() - 1
            while j < len(text):
                if text[j] == "(":
                    depth += 1
                elif text[j] == ")":
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            inner = text[i + m.end():j]
            out.append(f"({m.group(1)})(" + convert_casts(inner) + ")")
            i = j + 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def declaration_head(line):
    """Index just past the declared name when the line declares a method, a field or a constructor.

    Rewriting a declaration (`void fill(float d) {` -> `void BMML.p.fill(...)`) would be nonsense, so
    the head of such a line is copied through untouched and only the rest is rewritten.
    """
    code = line.split("//")[0]
    stripped = code.strip()
    if stripped.startswith(DECL_SKIP):
        return None
    m = re.match(r"^(\s*)((?:public |private |protected |static |final )*"
                 r"[A-Za-z_][\w\[\]<>,.]*\s+)(\w+)(\s*\()", code)
    if m:
        return m.end(3)
    m = re.match(r"^(\s*)((?:public |private |protected |static |final )*"
                 r"[A-Za-z_][\w\[\]<>,.]*\s+)(\w+)(\s*[;=])", code)
    if m:
        return m.end(3)
    m = re.match(r"^(\s*)(\w+)(\s*\()", code)          # constructor
    if m and m.group(2)[:1].isupper():
        return m.end(2)
    return None


def rewrite_code_segment(seg, names, prefix):
    for name in names:
        seg = re.sub(r"(?<![\w.$])" + name + r"\b", prefix + name, seg)
    return seg


def rewrite_line(line, names, prefix):
    """Rewrite names in code position only: never in a comment, a string, or a declaration head."""
    if prefix is None or not names:
        return line
    if line.lstrip().startswith("//"):
        return line
    head_at = declaration_head(line)
    head, rest = (line[:head_at], line[head_at:]) if head_at is not None else ("", line)
    out, buf = [], ""
    i = 0
    while i < len(rest):
        c = rest[i]
        if c == '"':
            if buf:
                out.append(rewrite_code_segment(buf, names, prefix))
                buf = ""
            j = i + 1
            while j < len(rest):
                if rest[j] == "\\":
                    j += 2
                    continue
                if rest[j] == '"':
                    j += 1
                    break
                j += 1
            out.append(rest[i:j])
            i = j
            continue
        if rest.startswith("//", i):
            if buf:
                out.append(rewrite_code_segment(buf, names, prefix))
                buf = ""
            out.append(rest[i:])
            i = len(rest)
            continue
        buf += c
        i += 1
    if buf:
        out.append(rewrite_code_segment(buf, names, prefix))
    return head + "".join(out)


def names_declared_at_top_level(text):
    """Function and field names declared at brace depth 0 of a region."""
    names, depth = set(), 0
    for line in text.splitlines():
        code = line.split("//")[0]
        if depth == 0:
            stripped = code.strip()
            if stripped and not stripped.startswith(DECL_SKIP):
                m = re.match(r"^(?:public |private |protected |static |final )*"
                             r"[A-Za-z_][\w\[\]<>,.]*\s+(\w+)\s*[\(=;]", stripped)
                if m:
                    names.add(m.group(1))
        depth += code.count("{") - code.count("}")
    return names


def member_names(class_text):
    """Names declared inside a class body, at any depth, plus the class's own name."""
    names = set(re.findall(r"^\s*(?:public |private |protected |static |final )*"
                           r"[A-Za-z_][\w\[\]<>,.]*\s+(\w+)\s*[\(;=]", class_text, re.M))
    names |= set(re.findall(r"^\s*(\w+)\s*\([^)]*\)\s*\{", class_text, re.M))
    return names


def make_static(text):
    """Top-level functions and fields have to be static to be reachable from the other classes."""
    out, depth = [], 0
    for line in text.splitlines(keepends=True):
        stripped = line.strip()
        code = line.split("//")[0]
        at_top = depth == 0
        depth += code.count("{") - code.count("}")
        declares = (at_top and stripped and not stripped.startswith(DECL_SKIP)
                    and not stripped.startswith(("//", "/*", "*", "}"))
                    and re.match(r"^(?:public |private |protected |static |final )*"
                                 r"[A-Za-z_][\w\[\]<>,.]*\s+\w+\s*[\(=;]", stripped))
        if declares:
            line = re.sub(r"^(\s*)(?=(?:public |private |protected |static |final )*"
                          r"[A-Za-z_][\w\[\]<>,.]*\s+\w+\s*[\(=;])",
                          r"\1public static ", line, count=1)
        out.append(line)
    return "".join(out)


def make_public(text, class_name):
    """Fields, constructors and methods of a class have to be public, not package-private.

    In a sketch every tab is one package, so a class's members can be left package-private and the
    sketch still reaches them. In a jar the class is in `bmml` and the sketch is in the default
    package, so `new Cloud("fern")` fails with "The constructor Cloud(String) is not visible".
    """
    out, depth = [], 0
    for line in text.splitlines(keepends=True):
        stripped = line.strip()
        code = line.split("//")[0]
        inside = depth == 1
        depth += code.count("{") - code.count("}")
        if inside and stripped and not stripped.startswith(("//", "/*", "*", "}", "else", "}")):
            field = re.match(r"^(?=(?:public |private |protected |static |final |transient )*"
                             r"[A-Za-z_][\w\[\]<>,.]*\s+\w+\s*[\(=;])", stripped)
            ctor = re.match(r"^(?=" + re.escape(class_name) + r"\s*\()", stripped)
            if field or ctor:
                line = re.sub(r"^(\s*)", r"\1public ", line, count=1)
        out.append(line)
    return "".join(out)


def main():
    if not PDE.exists():
        sys.exit(f"{PDE} is missing")
    src = float_literals(convert_casts(PDE.read_text()))
    lines = src.splitlines(keepends=True)
    i = 0
    while i < len(lines) and (lines[i].startswith("//") or not lines[i].strip()):
        i += 1
    header, rest = lines[:i], lines[i:]
    top, classes = split_regions(rest)
    if not classes:
        sys.exit("no classes found in the .pde")

    top_names = names_declared_at_top_level(top)
    class_names = {name for name, _ in classes}

    # --- the sketch-handle and the callback lookup work on the applet, not on the library object
    top = top.replace("getClass().getMethod(", "app.getClass().getMethod(")
    top = top.replace("m.invoke(this,", "m.invoke(app,")

    # --- bmml.BMML: the top-level functions and constants, with a place to keep the PApplet
    body = make_static(top)
    borrowed = sorted((set(re.findall(r"(?<![\w.$])([A-Za-z_]\w*)\s*\(", body))
                       | set(re.findall(r"(?<![\w.$])\b(pixels|width|height|frameCount|pixelWidth|"
                                        r"pixelHeight)\b", body)))
                      & (INSTANCE - top_names))
    # The library re-declares a few Processing names as extra overloads - the textured
    # background() forms. Inside BMML.java a bare call to such a name resolves to the library's own
    # overloads, so Processing's has to be reached through the sketch explicitly.
    borrowed = sorted(set(borrowed) | (INSTANCE & top_names))
    top_text = "".join(rewrite_line(l, borrowed, "app.") for l in body.splitlines(keepends=True))
    bmml = (f"{''.join(header)}package bmml;\n\n"
            "import processing.core.PApplet;\n"
            "import static processing.core.PApplet.*;\n"
            "import static processing.core.PConstants.*;\n\n"
            "/**\n"
            " * BitMapMathLib - the drawing maths behind the Nostalgia art pieces.\n"
            " *\n"
            " * <p>One per sketch, before anything else:\n"
            " *\n"
            " * <pre>import bmml.*;\n"
            " * import static bmml.BMML.*;\n"
            " * BMML bmml;\n"
            " * void setup() { size(240, 128); bmml = new BMML(this); }</pre>\n"
            " *\n"
            " * <p>Then the reference in reference/BMML-reference.txt applies as written. See README.md.\n"
            " */\n"
            f"public class BMML {{\n\n"
            "  /** the sketch every call draws into; set by the constructor */\n"
            "  public static PApplet app;\n\n"
            "  public BMML(PApplet sketch) {\n    app = sketch;\n  }\n\n"
            f"{top_text}}}\n")

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "BMML.java").write_text(bmml)

    # --- the classes of the .pde, one file each
    for name, text in classes:
        own = member_names(text) | {name}
        borrowed_calls = sorted((set(re.findall(r"(?<![\w.$])([A-Za-z_]\w*)\s*\(", text))
                                 | set(re.findall(r"(?<![\w.$])\b(pixels|width|height|frameCount|"
                                                  r"pixelWidth|pixelHeight)\b", text)))
                                & (INSTANCE - own))
        library_calls = sorted((set(re.findall(r"(?<![\w.$])([A-Za-z_]\w*)\s*\(", text))
                                | set(re.findall(r"(?<![\w.$])\b(\w+)\b", text)))
                               & (top_names - own))
        body = "".join(rewrite_line(l, borrowed_calls, "BMML.app.") for l in text.splitlines(keepends=True))
        body = "".join(rewrite_line(l, library_calls, "BMML.") for l in body.splitlines(keepends=True))
        head = (f"{''.join(header)}package bmml;\n\n"
                "import processing.core.PApplet;\n"
                "import static processing.core.PApplet.*;\n"
                "import static processing.core.PConstants.*;\n\n")
        # a sketch's own classes are package-private in the sketch, which is one package; in a jar
        # they are in bmml and a sketch in the default package cannot see them unless they are
        # public. `Cloud is not visible` is what this line is for.
        body = re.sub(r"^class\s+(\w+)", r"public class \1", body, count=1, flags=re.M)
        body = make_public(body, name)
        (OUT / f"{name}.java").write_text(head + body + "\n")

    print(f"wrote {OUT}/BMML.java and {len(classes)} class files: "
          + ", ".join(name for name, _ in classes))
    print(f"BMML borrows {len(borrowed)} Processing members through app.: {', '.join(borrowed)}")


if __name__ == "__main__":
    main()