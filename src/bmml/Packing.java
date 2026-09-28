// BitMapMathLib (BMML) 1.0.0 - the drawing maths behind the Nostalgia art pieces.
// https://github.com/MoonFingerRF/BitMapMathLib   MIT, (c) MoonFingerRF
//
// Drop-in edition: copy this file into a sketch folder as a second tab (a Processing "tab" is any
// other .pde file in the folder). Nothing to import; every name below is a plain Processing function.
// The reference of every function is in README.md / reference/BMML-reference.txt.
//
// Two things differ from a sketch written against the hub edition:
//   * fy(x), fr(a) and shade(x, y) - the functions plot(), polarPlot(), polarShape() and
//     shadeField() draw - are looked up on your sketch by name when they are first needed. Define
//     them as usual (`float fy(float x) { ... }`); if you never use those four functions you do not
//     need them, and if one is missing the drawing that wants it is simply skipped.
//   * texture(), strokeTexture(), noTexture(), noStrokeTexture(), textureSeed() and the textured
//     background() forms are the hub's own extension, which stock Processing does not have. They are
//     provided here as approximations - see README.md, "Hub extensions".

// ------------------------------------------------------------------ time, noise, hashing
package bmml;

import processing.core.PApplet;
import static processing.core.PApplet.*;
import static processing.core.PConstants.*;

public class Packing {
  float bx, by, bw, bh, rmin, rmax;
  public int n = 0;
  public float[] x = new float[600];
  public float[] y = new float[600];
  public float[] r = new float[600];
  public boolean full = false;
  public int misses = 0;

  public Packing(float x, float y, float w, float h, float rmin, float rmax) {
    bx = x; by = y; bw = w; bh = h;
    this.rmin = max(1, rmin);
    this.rmax = max(this.rmin, rmax);
  }

  public void step(int tries) {
    for (int t = 0; t < tries && !full; t++) {
      float px = bx + BMML.app.random(bw), py = by + BMML.app.random(bh);
      float best = min(min(px - bx, bx + bw - px), min(py - by, by + bh - py));
      for (int i = 0; i < n && best >= rmin; i++) {
        best = min(best, dist(px, py, x[i], y[i]) - r[i] - 1);
      }
      if (best >= rmin) {
        x[n] = px; y[n] = py; r[n] = min(best, rmax);
        n++;
        misses = 0;
        if (n >= x.length) full = true;
      } else {
        misses++;
        if (misses > 400) full = true;
      }
    }
  }

  public void draw() {
    for (int i = 0; i < n; i++) BMML.app.circle(x[i], y[i], 2 * r[i]);
  }

  public void clear() {
    n = 0;
    full = false;
    misses = 0;
  }
}

