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

/**
 * BitMapMathLib - the drawing maths behind the Nostalgia art pieces.
 *
 * <p>One per sketch, before anything else:
 *
 * <pre>import bmml.*;
 * import static bmml.BMML.*;
 * BMML bmml;
 * void setup() { size(240, 128); bmml = new BMML(this); }</pre>
 *
 * <p>Then the reference in reference/BMML-reference.txt applies as written. See README.md.
 */
public class BMML {

  /** the sketch every call draws into; set by the constructor */
  public static PApplet app;

  public BMML(PApplet sketch) {
    app = sketch;
  }

public static float ease(float t) {
  t = constrain(t, 0, 1);
  return t * t * (3 - 2 * t);
}

public static float wave(float period) {
  return 0.5f - 0.5f * cos(TWO_PI * app.frameCount / period);
}

public static float loopT(float period) {
  return (app.frameCount % period) / period;
}

public static float timeNoise(float x, float y, float speed) {
  return app.noise(x, y, app.frameCount * speed);
}

public static float flowAngle(float x, float y, float scale, float speed) {
  return app.noise(x * scale, y * scale, app.frameCount * speed) * TWO_PI * 2;
}

public static float cellRandom(int i, int j, int seed) {
  return _hash(i, j, seed) / 16777216.0f;
}

public static int _hash(int i, int j, int seed) {
  int h = i * 374761393 + j * 668265263 + seed * 1274126177;
  h = (h ^ (h >>> 13)) * 1274126177;
  h = h ^ (h >>> 16);
  return h & 16777215;
}

// ------------------------------------------------------------------ numbers and layout by relationship
public static final float PHI = (1 + sqrt(5)) / 2;
public static final float GOLDEN_ANGLE = TWO_PI / (PHI * PHI);
public static final float E = exp(1);
public static final float SQRT2 = sqrt(2);
public static final float CX = 120;
public static final float CY = 64;

public static float xAt(float a, float b) {
  return 240 * a / b;
}

public static float yAt(float a, float b) {
  return 128 * a / b;
}

public static int _clkSec = -1;
public static int _clkMs = 0;

public static float clockT(float seconds) {
  int s = second();
  if (s != _clkSec) {
    _clkSec = s;
    _clkMs = app.millis();
  }
  float frac = min(0.999f, (app.millis() - _clkMs) / 1000.0f);
  float whole = (hour() * 3600 + minute() * 60 + s) % seconds;
  return ((whole + frac) % seconds) / seconds;
}

public static float phylloX(int i, float cx, float spacing) {
  return cx + spacing * sqrt(i) * cos(i * GOLDEN_ANGLE);
}

public static float phylloY(int i, float cy, float spacing) {
  return cy - spacing * sqrt(i) * sin(i * GOLDEN_ANGLE);
}

// ------------------------------------------------------------------ plots and grids
public static void plot(float x0, float x1, float y0, float y1) {
  app.pushStyle();
  app.noFill();
  java.lang.reflect.Method fy0 = _callback("fy");
  if (fy0 == null) { app.popStyle(); return; }
  boolean on = false;
  float py = 0;
  for (int i = 0; i < 240; i++) {
    float v = _call1(fy0, x0 + (x1 - x0) * i / 239.0f);
    float y = 127 - (v - y0) / (y1 - y0) * 127;
    boolean ok = v == v && y > -400 && y < 528;
    if (on && (!ok || abs(y - py) > 128)) {
      app.endShape();
      on = false;
    }
    if (ok) {
      if (!on) {
        app.beginShape();
        on = true;
      }
      app.vertex(i, y);
    }
    py = y;
  }
  if (on) app.endShape();
  app.popStyle();
}

public static void polarPlot(float cx, float cy, float scale, float turns) {
  int n = constrain((int)(180 * turns), 8, 3000);
  app.pushStyle();
  app.noFill();
  java.lang.reflect.Method fr0 = _callback("fr");
  if (fr0 == null) { app.popStyle(); return; }
  app.beginShape();
  for (int i = 0; i <= n; i++) {
    float a = TWO_PI * turns * i / n;
    float r = _call1(fr0, a) * scale;
    app.vertex(cx + r * cos(a), cy - r * sin(a));
  }
  app.endShape();
  app.popStyle();
}

public static void polarShape(float cx, float cy, float scale) {
  java.lang.reflect.Method fr0 = _callback("fr");
  if (fr0 == null) return;
  app.beginShape();
  for (int i = 0; i < 360; i++) {
    float a = TWO_PI * i / 360;
    float r = _call1(fr0, a) * scale;
    app.vertex(cx + r * cos(a), cy - r * sin(a));
  }
  app.endShape(CLOSE);
}

public static void grid(float step) {
  if (step < 2) step = 2;
  for (float x = 0; x < 240; x += step) app.line(x, 0, x, 128);
  for (float y = 0; y < 128; y += step) app.line(0, y, 240, y);
}

public static void polarGrid(float cx, float cy, float rmax, int rings, int spokes) {
  app.pushStyle();
  app.noFill();
  for (int k = 1; k <= rings; k++) app.circle(cx, cy, 2 * rmax * k / rings);
  for (int k = 0; k < spokes; k++) {
    float a = TWO_PI * k / spokes;
    app.line(cx, cy, cx + rmax * cos(a), cy - rmax * sin(a));
  }
  app.popStyle();
}

// ------------------------------------------------------------------ parametric curves
public static void lissajous(float cx, float cy, float rx, float ry, float a, float b, float phase, float p) {
  int n = constrain((int)(160 + 60 * (abs(a) + abs(b))), 100, 1500);
  int m = (int)(n * constrain(p, 0, 1));
  app.pushStyle();
  app.noFill();
  app.beginShape();
  for (int i = 0; i <= m; i++) {
    float t = TWO_PI * i / n;
    app.vertex(cx + rx * sin(a * t + phase), cy - ry * sin(b * t));
  }
  app.endShape();
  app.popStyle();
}

public static void rose(float cx, float cy, float r, float k, float p) {
  float period = TWO_PI * 16;
  for (int d = 1; d <= 16; d++) {
    float kd = k * d;
    if (abs(kd - round(kd)) < 0.001f) {
      int nn = abs(round(kd));
      period = (nn * d) % 2 == 1 ? PI * d : TWO_PI * d;
      break;
    }
  }
  int n = constrain((int)(period * 40), 60, 2500);
  int m = (int)(n * constrain(p, 0, 1));
  app.pushStyle();
  app.noFill();
  app.beginShape();
  for (int i = 0; i <= m; i++) {
    float t = period * i / n;
    float q = r * cos(k * t);
    app.vertex(cx + q * cos(t), cy - q * sin(t));
  }
  app.endShape();
  app.popStyle();
}

public static void spiro(float cx, float cy, float R, float r, float d, float p) {
  int a = max(1, abs(round(R)));
  int b = max(1, abs(round(r)));
  while (b != 0) {
    int c = a % b;
    a = b;
    b = c;
  }
  float period = TWO_PI * max(1, abs(round(r))) / a;
  int n = constrain((int)(period * 30), 60, 3000);
  int m = (int)(n * constrain(p, 0, 1));
  app.pushStyle();
  app.noFill();
  app.beginShape();
  for (int i = 0; i <= m; i++) {
    float t = period * i / n;
    float x = (R - r) * cos(t) + d * cos((R - r) / r * t);
    float y = (R - r) * sin(t) - d * sin((R - r) / r * t);
    app.vertex(cx + x, cy - y);
  }
  app.endShape();
  app.popStyle();
}

// ------------------------------------------------------------------ turtle paths (L-systems, space-filling curves)

public static _Path _turtle(String axiom, String rules, float angleDeg, int iterations) {
  // rules "A=... B=...", separated by spaces, commas or semicolons (parsed by hand: the panel VM
  // has no splitTokens)
  char[] from = new char[rules.length() + 1];
  String[] rep = new String[rules.length() + 1];
  int nr = 0;
  int i0 = 0;
  for (int i = 0; i <= rules.length(); i++) {
    char c = i < rules.length() ? rules.charAt(i) : ' ';
    if (c == ' ' || c == ',' || c == ';') {
      if (i > i0) {
        String r = rules.substring(i0, i);
        int eq = r.indexOf('=');
        from[nr] = r.charAt(0);
        rep[nr] = eq < 0 ? "" : r.substring(eq + 1);
        nr++;
      }
      i0 = i + 1;
    }
  }
  char[] s = new char[axiom.length()];
  for (int i = 0; i < s.length; i++) s[i] = axiom.charAt(i);
  for (int it = 0; it < iterations; it++) {
    int len = 0;
    for (int i = 0; i < s.length; i++) {
      int add = 1;
      for (int k = 0; k < nr; k++) {
        if (from[k] == s[i]) {
          add = rep[k].length();
          break;
        }
      }
      len += add;
    }
    if (len > 60000) break;
    char[] t = new char[len];
    int j = 0;
    for (int i = 0; i < s.length; i++) {
      int hit = -1;
      for (int k = 0; k < nr; k++) {
        if (from[k] == s[i]) {
          hit = k;
          break;
        }
      }
      if (hit < 0) {
        t[j] = s[i];
        j++;
      } else {
        String rp = rep[hit];
        for (int q = 0; q < rp.length(); q++) {
          t[j] = rp.charAt(q);
          j++;
        }
      }
    }
    s = t;
  }
  int moves = 1;
  int depth = 1;
  for (int i = 0; i < s.length; i++) {
    char c = s[i];
    if (c == 'F' || c == 'G' || c == 'f' || c == ']') moves++;
    if (c == '[') depth++;
  }
  _Path path = new _Path(min(moves, 40000));
  float[] sx = new float[depth];
  float[] sy = new float[depth];
  float[] sa = new float[depth];
  int sp = 0;
  float x = 0, y = 0, a = -HALF_PI;
  float turn = radians(angleDeg);
  path.add(0, 0, false);
  for (int i = 0; i < s.length; i++) {
    char c = s[i];
    if (c == 'F' || c == 'G' || c == 'f') {
      x += cos(a);
      y += sin(a);
      path.add(x, y, c != 'f');
    } else if (c == '+') {
      a -= turn;
    } else if (c == '-') {
      a += turn;
    } else if (c == '|') {
      a += PI;
    } else if (c == '[') {
      sx[sp] = x; sy[sp] = y; sa[sp] = a;
      sp++;
    } else if (c == ']' && sp > 0) {
      sp--;
      x = sx[sp]; y = sy[sp]; a = sa[sp];
      path.add(x, y, false);
    }
  }
  return path;
}


public static String _scKey = "";
public static _Path _scPath = null;

public static void spaceCurve(String kind, float x, float y, float w, float h, int order, float p) {
  String key = kind + order;
  if (_scPath == null || !key.equals(_scKey)) {
    _scKey = key;
    if (kind.equals("hilbert")) {
      _scPath = _turtle("A", "A=+BF-AFA-FB+ B=-AF+BFB+FA-", 90, constrain(order, 1, 7));
    } else if (kind.equals("peano")) {
      _scPath = _turtle("L", "L=LFRFL-F-RFLFR+F+LFRFL R=RFLFR+F+LFRFL-F-RFLFR", 90, constrain(order, 1, 4));
    } else if (kind.equals("dragon")) {
      _scPath = _turtle("FX", "X=X+YF+ Y=-FX-Y", 90, constrain(order, 1, 14));
    } else if (kind.equals("koch")) {
      _scPath = _turtle("F--F--F", "F=F+F--F+F", 60, constrain(order, 0, 6));
    } else if (kind.equals("gosper")) {
      _scPath = _turtle("F", "F=F-G--G+F++FF+G- G=+F-GG--G-F++F+G", 60, constrain(order, 1, 4));
    } else {
      int o = constrain(order, 1, 7);
      int side = 1 << o;
      _scPath = new _Path(side * side);
      for (int i = 0; i < side * side; i++) {
        int zx = 0, zy = 0;
        for (int bit = 0; bit < o; bit++) {
          zx |= ((i >> (2 * bit)) & 1) << bit;
          zy |= ((i >> (2 * bit + 1)) & 1) << bit;
        }
        _scPath.add(zx, zy, i > 0);
      }
    }
  }
  _scPath.draw(x, y, w, h, p);
}

// ------------------------------------------------------------------ 1-bit patterns (shading)
public static int[] _tile = null;
public static int _tw = 1, _th = 1;
public static String[] _tkeys = new String[12];
public static int[][] _tiles = new int[12][];
public static int[] _tws = new int[12];
public static int[] _ths = new int[12];
public static int _tnext = 0;
public static int _psx = 0, _psy = 0;
public static int[] _BAYER = {0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5};

// the threshold tile of a pattern (0..255 per pixel: ink where darkness > it), 12 kept
public static void _tileFor(String kind, float scale) {
  int P = max(2, round(scale));
  String key = kind + P;
  for (int c = 0; c < 12; c++) {
    if (key.equals(_tkeys[c])) {
      _tile = _tiles[c];
      _tw = _tws[c];
      _th = _ths[c];
      return;
    }
  }
  int k = max(1, round(scale / 4));
  if (kind.equals("flat")) {
    _tw = 4 * k; _th = 4 * k;
  } else if (kind.equals("stipple")) {
    _tw = 64; _th = 64;
  } else if (kind.equals("checker") || kind.equals("weave")) {
    _tw = 2 * P; _th = 2 * P;
  } else if (kind.equals("wavy")) {
    _tw = 4 * P; _th = P;
  } else {
    _tw = P; _th = P;
  }
  _tile = new int[_tw * _th];
  for (int y = 0; y < _th; y++) {
    for (int x = 0; x < _tw; x++) {
      int t = 128;
      int b = _BAYER[(y % 4) * 4 + (x % 4)] * 16 + 8;
      if (kind.equals("flat")) {
        t = _BAYER[((y / k) % 4) * 4 + (x / k) % 4] * 16 + 8;
      } else if (kind.equals("stipple")) {
        int kk = max(1, round(scale / 3));
        t = _hash(x / kk, y / kk, 7) & 255;
      } else if (kind.equals("hatch")) {
        t = ((x + y) % P) * 256 / P;
      } else if (kind.equals("cross")) {
        t = min(((x + y) % P) * 256 / P, ((x - y + 64 * P) % P) * 256 / P);
      } else if (kind.equals("lines")) {
        t = (y % P) * 256 / P;
      } else if (kind.equals("vlines")) {
        t = (x % P) * 256 / P;
      } else if (kind.equals("dots")) {
        float d = dist(x + 0.5f, y + 0.5f, P / 2.0f, P / 2.0f) / (P * 0.7072f);
        t = (int)(d * 255);
      } else if (kind.equals("checker")) {
        t = ((x / P + y / P) % 2 == 0 ? 0 : 128) + b / 2;
      } else if (kind.equals("weave")) {
        int q = max(2, P / 3);
        t = (x / P + y / P) % 2 == 0 ? (y % q) * 256 / q : (x % q) * 256 / q;
      } else if (kind.equals("wavy")) {
        int yy = y + round(P * 0.3f * sin(TWO_PI * x / (4.0f * P)));
        t = ((yy % P + P) % P) * 256 / P;
      } else {
        t = b;
      }
      _tile[y * _tw + x] = t;
    }
  }
  _tkeys[_tnext] = key;
  _tiles[_tnext] = _tile;
  _tws[_tnext] = _tw;
  _ths[_tnext] = _th;
  _tnext = (_tnext + 1) % 12;
}

// ink for darkness v (0 paper .. 255 ink) at pixel (x, y) in the current pattern tile
public static boolean _ink(int v, int x, int y) {
  return v > _tile[((y + _psy) % _th) * _tw + (x + _psx) % _tw];
}

public static void _prepShift() {
  _psx = ((_psx % _tw) + _tw) % _tw;
  _psy = ((_psy % _th) + _th) % _th;
}

public static void patternShift(float dx, float dy) {
  _psx = round(dx);
  _psy = round(dy);
}

public static void pattern(String kind, float scale) {
  _patternPass(kind, scale, 0, 0, 240, 128);
}

public static void patternRect(String kind, float scale, float x, float y, float w, float h) {
  _patternPass(kind, scale, (int)(x), (int)(y), (int)(x + w), (int)(y + h));
}

public static void _patternPass(String kind, float scale, int x0, int y0, int x1, int y1) {
  _tileFor(kind, scale);
  _prepShift();
  x0 = max(0, x0); y0 = max(0, y0);
  x1 = min(240, x1); y1 = min(128, y1);
  app.loadPixels();
  int[] t = _tile;
  int tw = _tw;
  int pd = max(1, app.pixelWidth / app.width);
  int pw = app.pixelWidth;
  for (int y = y0; y < y1; y++) {
    int r = ((y + _psy) % _th) * tw;
    for (int x = x0; x < x1; x++) {
      int g = app.pixels[y * pd * pw + x * pd] & 255;
      if (g > 0 && g < 255) {
        int c = 255 - g > t[r + (x + _psx) % tw] ? -16777216 : -1;
        for (int dy = 0; dy < pd; dy++) {
          for (int dx = 0; dx < pd; dx++) app.pixels[(y * pd + dy) * pw + x * pd + dx] = c;
        }
      }
    }
  }
  app.updatePixels();
}

public static void shadeField(int cell) {
  cell = max(2, cell);
  app.pushStyle();
  app.noStroke();
  java.lang.reflect.Method sh = _callback("shade");
  if (sh == null) { app.popStyle(); return; }
  for (int y = 0; y < 128; y += cell) {
    for (int x = 0; x < 240; x += cell) {
      float v = constrain(_call2(sh, x + cell / 2.0f, y + cell / 2.0f), 0, 1);
      if (v > 0.004f) {
        app.fill(255 - 255 * v);
        app.rect(x, y, cell, cell);
      }
    }
  }
  app.popStyle();
}

public static void fade(float amount) {
  app.pushStyle();
  app.pushMatrix();
  app.resetMatrix();
  app.noStroke();
  app.fill(255, max(26, amount));
  app.rect(0, 0, 240, 128);
  app.popMatrix();
  app.popStyle();
}

// ------------------------------------------------------------------ point clouds: IFS / chaos game, strange attractors

// ------------------------------------------------------------------ cellular automata

public static void _runs(int[] cells, int cols, int rows, int cell, int gap) {
  app.pushStyle();
  app.noStroke();
  if (gap > 0) {
    for (int k = 0; k < cols * rows; k++) {
      if (cells[k] != 0) app.rect((k % cols) * cell + gap / 2, (k / cols) * cell + gap / 2, cell - gap, cell - gap);
    }
    app.popStyle();
    return;
  }
  for (int j = 0; j < rows; j++) {
    int base = j * cols;
    int i = 0;
    while (i < cols) {
      if (cells[base + i] != 0) {
        int s = i;
        while (i < cols && cells[base + i] != 0) i++;
        app.rect(s * cell, j * cell, (i - s) * cell, cell);
      } else {
        i++;
      }
    }
  }
  app.popStyle();
}


// ------------------------------------------------------------------ escape-time fractals

// ------------------------------------------------------------------ Voronoi / Delaunay
public static float[] _vx = new float[64 * 32];
public static float[] _vy = new float[64 * 32];
public static int[] _vt = new int[64 * 32];
public static int[] _vn = new int[64];

// each seed's cell (clipped to the frame) into _vx/_vy/_vn; _vt = the neighbour across each edge
public static void _cells(float[] xs, float[] ys) {
  int n = min(64, min(xs.length, ys.length));
  float[] px = new float[40];
  float[] py = new float[40];
  int[] pt = new int[40];
  float[] qx = new float[40];
  float[] qy = new float[40];
  int[] qt = new int[40];
  for (int i = 0; i < n; i++) {
    px[0] = 0; py[0] = 0; px[1] = 240; py[1] = 0; px[2] = 240; py[2] = 128; px[3] = 0; py[3] = 128;
    pt[0] = -1; pt[1] = -1; pt[2] = -1; pt[3] = -1;
    int m = 4;
    for (int j = 0; j < n && m > 0; j++) {
      if (j == i) continue;
      float nx = xs[j] - xs[i], ny = ys[j] - ys[i];
      if (nx == 0 && ny == 0) continue;
      float c = (nx * (xs[i] + xs[j]) + ny * (ys[i] + ys[j])) / 2;
      int q = 0;
      for (int k = 0; k < m; k++) {
        int k2 = (k + 1) % m;
        float dp = nx * px[k] + ny * py[k] - c;
        float dq = nx * px[k2] + ny * py[k2] - c;
        boolean inP = dp <= 0, inQ = dq <= 0;
        if (inP && q < 39) {
          qx[q] = px[k]; qy[q] = py[k]; qt[q] = pt[k];
          q++;
        }
        if (inP != inQ && q < 39) {
          float u = dp / (dp - dq);
          qx[q] = px[k] + (px[k2] - px[k]) * u;
          qy[q] = py[k] + (py[k2] - py[k]) * u;
          qt[q] = inP ? j : pt[k];
          q++;
        }
      }
      float[] sx = px; px = qx; qx = sx;
      float[] sy = py; py = qy; qy = sy;
      int[] st = pt; pt = qt; qt = st;
      m = q;
    }
    m = min(m, 32);
    _vn[i] = m;
    for (int k = 0; k < m; k++) {
      _vx[i * 32 + k] = px[k];
      _vy[i * 32 + k] = py[k];
      _vt[i * 32 + k] = pt[k];
    }
  }
}

public static void voronoi(float[] xs, float[] ys, int rings) {
  _cells(xs, ys);
  int n = min(64, min(xs.length, ys.length));
  app.pushStyle();
  for (int i = 0; i < n; i++) {
    int m = _vn[i];
    for (int k = 0; k < max(1, rings); k++) {
      if (rings > 1) {
        app.fill(255 - 255.0f * k / rings);
        if (k == 1) app.noStroke();
      }
      float s = 1 - k / (float) max(1, rings);
      app.beginShape();
      for (int e = 0; e < m; e++) {
        app.vertex(xs[i] + (_vx[i * 32 + e] - xs[i]) * s, ys[i] + (_vy[i * 32 + e] - ys[i]) * s);
      }
      app.endShape(CLOSE);
    }
    app.popStyle();
    app.pushStyle();
  }
  app.popStyle();
}

public static void delaunay(float[] xs, float[] ys) {
  _cells(xs, ys);
  int n = min(64, min(xs.length, ys.length));
  for (int i = 0; i < n; i++) {
    for (int e = 0; e < _vn[i]; e++) {
      int j = _vt[i * 32 + e];
      if (j > i) app.line(xs[i], ys[i], xs[j], ys[j]);
    }
  }
}

// ------------------------------------------------------------------ circle packing, Truchet tiles

public static void truchet(float x, float y, float w, float h, float cell, String kind, float t) {
  cell = max(4, cell);
  boolean arcs = kind.equals("arcs");
  boolean tri = kind.equals("tri");
  app.pushStyle();
  if (arcs) app.noFill();
  for (int j = 0; j * cell < h; j++) {
    for (int i = 0; i * cell < w; i++) {
      float x0 = x + i * cell, y0 = y + j * cell;
      boolean flip = app.noise(i * 0.37f, j * 0.37f, t) > 0.5f;
      if (arcs) {
        if (flip) {
          app.arc(x0, y0, cell, cell, 0, HALF_PI);
          app.arc(x0 + cell, y0 + cell, cell, cell, PI, PI + HALF_PI);
        } else {
          app.arc(x0 + cell, y0, cell, cell, HALF_PI, PI);
          app.arc(x0, y0 + cell, cell, cell, PI + HALF_PI, TWO_PI);
        }
      } else if (tri) {
        if (flip) app.triangle(x0, y0, x0 + cell, y0, x0, y0 + cell);
        else app.triangle(x0 + cell, y0, x0 + cell, y0 + cell, x0, y0 + cell);
      } else {
        if (flip) app.line(x0, y0, x0 + cell, y0 + cell);
        else app.line(x0 + cell, y0, x0, y0 + cell);
      }
    }
  }
  app.popStyle();
}

// ------------------------------------------------------------------ words as image
public static void textCircle(String s, float cx, float cy, float r, float start) {
  app.pushStyle();
  app.textAlign(CENTER);
  float a = start;
  for (int i = 0; i < s.length(); i++) {
    String ch = s.substring(i, i + 1);
    float cw = app.textWidth(ch);
    a += cw / 2 / r;
    app.pushMatrix();
    app.translate(cx + r * cos(a), cy + r * sin(a));
    app.rotate(a + HALF_PI);
    app.text(ch, 0, 0);
    app.popMatrix();
    a += cw / 2 / r;
  }
  app.popStyle();
}

public static void textWave(String s, float x, float y, float amp, float phase) {
  app.pushStyle();
  app.textAlign(LEFT);
  for (int i = 0; i < s.length(); i++) {
    String ch = s.substring(i, i + 1);
    app.text(ch, x, y + amp * sin(phase + i * 0.6f));
    x += app.textWidth(ch);
  }
  app.popStyle();
}

public static void textFit(String s, float x, float y, float w, float h) {
  if (s.length() == 0) return;
  app.pushStyle();
  app.textAlign(LEFT);
  app.textSize(20);
  float size = min(20 * w / max(1, app.textWidth(s)), h);
  app.textSize(max(4, size));
  app.text(s, x + (w - app.textWidth(s)) / 2, y + (h + app.textAscent() - app.textDescent()) / 2);
  app.popStyle();
}

public static void textGrid(String s, float x, float y, float w, float h, float size) {
  if (s.length() == 0) return;
  app.pushStyle();
  app.textAlign(LEFT);
  app.textSize(max(4, size));
  String word = s + " ";
  float ww = app.textWidth(word);
  int row = 0;
  for (float yy = y + size; yy <= y + h; yy += size * 1.1f) {
    float xx = x - (row % 2) * ww / 2;
    while (xx + ww <= x + w + app.textWidth(" ")) {
      if (xx >= x) app.text(s, xx, yy);
      xx += ww;
    }
    row++;
  }
  app.popStyle();
}

// ------------------------------------------------------------------ the sketch's own functions
// A function the sketch may or may not define cannot be called by name in a library tab, so fy, fr and
// shade are found on the sketch once, by reflection, and called through the Method afterwards. A
// missing one makes the drawing that needs it a no-op instead of a compile error.
public static java.lang.reflect.Method _mFy = null, _mFr = null, _mShade = null;
public static boolean _tFy = false, _tFr = false, _tShade = false;

public static java.lang.reflect.Method _find(String name, int args) {
  try {
    if (args == 2) return app.getClass().getMethod(name, new Class[] {float.class, float.class});
    return app.getClass().getMethod(name, new Class[] {float.class});
  } catch (Exception e) {
    return null;
  }
}

public static java.lang.reflect.Method _callback(String name) {
  if (name.equals("fy")) {
    if (!_tFy) { _tFy = true; _mFy = _find(name, 1); }
    return _mFy;
  }
  if (name.equals("fr")) {
    if (!_tFr) { _tFr = true; _mFr = _find(name, 1); }
    return _mFr;
  }
  if (name.equals("shade")) {
    if (!_tShade) { _tShade = true; _mShade = _find(name, 2); }
    return _mShade;
  }
  return null;
}

// true when the sketch defines that function (for a sketch that wants to know before drawing)
public static boolean hasFunction(String name) {
  return _callback(name) != null;
}

public static float _call1(java.lang.reflect.Method m, float a) {
  try {
    return ((Number) m.invoke(app, new Object[] {Float.valueOf(a)})).floatValue();
  } catch (Exception e) {
    return 0;
  }
}

public static float _call2(java.lang.reflect.Method m, float a, float b) {
  try {
    return ((Number) m.invoke(app, new Object[] {Float.valueOf(a), Float.valueOf(b)})).floatValue();
  } catch (Exception e) {
    return 0;
  }
}

// ------------------------------------------------------------------ textures (the hub's extension)
// Stock Processing has no texture()/strokeTexture()/textureSeed() and no textured background(): it
// fills a shape with one flat colour. These shims keep such a sketch compiling and give it a close
// grey: texture(kind, scale) is remembered and applied over the drawn frame by applyTexture(), or - if
// you would rather it happen on its own - call pattern(kind, scale) at the end of draw(). The hub
// tiles a texture inside every shape; here it is one pass over the whole frame, so overlapping shapes
// come out differently. Everything else (kinds, scales) is the same.
public static String _texKind = null;
public static float _texScale = 4;
public static String _strTexKind = null;
public static float _strTexScale = 4;
public static int _texSeed = 0;

public static void texture(String kind, float scale) {
  _texKind = kind;
  _texScale = scale;
}

public static void noTexture() {
  _texKind = null;
}

public static void strokeTexture(String kind, float scale) {
  _strTexKind = kind;
  _strTexScale = scale;
}

public static void noStrokeTexture() {
  _strTexKind = null;
}

public static void textureSeed(int seed) {
  _texSeed = seed;
  app.randomSeed(seed);
  app.noiseSeed(seed);
}

// the texture() asked for over everything drawn so far (see the note above)
public static void applyTexture() {
  if (_texKind != null) pattern(_texKind, _texScale);
}

public static boolean hasTexture() {
  return _texKind != null;
}

// background(g, kind[, scale]) and background(g1, g2, "vgradient"): the hub's textured background
public static void background(float g, String kind) {
  app.background(g);
  pattern(kind, 6);
}

public static void background(float g, String kind, float scale) {
  app.background(g);
  String k = kind;
  float s = scale;
  if (k.equals("noise") || k.equals("cloud")) {
    // these two are scales of grey already; a flat fill then a pattern reads closer than noise alone
    pattern("stipple", max(2, s));
  } else {
    pattern(k.equals("radial") || k.equals("halftone") ? "dots" : k, s);
  }
}

public static void background(float g1, float g2, String kind) {
  for (int y = 0; y < 128; y++) {
    float t = y / 127.0f;
    app.stroke(255 - (255 - g1) * (1 - t) - (255 - g2) * t);
    app.line(0, y, 240, y);
  }
  if (!kind.equals("vgradient")) pattern(kind, 6);
}
}
