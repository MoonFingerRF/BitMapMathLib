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
float ease(float t) {
  t = constrain(t, 0, 1);
  return t * t * (3 - 2 * t);
}

float wave(float period) {
  return 0.5 - 0.5 * cos(TWO_PI * frameCount / period);
}

float loopT(float period) {
  return (frameCount % period) / period;
}

float timeNoise(float x, float y, float speed) {
  return noise(x, y, frameCount * speed);
}

float flowAngle(float x, float y, float scale, float speed) {
  return noise(x * scale, y * scale, frameCount * speed) * TWO_PI * 2;
}

float cellRandom(int i, int j, int seed) {
  return _hash(i, j, seed) / 16777216.0;
}

int _hash(int i, int j, int seed) {
  int h = i * 374761393 + j * 668265263 + seed * 1274126177;
  h = (h ^ (h >>> 13)) * 1274126177;
  h = h ^ (h >>> 16);
  return h & 16777215;
}

// ------------------------------------------------------------------ numbers and layout by relationship
final float PHI = (1 + sqrt(5)) / 2;
final float GOLDEN_ANGLE = TWO_PI / (PHI * PHI);
final float E = exp(1);
final float SQRT2 = sqrt(2);
final float CX = 120;
final float CY = 64;

float xAt(float a, float b) {
  return 240 * a / b;
}

float yAt(float a, float b) {
  return 128 * a / b;
}

int _clkSec = -1;
int _clkMs = 0;

float clockT(float seconds) {
  int s = second();
  if (s != _clkSec) {
    _clkSec = s;
    _clkMs = millis();
  }
  float frac = min(0.999, (millis() - _clkMs) / 1000.0);
  float whole = (hour() * 3600 + minute() * 60 + s) % seconds;
  return ((whole + frac) % seconds) / seconds;
}

float phylloX(int i, float cx, float spacing) {
  return cx + spacing * sqrt(i) * cos(i * GOLDEN_ANGLE);
}

float phylloY(int i, float cy, float spacing) {
  return cy - spacing * sqrt(i) * sin(i * GOLDEN_ANGLE);
}

// ------------------------------------------------------------------ plots and grids
void plot(float x0, float x1, float y0, float y1) {
  pushStyle();
  noFill();
  java.lang.reflect.Method fy0 = _callback("fy");
  if (fy0 == null) { popStyle(); return; }
  boolean on = false;
  float py = 0;
  for (int i = 0; i < 240; i++) {
    float v = _call1(fy0, x0 + (x1 - x0) * i / 239.0);
    float y = 127 - (v - y0) / (y1 - y0) * 127;
    boolean ok = v == v && y > -400 && y < 528;
    if (on && (!ok || abs(y - py) > 128)) {
      endShape();
      on = false;
    }
    if (ok) {
      if (!on) {
        beginShape();
        on = true;
      }
      vertex(i, y);
    }
    py = y;
  }
  if (on) endShape();
  popStyle();
}

void polarPlot(float cx, float cy, float scale, float turns) {
  int n = constrain(int(180 * turns), 8, 3000);
  pushStyle();
  noFill();
  java.lang.reflect.Method fr0 = _callback("fr");
  if (fr0 == null) { popStyle(); return; }
  beginShape();
  for (int i = 0; i <= n; i++) {
    float a = TWO_PI * turns * i / n;
    float r = _call1(fr0, a) * scale;
    vertex(cx + r * cos(a), cy - r * sin(a));
  }
  endShape();
  popStyle();
}

void polarShape(float cx, float cy, float scale) {
  java.lang.reflect.Method fr0 = _callback("fr");
  if (fr0 == null) return;
  beginShape();
  for (int i = 0; i < 360; i++) {
    float a = TWO_PI * i / 360;
    float r = _call1(fr0, a) * scale;
    vertex(cx + r * cos(a), cy - r * sin(a));
  }
  endShape(CLOSE);
}

void grid(float step) {
  if (step < 2) step = 2;
  for (float x = 0; x < 240; x += step) line(x, 0, x, 128);
  for (float y = 0; y < 128; y += step) line(0, y, 240, y);
}

void polarGrid(float cx, float cy, float rmax, int rings, int spokes) {
  pushStyle();
  noFill();
  for (int k = 1; k <= rings; k++) circle(cx, cy, 2 * rmax * k / rings);
  for (int k = 0; k < spokes; k++) {
    float a = TWO_PI * k / spokes;
    line(cx, cy, cx + rmax * cos(a), cy - rmax * sin(a));
  }
  popStyle();
}

// ------------------------------------------------------------------ parametric curves
void lissajous(float cx, float cy, float rx, float ry, float a, float b, float phase, float p) {
  int n = constrain(int(160 + 60 * (abs(a) + abs(b))), 100, 1500);
  int m = int(n * constrain(p, 0, 1));
  pushStyle();
  noFill();
  beginShape();
  for (int i = 0; i <= m; i++) {
    float t = TWO_PI * i / n;
    vertex(cx + rx * sin(a * t + phase), cy - ry * sin(b * t));
  }
  endShape();
  popStyle();
}

void rose(float cx, float cy, float r, float k, float p) {
  float period = TWO_PI * 16;
  for (int d = 1; d <= 16; d++) {
    float kd = k * d;
    if (abs(kd - round(kd)) < 0.001) {
      int nn = abs(round(kd));
      period = (nn * d) % 2 == 1 ? PI * d : TWO_PI * d;
      break;
    }
  }
  int n = constrain(int(period * 40), 60, 2500);
  int m = int(n * constrain(p, 0, 1));
  pushStyle();
  noFill();
  beginShape();
  for (int i = 0; i <= m; i++) {
    float t = period * i / n;
    float q = r * cos(k * t);
    vertex(cx + q * cos(t), cy - q * sin(t));
  }
  endShape();
  popStyle();
}

void spiro(float cx, float cy, float R, float r, float d, float p) {
  int a = max(1, abs(round(R)));
  int b = max(1, abs(round(r)));
  while (b != 0) {
    int c = a % b;
    a = b;
    b = c;
  }
  float period = TWO_PI * max(1, abs(round(r))) / a;
  int n = constrain(int(period * 30), 60, 3000);
  int m = int(n * constrain(p, 0, 1));
  pushStyle();
  noFill();
  beginShape();
  for (int i = 0; i <= m; i++) {
    float t = period * i / n;
    float x = (R - r) * cos(t) + d * cos((R - r) / r * t);
    float y = (R - r) * sin(t) - d * sin((R - r) / r * t);
    vertex(cx + x, cy - y);
  }
  endShape();
  popStyle();
}

// ------------------------------------------------------------------ turtle paths (L-systems, space-filling curves)
class _Path {
  float[] xs;
  float[] ys;
  boolean[] pen;
  int n = 0;
  float x0 = 0, y0 = 0, x1 = 0, y1 = 0;

  _Path(int cap) {
    xs = new float[cap];
    ys = new float[cap];
    pen = new boolean[cap];
  }

  void add(float x, float y, boolean down) {
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

  void draw(float bx, float by, float bw, float bh, float p) {
    float sw = max(x1 - x0, 0.0001);
    float sh = max(y1 - y0, 0.0001);
    float s = min(bw / sw, bh / sh);
    float ox = bx + (bw - sw * s) / 2 - x0 * s;
    float oy = by + (bh - sh * s) / 2 - y0 * s;
    int m = round((n - 1) * constrain(p, 0, 1));
    pushStyle();
    noFill();
    boolean on = false;
    int count = 0;
    for (int i = 1; i <= m && i < n; i++) {
      if (pen[i]) {
        if (!on || count > 8000) {
          if (on) endShape();
          beginShape();
          vertex(ox + xs[i - 1] * s, oy + ys[i - 1] * s);
          on = true;
          count = 0;
        }
        vertex(ox + xs[i] * s, oy + ys[i] * s);
        count++;
      } else if (on) {
        endShape();
        on = false;
      }
    }
    if (on) endShape();
    popStyle();
  }
}

_Path _turtle(String axiom, String rules, float angleDeg, int iterations) {
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

class LSystem {
  String axiom;
  String rules;
  float angle;
  int iterations;
  _Path path = null;

  LSystem(String axiom, String rules, float angleDeg, int iterations) {
    this.axiom = axiom;
    this.rules = rules;
    this.angle = angleDeg;
    this.iterations = iterations;
  }

  void draw(float x, float y, float w, float h, float p) {
    if (path == null) path = _turtle(axiom, rules, angle, iterations);
    path.draw(x, y, w, h, p);
  }
}

String _scKey = "";
_Path _scPath = null;

void spaceCurve(String kind, float x, float y, float w, float h, int order, float p) {
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
int[] _tile = null;
int _tw = 1, _th = 1;
String[] _tkeys = new String[12];
int[][] _tiles = new int[12][];
int[] _tws = new int[12];
int[] _ths = new int[12];
int _tnext = 0;
int _psx = 0, _psy = 0;
int[] _BAYER = {0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5};

// the threshold tile of a pattern (0..255 per pixel: ink where darkness > it), 12 kept
void _tileFor(String kind, float scale) {
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
        float d = dist(x + 0.5, y + 0.5, P / 2.0, P / 2.0) / (P * 0.7072);
        t = int(d * 255);
      } else if (kind.equals("checker")) {
        t = ((x / P + y / P) % 2 == 0 ? 0 : 128) + b / 2;
      } else if (kind.equals("weave")) {
        int q = max(2, P / 3);
        t = (x / P + y / P) % 2 == 0 ? (y % q) * 256 / q : (x % q) * 256 / q;
      } else if (kind.equals("wavy")) {
        int yy = y + round(P * 0.3 * sin(TWO_PI * x / (4.0 * P)));
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
boolean _ink(int v, int x, int y) {
  return v > _tile[((y + _psy) % _th) * _tw + (x + _psx) % _tw];
}

void _prepShift() {
  _psx = ((_psx % _tw) + _tw) % _tw;
  _psy = ((_psy % _th) + _th) % _th;
}

void patternShift(float dx, float dy) {
  _psx = round(dx);
  _psy = round(dy);
}

void pattern(String kind, float scale) {
  _patternPass(kind, scale, 0, 0, 240, 128);
}

void patternRect(String kind, float scale, float x, float y, float w, float h) {
  _patternPass(kind, scale, int(x), int(y), int(x + w), int(y + h));
}

void _patternPass(String kind, float scale, int x0, int y0, int x1, int y1) {
  _tileFor(kind, scale);
  _prepShift();
  x0 = max(0, x0); y0 = max(0, y0);
  x1 = min(240, x1); y1 = min(128, y1);
  loadPixels();
  int[] t = _tile;
  int tw = _tw;
  int pd = max(1, pixelWidth / width);
  int pw = pixelWidth;
  for (int y = y0; y < y1; y++) {
    int r = ((y + _psy) % _th) * tw;
    for (int x = x0; x < x1; x++) {
      int g = pixels[y * pd * pw + x * pd] & 255;
      if (g > 0 && g < 255) {
        int c = 255 - g > t[r + (x + _psx) % tw] ? -16777216 : -1;
        for (int dy = 0; dy < pd; dy++) {
          for (int dx = 0; dx < pd; dx++) pixels[(y * pd + dy) * pw + x * pd + dx] = c;
        }
      }
    }
  }
  updatePixels();
}

void shadeField(int cell) {
  cell = max(2, cell);
  pushStyle();
  noStroke();
  java.lang.reflect.Method sh = _callback("shade");
  if (sh == null) { popStyle(); return; }
  for (int y = 0; y < 128; y += cell) {
    for (int x = 0; x < 240; x += cell) {
      float v = constrain(_call2(sh, x + cell / 2.0, y + cell / 2.0), 0, 1);
      if (v > 0.004) {
        fill(255 - 255 * v);
        rect(x, y, cell, cell);
      }
    }
  }
  popStyle();
}

void fade(float amount) {
  pushStyle();
  pushMatrix();
  resetMatrix();
  noStroke();
  fill(255, max(26, amount));
  rect(0, 0, 240, 128);
  popMatrix();
  popStyle();
}

// ------------------------------------------------------------------ point clouds: IFS / chaos game, strange attractors
class Cloud {
  String kind;
  float a, b, c, d;
  float x = 0.1, y = 0.1, z = 0.1;
  float bx0, by0, bx1, by1;
  float ux = 0, uy = 0, uw = 240, uh = 128;
  float[] hits = new float[240 * 128];
  float total = 0;
  int filled = 0;
  float[] maps = null;
  int nmaps = 0;

  Cloud(String kind) {
    this.kind = kind;
    if (kind.equals("fern")) {
      maps = new float[] {0, 0, 0, 0.16, 0, 0, 0.01, 0.85, 0.04, -0.04, 0.85, 0, 1.6, 0.85,
        0.2, -0.26, 0.23, 0.22, 0, 1.6, 0.07, -0.15, 0.28, 0.26, 0.24, 0, 0.44, 0.07};
      bounds(-2.2, 0, 2.7, 10);
    } else if (kind.equals("sierpinski")) {
      maps = new float[] {0.5, 0, 0, 0.5, 0, 0, 0.3334, 0.5, 0, 0, 0.5, 0.5, 0, 0.3333,
        0.5, 0, 0, 0.5, 0.25, 0.433, 0.3333};
      bounds(0, 0, 1, 0.866);
    } else if (kind.equals("carpet")) {
      maps = new float[8 * 7];
      int m = 0;
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (i == 1 && j == 1) continue;
          maps[m * 7] = 1 / 3.0;
          maps[m * 7 + 3] = 1 / 3.0;
          maps[m * 7 + 4] = i / 3.0;
          maps[m * 7 + 5] = j / 3.0;
          maps[m * 7 + 6] = 0.125;
          m++;
        }
      }
      bounds(0, 0, 1, 1);
    } else if (kind.equals("dragon")) {
      maps = new float[] {0.5, -0.5, 0.5, 0.5, 0, 0, 0.5, -0.5, -0.5, 0.5, -0.5, 1, 0, 0.5};
      bounds(-0.4, -0.4, 1.25, 0.9);
    } else if (kind.equals("lorenz")) {
      set(10, 28, 8 / 3.0, 0);
      bounds(-30, 0, 30, 52);
    } else if (kind.equals("dejong")) {
      set(-2.0, -2.0, -1.2, 2.0);
      bounds(-2.1, -2.1, 2.1, 2.1);
    } else {
      set(-1.4, 1.6, 1.0, 0.7);
    }
    if (maps != null) nmaps = maps.length / 7;
  }

  void bounds(float x0, float y0, float x1, float y1) {
    bx0 = x0; by0 = y0; bx1 = x1; by1 = y1;
  }

  void set(float a, float b, float c, float d) {
    this.a = a; this.b = b; this.c = c; this.d = d;
    if (kind.equals("clifford")) bounds(-1 - abs(c), -1 - abs(d), 1 + abs(c), 1 + abs(d));
  }

  void fit(float x, float y, float w, float h) {
    ux = x; uy = y; uw = w; uh = h;
  }

  void step(int n) {
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
        float r = random(1);
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
        float dt = 0.006;
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
      int sx = int(ox + (px - bx0) * s);
      int sy = int(oy + (by1 - py) * s);
      if (sx >= 0 && sx < 240 && sy >= 0 && sy < 128) {
        int k = sy * 240 + sx;
        if (hits[k] == 0) filled++;
        hits[k] += 1;
        total += 1;
      }
    }
  }

  void fade(float keep) {
    total = 0;
    filled = 0;
    for (int k = 0; k < hits.length; k++) {
      float h = hits[k];
      if (h > 0) {
        h *= keep;
        if (h < 0.3) h = 0;
        hits[k] = h;
        if (h > 0) {
          total += h;
          filled++;
        }
      }
    }
  }

  void draw(String tex, float scale) {
    if (filled == 0) return;
    _tileFor(tex, scale);
    _prepShift();
    float mean = total / filled;
    loadPixels();
    int pd = max(1, pixelWidth / width);
    int pw = pixelWidth;
    for (int k = 0; k < hits.length; k++) {
      float h = hits[k];
      if (h > 0) {
        int v = int(255 * h * h / (h * h + mean * mean));
        if (_ink(v, k % 240, k / 240)) {
          int x = k % 240, y = k / 240;
          for (int dy = 0; dy < pd; dy++) {
            for (int dx = 0; dx < pd; dx++) pixels[(y * pd + dy) * pw + x * pd + dx] = -16777216;
          }
        }
      }
    }
    updatePixels();
  }
}

// ------------------------------------------------------------------ cellular automata
class Automaton {
  int rule, cell, cols, rows;
  int[] cells;
  int count = 0;
  boolean page = false;     // true: start again from the top when full (instead of scrolling)
  int gap = 0;              // > 0: each cell a square with this many pixels of paper around it

  Automaton(int rule, int cell) {
    this.rule = rule;
    this.cell = max(2, cell);
    cols = 240 / this.cell;
    rows = 128 / this.cell;
    cells = new int[cols * rows];
    cells[cols / 2] = 1;
    count = 1;
  }

  void fill(float density) {
    for (int i = 0; i < cols; i++) cells[i] = random(1) < density ? 1 : 0;
    count = 1;
  }

  void step() {
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
      for (int i = 0; i < cols; i++) next[i] = random(1) < 0.5 ? 1 : 0;
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

  void set(int i) {
    int row = max(0, min(count, rows) - 1);
    cells[row * cols + ((i % cols) + cols) % cols] = 1;
  }

  void draw() {
    _runs(cells, cols, min(count, rows), cell, gap);
  }
}

void _runs(int[] cells, int cols, int rows, int cell, int gap) {
  pushStyle();
  noStroke();
  if (gap > 0) {
    for (int k = 0; k < cols * rows; k++) {
      if (cells[k] != 0) rect((k % cols) * cell + gap / 2, (k / cols) * cell + gap / 2, cell - gap, cell - gap);
    }
    popStyle();
    return;
  }
  for (int j = 0; j < rows; j++) {
    int base = j * cols;
    int i = 0;
    while (i < cols) {
      if (cells[base + i] != 0) {
        int s = i;
        while (i < cols && cells[base + i] != 0) i++;
        rect(s * cell, j * cell, (i - s) * cell, cell);
      } else {
        i++;
      }
    }
  }
  popStyle();
}

class Life {
  int cell, cols, rows;
  int born = 0, survive = 0;
  int[] cells;
  int[] next;
  boolean started = false;
  int lastPop = -1;
  int same = 0;
  boolean reseed = true;    // false: never drop new cells in when it dies out or stalls
  int gap = 0;              // > 0: each cell a square with this many pixels of paper around it

  Life(String rule, int cell) {
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

  void fill(float density) {
    for (int k = 0; k < cells.length; k++) cells[k] = random(1) < density ? 1 : 0;
    started = true;
  }

  void clear() {
    for (int k = 0; k < cells.length; k++) cells[k] = 0;
    started = true;
  }

  void set(int i, int j, int v) {
    started = true;
    cells[((j % rows + rows) % rows) * cols + (i % cols + cols) % cols] = v != 0 ? 1 : 0;
  }

  int get(int i, int j) {
    return cells[((j % rows + rows) % rows) * cols + (i % cols + cols) % cols];
  }

  void step() {
    if (!started) fill(0.3);
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
      int x0 = int(random(cols - w)), y0 = int(random(rows - h));
      for (int j = y0; j < y0 + h; j++) {
        for (int i = x0; i < x0 + w; i++) cells[j * cols + i] = random(1) < 0.35 ? 1 : 0;
      }
      same = 0;
    }
  }

  void draw() {
    if (!started) fill(0.3);
    _runs(cells, cols, rows, cell, gap);
  }
}

// ------------------------------------------------------------------ escape-time fractals
class Fractal {
  String kind;
  float a, b, na, nb, zoom;
  int row = 0;
  int passes = 0;
  int iterations = 40;

  Fractal(String kind, float a, float b, float zoom) {
    this.kind = kind;
    this.a = a; this.b = b; this.na = a; this.nb = b;
    this.zoom = zoom;
  }

  void set(float a, float b) {
    na = a;
    nb = b;
  }

  void draw(int rows, String tex, float scale) {
    boolean bands = tex.equals("bands");
    if (!bands) {
      _tileFor(tex, scale);
      _prepShift();
    }
    boolean julia = kind.equals("julia");
    float w = 3.2 / zoom;
    float h = w * 128 / 240.0;
    float cx0 = julia ? 0 : a;
    float cy0 = julia ? 0 : b;
    int N = max(4, iterations);
    loadPixels();
    int pd = max(1, pixelWidth / width);
    int pw = pixelWidth;
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
      float ci = cy0 - h / 2 + h * y / 127.0;
      for (int x = 0; x < 240; x++) {
        float cr = cx0 - w / 2 + w * x / 239.0;
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
        int v = n >= N ? 255 : int(255 * pow(max(0, n - 2) / (float) (N - 2), 0.6));
        for (int yy = y; yy < min(128, y + tall); yy++) {
          boolean ink;
          if (n >= N) ink = true;
          else if (bands) ink = n % 2 == 1;
          else ink = _ink(v, x, yy);
          int c = ink ? -16777216 : -1;
          for (int dy = 0; dy < pd; dy++) {
            for (int dx = 0; dx < pd; dx++) pixels[(yy * pd + dy) * pw + x * pd + dx] = c;
          }
        }
      }
      row++;
    }
    updatePixels();
  }
}

// ------------------------------------------------------------------ Voronoi / Delaunay
float[] _vx = new float[64 * 32];
float[] _vy = new float[64 * 32];
int[] _vt = new int[64 * 32];
int[] _vn = new int[64];

// each seed's cell (clipped to the frame) into _vx/_vy/_vn; _vt = the neighbour across each edge
void _cells(float[] xs, float[] ys) {
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

void voronoi(float[] xs, float[] ys, int rings) {
  _cells(xs, ys);
  int n = min(64, min(xs.length, ys.length));
  pushStyle();
  for (int i = 0; i < n; i++) {
    int m = _vn[i];
    for (int k = 0; k < max(1, rings); k++) {
      if (rings > 1) {
        fill(255 - 255.0 * k / rings);
        if (k == 1) noStroke();
      }
      float s = 1 - k / (float) max(1, rings);
      beginShape();
      for (int e = 0; e < m; e++) {
        vertex(xs[i] + (_vx[i * 32 + e] - xs[i]) * s, ys[i] + (_vy[i * 32 + e] - ys[i]) * s);
      }
      endShape(CLOSE);
    }
    popStyle();
    pushStyle();
  }
  popStyle();
}

void delaunay(float[] xs, float[] ys) {
  _cells(xs, ys);
  int n = min(64, min(xs.length, ys.length));
  for (int i = 0; i < n; i++) {
    for (int e = 0; e < _vn[i]; e++) {
      int j = _vt[i * 32 + e];
      if (j > i) line(xs[i], ys[i], xs[j], ys[j]);
    }
  }
}

// ------------------------------------------------------------------ circle packing, Truchet tiles
class Packing {
  float bx, by, bw, bh, rmin, rmax;
  int n = 0;
  float[] x = new float[600];
  float[] y = new float[600];
  float[] r = new float[600];
  boolean full = false;
  int misses = 0;

  Packing(float x, float y, float w, float h, float rmin, float rmax) {
    bx = x; by = y; bw = w; bh = h;
    this.rmin = max(1, rmin);
    this.rmax = max(this.rmin, rmax);
  }

  void step(int tries) {
    for (int t = 0; t < tries && !full; t++) {
      float px = bx + random(bw), py = by + random(bh);
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

  void draw() {
    for (int i = 0; i < n; i++) circle(x[i], y[i], 2 * r[i]);
  }

  void clear() {
    n = 0;
    full = false;
    misses = 0;
  }
}

void truchet(float x, float y, float w, float h, float cell, String kind, float t) {
  cell = max(4, cell);
  boolean arcs = kind.equals("arcs");
  boolean tri = kind.equals("tri");
  pushStyle();
  if (arcs) noFill();
  for (int j = 0; j * cell < h; j++) {
    for (int i = 0; i * cell < w; i++) {
      float x0 = x + i * cell, y0 = y + j * cell;
      boolean flip = noise(i * 0.37, j * 0.37, t) > 0.5;
      if (arcs) {
        if (flip) {
          arc(x0, y0, cell, cell, 0, HALF_PI);
          arc(x0 + cell, y0 + cell, cell, cell, PI, PI + HALF_PI);
        } else {
          arc(x0 + cell, y0, cell, cell, HALF_PI, PI);
          arc(x0, y0 + cell, cell, cell, PI + HALF_PI, TWO_PI);
        }
      } else if (tri) {
        if (flip) triangle(x0, y0, x0 + cell, y0, x0, y0 + cell);
        else triangle(x0 + cell, y0, x0 + cell, y0 + cell, x0, y0 + cell);
      } else {
        if (flip) line(x0, y0, x0 + cell, y0 + cell);
        else line(x0 + cell, y0, x0, y0 + cell);
      }
    }
  }
  popStyle();
}

// ------------------------------------------------------------------ words as image
void textCircle(String s, float cx, float cy, float r, float start) {
  pushStyle();
  textAlign(CENTER);
  float a = start;
  for (int i = 0; i < s.length(); i++) {
    String ch = s.substring(i, i + 1);
    float cw = textWidth(ch);
    a += cw / 2 / r;
    pushMatrix();
    translate(cx + r * cos(a), cy + r * sin(a));
    rotate(a + HALF_PI);
    text(ch, 0, 0);
    popMatrix();
    a += cw / 2 / r;
  }
  popStyle();
}

void textWave(String s, float x, float y, float amp, float phase) {
  pushStyle();
  textAlign(LEFT);
  for (int i = 0; i < s.length(); i++) {
    String ch = s.substring(i, i + 1);
    text(ch, x, y + amp * sin(phase + i * 0.6));
    x += textWidth(ch);
  }
  popStyle();
}

void textFit(String s, float x, float y, float w, float h) {
  if (s.length() == 0) return;
  pushStyle();
  textAlign(LEFT);
  textSize(20);
  float size = min(20 * w / max(1, textWidth(s)), h);
  textSize(max(4, size));
  text(s, x + (w - textWidth(s)) / 2, y + (h + textAscent() - textDescent()) / 2);
  popStyle();
}

void textGrid(String s, float x, float y, float w, float h, float size) {
  if (s.length() == 0) return;
  pushStyle();
  textAlign(LEFT);
  textSize(max(4, size));
  String word = s + " ";
  float ww = textWidth(word);
  int row = 0;
  for (float yy = y + size; yy <= y + h; yy += size * 1.1) {
    float xx = x - (row % 2) * ww / 2;
    while (xx + ww <= x + w + textWidth(" ")) {
      if (xx >= x) text(s, xx, yy);
      xx += ww;
    }
    row++;
  }
  popStyle();
}

// ------------------------------------------------------------------ the sketch's own functions
// A function the sketch may or may not define cannot be called by name in a library tab, so fy, fr and
// shade are found on the sketch once, by reflection, and called through the Method afterwards. A
// missing one makes the drawing that needs it a no-op instead of a compile error.
java.lang.reflect.Method _mFy = null, _mFr = null, _mShade = null;
boolean _tFy = false, _tFr = false, _tShade = false;

java.lang.reflect.Method _find(String name, int args) {
  try {
    if (args == 2) return getClass().getMethod(name, new Class[] {float.class, float.class});
    return getClass().getMethod(name, new Class[] {float.class});
  } catch (Exception e) {
    return null;
  }
}

java.lang.reflect.Method _callback(String name) {
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
boolean hasFunction(String name) {
  return _callback(name) != null;
}

float _call1(java.lang.reflect.Method m, float a) {
  try {
    return ((Number) m.invoke(this, new Object[] {Float.valueOf(a)})).floatValue();
  } catch (Exception e) {
    return 0;
  }
}

float _call2(java.lang.reflect.Method m, float a, float b) {
  try {
    return ((Number) m.invoke(this, new Object[] {Float.valueOf(a), Float.valueOf(b)})).floatValue();
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
String _texKind = null;
float _texScale = 4;
String _strTexKind = null;
float _strTexScale = 4;
int _texSeed = 0;

void texture(String kind, float scale) {
  _texKind = kind;
  _texScale = scale;
}

void noTexture() {
  _texKind = null;
}

void strokeTexture(String kind, float scale) {
  _strTexKind = kind;
  _strTexScale = scale;
}

void noStrokeTexture() {
  _strTexKind = null;
}

void textureSeed(int seed) {
  _texSeed = seed;
  randomSeed(seed);
  noiseSeed(seed);
}

// the texture() asked for over everything drawn so far (see the note above)
void applyTexture() {
  if (_texKind != null) pattern(_texKind, _texScale);
}

boolean hasTexture() {
  return _texKind != null;
}

// background(g, kind[, scale]) and background(g1, g2, "vgradient"): the hub's textured background
void background(float g, String kind) {
  background(g);
  pattern(kind, 6);
}

void background(float g, String kind, float scale) {
  background(g);
  String k = kind;
  float s = scale;
  if (k.equals("noise") || k.equals("cloud")) {
    // these two are scales of grey already; a flat fill then a pattern reads closer than noise alone
    pattern("stipple", max(2, s));
  } else {
    pattern(k.equals("radial") || k.equals("halftone") ? "dots" : k, s);
  }
}

void background(float g1, float g2, String kind) {
  for (int y = 0; y < 128; y++) {
    float t = y / 127.0;
    stroke(255 - (255 - g1) * (1 - t) - (255 - g2) * t);
    line(0, y, 240, y);
  }
  if (!kind.equals("vgradient")) pattern(kind, 6);
}
