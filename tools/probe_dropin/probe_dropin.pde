// Not an example: the drop-in edition's runtime check. Built and run by tools/build_examples.sh
// with BitMapMathLib.pde as the second tab, prints one line per group and exits.
//
// It is tools/probe/probe.pde with the library's four lines taken out - no imports, no `BMML bmml`,
// no constructor call, no BMML.app. Keep the two in step: they are the same sketch otherwise.
float fy(float x) { return sin(x) * 0.5; }
float fr(float a) { return 1 + cos(a) * 0.5; }
float shade(float x, float y) { return x / 240.0; }

Cloud fern = new Cloud("fern");
Automaton automaton = new Automaton(30, 3);
Life life = new Life("B3/S23", 3);
Fractal fractal = new Fractal("julia", -4 / 5.0, 1 / 6.0, 1);
LSystem lsystem = new LSystem("F", "F=F[+F]F[-F]F", 25, 4);
Packing packing = new Packing(0, 0, 120, 60, 2, 10);
float[] xs = new float[12];
float[] ys = new float[12];

void setup() {
  size(240, 128);
  pixelDensity(1);
  println("PROBE callbacks fy=" + hasFunction("fy") + " fr=" + hasFunction("fr")
          + " shade=" + hasFunction("shade") + " nope=" + hasFunction("nope"));
}

int frames = 0;

void draw() {
  background(255);
  noStroke();
  fill(150);
  rect(20, 20, 200, 88);
  pattern("hatch", 5);
  shadeField(4);                       // through the sketch's own shade(), by reflection
  plot(0, 6, -1, 1);                   // through fy()
  polarPlot(120, 64, 30, 1);
  polarShape(120, 64, 20);
  voronoi(xs, ys, 3);
  delaunay(xs, ys);
  truchet(0, 0, 240, 128, 16, "arcs", frameCount / 60.0);
  spaceCurve("hilbert", 0, 0, 240, 128, 3, 1);
  lissajous(120, 64, 60, 40, 3, 4, 0, 1);
  rose(120, 64, 30, 5.0 / 2, 1);
  spiro(120, 64, 40, 12, 20, 1);
  lsystem.draw(0, 0, 240, 128, 1);
  grid(16);
  polarGrid(120, 64, 40, 3, 8);
  fern.fit(0, 0, 120, 128);
  fern.step(400);
  fern.draw("dots", 4);
  fern.fade(0.98);
  automaton.step();
  automaton.draw();
  life.step();
  life.draw();
  fractal.draw(4, "dots", 4);
  packing.step(40);
  packing.draw();
  textCircle("bmml", 120, 64, 30, 0);
  textWave("bitmap", 10, 110, 3, frameCount / 10.0);
  textFit("library", 10, 10, 100, 16);
  textGrid("bmml", 0, 0, 240, 128, 10);
  texture("dots", 4);
  textureSeed(7);
  applyTexture();
  noTexture();
  strokeTexture("hatch", 5);
  noStrokeTexture();
  background(200, "dots", 4);
  background(20, 240, "vgradient");
  fade(40);
  for (int i = 0; i < 12; i++) {
    xs[i] = 240 * timeNoise(i, 0, 1 / 256.0);
    ys[i] = 128 * timeNoise(i, PHI, 1 / 256.0);
  }
  loadPixels();
  long sum = 0;
  int ink = 0;
  for (int i = 0; i < pixels.length; i++) {
    int g = pixels[i] & 255;
    sum += g;
    if (g < 128) ink++;
  }
  println("PROBE frame " + frameCount + " ink=" + ink + " sum=" + sum);
  frames++;
  if (frames >= 3) {
    println("PROBE ok");
    exit();
  }
}