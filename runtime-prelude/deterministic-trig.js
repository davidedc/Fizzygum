// deterministic-trig.js — engine-independent transcendentals for Fizzygum / SWCanvas.
//
// WHY: ECMAScript leaves Math.sin/cos/tan/atan2/asin/acos "implementation-approximated"
// (only +,-,*,/ and sqrt are required to be correctly-rounded / identical everywhere).
// Measured on macOS arm64: JavaScriptCore (Safari) and V8 (Chrome) disagree by 1 ULP on
// ~10-20% of trig values; even two V8 builds (Chromium 127 vs node 22) differ by ~48/1974.
// SWCanvas's software rasterizer feeds these into rotate()/arc()/round-joins, so the SAME
// scene rasterizes a pixel or two differently per engine — breaking the exact SHA-256 ref
// match (axis-aligned content, which avoids trig, stays identical). See MACRO-PATTERNS.md.
//
// FIX: a faithful JS port of SunPro's fdlibm — the public-domain reference implementation —
// computed entirely with +,-,*,/ and Math.sqrt, so the result is bit-identical on every
// conforming engine. Accuracy is <1 ULP (same as a good native libm). Installing it over
// Math.* makes SWCanvas's curved/rotated output reproducible across Chrome, Safari, node, …
//
// Trig is never in a hot path here (clocks redraw ~1x/s; rounded corners are cached in
// back-buffers), so the modest pure-JS cost is imperceptible.
//
// Exposes `globalThis.DetTrig` (and module.exports in Node). Call DetTrig.install(Math) to
// override the platform transcendentals. Does NOT auto-install (so tests can compare against
// native). Pure port; no dependency on the host Math.* trig.
(function (root) {
  'use strict';

  // --- IEEE-754 word access (endian-aware, shared scratch buffer; single-threaded → safe) ---
  var _buf = new ArrayBuffer(8);
  var _f64 = new Float64Array(_buf);
  var _u32 = new Uint32Array(_buf);
  _f64[0] = 1.0; // 0x3ff00000_00000000 → locate the high word
  var HI = (_u32[1] === 0x3ff00000) ? 1 : 0;
  var LO = 1 - HI;
  function highWord(x) { _f64[0] = x; return _u32[HI] | 0; }
  function lowWord(x) { _f64[0] = x; return _u32[LO] | 0; }
  function setHighWord(x, hi) { _f64[0] = x; _u32[HI] = hi >>> 0; return _f64[0]; }
  function setLowWord(x, lo) { _f64[0] = x; _u32[LO] = lo >>> 0; return _f64[0]; }
  function fromWords(hi, lo) { _u32[HI] = hi >>> 0; _u32[LO] = lo >>> 0; return _f64[0]; }

  var abs = Math.abs, sqrt = Math.sqrt; // both IEEE-754-exact across engines

  // --- constants (SunPro fdlibm) ---
  var one = 1.0, half = 0.5, two24 = 1.67772160000000000000e+07;
  var pio2_1 = 1.57079632673412561417e+00, pio2_1t = 6.07710050650619224932e-11,
      pio2_2 = 6.07710050630396597660e-11, pio2_2t = 2.02226624879595063154e-21,
      pio2_3 = 2.02226624871116645580e-21, pio2_3t = 8.47842766036889956997e-32,
      invpio2 = 6.36619772367581382433e-01;

  // k_sin
  var S1 = -1.66666666666666324348e-01, S2 = 8.33333333332248946124e-03,
      S3 = -1.98412698298579493134e-04, S4 = 2.75573137070700676789e-06,
      S5 = -2.50507602534068634195e-08, S6 = 1.58969099521155010221e-10;
  // k_cos
  var C1 = 4.16666666666666019037e-02, C2 = -1.38888888888741095749e-03,
      C3 = 2.48015872894767294178e-05, C4 = -2.75573143513906633035e-07,
      C5 = 2.08757232129817482790e-09, C6 = -1.13596475577881948265e-11;
  // k_tan
  var T = [3.33333333333334091986e-01, 1.33333333333201242699e-01, 5.39682539762260521377e-02,
           2.18694882948595424599e-02, 8.86323982359930005737e-03, 3.59207910759131235356e-03,
           1.45620945432529025516e-03, 5.88041240820264096874e-04, 2.46463134818469906812e-04,
           7.81794442939557092300e-05, 7.14072491382608190305e-05, -1.85586374855275456654e-05,
           2.59073051863633712884e-05];
  var pio4 = 7.85398163397448278999e-01, pio4lo = 3.06161699786838301793e-17;

  // atan
  var atanhi = [4.63647609000806093515e-01, 7.85398163397448278999e-01,
                9.82793723247329054082e-01, 1.57079632679489655800e+00];
  var atanlo = [2.26987774529616870924e-17, 3.06161699786838301793e-17,
                1.39033110312309984516e-17, 6.12323399573676603587e-17];
  var aT = [3.33333333333329318027e-01, -1.99999999998764832476e-01, 1.42857142725034663711e-01,
            -1.11111104054623557880e-01, 9.09088713343650656196e-02, -7.69187620504482999495e-02,
            6.66107313738753120669e-02, -5.83357013379057348645e-02, 4.97687799461593236017e-02,
            -3.65315727442169155270e-02, 1.62858201153657823623e-02];

  // atan2 / asin / acos
  var tiny = 1.0e-300, zero = 0.0;
  var pi = 3.14159265358979311600e+00, pi_lo = 1.2246467991473531772e-16,
      pi_o_2 = 1.57079632679489655800e+00, pi_o_4 = 7.85398163397448278999e-01;
  var pio2_hi = 1.57079632679489655800e+00, pio2_lo = 6.12323399573676603587e-17,
      pio4_hi = 7.85398163397448278999e-01;
  var pS0 = 1.66666666666666657415e-01, pS1 = -3.25565818622400915405e-01,
      pS2 = 2.01212532134862925881e-01, pS3 = -4.00555345006794114027e-02,
      pS4 = 7.91534994289814532176e-04, pS5 = 3.47933107596021167570e-05,
      qS1 = -2.40339491173441421878e+00, qS2 = 2.02094576023350569471e+00,
      qS3 = -6.88283971605453293030e-01, qS4 = 7.70381505559019352791e-02;
  var huge = 1.0e+300;

  // --- argument reduction: returns n mod 4-ish (full int) and writes y[0],y[1] in [-pi/4,pi/4] ---
  function rem_pio2(x, y) {
    var hx = highWord(x), ix = hx & 0x7fffffff;
    var z, w, t, r, fn, n, j, i, hy0;
    if (ix <= 0x3fe921fb) { y[0] = x; y[1] = 0; return 0; }          // |x| <= pi/4
    if (ix < 0x4002d97c) {                                            // |x| < 3pi/4 → ±1 step
      if (hx > 0) {
        z = x - pio2_1;
        if (ix !== 0x3ff921fb) { y[0] = z - pio2_1t; y[1] = (z - y[0]) - pio2_1t; }
        else { z -= pio2_2; y[0] = z - pio2_2t; y[1] = (z - y[0]) - pio2_2t; }
        return 1;
      } else {
        z = x + pio2_1;
        if (ix !== 0x3ff921fb) { y[0] = z + pio2_1t; y[1] = (z - y[0]) + pio2_1t; }
        else { z += pio2_2; y[0] = z + pio2_2t; y[1] = (z - y[0]) + pio2_2t; }
        return -1;
      }
    }
    if (ix <= 0x413921fb) {                                          // |x| <= 2^20*pi/2 (medium)
      t = abs(x);
      n = (invpio2 * t + half) | 0; fn = n;
      r = t - fn * pio2_1; w = fn * pio2_1t;
      j = ix >> 20;
      y[0] = r - w; hy0 = highWord(y[0]); i = j - ((hy0 >> 20) & 0x7ff);
      if (i > 16) {                                                  // 2nd iteration
        t = r; w = fn * pio2_2; r = t - w; w = fn * pio2_2t - ((t - r) - w); y[0] = r - w;
        hy0 = highWord(y[0]); i = j - ((hy0 >> 20) & 0x7ff);
        if (i > 49) { t = r; w = fn * pio2_3; r = t - w; w = fn * pio2_3t - ((t - r) - w); y[0] = r - w; } // 3rd
      }
      w = (r - y[0]) - w; y[1] = w;
      if (hx < 0) { y[0] = -y[0]; y[1] = -y[1]; return -n; }
      return n;
    }
    // |x| > 2^20*pi/2 — never reached by SWCanvas rendering (angles are bounded). Deterministic
    // coarse fallback (double-double reduction by pi/2); not accuracy-critical since unused in practice.
    t = abs(x);
    var q = Math.floor(t * invpio2 + half);
    r = t - q * pio2_1; w = q * pio2_1t;
    y[0] = r - w; y[1] = (r - y[0]) - w;
    n = q | 0;
    if (hx < 0) { y[0] = -y[0]; y[1] = -y[1]; return -n; }
    return n;
  }

  function kernel_sin(x, y, iy) {
    var z = x * x, w = z * z;
    var r = S2 + z * (S3 + z * S4) + z * w * (S5 + z * S6);
    var v = z * x;
    if (iy === 0) return x + v * (S1 + z * r);
    return x - ((z * (half * y - v * r) - y) - v * S1);
  }

  function kernel_cos(x, y) {
    var ix = highWord(x) & 0x7fffffff;
    var z = x * x, w = z * z;
    var r = z * (C1 + z * (C2 + z * C3)) + w * w * (C4 + z * (C5 + z * C6));
    if (ix < 0x3fd33333) return one - (half * z - (z * r - x * y)); // |x| < 0.3
    var qx;
    if (ix > 0x3fe90000) qx = 0.28125;
    else qx = fromWords(ix - 0x00200000, 0);
    var hz = half * z - qx, a = one - qx;
    return a - (hz - (z * r - x * y));
  }

  function kernel_tan(x, y, iy) {
    var hx = highWord(x), ix = hx & 0x7fffffff, z, r, v, w, s, a;
    if (ix >= 0x3FE59428) { // |x| >= 0.6744
      if (hx < 0) { x = -x; y = -y; }
      z = pio4 - x; w = pio4lo - y; x = z + w; y = 0.0;
    }
    z = x * x; w = z * z;
    r = T[1] + w * (T[3] + w * (T[5] + w * (T[7] + w * (T[9] + w * T[11]))));
    v = z * (T[2] + w * (T[4] + w * (T[6] + w * (T[8] + w * (T[10] + w * T[12])))));
    s = z * x;
    r = y + z * (s * (r + v) + y);
    r += T[0] * s;
    w = x + r;
    if (ix >= 0x3FE59428) {
      v = iy;
      return (1 - ((hx >> 30) & 2)) * (v - 2.0 * (x - (w * w / (w + v) - r)));
    }
    if (iy === 1) return w;
    // -1/(x+r) computed carefully
    var z1 = setLowWord(w, 0);
    v = r - (z1 - x);
    a = -1.0 / w;
    var a1 = setLowWord(a, 0);
    s = 1.0 + a1 * z1;
    return a1 + a * (s + a1 * v);
  }

  function det_sin(x) {
    var ix = highWord(x) & 0x7fffffff;
    if (ix <= 0x3fe921fb) {                                  // |x| <= pi/4
      if (ix < 0x3e500000) { if ((x | 0) === 0 && x === x) return x; } // tiny
      return kernel_sin(x, 0.0, 0);
    }
    if (ix >= 0x7ff00000) return x - x;                      // inf/NaN
    var y = [0, 0], n = rem_pio2(x, y);
    switch (n & 3) {
      case 0: return kernel_sin(y[0], y[1], 1);
      case 1: return kernel_cos(y[0], y[1]);
      case 2: return -kernel_sin(y[0], y[1], 1);
      default: return -kernel_cos(y[0], y[1]);
    }
  }

  function det_cos(x) {
    var ix = highWord(x) & 0x7fffffff;
    if (ix <= 0x3fe921fb) {                                  // |x| <= pi/4
      if (ix < 0x3e400000) { if ((x | 0) === 0 && x === x) return one; }
      return kernel_cos(x, 0.0);
    }
    if (ix >= 0x7ff00000) return x - x;
    var y = [0, 0], n = rem_pio2(x, y);
    switch (n & 3) {
      case 0: return kernel_cos(y[0], y[1]);
      case 1: return -kernel_sin(y[0], y[1], 1);
      case 2: return -kernel_cos(y[0], y[1]);
      default: return kernel_sin(y[0], y[1], 1);
    }
  }

  function det_tan(x) {
    var ix = highWord(x) & 0x7fffffff;
    if (ix <= 0x3fe921fb) {                                  // |x| <= pi/4
      if (ix < 0x3e300000) { if ((x | 0) === 0 && x === x) return x; }
      return kernel_tan(x, 0.0, 1);
    }
    if (ix >= 0x7ff00000) return x - x;
    var y = [0, 0], n = rem_pio2(x, y);
    return kernel_tan(y[0], y[1], 1 - ((n & 1) << 1));
  }

  function det_atan(x) {
    var hx = highWord(x), ix = hx & 0x7fffffff, id, z, w, s1, s2, zr;
    if (ix >= 0x44100000) {                                  // |x| >= 2^66
      if (ix > 0x7ff00000 || (ix === 0x7ff00000 && lowWord(x) !== 0)) return x + x;
      return (hx > 0) ? atanhi[3] + atanlo[3] : -atanhi[3] - atanlo[3];
    }
    if (ix < 0x3fdc0000) {                                   // |x| < 0.4375
      if (ix < 0x3e400000) { if (huge + x > one) return x; } // tiny
      id = -1;
    } else {
      x = abs(x);
      if (ix < 0x3ff30000) {
        if (ix < 0x3fe60000) { id = 0; x = (2.0 * x - one) / (2.0 + x); }
        else { id = 1; x = (x - one) / (x + one); }
      } else {
        if (ix < 0x40038000) { id = 2; x = (x - 1.5) / (one + 1.5 * x); }
        else { id = 3; x = -1.0 / x; }
      }
    }
    z = x * x; w = z * z;
    s1 = z * (aT[0] + w * (aT[2] + w * (aT[4] + w * (aT[6] + w * (aT[8] + w * aT[10])))));
    s2 = w * (aT[1] + w * (aT[3] + w * (aT[5] + w * (aT[7] + w * aT[9]))));
    if (id < 0) return x - x * (s1 + s2);
    zr = atanhi[id] - ((x * (s1 + s2) - atanlo[id]) - x);
    return (hx < 0) ? -zr : zr;
  }

  function det_atan2(y, x) {
    if (x !== x || y !== y) return x + y;
    var hx = highWord(x), ix = hx & 0x7fffffff, lx = lowWord(x);
    var hy = highWord(y), iy = hy & 0x7fffffff, ly = lowWord(y);
    if (((hx - 0x3ff00000) | lx) === 0) return det_atan(y);  // x == 1.0
    var m = ((hy >> 31) & 1) | ((hx >> 30) & 2);             // 2*sign(x) + sign(y)
    if ((iy | ly) === 0) {                                   // y == 0
      switch (m) { case 0: case 1: return y; case 2: return pi + tiny; default: return -pi - tiny; }
    }
    if ((ix | lx) === 0) return (hy < 0) ? -pi_o_2 - tiny : pi_o_2 + tiny; // x == 0
    if (ix === 0x7ff00000) {                                 // x == inf
      if (iy === 0x7ff00000) {
        switch (m) { case 0: return pi_o_4 + tiny; case 1: return -pi_o_4 - tiny;
                     case 2: return 3.0 * pi_o_4 + tiny; default: return -3.0 * pi_o_4 - tiny; }
      } else {
        switch (m) { case 0: return zero; case 1: return -zero; case 2: return pi + tiny; default: return -pi - tiny; }
      }
    }
    if (iy === 0x7ff00000) return (hy < 0) ? -pi_o_2 - tiny : pi_o_2 + tiny; // y == inf
    var k = (iy - ix) >> 20, z;
    if (k > 60) z = pi_o_2 + 0.5 * pi_lo;                    // |y/x| huge
    else if (hx < 0 && k < -60) z = 0.0;                     // |y/x| tiny, x<0
    else z = det_atan(abs(y / x));
    switch (m) {
      case 0: return z;
      case 1: return setHighWord(z, highWord(z) ^ 0x80000000);
      case 2: return pi - (z - pi_lo);
      default: return (z - pi_lo) - pi;
    }
  }

  function det_asin(x) {
    var hx = highWord(x), ix = hx & 0x7fffffff, t, w, p, q, s, c, r;
    if (ix >= 0x3ff00000) {                                  // |x| >= 1
      if (((ix - 0x3ff00000) | lowWord(x)) === 0) return x * pio2_hi + x * pio2_lo;
      return (x - x) / (x - x);
    } else if (ix < 0x3fe00000) {                            // |x| < 0.5
      if (ix < 0x3e400000) { if (huge + x > one) return x; }
      t = x * x;
      p = t * (pS0 + t * (pS1 + t * (pS2 + t * (pS3 + t * (pS4 + t * pS5)))));
      q = one + t * (qS1 + t * (qS2 + t * (qS3 + t * qS4)));
      return x + x * (p / q);
    }
    w = one - abs(x); t = w * half;
    p = t * (pS0 + t * (pS1 + t * (pS2 + t * (pS3 + t * (pS4 + t * pS5)))));
    q = one + t * (qS1 + t * (qS2 + t * (qS3 + t * qS4)));
    s = sqrt(t);
    if (ix >= 0x3FEF3333) { w = p / q; t = pio2_hi - (2.0 * (s + s * w) - pio2_lo); }
    else {
      w = setLowWord(s, 0);
      c = (t - w * w) / (s + w); r = p / q;
      p = 2.0 * s * r - (pio2_lo - 2.0 * c); q = pio4_hi - 2.0 * w; t = pio4_hi - (p - q);
    }
    return (hx > 0) ? t : -t;
  }

  function det_acos(x) {
    var hx = highWord(x), ix = hx & 0x7fffffff, z, p, q, r, w, s, c, df;
    if (ix >= 0x3ff00000) {                                  // |x| >= 1
      if (((ix - 0x3ff00000) | lowWord(x)) === 0) return (hx > 0) ? 0.0 : pi + 2.0 * pio2_lo;
      return (x - x) / (x - x);
    }
    if (ix < 0x3fe00000) {                                   // |x| < 0.5
      if (ix <= 0x3c600000) return pio2_hi + pio2_lo;
      z = x * x;
      p = z * (pS0 + z * (pS1 + z * (pS2 + z * (pS3 + z * (pS4 + z * pS5)))));
      q = one + z * (qS1 + z * (qS2 + z * (qS3 + z * qS4)));
      r = p / q;
      return pio2_hi - (x - (pio2_lo - x * r));
    } else if (hx < 0) {                                     // x <= -0.5
      z = (one + x) * half;
      p = z * (pS0 + z * (pS1 + z * (pS2 + z * (pS3 + z * (pS4 + z * pS5)))));
      q = one + z * (qS1 + z * (qS2 + z * (qS3 + z * qS4)));
      s = sqrt(z); r = p / q; w = r * s - pio2_lo;
      return pi - 2.0 * (s + w);
    }
    z = (one - x) * half;                                    // x >= 0.5
    s = sqrt(z); df = setLowWord(s, 0);
    c = (z - df * df) / (s + df);
    p = z * (pS0 + z * (pS1 + z * (pS2 + z * (pS3 + z * (pS4 + z * pS5)))));
    q = one + z * (qS1 + z * (qS2 + z * (qS3 + z * qS4)));
    r = p / q; w = r * s + c;
    return 2.0 * (df + w);
  }

  var DetTrig = {
    sin: det_sin, cos: det_cos, tan: det_tan,
    atan: det_atan, atan2: det_atan2, asin: det_asin, acos: det_acos,
    install: function (target) {
      target = target || Math;
      target.sin = det_sin; target.cos = det_cos; target.tan = det_tan;
      target.atan = det_atan; target.atan2 = det_atan2; target.asin = det_asin; target.acos = det_acos;
      return target;
    }
  };

  root.DetTrig = DetTrig;
  if (typeof module !== 'undefined' && module.exports) module.exports = DetTrig;
})(typeof globalThis !== 'undefined' ? globalThis : this);
