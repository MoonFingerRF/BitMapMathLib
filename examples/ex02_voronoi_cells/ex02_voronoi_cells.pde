// BitMapMathLib example - Voronoi cells that drift, hatched by distance.
// Copy BitMapMathLib.pde into this folder as a second tab and press Run.

float[] xs = new float[18];
float[] ys = new float[18];

void setup() {
  size(240, 128);
  background(255);
}

void draw() {
  background(255);
  for (int i = 0; i < 18; i++) {
    xs[i] = width * timeNoise(i, 0, 1 / 256.0);       // noise that drifts with frameCount
    ys[i] = height * timeNoise(i, PHI, 1 / 256.0);
  }
  voronoi(xs, ys, 4);                                  // rings = 4 shades each cell to its centre
  pattern("hatch", 5);                                 // every grey pixel becomes the pattern
  stroke(0);
  delaunay(xs, ys);                                    // the lines between neighbours
  fill(255);
  for (int i = 0; i < 18; i++) circle(xs[i], ys[i], 1.5);
}
