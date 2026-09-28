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

public class Automaton {
  int rule, cell, cols, rows;
  public int[] cells;
  public int count = 0;
  public boolean page = false;     // true: start again from the top when full (instead of scrolling)
  public int gap = 0;              // > 0: each cell a square with this many pixels of paper around it

  public Automaton(int rule, int cell) {
    this.rule = rule;
    this.cell = max(2, cell);
    cols = 240 / this.cell;
    rows = 128 / this.cell;
    cells = new int[cols * rows];
    cells[cols / 2] = 1;
    count = 1;
  }

  public void fill(float density) {
    for (int i = 0; i < cols; i++) cells[i] = BMML.app.random(1) < density ? 1 : 0;
    count = 1;
  }

  public void step() {
    int last = min(count, rows) - 1;
    int base = last * cols;
    int[] next = new int[cols];
    int alive = 0;
    for (int i = 0; i < cols; i++) {
      int l = cells[base + (i + cols - 1) % cols];
      int m = cells[base + i];
      int r = cells[base + (i + 1) % cols];
      next[i] = (rule >> (l * 4 + m * 2 + r)) & 1;
      alive += next[i];
    }
    if (alive == 0 || alive == cols) {
      for (int i = 0; i < cols; i++) next[i] = BMML.app.random(1) < 0.5f ? 1 : 0;
    }
    if (count >= rows) {
      if (page) {
        for (int k = cols; k < cells.length; k++) cells[k] = 0;
        arrayCopy(next, 0, cells, 0, cols);
        count = 1;
        return;
      }
      arrayCopy(cells, cols, cells, 0, cols * (rows - 1));
      count = rows - 1;
    }
    arrayCopy(next, 0, cells, count * cols, cols);
    count++;
  }

  public void set(int i) {
    int row = max(0, min(count, rows) - 1);
    cells[row * cols + ((i % cols) + cols) % cols] = 1;
  }

  public void draw() {
    BMML._runs(cells, cols, min(count, rows), cell, gap);
  }
}

