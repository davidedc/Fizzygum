// Page-side instrumentation: counts canvas-2D workload without altering any
// arguments or pixels. Installed via evaluateOnNewDocument BEFORE any page
// script runs. Patches BOTH the native CanvasRenderingContext2D prototype and
// (via a window.SWCanvas set-trap) SWCanvas's CanvasCompatibleContext2D
// prototype, tagging counters 'native' / 'sw'.
//
// This implements the observation asked for by SWCanvas
// plans/clipping-optimization.md §8: clip() classification (axis-aligned
// integer rect vs not, under rotation, nested), draw calls partitioned by
// the *effective* clip kind (none / rect-only / mask), save-while-clipped
// (= mask deep-clone in today's SWCanvas), plus draw-extent areas and
// clip-bbox/surface ratios.
(function () {
  if (window.__PF) return;
  var PF = (window.__PF = {
    tags: {},
    errors: [],
    frames: { updateBrokenCalls: 0, brokenRects: 0, brokenArea: 0 },
  });

  function tagBucket(tag) {
    var t = PF.tags[tag];
    if (!t) {
      t = PF.tags[tag] = {
        counts: {}, // plain per-method call counts
        clip: {
          calls: 0,
          axisAlignedIntRect: 0,
          axisAlignedNonIntRect: 0,
          nonRect: 0,
          underRotation: 0,
          nested: 0,
          bboxRatioSum: 0,
          bboxRatioN: 0,
          bboxRatioBuckets: {}, // e.g. '<=1%', '<=5%', ...
        },
        saves: { total: 0, whileClipped: 0 },
        draws: {}, // method -> {none, rect, mask}
        areas: {}, // method -> {sum, n, max}
      };
    }
    return t;
  }

  function bump(o, k) { o[k] = (o[k] || 0) + 1; }

  var IDENT = [1, 0, 0, 1, 0, 0];

  function mul(m, n) {
    return [
      m[0] * n[0] + m[2] * n[1],
      m[1] * n[0] + m[3] * n[1],
      m[0] * n[2] + m[2] * n[3],
      m[1] * n[2] + m[3] * n[3],
      m[0] * n[4] + m[2] * n[5] + m[4],
      m[1] * n[4] + m[3] * n[5] + m[5],
    ];
  }

  function ratioBucket(r) {
    if (r <= 0.01) return '<=1%';
    if (r <= 0.05) return '<=5%';
    if (r <= 0.15) return '<=15%';
    if (r <= 0.5) return '<=50%';
    if (r < 0.999) return '<100%';
    return '=100%';
  }

  var stateMap = typeof WeakMap !== 'undefined' ? new WeakMap() : null;
  function st(ctx) {
    var s = stateMap.get(ctx);
    if (!s) {
      s = { m: IDENT.slice(), stack: [], clipKind: 0, path: [], pathBad: false };
      stateMap.set(ctx, s);
    }
    return s;
  }

  function surfaceDims(ctx) {
    try {
      if (ctx._core && ctx._core.surface) return { w: ctx._core.surface.width, h: ctx._core.surface.height };
      if (ctx.canvas) return { w: ctx.canvas.width, h: ctx.canvas.height };
    } catch (e) {}
    return null;
  }

  function tp(s, x, y) { // transform point by current matrix
    var m = s.m;
    return [m[0] * x + m[2] * y + m[4], m[1] * x + m[3] * y + m[5]];
  }

  // classify collected polyline points as axis-aligned rect. Points are the
  // transformed moveTo/lineTo vertices. Accepts the closing duplicate point.
  function classifyRect(pts) {
    if (pts.length < 4 || pts.length > 5) return null;
    var p = pts.slice();
    if (p.length === 5) {
      var a = p[0], b = p[4];
      if (Math.abs(a[0] - b[0]) > 1e-6 || Math.abs(a[1] - b[1]) > 1e-6) return null;
      p.pop();
    }
    var xs = {}, ys = {};
    for (var i = 0; i < 4; i++) {
      xs[p[i][0].toFixed(4)] = true;
      ys[p[i][1].toFixed(4)] = true;
    }
    if (Object.keys(xs).length !== 2 || Object.keys(ys).length !== 2) return null;
    // consecutive edges must alternate horizontal/vertical
    for (var j = 0; j < 4; j++) {
      var q = p[j], r = p[(j + 1) % 4];
      var dx = Math.abs(q[0] - r[0]) > 1e-6, dy = Math.abs(q[1] - r[1]) > 1e-6;
      if (dx && dy) return null; // diagonal edge
    }
    var integer = p.every(function (pt) {
      return Math.abs(pt[0] - Math.round(pt[0])) < 1e-6 && Math.abs(pt[1] - Math.round(pt[1])) < 1e-6;
    });
    var minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    for (var k = 0; k < 4; k++) {
      minX = Math.min(minX, p[k][0]); maxX = Math.max(maxX, p[k][0]);
      minY = Math.min(minY, p[k][1]); maxY = Math.max(maxY, p[k][1]);
    }
    return { integer: integer, area: (maxX - minX) * (maxY - minY) };
  }

  function area2(o, method, v) {
    var a = o.areas[method] || (o.areas[method] = { sum: 0, n: 0, max: 0 });
    a.sum += v; a.n++; if (v > a.max) a.max = v;
  }

  function drawTally(o, s, method) {
    var d = o.draws[method] || (o.draws[method] = { none: 0, rect: 0, mask: 0 });
    d[s.clipKind === 0 ? 'none' : s.clipKind === 1 ? 'rect' : 'mask']++;
  }

  function wrapProto(proto, tag) {
    var T = tagBucket(tag);
    function wrap(name, fn) {
      var orig = proto[name];
      if (typeof orig !== 'function') return;
      proto[name] = function () {
        try { fn(this, arguments); } catch (e) { if (PF.errors.length < 20) PF.errors.push(tag + '.' + name + ': ' + e.message); }
        return orig.apply(this, arguments);
      };
    }

    wrap('save', function (ctx) {
      var s = st(ctx);
      T.saves.total++;
      if (s.clipKind > 0) T.saves.whileClipped++;
      s.stack.push({ m: s.m.slice(), clipKind: s.clipKind });
    });
    wrap('restore', function (ctx) {
      var s = st(ctx);
      var f = s.stack.pop();
      if (f) { s.m = f.m; s.clipKind = f.clipKind; }
    });
    wrap('translate', function (ctx, a) { var s = st(ctx); s.m = mul(s.m, [1, 0, 0, 1, a[0], a[1]]); });
    wrap('scale', function (ctx, a) { var s = st(ctx); s.m = mul(s.m, [a[0], 0, 0, a[1], 0, 0]); });
    wrap('rotate', function (ctx, a) {
      var s = st(ctx); var c = Math.cos(a[0]), n = Math.sin(a[0]);
      s.m = mul(s.m, [c, n, -n, c, 0, 0]);
    });
    wrap('transform', function (ctx, a) { var s = st(ctx); s.m = mul(s.m, [a[0], a[1], a[2], a[3], a[4], a[5]]); });
    wrap('setTransform', function (ctx, a) {
      var s = st(ctx);
      if (a.length >= 6) s.m = [a[0], a[1], a[2], a[3], a[4], a[5]];
      else if (a[0] && typeof a[0] === 'object') s.m = [a[0].a, a[0].b, a[0].c, a[0].d, a[0].e, a[0].f];
    });
    wrap('resetTransform', function (ctx) { st(ctx).m = IDENT.slice(); });

    wrap('beginPath', function (ctx) { var s = st(ctx); s.path = []; s.pathBad = false; });
    wrap('moveTo', function (ctx, a) { var s = st(ctx); s.path.push(tp(s, a[0], a[1])); });
    wrap('lineTo', function (ctx, a) { var s = st(ctx); s.path.push(tp(s, a[0], a[1])); });
    wrap('rect', function (ctx, a) {
      var s = st(ctx);
      // only a lone rect() in the path stays classifiable; rect after other
      // segments is unusual in Fizzygum — treat additively like 4 lineTo corners.
      s.path.push(tp(s, a[0], a[1]), tp(s, a[0] + a[2], a[1]), tp(s, a[0] + a[2], a[1] + a[3]), tp(s, a[0], a[1] + a[3]));
    });
    ['arc', 'arcTo', 'ellipse', 'bezierCurveTo', 'quadraticCurveTo', 'roundRect'].forEach(function (m) {
      wrap(m, function (ctx) { st(ctx).pathBad = true; });
    });

    wrap('clip', function (ctx, a) {
      var s = st(ctx);
      var C = T.clip;
      C.calls++;
      if (s.clipKind > 0) C.nested++;
      var rotated = Math.abs(s.m[1]) > 1e-9 || Math.abs(s.m[2]) > 1e-9;
      if (rotated) C.underRotation++;
      var rectInfo = null;
      // a Path2D argument (unused by Fizzygum) would defeat our tracking
      var pathArg = a.length && typeof a[0] === 'object';
      if (!rotated && !s.pathBad && !pathArg) rectInfo = classifyRect(s.path);
      if (rectInfo) {
        if (rectInfo.integer) C.axisAlignedIntRect++; else C.axisAlignedNonIntRect++;
        var dims = surfaceDims(ctx);
        if (dims && dims.w > 0 && dims.h > 0) {
          var r = Math.min(1, rectInfo.area / (dims.w * dims.h));
          C.bboxRatioSum += r; C.bboxRatioN++;
          bump(C.bboxRatioBuckets, ratioBucket(r));
        }
        s.clipKind = Math.max(s.clipKind, 1);
      } else {
        C.nonRect++;
        s.clipKind = 2;
      }
    });

    // draw calls partitioned by effective clip kind
    wrap('fillRect', function (ctx, a) {
      var s = st(ctx);
      bump(T.counts, 'fillRect'); drawTally(T, s, 'fillRect');
      var sc = Math.abs(s.m[0] * s.m[3] - s.m[1] * s.m[2]);
      area2(T, 'fillRect', Math.abs(a[2] * a[3]) * sc);
    });
    wrap('strokeRect', function (ctx) { var s = st(ctx); bump(T.counts, 'strokeRect'); drawTally(T, s, 'strokeRect'); });
    wrap('clearRect', function (ctx, a) {
      var s = st(ctx);
      bump(T.counts, 'clearRect'); drawTally(T, s, 'clearRect');
      var sc = Math.abs(s.m[0] * s.m[3] - s.m[1] * s.m[2]);
      area2(T, 'clearRect', Math.abs(a[2] * a[3]) * sc);
    });
    wrap('fill', function (ctx) { var s = st(ctx); bump(T.counts, 'fill'); drawTally(T, s, 'fill'); });
    wrap('stroke', function (ctx) { var s = st(ctx); bump(T.counts, 'stroke'); drawTally(T, s, 'stroke'); });
    wrap('drawImage', function (ctx, a) {
      var s = st(ctx);
      bump(T.counts, 'drawImage'); drawTally(T, s, 'drawImage');
      var dw, dh;
      if (a.length >= 9) { dw = a[7]; dh = a[8]; }
      else if (a.length >= 5) { dw = a[3]; dh = a[4]; }
      else { dw = (a[0] && a[0].width) || 0; dh = (a[0] && a[0].height) || 0; }
      var sc = Math.abs(s.m[0] * s.m[3] - s.m[1] * s.m[2]);
      area2(T, 'drawImage', Math.abs(dw * dh) * sc);
    });
    wrap('fillText', function (ctx, a) {
      var s = st(ctx);
      bump(T.counts, 'fillText'); drawTally(T, s, 'fillText');
      area2(T, 'fillTextChars', String(a[0]).length);
    });
    wrap('strokeText', function (ctx) { var s = st(ctx); bump(T.counts, 'strokeText'); drawTally(T, s, 'strokeText'); });
    wrap('getImageData', function () { bump(T.counts, 'getImageData'); });
    wrap('putImageData', function () { bump(T.counts, 'putImageData'); });
    wrap('measureText', function () { bump(T.counts, 'measureText'); });
    wrap('createLinearGradient', function () { bump(T.counts, 'createLinearGradient'); });
    wrap('createRadialGradient', function () { bump(T.counts, 'createRadialGradient'); });
    wrap('createPattern', function () { bump(T.counts, 'createPattern'); });
    wrap('toDataURL', function () { bump(T.counts, 'toDataURL'); });
  }

  // native canvas contexts
  try {
    if (window.CanvasRenderingContext2D) wrapProto(CanvasRenderingContext2D.prototype, 'native');
  } catch (e) { PF.errors.push('native: ' + e.message); }

  // SWCanvas loads later in the boot bundle: trap the global's assignment.
  (function () {
    var real;
    try {
      Object.defineProperty(window, 'SWCanvas', {
        configurable: true,
        get: function () { return real; },
        set: function (v) {
          real = v;
          try {
            var probe = v.createCanvas(1, 1);
            var proto = Object.getPrototypeOf(probe.getContext('2d'));
            wrapProto(proto, 'sw');
            // canvas allocation tracking
            var origCreate = v.createCanvas;
            v.createCanvas = function (w, h) {
              var T = tagBucket('sw');
              bump(T.counts, 'createCanvas');
              area2(T, 'createCanvasArea', (w || 0) * (h || 0));
              return origCreate.apply(this, arguments);
            };
          } catch (e) { PF.errors.push('sw patch: ' + e.message); }
        },
      });
    } catch (e) { PF.errors.push('sw trap: ' + e.message); }
  })();

  PF.report = function () { return JSON.parse(JSON.stringify({ tags: PF.tags, frames: PF.frames, errors: PF.errors })); };
})();
