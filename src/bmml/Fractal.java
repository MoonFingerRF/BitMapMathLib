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

public class Fractal {
  public String kind;
  float a, b, na, nb, zoom;
  public int row = 0;
  public int passes = 0;
  public int iterations = 40;

  public Fractal(String kind, float a, float b, float zoom) {
    this.kind = kind;
    this.a = a; this.b = b; this.na = a; this.nb = b;
    this.zoom = zoom;
  }

  public void set(float a, float b) {
    na = a;
    nb = b;
  }

  public void draw(int rows, String tex, float scale) {
    boolean bands = tex.equals("bands");
    if (!bands) {
      BMML._tileFor(tex, scale);
      BMML._prepShift();
    }
    boolean julia = kind.equals("julia");
    float w = 3.2f / zoom;
    float h = w * 128 / 240.0f;
    float cx0 = julia ? 0 : a;
    float cy0 = julia ? 0 : b;
    int N = max(4, iterations);
    BMML.app.loadPixels();
    int pd = max(1, BMML.app.pixelWidth / BMML.app.width);
    int pw = BMML.app.pixelWidth;
    for (int k = 0; k < min(rows, 12); k++) {
      if (row >= 128) {
        row = 0;
        passes++;
        a = na;
        b = nb;
        cx0 = julia ? 0 : a;
        cy0 = julia ? 0 : b;
      }
      // the first pass coarse to fine (every 8th row drawn 8 tall, then 4th, 2nd, the rest), later
      // passes top to bottom
      int y = row, tall = 1;
      if (passes > 0) { y = row; tall = 1; }
      else if (row < 16) { y = row * 8; tall = 8; }
      else if (row < 32) { y = (row - 16) * 8 + 4; tall = 4; }
      else if (row < 64) { y = (row - 32) * 4 + 2; tall = 2; }
      else { y = (row - 64) * 2 + 1; tall = 1; }
      float ci = cy0 - h / 2 + h * y / 127.0f;
      for (int x = 0; x < 240; x++) {
        float cr = cx0 - w / 2 + w * x / 239.0f;
        float zr = julia ? cr : 0;
        float zi = julia ? ci : 0;
        float kr = julia ? a : cr;
        float ki = julia ? b : ci;
        int n = 0;
        while (n < N && zr * zr + zi * zi < 4) {
          float t = zr * zr - zi * zi + kr;
          zi = 2 * zr * zi + ki;
          zr = t;
          n++;
        }
        int v = n >= N ? 255 : (int)(255 * pow(max(0, n - 2) / (float) (N - 2), 0.6f));
        for (int yy = y; yy < min(128, y + tall); yy++) {
          boolean ink;
          if (n >= N) ink = true;
          else if (bands) ink = n % 2 == 1;
          else ink = BMML._ink(v, x, yy);
          int c = ink ? -16777216 : -1;
          for (int dy = 0; dy < pd; dy++) {
            for (int dx = 0; dx < pd; dx++) BMML.app.pixels[(yy * pd + dy) * pw + x * pd + dx] = c;
          }
        }
      }
      row++;
    }
    BMML.app.updatePixels();
  }
}

