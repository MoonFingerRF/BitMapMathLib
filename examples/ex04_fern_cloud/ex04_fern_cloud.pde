// BitMapMathLib example - an IFS fern, built up point by point and inked in a pattern.
// Copy BitMapMathLib.pde into this folder as a second tab and press Run.

Cloud fern = new Cloud("fern");

void setup() {
  size(240, 128);
  fern.fit(20, 2, 90, 124);
  background(255);
}

void draw() {
  noStroke();
  fill(255, 60);                                       // a slow fade, so the fern settles
  rect(0, 0, 240, 128);
  fern.fade(0.97);                                     // 97% of last frame's points stay
  fern.step(1200);                                     // add points
  fern.draw("hatch", 3);                               // ink them in a pattern
  noFill();
  stroke(120);
  polarGrid(180, 64, 50, 3, 8);
  stroke(0);
  lissajous(180, 64, 40, 28, 3, 4, frameCount / 60.0, loopT(200));
}
