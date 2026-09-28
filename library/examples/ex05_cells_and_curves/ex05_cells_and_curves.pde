// ex05_cells_and_curves - the library edition of this example.
// Installed BitMapMathLib (Sketch > Import Library... > Add Library, then restart Processing).
// The drop-in edition in the repository does the same thing without the imports: see README.md.

import bmml.*;
import static bmml.BMML.*;

BMML bmml;

// BitMapMathLib example - a cellular automaton under a Hilbert curve.
// Copy BitMapMathLib.pde into this folder as a second tab and press Run.

Automaton a = new Automaton(30, 3);
Life g = new Life("B3/S23", 3);

void setup() {
  bmml = new BMML(this);
  size(240, 128);
  background(255);
}

void draw() {
  background(255);
  noStroke();
  fill(210);
  rect(0, 0, 240, 128);
  fill(0);
  a.step();
  a.draw();
  stroke(0);
  noFill();
  spaceCurve("hilbert", 0, 0, 240, 128, 4, launchT());
  g.step();
  stroke(70);
  noFill();
  truchet(0, 0, 240, 128, 16, "arcs", frameCount / 90.0);
}

float launchT() {
  return ease(loopT(240));
}
