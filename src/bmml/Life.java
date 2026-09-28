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

public class Life {
  int cell, cols, rows;
  public int born = 0, survive = 0;
  public int[] cells;
  public int[] next;
  public boolean started = false;
  public int lastPop = -1;
  public int same = 0;
  public boolean reseed = true;    // false: never drop new cells in when it dies out or stalls
  public int gap = 0;              // > 0: each cell a square with this many pixels of paper around it

  public Life(String rule, int cell) {
    this.cell = max(2, cell);
    cols = 240 / this.cell;
    rows = 128 / this.cell;
    cells = new int[cols * rows];
    next = new int[cols * rows];
    String r = rule.toUpperCase();
    int mode = 0;
    for (int i = 0; i < r.length(); i++) {
      char ch = r.charAt(i);
      if (ch == 'B') mode = 1;
      else if (ch == 'S') mode = 2;
      else if (ch >= '0' && ch <= '8') {
        if (mode == 1) born |= 1 << (ch - '0');
        if (mode == 2) survive |= 1 << (ch - '0');
      }
    }
  }

  public void fill(float density) {
    for (int k = 0; k < cells.length; k++) cells[k] = BMML.app.random(1) < density ? 1 : 0;
    started = true;
  }

  public void clear() {
    for (int k = 0; k < cells.length; k++) cells[k] = 0;
    started = true;
  }

  public void set(int i, int j, int v) {
    started = true;
    cells[((j % rows + rows) % rows) * cols + (i % cols + cols) % cols] = v != 0 ? 1 : 0;
  }

  public int get(int i, int j) {
    return cells[((j % rows + rows) % rows) * cols + (i % cols + cols) % cols];
  }

  public void step() {
    if (!started) fill(0.3f);
    int pop = 0;
    for (int j = 0; j < rows; j++) {
      int up = ((j + rows - 1) % rows) * cols;
      int mid = j * cols;
      int dn = ((j + 1) % rows) * cols;
      for (int i = 0; i < cols; i++) {
        int l = (i + cols - 1) % cols;
        int r = (i + 1) % cols;
        int n = cells[up + l] + cells[up + i] + cells[up + r] + cells[mid + l] + cells[mid + r]
          + cells[dn + l] + cells[dn + i] + cells[dn + r];
        int v = cells[mid + i] == 1 ? (survive >> n) & 1 : (born >> n) & 1;
        next[mid + i] = v;
        pop += v;
      }
    }
    int[] t = cells;
    cells = next;
    next = t;
    same = pop == lastPop ? same + 1 : 0;
    lastPop = pop;
    if (reseed && (pop < cells.length / 200 || same > 40)) {
      int w = cols / 4, h = rows / 3;
      int x0 = (int)(BMML.app.random(cols - w)), y0 = (int)(BMML.app.random(rows - h));
      for (int j = y0; j < y0 + h; j++) {
        for (int i = x0; i < x0 + w; i++) cells[j * cols + i] = BMML.app.random(1) < 0.35f ? 1 : 0;
      }
      same = 0;
    }
  }

  public void draw() {
    if (!started) fill(0.3f);
    BMML._runs(cells, cols, rows, cell, gap);
  }
}

