// BitMapMathLib example - a grey ramp turned into every pattern the library has.
// Copy BitMapMathLib.pde into this folder as a second tab and press Run.

String[] kinds = {"stipple", "hatch", "cross", "lines", "dots", "checker", "weave", "wavy"};
int shown = 4;

void setup() {
  size(240, 128);
  noLoop();
}

void draw() {
  background(255);
  noStroke();
  for (int i = 0; i < 6; i++) {
    fill(40 + i * 36);
    rect(6 + i * 39, 6, 33, 50);
  }
  patternShift(3, 3);                                  // moves the patterns under the greys
  pattern(kinds[shown % kinds.length], 5);
  noStroke();
  fill(0);
  textSize(11);
  textFit(kinds[shown % kinds.length], 6, 64, 228, 14);
  textFit("click to change", 6, 84, 228, 14);
}

void mousePressed() {
  shown++;
  redraw();
}
