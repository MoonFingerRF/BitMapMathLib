// ex01_julia_shade - the library edition of this example.
// Installed BitMapMathLib (Sketch > Import Library... > Add Library, then restart Processing).
// The drop-in edition in the repository does the same thing without the imports: see README.md.

import bmml.*;
import static bmml.BMML.*;

BMML bmml;

// BitMapMathLib example - a Julia set, shaded by escape time.
// Copy BitMapMathLib.pde into this folder as a second tab and press Run.
//
// shadeField(cell) fills the frame from your own shade(x, y): return 0 for paper, 1 for ink.

// the escape time at one pixel, as ink: inside the set is solid, outside is a grey cloud
float shade(float x, float y) {
  float cr = map(x, 0, width, -1.8, 1.8);
  float ci = map(y, 0, height, -1.2, 1.2);
  float zr = cr, zi = ci;
  int n = 0;
  while (n < 24 && zr * zr + zi * zi < 4) {
    float t = zr * zr - zi * zi - 0.62;
    zi = 2 * zr * zi + 0.42;
    zr = t;
    n++;
  }
  return n >= 24 ? 1 : n / 24.0;
}

void setup() {
  bmml = new BMML(this);
  size(240, 128);
}

void draw() {
  background(255);
  shadeField(2);                       // 2-pixel cells: one shade() call each
  noFill();
  stroke(0);
  polarGrid(120, 64, 60, 4, 12);
}
