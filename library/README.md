# BitMapMathLib (BMML)

The drawing mathematics behind the [Nostalgia](https://github.com/MoonFingerRF) art pieces, on a
240 × 128 canvas of one bit per pixel: threshold patterns and dithering, escape-time fractals, IFS
point clouds and strange attractors, cellular automata and Game of Life, L-systems and space-filling
curves, Voronoi and Delaunay, circle packing and Truchet tiles, and text as an image.

It is a *prelude*, not a framework: a sketch keeps its own `setup()` and `draw()`, and every function
here draws with the current stroke and fill, exactly as Processing does.

- **Version** 1.0.0
- **Processing** 4.x, Java mode (built and tested against Processing 4.5.2)
- **Licence** MIT, © MoonFingerRF
- **Reference** [`reference/BMML-reference.txt`](reference/BMML-reference.txt)

```processing
Fractal f = new Fractal("julia", -4 / 5.0, 1 / 6.0, 1);

void setup() { size(240, 128); }

void draw() {
  float a = TWO_PI * loopT(2000);
  f.set(-4 / 5.0 + cos(a) / 20, 1 / 6.0 + sin(a) / 20);
  f.draw(6, "dots", 4);
}
```

## Install

### 1. Drop-in (nothing to install)

Download `BitMapMathLib.pde` and copy it into your sketch folder as a **second tab** — a tab is any
other `.pde` file in the folder. Nothing else changes: your sketch keeps its own name and its own
`setup()` and `draw()`, and every function in the reference is available by name.

```
MySketch/
  MySketch.pde          <- yours
  BitMapMathLib.pde     <- copy this in
```

Best when you want one sketch to be self-contained, or you want to read and change the library.

### 2. Installed library

Download `BitMapMathLib.zip` from the
[releases page](https://github.com/MoonFingerRF/BitMapMathLib/releases), then either

- Processing ▸ **Sketch ▸ Import Library… ▸ Add Library…** and pick the zip, or
- unzip it so that `BitMapMathLib/library/BitMapMathLib.jar` sits in your sketchbook's `libraries/`
  folder (`~/Documents/Processing/libraries/` by default), and restart Processing.

Then, in the sketch:

```processing
import bmml.*;
import static bmml.BMML.*;      // so the function names are bare, as in the reference

BMML bmml;

void setup() {
  size(240, 128);
  bmml = new BMML(this);        // hand the sketch over, before anything else
}
```

The library has no `PApplet` subclass to install, so `new BMML(this)` is what connects it to your
sketch. Until that line has run, calls into the library have no canvas to draw on. Nothing else about
the reference changes.

## Your own functions

Three functions are yours, not ours, and the library draws them where it needs them:

| function | drawn by |
| --- | --- |
| `float fy(float x)` | `plot(x0, x1, y0, y1)` |
| `float fr(float a)` | `polarPlot(cx, cy, scale, turns)`, `polarShape(cx, cy, scale)` |
| `float shade(float x, float y)` | `shadeField(cell)` |

Define them in your sketch as usual:

```processing
float fy(float x) { return sin(x) * sin(x / 3 + frameCount / 20.0); }

void draw() {
  background(255);
  stroke(190); grid(width / 15);
  stroke(0);   plot(-3 * PI, 3 * PI, -3 / 2.0, 3 / 2.0);
}
```

A sketch that never calls `plot`, `polarPlot`, `polarShape` or `shadeField` does not need them, and
if one is missing the drawing that wants it is skipped rather than stopping the sketch with a
compile error. `hasFunction("fy")` tells you whether one is there.

## The two editions differ in exactly two places

Everything in the reference behaves the same in both editions, except:

**`pixelDensity`.** Processing 4 sets `pixelDensity(2)` by default on a high-density screen. The
library's pixel passes (`pattern`, `Cloud.draw`, `Fractal.draw`) are written for one buffer pixel per
canvas pixel and scale themselves to whatever density is in force, so a retina screen and a plain
one come out the same. You do not have to call `pixelDensity(1)`.

**Textures.** The Nostalgia hub adds a texture to Processing — a shape filled with a 1-bit pattern
rather than a flat grey. Stock Processing has none of it, so the drop-in edition provides
`texture()`, `strokeTexture()`, `noTexture()`, `noStrokeTexture()`, `textureSeed()`,
`applyTexture()`, `hasTexture()` and the textured `background()` forms as approximations: the hub
tiles the texture inside each shape, the approximation makes one pass over the whole frame, so shapes
drawn over one another come out differently. Call `applyTexture()` once at the end of `draw()`. Skip
these functions entirely and the two editions are identical.

## Reference

The full function reference is [`reference/BMML-reference.txt`](reference/BMML-reference.txt). In
short:

- **Numbers and places** `PHI`, `GOLDEN_ANGLE`, `E`, `SQRT2`, `CX`, `CY`, `xAt`, `yAt`, `phylloX`, `phylloY`
- **Time and noise** `ease`, `wave`, `loopT`, `clockT`, `timeNoise`, `flowAngle`, `cellRandom`
- **Plots** `plot`, `polarPlot`, `polarShape`, `grid`, `polarGrid`
- **Curves** `lissajous`, `rose`, `spiro`, `spaceCurve`, `LSystem`
- **Point clouds** `Cloud` (`fern`, `sierpinski`, `carpet`, `dragon`, `lorenz`, `clifford`, `dejong`)
- **Cells** `Automaton`, `Life`, `Fractal`
- **Geometry** `voronoi`, `delaunay`, `Packing`, `truchet`
- **Shading** `pattern`, `patternRect`, `patternShift`, `shadeField`, `fade`
- **Words** `textCircle`, `textWave`, `textFit`, `textGrid`

Two of `pattern`, `shadeField`, `Cloud.draw` and `Fractal.draw` in one frame is the practical limit:
each one touches every pixel.

## Examples

`examples/` holds five sketches. Each is built and checked against stock Processing by

```sh
sh tools/build_examples.sh
```

| example | what it shows |
| --- | --- |
| `ex01_julia_shade` | a Julia set filled by `shadeField`, with your own `shade(x, y)` |
| `ex02_voronoi_cells` | drifting Voronoi cells, hatched by distance, with `delaunay` on top |
| `ex03_pattern_grid` | a grey ramp turned into each pattern in turn |
| `ex04_fern_cloud` | an IFS fern built point by point and inked in a pattern |
| `ex05_cells_and_curves` | a cellular automaton under a Hilbert curve and Truchet arcs |

The same five are in the library zip as `examples/`, written for `import bmml.*;` instead of the
second tab. They are generated from the drop-in ones by `tools/make_library.py`, so the two cannot
drift apart.

## Building this repository

```sh
sh tools/build_examples.sh        # every drop-in example, plus a probe that runs every function
sh tools/build_library.sh         # the jar (against Processing's core.jar), library/, dist/*.zip
sh tools/verify_library.sh        # installs the zip into the sketchbook, builds the examples,
                                  # runs tools/probe/probe.pde and checks what it printed
```

`library/`, `src/bmml/` and `build/` are generated; only `BitMapMathLib.pde`, `examples/`,
`reference/`, `tools/` and the three documents at the top are written by hand. `library/` is
committed because it is what a visitor installs — the jar in it is the same one `dist/` holds.

`BitMapMathLib.pde` is the source of truth. `src/bmml/*.java` is generated from it by
`tools/make_java.py`, and is committed so the jar can be rebuilt without the generator; the generated
Java is compiled by `javac` against Processing's own `core.jar`, so a wrong rewrite is a compile
error rather than a wrong picture.

## Licence

MIT. See [LICENSE](LICENSE). The examples and the library itself are © MoonFingerRF.