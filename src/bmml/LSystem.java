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

public class LSystem {
  public String axiom;
  public String rules;
  public float angle;
  public int iterations;
  public _Path path = null;

  public LSystem(String axiom, String rules, float angleDeg, int iterations) {
    this.axiom = axiom;
    this.rules = rules;
    this.angle = angleDeg;
    this.iterations = iterations;
  }

  public void draw(float x, float y, float w, float h, float p) {
    if (path == null) path = BMML._turtle(axiom, rules, angle, iterations);
    path.draw(x, y, w, h, p);
  }
}

