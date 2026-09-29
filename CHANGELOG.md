# Changelog

BitMapMathLib follows [semantic versioning](https://semver.org/): the function names, their
arguments and what they draw are the interface.

## Unreleased

### Changed

- `clockT(seconds)` now moves smoothly: it adds the fraction of the current second (from `millis()`)
  to the wall-clock seconds, so a piece on `clockT(15)` glides instead of stepping once a second.
  Still wall-clock aligned, still in [0, 1).

## 1.0.0

First release. The drawing mathematics behind the Nostalgia art pieces, published on its own in two
editions that share one function list.

### Added

- **Drop-in edition** `BitMapMathLib.pde` — copy it into a sketch folder as a second tab and every
  function in the reference is available by name. Nothing to install, no imports.
- **Installed library** `BitMapMathLib.zip` — the same code as `bmml.BMML`, a plain class rather
  than a `PApplet` subclass, so a sketch connects it with `new BMML(this)` in `setup()`.
- **The reference** `reference/BMML-reference.txt`: numbers and places, time and noise, plots,
  curves, point clouds, cells, geometry, shading and words.
- **Five examples**, each built against stock desktop Processing 4 and each written twice — for the
  second tab in `examples/`, and for `import bmml.*;` in the library's `examples/`. An installed
  library is installed the way a visitor would install it and run before the examples are called
  good, by `tools/verify_library.sh`.

### Changed from the hub original

- **`String[] to` renamed.** `to` is a Processing keyword; the L-system replacement table is `rep`.
- **`fy`, `fr` and `shade` are found by reflection.** In the hub these are the sketch's own
  functions and the compiler knows them; stock Processing rejects a call to a function that is not
  there, so the library looks for them on the sketch at the moment it needs one. A missing function
  skips its drawing instead of stopping the sketch, and `hasFunction("fy")` reports whether one is
  there.
- **`pixelDensity` handled.** Processing 4 defaults to `pixelDensity(2)` on a high-density screen.
  `pattern`, `Cloud.draw` and `Fractal.draw` index the pixel buffer by hand; they now scale to
  whatever density is in force, so a retina screen and a plain one produce the same picture. The
  hub could rely on `pixelDensity(1)` and cannot be asked for anything else.
- **Textures approximated.** `texture()`, `strokeTexture()`, `noTexture()`, `noStrokeTexture()`,
  `textureSeed()`, `applyTexture()`, `hasTexture()` and the textured `background()` forms exist in
  the drop-in edition, because the hub has them and sketches in the gallery use them; the hub tiles
  a texture inside each shape, the approximation covers the frame once, so overlapping shapes differ.
  Every other function is identical in both editions.

### Building

- `BitMapMathLib.pde` is the source of truth. `src/bmml/*.java` is generated from it by
  `tools/make_java.py` and compiled by `javac` against Processing's own `core.jar`, so a bad rewrite
  is a compile error rather than a wrong picture.