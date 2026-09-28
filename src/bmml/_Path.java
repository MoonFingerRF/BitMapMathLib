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

public class _Path {
  public float[] xs;
  public float[] ys;
  public boolean[] pen;
  public int n = 0;
  public float x0 = 0, y0 = 0, x1 = 0, y1 = 0;

  public _Path(int cap) {
    xs = new float[cap];
    ys = new float[cap];
    pen = new boolean[cap];
  }

  public void add(float x, float y, boolean down) {
    if (n >= xs.length) return;
    if (n == 0) {
      x0 = x; x1 = x; y0 = y; y1 = y;
    }
    xs[n] = x;
    ys[n] = y;
    pen[n] = down;
    n++;
    x0 = min(x0, x); x1 = max(x1, x);
    y0 = min(y0, y); y1 = max(y1, y);
  }

  public void draw(float bx, float by, float bw, float bh, float p) {
    float sw = max(x1 - x0, 0.0001f);
    float sh = max(y1 - y0, 0.0001f);
    float s = min(bw / sw, bh / sh);
    float ox = bx + (bw - sw * s) / 2 - x0 * s;
    float oy = by + (bh - sh * s) / 2 - y0 * s;
    int m = round((n - 1) * constrain(p, 0, 1));
    BMML.app.pushStyle();
    BMML.app.noFill();
    boolean on = false;
    int count = 0;
    for (int i = 1; i <= m && i < n; i++) {
      if (pen[i]) {
        if (!on || count > 8000) {
          if (on) BMML.app.endShape();
          BMML.app.beginShape();
          BMML.app.vertex(ox + xs[i - 1] * s, oy + ys[i - 1] * s);
          on = true;
          count = 0;
        }
        BMML.app.vertex(ox + xs[i] * s, oy + ys[i] * s);
        count++;
      } else if (on) {
        BMML.app.endShape();
        on = false;
      }
    }
    if (on) BMML.app.endShape();
    BMML.app.popStyle();
  }
}

