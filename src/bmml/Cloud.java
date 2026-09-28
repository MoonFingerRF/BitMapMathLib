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

public class Cloud {
  public String kind;
  float a, b, c, d;
  public float x = 0.1f, y = 0.1f, z = 0.1f;
  float bx0, by0, bx1, by1;
  public float ux = 0, uy = 0, uw = 240, uh = 128;
  public float[] hits = new float[240 * 128];
  public float total = 0;
  public int filled = 0;
  public float[] maps = null;
  public int nmaps = 0;

  public Cloud(String kind) {
    this.kind = kind;
    if (kind.equals("fern")) {
      maps = new float[] {0, 0, 0, 0.16f, 0, 0, 0.01f, 0.85f, 0.04f, -0.04f, 0.85f, 0, 1.6f, 0.85f,
        0.2f, -0.26f, 0.23f, 0.22f, 0, 1.6f, 0.07f, -0.15f, 0.28f, 0.26f, 0.24f, 0, 0.44f, 0.07f};
      bounds(-2.2f, 0, 2.7f, 10);
    } else if (kind.equals("sierpinski")) {
      maps = new float[] {0.5f, 0, 0, 0.5f, 0, 0, 0.3334f, 0.5f, 0, 0, 0.5f, 0.5f, 0, 0.3333f,
        0.5f, 0, 0, 0.5f, 0.25f, 0.433f, 0.3333f};
      bounds(0, 0, 1, 0.866f);
    } else if (kind.equals("carpet")) {
      maps = new float[8 * 7];
      int m = 0;
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (i == 1 && j == 1) continue;
          maps[m * 7] = 1 / 3.0f;
          maps[m * 7 + 3] = 1 / 3.0f;
          maps[m * 7 + 4] = i / 3.0f;
          maps[m * 7 + 5] = j / 3.0f;
          maps[m * 7 + 6] = 0.125f;
          m++;
        }
      }
      bounds(0, 0, 1, 1);
    } else if (kind.equals("dragon")) {
      maps = new float[] {0.5f, -0.5f, 0.5f, 0.5f, 0, 0, 0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 1, 0, 0.5f};
      bounds(-0.4f, -0.4f, 1.25f, 0.9f);
    } else if (kind.equals("lorenz")) {
      set(10, 28, 8 / 3.0f, 0);
      bounds(-30, 0, 30, 52);
    } else if (kind.equals("dejong")) {
      set(-2.0f, -2.0f, -1.2f, 2.0f);
      bounds(-2.1f, -2.1f, 2.1f, 2.1f);
    } else {
      set(-1.4f, 1.6f, 1.0f, 0.7f);
    }
    if (maps != null) nmaps = maps.length / 7;
  }

  public void bounds(float x0, float y0, float x1, float y1) {
    bx0 = x0; by0 = y0; bx1 = x1; by1 = y1;
  }

  public void set(float a, float b, float c, float d) {
    this.a = a; this.b = b; this.c = c; this.d = d;
    if (kind.equals("clifford")) bounds(-1 - abs(c), -1 - abs(d), 1 + abs(c), 1 + abs(d));
  }

  public void fit(float x, float y, float w, float h) {
    ux = x; uy = y; uw = w; uh = h;
  }

  public void step(int n) {
    float sw = bx1 - bx0, sh = by1 - by0;
    float s = min(uw / sw, uh / sh);
    float ox = ux + (uw - sw * s) / 2;
    float oy = uy + (uh - sh * s) / 2;
    boolean lorenz = kind.equals("lorenz");
    boolean dejong = kind.equals("dejong");
    float ca = cos(d), sa = sin(d);
    for (int i = 0; i < n; i++) {
      float px, py;
      if (nmaps > 0) {
        float r = BMML.app.random(1);
        int m = 0;
        while (m < nmaps - 1 && r > maps[m * 7 + 6]) {
          r -= maps[m * 7 + 6];
          m++;
        }
        int o = m * 7;
        float nx = maps[o] * x + maps[o + 1] * y + maps[o + 4];
        y = maps[o + 2] * x + maps[o + 3] * y + maps[o + 5];
        x = nx;
        px = x;
        py = y;
      } else if (lorenz) {
        float dt = 0.006f;
        float dx = a * (y - x), dy = x * (b - z) - y, dz = x * y - c * z;
        x += dx * dt; y += dy * dt; z += dz * dt;
        px = x * ca - y * sa;
        py = z;
      } else if (dejong) {
        float nx = sin(a * y) - cos(b * x);
        y = sin(c * x) - cos(d * y);
        x = nx;
        px = x;
        py = y;
      } else {
        float nx = sin(a * y) + c * cos(a * x);
        y = sin(b * x) + d * cos(b * y);
        x = nx;
        px = x;
        py = y;
      }
      int sx = (int)(ox + (px - bx0) * s);
      int sy = (int)(oy + (by1 - py) * s);
      if (sx >= 0 && sx < 240 && sy >= 0 && sy < 128) {
        int k = sy * 240 + sx;
        if (hits[k] == 0) filled++;
        hits[k] += 1;
        total += 1;
      }
    }
  }

  public void fade(float keep) {
    total = 0;
    filled = 0;
    for (int k = 0; k < hits.length; k++) {
      float h = hits[k];
      if (h > 0) {
        h *= keep;
        if (h < 0.3f) h = 0;
        hits[k] = h;
        if (h > 0) {
          total += h;
          filled++;
        }
      }
    }
  }

  public void draw(String tex, float scale) {
    if (filled == 0) return;
    BMML._tileFor(tex, scale);
    BMML._prepShift();
    float mean = total / filled;
    BMML.app.loadPixels();
    int pd = max(1, BMML.app.pixelWidth / BMML.app.width);
    int pw = BMML.app.pixelWidth;
    for (int k = 0; k < hits.length; k++) {
      float h = hits[k];
      if (h > 0) {
        int v = (int)(255 * h * h / (h * h + mean * mean));
        if (BMML._ink(v, k % 240, k / 240)) {
          int x = k % 240, y = k / 240;
          for (int dy = 0; dy < pd; dy++) {
            for (int dx = 0; dx < pd; dx++) BMML.app.pixels[(y * pd + dy) * pw + x * pd + dx] = -16777216;
          }
        }
      }
    }
    BMML.app.updatePixels();
  }
}

