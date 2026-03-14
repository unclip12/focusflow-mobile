const vf = () => Promise.resolve().then(() => gf), { Fragment: er, jsx: c, jsxs: y } = globalThis.__GLOBALS__.ReactJSXRuntime;
"use" in globalThis.__GLOBALS__.React || (globalThis.__GLOBALS__.React.use = () => {
  throw new Error("`use` is not available in this version of React. Make currently only supports React 18, but `use` is only available in React 19+.");
});
function tr(e) {
  return globalThis.__GLOBALS__.React.isValidElement(e) && e.props && "_fgT" in e.props;
}
function st(e) {
  return globalThis.__GLOBALS__.React.isValidElement(e) && e.type === "fg-txt";
}
function nr(e) {
  const { _fgT: t, _fgS: n, _fgB: i, _fgD: s, ...o } = e.props;
  return globalThis.__GLOBALS__.React.createElement(t, {
    ...o,
    key: e.key
  }, o.children);
}
function Pt(e) {
  return tr(e) ? nr(e) : st(e) ? e.props.children : e;
}
const tt = globalThis.__GLOBALS__.React.Children, Qo = {
  map(e, t, n) {
    return tt.map(e, (i, s) => {
      const o = Pt(i);
      return st(i) ? null : t.call(n, o, s);
    });
  },
  forEach(e, t, n) {
    tt.forEach(e, (i, s) => {
      if (st(i))
        return;
      const o = Pt(i);
      t.call(n, o, s);
    });
  },
  count(e) {
    let t = 0;
    return tt.forEach(e, (n) => {
      st(n) || t++;
    }), t;
  },
  toArray(e) {
    const t = [];
    return tt.forEach(e, (n) => {
      st(n) || t.push(Pt(n));
    }), t;
  },
  only(e) {
    const t = tt.only(e);
    return Pt(t);
  }
}, Vi = globalThis.__GLOBALS__.React.cloneElement, ea = (e, ...t) => tr(e) ? Vi(nr(e), ...t) : Vi(e, ...t);
({
  ...globalThis.__GLOBALS__.React
});
const { Component: ir, createContext: Ye, createElement: zt, createFactory: bf, createRef: xf, forwardRef: zn, Fragment: sr, isValidElement: ta, lazy: Ff, memo: wf, Profiler: Sf, PureComponent: Tf, startTransition: Cf, StrictMode: kf, Suspense: Mf, use: Pf, useCallback: Ke, useContext: Q, useDebugValue: Af, useDeferredValue: Vf, useEffect: xe, useId: jn, useImperativeHandle: Ef, useInsertionEffect: Wn, useLayoutEffect: na, useMemo: Le, useReducer: If, useRef: Se, useState: W, useSyncExternalStore: Nf, useTransition: Df, version: Bf } = globalThis.__GLOBALS__.React, On = Ye({});
function xt(e) {
  const t = Se(null);
  return t.current === null && (t.current = e()), t.current;
}
const _n = typeof window < "u", $n = _n ? na : xe, Ut = /* @__PURE__ */ Ye(null);
function Un(e, t) {
  e.indexOf(t) === -1 && e.push(t);
}
function Gn(e, t) {
  const n = e.indexOf(t);
  n > -1 && e.splice(n, 1);
}
const Te = (e, t, n) => n > t ? t : n < e ? e : n;
let Hn = () => {
};
const Ce = {}, rr = (e) => /^-?(?:\d+(?:\.\d+)?|\.\d+)$/u.test(e);
function or(e) {
  return typeof e == "object" && e !== null;
}
const ar = (e) => /^0[^.\s]+$/u.test(e);
// @__NO_SIDE_EFFECTS__
function Kn(e) {
  let t;
  return () => (t === void 0 && (t = e()), t);
}
const he = /* @__NO_SIDE_EFFECTS__ */ (e) => e, ia = (e, t) => (n) => t(e(n)), Ft = (...e) => e.reduce(ia), ft = /* @__NO_SIDE_EFFECTS__ */ (e, t, n) => {
  const i = t - e;
  return i === 0 ? 1 : (n - e) / i;
};
class qn {
  constructor() {
    this.subscriptions = [];
  }
  add(t) {
    return Un(this.subscriptions, t), () => Gn(this.subscriptions, t);
  }
  notify(t, n, i) {
    const s = this.subscriptions.length;
    if (s)
      if (s === 1)
        this.subscriptions[0](t, n, i);
      else
        for (let o = 0; o < s; o++) {
          const r = this.subscriptions[o];
          r && r(t, n, i);
        }
  }
  getSize() {
    return this.subscriptions.length;
  }
  clear() {
    this.subscriptions.length = 0;
  }
}
const ve = /* @__NO_SIDE_EFFECTS__ */ (e) => e * 1e3, ue = /* @__NO_SIDE_EFFECTS__ */ (e) => e / 1e3;
function lr(e, t) {
  return t ? e * (1e3 / t) : 0;
}
const cr = (e, t, n) => (((1 - 3 * n + 3 * t) * e + (3 * n - 6 * t)) * e + 3 * t) * e, sa = 1e-7, ra = 12;
function oa(e, t, n, i, s) {
  let o, r, l = 0;
  do
    r = t + (n - t) / 2, o = cr(r, i, s) - e, o > 0 ? n = r : t = r;
  while (Math.abs(o) > sa && ++l < ra);
  return r;
}
function wt(e, t, n, i) {
  if (e === t && n === i)
    return he;
  const s = (o) => oa(o, 0, 1, e, n);
  return (o) => o === 0 || o === 1 ? o : cr(s(o), t, i);
}
const dr = (e) => (t) => t <= 0.5 ? e(2 * t) / 2 : (2 - e(2 * (1 - t))) / 2, ur = (e) => (t) => 1 - e(1 - t), hr = /* @__PURE__ */ wt(0.33, 1.53, 0.69, 0.99), Xn = /* @__PURE__ */ ur(hr), fr = /* @__PURE__ */ dr(Xn), pr = (e) => (e *= 2) < 1 ? 0.5 * Xn(e) : 0.5 * (2 - Math.pow(2, -10 * (e - 1))), Yn = (e) => 1 - Math.sin(Math.acos(e)), mr = ur(Yn), yr = dr(Yn), aa = /* @__PURE__ */ wt(0.42, 0, 1, 1), la = /* @__PURE__ */ wt(0, 0, 0.58, 1), gr = /* @__PURE__ */ wt(0.42, 0, 0.58, 1), ca = (e) => Array.isArray(e) && typeof e[0] != "number", vr = (e) => Array.isArray(e) && typeof e[0] == "number", da = {
  linear: he,
  easeIn: aa,
  easeInOut: gr,
  easeOut: la,
  circIn: Yn,
  circInOut: yr,
  circOut: mr,
  backIn: Xn,
  backInOut: fr,
  backOut: hr,
  anticipate: pr
}, ua = (e) => typeof e == "string", Ei = (e) => {
  if (vr(e)) {
    Hn(e.length === 4);
    const [t, n, i, s] = e;
    return wt(t, n, i, s);
  } else if (ua(e))
    return da[e];
  return e;
}, At = [
  "setup",
  // Compute
  "read",
  // Read
  "resolveKeyframes",
  // Write/Read/Write/Read
  "preUpdate",
  // Compute
  "update",
  // Compute
  "preRender",
  // Compute
  "render",
  // Write
  "postRender"
  // Compute
];
function ha(e, t) {
  let n = /* @__PURE__ */ new Set(), i = /* @__PURE__ */ new Set(), s = !1, o = !1;
  const r = /* @__PURE__ */ new WeakSet();
  let l = {
    delta: 0,
    timestamp: 0,
    isProcessing: !1
  };
  function a(u) {
    r.has(u) && (d.schedule(u), e()), u(l);
  }
  const d = {
    /**
     * Schedule a process to run on the next frame.
     */
    schedule: (u, h = !1, p = !1) => {
      const b = p && s ? n : i;
      return h && r.add(u), b.has(u) || b.add(u), u;
    },
    /**
     * Cancel the provided callback from running on the next frame.
     */
    cancel: (u) => {
      i.delete(u), r.delete(u);
    },
    /**
     * Execute all schedule callbacks.
     */
    process: (u) => {
      if (l = u, s) {
        o = !0;
        return;
      }
      s = !0, [n, i] = [i, n], n.forEach(a), n.clear(), s = !1, o && (o = !1, d.process(u));
    }
  };
  return d;
}
const fa = 40;
function br(e, t) {
  let n = !1, i = !0;
  const s = {
    delta: 0,
    timestamp: 0,
    isProcessing: !1
  }, o = () => n = !0, r = At.reduce((T, E) => (T[E] = ha(o), T), {}), { setup: l, read: a, resolveKeyframes: d, preUpdate: u, update: h, preRender: p, render: g, postRender: b } = r, w = () => {
    const T = Ce.useManualTiming ? s.timestamp : performance.now();
    n = !1, Ce.useManualTiming || (s.delta = i ? 1e3 / 60 : Math.max(Math.min(T - s.timestamp, fa), 1)), s.timestamp = T, s.isProcessing = !0, l.process(s), a.process(s), d.process(s), u.process(s), h.process(s), p.process(s), g.process(s), b.process(s), s.isProcessing = !1, n && t && (i = !1, e(w));
  }, x = () => {
    n = !0, i = !0, s.isProcessing || e(w);
  };
  return { schedule: At.reduce((T, E) => {
    const k = r[E];
    return T[E] = (I, B = !1, A = !1) => (n || x(), k.schedule(I, B, A)), T;
  }, {}), cancel: (T) => {
    for (let E = 0; E < At.length; E++)
      r[At[E]].cancel(T);
  }, state: s, steps: r };
}
const { schedule: $, cancel: ke, state: ie, steps: Qt } = /* @__PURE__ */ br(typeof requestAnimationFrame < "u" ? requestAnimationFrame : he, !0);
let Dt;
function pa() {
  Dt = void 0;
}
const ae = {
  now: () => (Dt === void 0 && ae.set(ie.isProcessing || Ce.useManualTiming ? ie.timestamp : performance.now()), Dt),
  set: (e) => {
    Dt = e, queueMicrotask(pa);
  }
}, xr = (e) => (t) => typeof t == "string" && t.startsWith(e), Zn = /* @__PURE__ */ xr("--"), ma = /* @__PURE__ */ xr("var(--"), Jn = (e) => ma(e) ? ya.test(e.split("/*")[0].trim()) : !1, ya = /var\(--(?:[\w-]+\s*|[\w-]+\s*,(?:\s*[^)(\s]|\s*\((?:[^)(]|\([^)(]*\))*\))+\s*)\)$/iu, Ze = {
  test: (e) => typeof e == "number",
  parse: parseFloat,
  transform: (e) => e
}, pt = {
  ...Ze,
  transform: (e) => Te(0, 1, e)
}, Vt = {
  ...Ze,
  default: 1
}, ot = (e) => Math.round(e * 1e5) / 1e5, Qn = /-?(?:\d+(?:\.\d+)?|\.\d+)/gu;
function ga(e) {
  return e == null;
}
const va = /^(?:#[\da-f]{3,8}|(?:rgb|hsl)a?\((?:-?[\d.]+%?[,\s]+){2}-?[\d.]+%?\s*(?:[,/]\s*)?(?:\b\d+(?:\.\d+)?|\.\d+)?%?\))$/iu, ei = (e, t) => (n) => !!(typeof n == "string" && va.test(n) && n.startsWith(e) || t && !ga(n) && Object.prototype.hasOwnProperty.call(n, t)), Fr = (e, t, n) => (i) => {
  if (typeof i != "string")
    return i;
  const [s, o, r, l] = i.match(Qn);
  return {
    [e]: parseFloat(s),
    [t]: parseFloat(o),
    [n]: parseFloat(r),
    alpha: l !== void 0 ? parseFloat(l) : 1
  };
}, ba = (e) => Te(0, 255, e), en = {
  ...Ze,
  transform: (e) => Math.round(ba(e))
}, Ne = {
  test: /* @__PURE__ */ ei("rgb", "red"),
  parse: /* @__PURE__ */ Fr("red", "green", "blue"),
  transform: ({ red: e, green: t, blue: n, alpha: i = 1 }) => "rgba(" + en.transform(e) + ", " + en.transform(t) + ", " + en.transform(n) + ", " + ot(pt.transform(i)) + ")"
};
function xa(e) {
  let t = "", n = "", i = "", s = "";
  return e.length > 5 ? (t = e.substring(1, 3), n = e.substring(3, 5), i = e.substring(5, 7), s = e.substring(7, 9)) : (t = e.substring(1, 2), n = e.substring(2, 3), i = e.substring(3, 4), s = e.substring(4, 5), t += t, n += n, i += i, s += s), {
    red: parseInt(t, 16),
    green: parseInt(n, 16),
    blue: parseInt(i, 16),
    alpha: s ? parseInt(s, 16) / 255 : 1
  };
}
const yn = {
  test: /* @__PURE__ */ ei("#"),
  parse: xa,
  transform: Ne.transform
}, St = /* @__NO_SIDE_EFFECTS__ */ (e) => ({
  test: (t) => typeof t == "string" && t.endsWith(e) && t.split(" ").length === 1,
  parse: parseFloat,
  transform: (t) => `${t}${e}`
}), Me = /* @__PURE__ */ St("deg"), be = /* @__PURE__ */ St("%"), M = /* @__PURE__ */ St("px"), Fa = /* @__PURE__ */ St("vh"), wa = /* @__PURE__ */ St("vw"), Ii = {
  ...be,
  parse: (e) => be.parse(e) / 100,
  transform: (e) => be.transform(e * 100)
}, Oe = {
  test: /* @__PURE__ */ ei("hsl", "hue"),
  parse: /* @__PURE__ */ Fr("hue", "saturation", "lightness"),
  transform: ({ hue: e, saturation: t, lightness: n, alpha: i = 1 }) => "hsla(" + Math.round(e) + ", " + be.transform(ot(t)) + ", " + be.transform(ot(n)) + ", " + ot(pt.transform(i)) + ")"
}, Z = {
  test: (e) => Ne.test(e) || yn.test(e) || Oe.test(e),
  parse: (e) => Ne.test(e) ? Ne.parse(e) : Oe.test(e) ? Oe.parse(e) : yn.parse(e),
  transform: (e) => typeof e == "string" ? e : e.hasOwnProperty("red") ? Ne.transform(e) : Oe.transform(e),
  getAnimatableNone: (e) => {
    const t = Z.parse(e);
    return t.alpha = 0, Z.transform(t);
  }
}, Sa = /(?:#[\da-f]{3,8}|(?:rgb|hsl)a?\((?:-?[\d.]+%?[,\s]+){2}-?[\d.]+%?\s*(?:[,/]\s*)?(?:\b\d+(?:\.\d+)?|\.\d+)?%?\))/giu;
function Ta(e) {
  return isNaN(e) && typeof e == "string" && (e.match(Qn)?.length || 0) + (e.match(Sa)?.length || 0) > 0;
}
const wr = "number", Sr = "color", Ca = "var", ka = "var(", Ni = "${}", Ma = /var\s*\(\s*--(?:[\w-]+\s*|[\w-]+\s*,(?:\s*[^)(\s]|\s*\((?:[^)(]|\([^)(]*\))*\))+\s*)\)|#[\da-f]{3,8}|(?:rgb|hsl)a?\((?:-?[\d.]+%?[,\s]+){2}-?[\d.]+%?\s*(?:[,/]\s*)?(?:\b\d+(?:\.\d+)?|\.\d+)?%?\)|-?(?:\d+(?:\.\d+)?|\.\d+)/giu;
function mt(e) {
  const t = e.toString(), n = [], i = {
    color: [],
    number: [],
    var: []
  }, s = [];
  let o = 0;
  const l = t.replace(Ma, (a) => (Z.test(a) ? (i.color.push(o), s.push(Sr), n.push(Z.parse(a))) : a.startsWith(ka) ? (i.var.push(o), s.push(Ca), n.push(a)) : (i.number.push(o), s.push(wr), n.push(parseFloat(a))), ++o, Ni)).split(Ni);
  return { values: n, split: l, indexes: i, types: s };
}
function Tr(e) {
  return mt(e).values;
}
function Cr(e) {
  const { split: t, types: n } = mt(e), i = t.length;
  return (s) => {
    let o = "";
    for (let r = 0; r < i; r++)
      if (o += t[r], s[r] !== void 0) {
        const l = n[r];
        l === wr ? o += ot(s[r]) : l === Sr ? o += Z.transform(s[r]) : o += s[r];
      }
    return o;
  };
}
const Pa = (e) => typeof e == "number" ? 0 : Z.test(e) ? Z.getAnimatableNone(e) : e;
function Aa(e) {
  const t = Tr(e);
  return Cr(e)(t.map(Pa));
}
const Pe = {
  test: Ta,
  parse: Tr,
  createTransformer: Cr,
  getAnimatableNone: Aa
};
function tn(e, t, n) {
  return n < 0 && (n += 1), n > 1 && (n -= 1), n < 1 / 6 ? e + (t - e) * 6 * n : n < 1 / 2 ? t : n < 2 / 3 ? e + (t - e) * (2 / 3 - n) * 6 : e;
}
function Va({ hue: e, saturation: t, lightness: n, alpha: i }) {
  e /= 360, t /= 100, n /= 100;
  let s = 0, o = 0, r = 0;
  if (!t)
    s = o = r = n;
  else {
    const l = n < 0.5 ? n * (1 + t) : n + t - n * t, a = 2 * n - l;
    s = tn(a, l, e + 1 / 3), o = tn(a, l, e), r = tn(a, l, e - 1 / 3);
  }
  return {
    red: Math.round(s * 255),
    green: Math.round(o * 255),
    blue: Math.round(r * 255),
    alpha: i
  };
}
function jt(e, t) {
  return (n) => n > 0 ? t : e;
}
const G = (e, t, n) => e + (t - e) * n, nn = (e, t, n) => {
  const i = e * e, s = n * (t * t - i) + i;
  return s < 0 ? 0 : Math.sqrt(s);
}, Ea = [yn, Ne, Oe], Ia = (e) => Ea.find((t) => t.test(e));
function Di(e) {
  const t = Ia(e);
  if (!t)
    return !1;
  let n = t.parse(e);
  return t === Oe && (n = Va(n)), n;
}
const Bi = (e, t) => {
  const n = Di(e), i = Di(t);
  if (!n || !i)
    return jt(e, t);
  const s = { ...n };
  return (o) => (s.red = nn(n.red, i.red, o), s.green = nn(n.green, i.green, o), s.blue = nn(n.blue, i.blue, o), s.alpha = G(n.alpha, i.alpha, o), Ne.transform(s));
}, gn = /* @__PURE__ */ new Set(["none", "hidden"]);
function Na(e, t) {
  return gn.has(e) ? (n) => n <= 0 ? e : t : (n) => n >= 1 ? t : e;
}
function Da(e, t) {
  return (n) => G(e, t, n);
}
function ti(e) {
  return typeof e == "number" ? Da : typeof e == "string" ? Jn(e) ? jt : Z.test(e) ? Bi : La : Array.isArray(e) ? kr : typeof e == "object" ? Z.test(e) ? Bi : Ba : jt;
}
function kr(e, t) {
  const n = [...e], i = n.length, s = e.map((o, r) => ti(o)(o, t[r]));
  return (o) => {
    for (let r = 0; r < i; r++)
      n[r] = s[r](o);
    return n;
  };
}
function Ba(e, t) {
  const n = { ...e, ...t }, i = {};
  for (const s in n)
    e[s] !== void 0 && t[s] !== void 0 && (i[s] = ti(e[s])(e[s], t[s]));
  return (s) => {
    for (const o in i)
      n[o] = i[o](s);
    return n;
  };
}
function Ra(e, t) {
  const n = [], i = { color: 0, var: 0, number: 0 };
  for (let s = 0; s < t.values.length; s++) {
    const o = t.types[s], r = e.indexes[o][i[o]], l = e.values[r] ?? 0;
    n[s] = l, i[o]++;
  }
  return n;
}
const La = (e, t) => {
  const n = Pe.createTransformer(t), i = mt(e), s = mt(t);
  return i.indexes.var.length === s.indexes.var.length && i.indexes.color.length === s.indexes.color.length && i.indexes.number.length >= s.indexes.number.length ? gn.has(e) && !s.values.length || gn.has(t) && !i.values.length ? Na(e, t) : Ft(kr(Ra(i, s), s.values), n) : jt(e, t);
};
function Mr(e, t, n) {
  return typeof e == "number" && typeof t == "number" && typeof n == "number" ? G(e, t, n) : ti(e)(e, t);
}
const za = (e) => {
  const t = ({ timestamp: n }) => e(n);
  return {
    start: (n = !0) => $.update(t, n),
    stop: () => ke(t),
    /**
     * If we're processing this frame we can use the
     * framelocked timestamp to keep things in sync.
     */
    now: () => ie.isProcessing ? ie.timestamp : ae.now()
  };
}, Pr = (e, t, n = 10) => {
  let i = "";
  const s = Math.max(Math.round(t / n), 2);
  for (let o = 0; o < s; o++)
    i += Math.round(e(o / (s - 1)) * 1e4) / 1e4 + ", ";
  return `linear(${i.substring(0, i.length - 2)})`;
}, Wt = 2e4;
function ni(e) {
  let t = 0;
  const n = 50;
  let i = e.next(t);
  for (; !i.done && t < Wt; )
    t += n, i = e.next(t);
  return t >= Wt ? 1 / 0 : t;
}
function ja(e, t = 100, n) {
  const i = n({ ...e, keyframes: [0, t] }), s = Math.min(ni(i), Wt);
  return {
    type: "keyframes",
    ease: (o) => i.next(s * o).value / t,
    duration: /* @__PURE__ */ ue(s)
  };
}
const Wa = 5;
function Ar(e, t, n) {
  const i = Math.max(t - Wa, 0);
  return lr(n - e(i), t - i);
}
const q = {
  // Default spring physics
  stiffness: 100,
  damping: 10,
  mass: 1,
  velocity: 0,
  // Default duration/bounce-based options
  duration: 800,
  // in ms
  bounce: 0.3,
  visualDuration: 0.3,
  // in seconds
  // Rest thresholds
  restSpeed: {
    granular: 0.01,
    default: 2
  },
  restDelta: {
    granular: 5e-3,
    default: 0.5
  },
  // Limits
  minDuration: 0.01,
  // in seconds
  maxDuration: 10,
  // in seconds
  minDamping: 0.05,
  maxDamping: 1
}, sn = 1e-3;
function Oa({ duration: e = q.duration, bounce: t = q.bounce, velocity: n = q.velocity, mass: i = q.mass }) {
  let s, o, r = 1 - t;
  r = Te(q.minDamping, q.maxDamping, r), e = Te(q.minDuration, q.maxDuration, /* @__PURE__ */ ue(e)), r < 1 ? (s = (d) => {
    const u = d * r, h = u * e, p = u - n, g = vn(d, r), b = Math.exp(-h);
    return sn - p / g * b;
  }, o = (d) => {
    const h = d * r * e, p = h * n + n, g = Math.pow(r, 2) * Math.pow(d, 2) * e, b = Math.exp(-h), w = vn(Math.pow(d, 2), r);
    return (-s(d) + sn > 0 ? -1 : 1) * ((p - g) * b) / w;
  }) : (s = (d) => {
    const u = Math.exp(-d * e), h = (d - n) * e + 1;
    return -sn + u * h;
  }, o = (d) => {
    const u = Math.exp(-d * e), h = (n - d) * (e * e);
    return u * h;
  });
  const l = 5 / e, a = $a(s, o, l);
  if (e = /* @__PURE__ */ ve(e), isNaN(a))
    return {
      stiffness: q.stiffness,
      damping: q.damping,
      duration: e
    };
  {
    const d = Math.pow(a, 2) * i;
    return {
      stiffness: d,
      damping: r * 2 * Math.sqrt(i * d),
      duration: e
    };
  }
}
const _a = 12;
function $a(e, t, n) {
  let i = n;
  for (let s = 1; s < _a; s++)
    i = i - e(i) / t(i);
  return i;
}
function vn(e, t) {
  return e * Math.sqrt(1 - t * t);
}
const Ua = ["duration", "bounce"], Ga = ["stiffness", "damping", "mass"];
function Ri(e, t) {
  return t.some((n) => e[n] !== void 0);
}
function Ha(e) {
  let t = {
    velocity: q.velocity,
    stiffness: q.stiffness,
    damping: q.damping,
    mass: q.mass,
    isResolvedFromDuration: !1,
    ...e
  };
  if (!Ri(e, Ga) && Ri(e, Ua))
    if (e.visualDuration) {
      const n = e.visualDuration, i = 2 * Math.PI / (n * 1.2), s = i * i, o = 2 * Te(0.05, 1, 1 - (e.bounce || 0)) * Math.sqrt(s);
      t = {
        ...t,
        mass: q.mass,
        stiffness: s,
        damping: o
      };
    } else {
      const n = Oa(e);
      t = {
        ...t,
        ...n,
        mass: q.mass
      }, t.isResolvedFromDuration = !0;
    }
  return t;
}
function Ot(e = q.visualDuration, t = q.bounce) {
  const n = typeof e != "object" ? {
    visualDuration: e,
    keyframes: [0, 1],
    bounce: t
  } : e;
  let { restSpeed: i, restDelta: s } = n;
  const o = n.keyframes[0], r = n.keyframes[n.keyframes.length - 1], l = { done: !1, value: o }, { stiffness: a, damping: d, mass: u, duration: h, velocity: p, isResolvedFromDuration: g } = Ha({
    ...n,
    velocity: -/* @__PURE__ */ ue(n.velocity || 0)
  }), b = p || 0, w = d / (2 * Math.sqrt(a * u)), x = r - o, F = /* @__PURE__ */ ue(Math.sqrt(a / u)), S = Math.abs(x) < 5;
  i || (i = S ? q.restSpeed.granular : q.restSpeed.default), s || (s = S ? q.restDelta.granular : q.restDelta.default);
  let T;
  if (w < 1) {
    const k = vn(F, w);
    T = (I) => {
      const B = Math.exp(-w * F * I);
      return r - B * ((b + w * F * x) / k * Math.sin(k * I) + x * Math.cos(k * I));
    };
  } else if (w === 1)
    T = (k) => r - Math.exp(-F * k) * (x + (b + F * x) * k);
  else {
    const k = F * Math.sqrt(w * w - 1);
    T = (I) => {
      const B = Math.exp(-w * F * I), A = Math.min(k * I, 300);
      return r - B * ((b + w * F * x) * Math.sinh(A) + k * x * Math.cosh(A)) / k;
    };
  }
  const E = {
    calculatedDuration: g && h || null,
    next: (k) => {
      const I = T(k);
      if (g)
        l.done = k >= h;
      else {
        let B = k === 0 ? b : 0;
        w < 1 && (B = k === 0 ? /* @__PURE__ */ ve(b) : Ar(T, k, I));
        const A = Math.abs(B) <= i, Y = Math.abs(r - I) <= s;
        l.done = A && Y;
      }
      return l.value = l.done ? r : I, l;
    },
    toString: () => {
      const k = Math.min(ni(E), Wt), I = Pr((B) => E.next(k * B).value, k, 30);
      return k + "ms " + I;
    },
    toTransition: () => {
    }
  };
  return E;
}
Ot.applyToOptions = (e) => {
  const t = ja(e, 100, Ot);
  return e.ease = t.ease, e.duration = /* @__PURE__ */ ve(t.duration), e.type = "keyframes", e;
};
function bn({ keyframes: e, velocity: t = 0, power: n = 0.8, timeConstant: i = 325, bounceDamping: s = 10, bounceStiffness: o = 500, modifyTarget: r, min: l, max: a, restDelta: d = 0.5, restSpeed: u }) {
  const h = e[0], p = {
    done: !1,
    value: h
  }, g = (A) => l !== void 0 && A < l || a !== void 0 && A > a, b = (A) => l === void 0 ? a : a === void 0 || Math.abs(l - A) < Math.abs(a - A) ? l : a;
  let w = n * t;
  const x = h + w, F = r === void 0 ? x : r(x);
  F !== x && (w = F - h);
  const S = (A) => -w * Math.exp(-A / i), T = (A) => F + S(A), E = (A) => {
    const Y = S(A), te = T(A);
    p.done = Math.abs(Y) <= d, p.value = p.done ? F : te;
  };
  let k, I;
  const B = (A) => {
    g(p.value) && (k = A, I = Ot({
      keyframes: [p.value, b(p.value)],
      velocity: Ar(T, A, p.value),
      // TODO: This should be passing * 1000
      damping: s,
      stiffness: o,
      restDelta: d,
      restSpeed: u
    }));
  };
  return B(0), {
    calculatedDuration: null,
    next: (A) => {
      let Y = !1;
      return !I && k === void 0 && (Y = !0, E(A), B(A)), k !== void 0 && A >= k ? I.next(A - k) : (!Y && E(A), p);
    }
  };
}
function Ka(e, t, n) {
  const i = [], s = n || Ce.mix || Mr, o = e.length - 1;
  for (let r = 0; r < o; r++) {
    let l = s(e[r], e[r + 1]);
    if (t) {
      const a = Array.isArray(t) ? t[r] || he : t;
      l = Ft(a, l);
    }
    i.push(l);
  }
  return i;
}
function Vr(e, t, { clamp: n = !0, ease: i, mixer: s } = {}) {
  const o = e.length;
  if (Hn(o === t.length), o === 1)
    return () => t[0];
  if (o === 2 && t[0] === t[1])
    return () => t[1];
  const r = e[0] === e[1];
  e[0] > e[o - 1] && (e = [...e].reverse(), t = [...t].reverse());
  const l = Ka(t, i, s), a = l.length, d = (u) => {
    if (r && u < e[0])
      return t[0];
    let h = 0;
    if (a > 1)
      for (; h < e.length - 2 && !(u < e[h + 1]); h++)
        ;
    const p = /* @__PURE__ */ ft(e[h], e[h + 1], u);
    return l[h](p);
  };
  return n ? (u) => d(Te(e[0], e[o - 1], u)) : d;
}
function qa(e, t) {
  const n = e[e.length - 1];
  for (let i = 1; i <= t; i++) {
    const s = /* @__PURE__ */ ft(0, t, i);
    e.push(G(n, 1, s));
  }
}
function Xa(e) {
  const t = [0];
  return qa(t, e.length - 1), t;
}
function Ya(e, t) {
  return e.map((n) => n * t);
}
function Za(e, t) {
  return e.map(() => t || gr).splice(0, e.length - 1);
}
function at({ duration: e = 300, keyframes: t, times: n, ease: i = "easeInOut" }) {
  const s = ca(i) ? i.map(Ei) : Ei(i), o = {
    done: !1,
    value: t[0]
  }, r = Ya(
    // Only use the provided offsets if they're the correct length
    // TODO Maybe we should warn here if there's a length mismatch
    n && n.length === t.length ? n : Xa(t),
    e
  ), l = Vr(r, t, {
    ease: Array.isArray(s) ? s : Za(t, s)
  });
  return {
    calculatedDuration: e,
    next: (a) => (o.value = l(a), o.done = a >= e, o)
  };
}
const Ja = (e) => e !== null;
function ii(e, { repeat: t, repeatType: n = "loop" }, i, s = 1) {
  const o = e.filter(Ja), l = s < 0 || t && n !== "loop" && t % 2 === 1 ? 0 : o.length - 1;
  return !l || i === void 0 ? o[l] : i;
}
const Qa = {
  decay: bn,
  inertia: bn,
  tween: at,
  keyframes: at,
  spring: Ot
};
function Er(e) {
  typeof e.type == "string" && (e.type = Qa[e.type]);
}
class si {
  constructor() {
    this.updateFinished();
  }
  get finished() {
    return this._finished;
  }
  updateFinished() {
    this._finished = new Promise((t) => {
      this.resolve = t;
    });
  }
  notifyFinished() {
    this.resolve();
  }
  /**
   * Allows the animation to be awaited.
   *
   * @deprecated Use `finished` instead.
   */
  then(t, n) {
    return this.finished.then(t, n);
  }
}
const el = (e) => e / 100;
class Gt extends si {
  constructor(t) {
    super(), this.state = "idle", this.startTime = null, this.isStopped = !1, this.currentTime = 0, this.holdTime = null, this.playbackSpeed = 1, this.stop = () => {
      const { motionValue: n } = this.options;
      n && n.updatedAt !== ae.now() && this.tick(ae.now()), this.isStopped = !0, this.state !== "idle" && (this.teardown(), this.options.onStop?.());
    }, this.options = t, this.initAnimation(), this.play(), t.autoplay === !1 && this.pause();
  }
  initAnimation() {
    const { options: t } = this;
    Er(t);
    const { type: n = at, repeat: i = 0, repeatDelay: s = 0, repeatType: o, velocity: r = 0 } = t;
    let { keyframes: l } = t;
    const a = n || at;
    a !== at && typeof l[0] != "number" && (this.mixKeyframes = Ft(el, Mr(l[0], l[1])), l = [0, 100]);
    const d = a({ ...t, keyframes: l });
    o === "mirror" && (this.mirroredGenerator = a({
      ...t,
      keyframes: [...l].reverse(),
      velocity: -r
    })), d.calculatedDuration === null && (d.calculatedDuration = ni(d));
    const { calculatedDuration: u } = d;
    this.calculatedDuration = u, this.resolvedDuration = u + s, this.totalDuration = this.resolvedDuration * (i + 1) - s, this.generator = d;
  }
  updateTime(t) {
    const n = Math.round(t - this.startTime) * this.playbackSpeed;
    this.holdTime !== null ? this.currentTime = this.holdTime : this.currentTime = n;
  }
  tick(t, n = !1) {
    const { generator: i, totalDuration: s, mixKeyframes: o, mirroredGenerator: r, resolvedDuration: l, calculatedDuration: a } = this;
    if (this.startTime === null)
      return i.next(0);
    const { delay: d = 0, keyframes: u, repeat: h, repeatType: p, repeatDelay: g, type: b, onUpdate: w, finalKeyframe: x } = this.options;
    this.speed > 0 ? this.startTime = Math.min(this.startTime, t) : this.speed < 0 && (this.startTime = Math.min(t - s / this.speed, this.startTime)), n ? this.currentTime = t : this.updateTime(t);
    const F = this.currentTime - d * (this.playbackSpeed >= 0 ? 1 : -1), S = this.playbackSpeed >= 0 ? F < 0 : F > s;
    this.currentTime = Math.max(F, 0), this.state === "finished" && this.holdTime === null && (this.currentTime = s);
    let T = this.currentTime, E = i;
    if (h) {
      const A = Math.min(this.currentTime, s) / l;
      let Y = Math.floor(A), te = A % 1;
      !te && A >= 1 && (te = 1), te === 1 && Y--, Y = Math.min(Y, h + 1), !!(Y % 2) && (p === "reverse" ? (te = 1 - te, g && (te -= g / l)) : p === "mirror" && (E = r)), T = Te(0, 1, te) * l;
    }
    const k = S ? { done: !1, value: u[0] } : E.next(T);
    o && (k.value = o(k.value));
    let { done: I } = k;
    !S && a !== null && (I = this.playbackSpeed >= 0 ? this.currentTime >= s : this.currentTime <= 0);
    const B = this.holdTime === null && (this.state === "finished" || this.state === "running" && I);
    return B && b !== bn && (k.value = ii(u, this.options, x, this.speed)), w && w(k.value), B && this.finish(), k;
  }
  /**
   * Allows the returned animation to be awaited or promise-chained. Currently
   * resolves when the animation finishes at all but in a future update could/should
   * reject if its cancels.
   */
  then(t, n) {
    return this.finished.then(t, n);
  }
  get duration() {
    return /* @__PURE__ */ ue(this.calculatedDuration);
  }
  get iterationDuration() {
    const { delay: t = 0 } = this.options || {};
    return this.duration + /* @__PURE__ */ ue(t);
  }
  get time() {
    return /* @__PURE__ */ ue(this.currentTime);
  }
  set time(t) {
    t = /* @__PURE__ */ ve(t), this.currentTime = t, this.startTime === null || this.holdTime !== null || this.playbackSpeed === 0 ? this.holdTime = t : this.driver && (this.startTime = this.driver.now() - t / this.playbackSpeed), this.driver?.start(!1);
  }
  get speed() {
    return this.playbackSpeed;
  }
  set speed(t) {
    this.updateTime(ae.now());
    const n = this.playbackSpeed !== t;
    this.playbackSpeed = t, n && (this.time = /* @__PURE__ */ ue(this.currentTime));
  }
  play() {
    if (this.isStopped)
      return;
    const { driver: t = za, startTime: n } = this.options;
    this.driver || (this.driver = t((s) => this.tick(s))), this.options.onPlay?.();
    const i = this.driver.now();
    this.state === "finished" ? (this.updateFinished(), this.startTime = i) : this.holdTime !== null ? this.startTime = i - this.holdTime : this.startTime || (this.startTime = n ?? i), this.state === "finished" && this.speed < 0 && (this.startTime += this.calculatedDuration), this.holdTime = null, this.state = "running", this.driver.start();
  }
  pause() {
    this.state = "paused", this.updateTime(ae.now()), this.holdTime = this.currentTime;
  }
  complete() {
    this.state !== "running" && this.play(), this.state = "finished", this.holdTime = null;
  }
  finish() {
    this.notifyFinished(), this.teardown(), this.state = "finished", this.options.onComplete?.();
  }
  cancel() {
    this.holdTime = null, this.startTime = 0, this.tick(0), this.teardown(), this.options.onCancel?.();
  }
  teardown() {
    this.state = "idle", this.stopDriver(), this.startTime = this.holdTime = null;
  }
  stopDriver() {
    this.driver && (this.driver.stop(), this.driver = void 0);
  }
  sample(t) {
    return this.startTime = 0, this.tick(t, !0);
  }
  attachTimeline(t) {
    return this.options.allowFlatten && (this.options.type = "keyframes", this.options.ease = "linear", this.initAnimation()), this.driver?.stop(), t.observe(this);
  }
}
function tl(e) {
  for (let t = 1; t < e.length; t++)
    e[t] ?? (e[t] = e[t - 1]);
}
const De = (e) => e * 180 / Math.PI, xn = (e) => {
  const t = De(Math.atan2(e[1], e[0]));
  return Fn(t);
}, nl = {
  x: 4,
  y: 5,
  translateX: 4,
  translateY: 5,
  scaleX: 0,
  scaleY: 3,
  scale: (e) => (Math.abs(e[0]) + Math.abs(e[3])) / 2,
  rotate: xn,
  rotateZ: xn,
  skewX: (e) => De(Math.atan(e[1])),
  skewY: (e) => De(Math.atan(e[2])),
  skew: (e) => (Math.abs(e[1]) + Math.abs(e[2])) / 2
}, Fn = (e) => (e = e % 360, e < 0 && (e += 360), e), Li = xn, zi = (e) => Math.sqrt(e[0] * e[0] + e[1] * e[1]), ji = (e) => Math.sqrt(e[4] * e[4] + e[5] * e[5]), il = {
  x: 12,
  y: 13,
  z: 14,
  translateX: 12,
  translateY: 13,
  translateZ: 14,
  scaleX: zi,
  scaleY: ji,
  scale: (e) => (zi(e) + ji(e)) / 2,
  rotateX: (e) => Fn(De(Math.atan2(e[6], e[5]))),
  rotateY: (e) => Fn(De(Math.atan2(-e[2], e[0]))),
  rotateZ: Li,
  rotate: Li,
  skewX: (e) => De(Math.atan(e[4])),
  skewY: (e) => De(Math.atan(e[1])),
  skew: (e) => (Math.abs(e[1]) + Math.abs(e[4])) / 2
};
function wn(e) {
  return e.includes("scale") ? 1 : 0;
}
function Sn(e, t) {
  if (!e || e === "none")
    return wn(t);
  const n = e.match(/^matrix3d\(([-\d.e\s,]+)\)$/u);
  let i, s;
  if (n)
    i = il, s = n;
  else {
    const l = e.match(/^matrix\(([-\d.e\s,]+)\)$/u);
    i = nl, s = l;
  }
  if (!s)
    return wn(t);
  const o = i[t], r = s[1].split(",").map(rl);
  return typeof o == "function" ? o(r) : r[o];
}
const sl = (e, t) => {
  const { transform: n = "none" } = getComputedStyle(e);
  return Sn(n, t);
};
function rl(e) {
  return parseFloat(e.trim());
}
const Je = [
  "transformPerspective",
  "x",
  "y",
  "z",
  "translateX",
  "translateY",
  "translateZ",
  "scale",
  "scaleX",
  "scaleY",
  "rotate",
  "rotateX",
  "rotateY",
  "rotateZ",
  "skew",
  "skewX",
  "skewY"
], Qe = new Set(Je), Wi = (e) => e === Ze || e === M, ol = /* @__PURE__ */ new Set(["x", "y", "z"]), al = Je.filter((e) => !ol.has(e));
function ll(e) {
  const t = [];
  return al.forEach((n) => {
    const i = e.getValue(n);
    i !== void 0 && (t.push([n, i.get()]), i.set(n.startsWith("scale") ? 1 : 0));
  }), t;
}
const Be = {
  // Dimensions
  width: ({ x: e }, { paddingLeft: t = "0", paddingRight: n = "0" }) => e.max - e.min - parseFloat(t) - parseFloat(n),
  height: ({ y: e }, { paddingTop: t = "0", paddingBottom: n = "0" }) => e.max - e.min - parseFloat(t) - parseFloat(n),
  top: (e, { top: t }) => parseFloat(t),
  left: (e, { left: t }) => parseFloat(t),
  bottom: ({ y: e }, { top: t }) => parseFloat(t) + (e.max - e.min),
  right: ({ x: e }, { left: t }) => parseFloat(t) + (e.max - e.min),
  // Transform
  x: (e, { transform: t }) => Sn(t, "x"),
  y: (e, { transform: t }) => Sn(t, "y")
};
Be.translateX = Be.x;
Be.translateY = Be.y;
const Re = /* @__PURE__ */ new Set();
let Tn = !1, Cn = !1, kn = !1;
function Ir() {
  if (Cn) {
    const e = Array.from(Re).filter((i) => i.needsMeasurement), t = new Set(e.map((i) => i.element)), n = /* @__PURE__ */ new Map();
    t.forEach((i) => {
      const s = ll(i);
      s.length && (n.set(i, s), i.render());
    }), e.forEach((i) => i.measureInitialState()), t.forEach((i) => {
      i.render();
      const s = n.get(i);
      s && s.forEach(([o, r]) => {
        i.getValue(o)?.set(r);
      });
    }), e.forEach((i) => i.measureEndState()), e.forEach((i) => {
      i.suspendedScrollY !== void 0 && window.scrollTo(0, i.suspendedScrollY);
    });
  }
  Cn = !1, Tn = !1, Re.forEach((e) => e.complete(kn)), Re.clear();
}
function Nr() {
  Re.forEach((e) => {
    e.readKeyframes(), e.needsMeasurement && (Cn = !0);
  });
}
function cl() {
  kn = !0, Nr(), Ir(), kn = !1;
}
class ri {
  constructor(t, n, i, s, o, r = !1) {
    this.state = "pending", this.isAsync = !1, this.needsMeasurement = !1, this.unresolvedKeyframes = [...t], this.onComplete = n, this.name = i, this.motionValue = s, this.element = o, this.isAsync = r;
  }
  scheduleResolve() {
    this.state = "scheduled", this.isAsync ? (Re.add(this), Tn || (Tn = !0, $.read(Nr), $.resolveKeyframes(Ir))) : (this.readKeyframes(), this.complete());
  }
  readKeyframes() {
    const { unresolvedKeyframes: t, name: n, element: i, motionValue: s } = this;
    if (t[0] === null) {
      const o = s?.get(), r = t[t.length - 1];
      if (o !== void 0)
        t[0] = o;
      else if (i && n) {
        const l = i.readValue(n, r);
        l != null && (t[0] = l);
      }
      t[0] === void 0 && (t[0] = r), s && o === void 0 && s.set(t[0]);
    }
    tl(t);
  }
  setFinalKeyframe() {
  }
  measureInitialState() {
  }
  renderEndStyles() {
  }
  measureEndState() {
  }
  complete(t = !1) {
    this.state = "complete", this.onComplete(this.unresolvedKeyframes, this.finalKeyframe, t), Re.delete(this);
  }
  cancel() {
    this.state === "scheduled" && (Re.delete(this), this.state = "pending");
  }
  resume() {
    this.state === "pending" && this.scheduleResolve();
  }
}
const dl = (e) => e.startsWith("--");
function ul(e, t, n) {
  dl(t) ? e.style.setProperty(t, n) : e.style[t] = n;
}
const hl = /* @__PURE__ */ Kn(() => window.ScrollTimeline !== void 0), fl = {};
function pl(e, t) {
  const n = /* @__PURE__ */ Kn(e);
  return () => fl[t] ?? n();
}
const Dr = /* @__PURE__ */ pl(() => {
  try {
    document.createElement("div").animate({ opacity: 0 }, { easing: "linear(0, 1)" });
  } catch {
    return !1;
  }
  return !0;
}, "linearEasing"), rt = ([e, t, n, i]) => `cubic-bezier(${e}, ${t}, ${n}, ${i})`, Oi = {
  linear: "linear",
  ease: "ease",
  easeIn: "ease-in",
  easeOut: "ease-out",
  easeInOut: "ease-in-out",
  circIn: /* @__PURE__ */ rt([0, 0.65, 0.55, 1]),
  circOut: /* @__PURE__ */ rt([0.55, 0, 1, 0.45]),
  backIn: /* @__PURE__ */ rt([0.31, 0.01, 0.66, -0.59]),
  backOut: /* @__PURE__ */ rt([0.33, 1.53, 0.69, 0.99])
};
function Br(e, t) {
  if (e)
    return typeof e == "function" ? Dr() ? Pr(e, t) : "ease-out" : vr(e) ? rt(e) : Array.isArray(e) ? e.map((n) => Br(n, t) || Oi.easeOut) : Oi[e];
}
function ml(e, t, n, { delay: i = 0, duration: s = 300, repeat: o = 0, repeatType: r = "loop", ease: l = "easeOut", times: a } = {}, d = void 0) {
  const u = {
    [t]: n
  };
  a && (u.offset = a);
  const h = Br(l, s);
  Array.isArray(h) && (u.easing = h);
  const p = {
    delay: i,
    duration: s,
    easing: Array.isArray(h) ? "linear" : h,
    fill: "both",
    iterations: o + 1,
    direction: r === "reverse" ? "alternate" : "normal"
  };
  return d && (p.pseudoElement = d), e.animate(u, p);
}
function Rr(e) {
  return typeof e == "function" && "applyToOptions" in e;
}
function yl({ type: e, ...t }) {
  return Rr(e) && Dr() ? e.applyToOptions(t) : (t.duration ?? (t.duration = 300), t.ease ?? (t.ease = "easeOut"), t);
}
class gl extends si {
  constructor(t) {
    if (super(), this.finishedTime = null, this.isStopped = !1, !t)
      return;
    const { element: n, name: i, keyframes: s, pseudoElement: o, allowFlatten: r = !1, finalKeyframe: l, onComplete: a } = t;
    this.isPseudoElement = !!o, this.allowFlatten = r, this.options = t, Hn(typeof t.type != "string");
    const d = yl(t);
    this.animation = ml(n, i, s, d, o), d.autoplay === !1 && this.animation.pause(), this.animation.onfinish = () => {
      if (this.finishedTime = this.time, !o) {
        const u = ii(s, this.options, l, this.speed);
        this.updateMotionValue ? this.updateMotionValue(u) : ul(n, i, u), this.animation.cancel();
      }
      a?.(), this.notifyFinished();
    };
  }
  play() {
    this.isStopped || (this.animation.play(), this.state === "finished" && this.updateFinished());
  }
  pause() {
    this.animation.pause();
  }
  complete() {
    this.animation.finish?.();
  }
  cancel() {
    try {
      this.animation.cancel();
    } catch {
    }
  }
  stop() {
    if (this.isStopped)
      return;
    this.isStopped = !0;
    const { state: t } = this;
    t === "idle" || t === "finished" || (this.updateMotionValue ? this.updateMotionValue() : this.commitStyles(), this.isPseudoElement || this.cancel());
  }
  /**
   * WAAPI doesn't natively have any interruption capabilities.
   *
   * In this method, we commit styles back to the DOM before cancelling
   * the animation.
   *
   * This is designed to be overridden by NativeAnimationExtended, which
   * will create a renderless JS animation and sample it twice to calculate
   * its current value, "previous" value, and therefore allow
   * Motion to also correctly calculate velocity for any subsequent animation
   * while deferring the commit until the next animation frame.
   */
  commitStyles() {
    this.isPseudoElement || this.animation.commitStyles?.();
  }
  get duration() {
    const t = this.animation.effect?.getComputedTiming?.().duration || 0;
    return /* @__PURE__ */ ue(Number(t));
  }
  get iterationDuration() {
    const { delay: t = 0 } = this.options || {};
    return this.duration + /* @__PURE__ */ ue(t);
  }
  get time() {
    return /* @__PURE__ */ ue(Number(this.animation.currentTime) || 0);
  }
  set time(t) {
    this.finishedTime = null, this.animation.currentTime = /* @__PURE__ */ ve(t);
  }
  /**
   * The playback speed of the animation.
   * 1 = normal speed, 2 = double speed, 0.5 = half speed.
   */
  get speed() {
    return this.animation.playbackRate;
  }
  set speed(t) {
    t < 0 && (this.finishedTime = null), this.animation.playbackRate = t;
  }
  get state() {
    return this.finishedTime !== null ? "finished" : this.animation.playState;
  }
  get startTime() {
    return Number(this.animation.startTime);
  }
  set startTime(t) {
    this.animation.startTime = t;
  }
  /**
   * Attaches a timeline to the animation, for instance the `ScrollTimeline`.
   */
  attachTimeline({ timeline: t, observe: n }) {
    return this.allowFlatten && this.animation.effect?.updateTiming({ easing: "linear" }), this.animation.onfinish = null, t && hl() ? (this.animation.timeline = t, he) : n(this);
  }
}
const Lr = {
  anticipate: pr,
  backInOut: fr,
  circInOut: yr
};
function vl(e) {
  return e in Lr;
}
function bl(e) {
  typeof e.ease == "string" && vl(e.ease) && (e.ease = Lr[e.ease]);
}
const _i = 10;
class xl extends gl {
  constructor(t) {
    bl(t), Er(t), super(t), t.startTime && (this.startTime = t.startTime), this.options = t;
  }
  /**
   * WAAPI doesn't natively have any interruption capabilities.
   *
   * Rather than read commited styles back out of the DOM, we can
   * create a renderless JS animation and sample it twice to calculate
   * its current value, "previous" value, and therefore allow
   * Motion to calculate velocity for any subsequent animation.
   */
  updateMotionValue(t) {
    const { motionValue: n, onUpdate: i, onComplete: s, element: o, ...r } = this.options;
    if (!n)
      return;
    if (t !== void 0) {
      n.set(t);
      return;
    }
    const l = new Gt({
      ...r,
      autoplay: !1
    }), a = /* @__PURE__ */ ve(this.finishedTime ?? this.time);
    n.setWithVelocity(l.sample(a - _i).value, l.sample(a).value, _i), l.stop();
  }
}
const $i = (e, t) => t === "zIndex" ? !1 : !!(typeof e == "number" || Array.isArray(e) || typeof e == "string" && // It's animatable if we have a string
(Pe.test(e) || e === "0") && // And it contains numbers and/or colors
!e.startsWith("url("));
function Fl(e) {
  const t = e[0];
  if (e.length === 1)
    return !0;
  for (let n = 0; n < e.length; n++)
    if (e[n] !== t)
      return !0;
}
function wl(e, t, n, i) {
  const s = e[0];
  if (s === null)
    return !1;
  if (t === "display" || t === "visibility")
    return !0;
  const o = e[e.length - 1], r = $i(s, t), l = $i(o, t);
  return !r || !l ? !1 : Fl(e) || (n === "spring" || Rr(n)) && i;
}
function Mn(e) {
  e.duration = 0, e.type = "keyframes";
}
const Sl = /* @__PURE__ */ new Set([
  "opacity",
  "clipPath",
  "filter",
  "transform"
  // TODO: Could be re-enabled now we have support for linear() easing
  // "background-color"
]), Tl = /* @__PURE__ */ Kn(() => Object.hasOwnProperty.call(Element.prototype, "animate"));
function Cl(e) {
  const { motionValue: t, name: n, repeatDelay: i, repeatType: s, damping: o, type: r } = e;
  if (!(t?.owner?.current instanceof HTMLElement))
    return !1;
  const { onUpdate: a, transformTemplate: d } = t.owner.getProps();
  return Tl() && n && Sl.has(n) && (n !== "transform" || !d) && /**
   * If we're outputting values to onUpdate then we can't use WAAPI as there's
   * no way to read the value from WAAPI every frame.
   */
  !a && !i && s !== "mirror" && o !== 0 && r !== "inertia";
}
const kl = 40;
class Ml extends si {
  constructor({ autoplay: t = !0, delay: n = 0, type: i = "keyframes", repeat: s = 0, repeatDelay: o = 0, repeatType: r = "loop", keyframes: l, name: a, motionValue: d, element: u, ...h }) {
    super(), this.stop = () => {
      this._animation && (this._animation.stop(), this.stopTimeline?.()), this.keyframeResolver?.cancel();
    }, this.createdAt = ae.now();
    const p = {
      autoplay: t,
      delay: n,
      type: i,
      repeat: s,
      repeatDelay: o,
      repeatType: r,
      name: a,
      motionValue: d,
      element: u,
      ...h
    }, g = u?.KeyframeResolver || ri;
    this.keyframeResolver = new g(l, (b, w, x) => this.onKeyframesResolved(b, w, p, !x), a, d, u), this.keyframeResolver?.scheduleResolve();
  }
  onKeyframesResolved(t, n, i, s) {
    this.keyframeResolver = void 0;
    const { name: o, type: r, velocity: l, delay: a, isHandoff: d, onUpdate: u } = i;
    this.resolvedAt = ae.now(), wl(t, o, r, l) || ((Ce.instantAnimations || !a) && u?.(ii(t, i, n)), t[0] = t[t.length - 1], Mn(i), i.repeat = 0);
    const p = {
      startTime: s ? this.resolvedAt ? this.resolvedAt - this.createdAt > kl ? this.resolvedAt : this.createdAt : this.createdAt : void 0,
      finalKeyframe: n,
      ...i,
      keyframes: t
    }, g = !d && Cl(p) ? new xl({
      ...p,
      element: p.motionValue.owner.current
    }) : new Gt(p);
    g.finished.then(() => this.notifyFinished()).catch(he), this.pendingTimeline && (this.stopTimeline = g.attachTimeline(this.pendingTimeline), this.pendingTimeline = void 0), this._animation = g;
  }
  get finished() {
    return this._animation ? this.animation.finished : this._finished;
  }
  then(t, n) {
    return this.finished.finally(t).then(() => {
    });
  }
  get animation() {
    return this._animation || (this.keyframeResolver?.resume(), cl()), this._animation;
  }
  get duration() {
    return this.animation.duration;
  }
  get iterationDuration() {
    return this.animation.iterationDuration;
  }
  get time() {
    return this.animation.time;
  }
  set time(t) {
    this.animation.time = t;
  }
  get speed() {
    return this.animation.speed;
  }
  get state() {
    return this.animation.state;
  }
  set speed(t) {
    this.animation.speed = t;
  }
  get startTime() {
    return this.animation.startTime;
  }
  attachTimeline(t) {
    return this._animation ? this.stopTimeline = this.animation.attachTimeline(t) : this.pendingTimeline = t, () => this.stop();
  }
  play() {
    this.animation.play();
  }
  pause() {
    this.animation.pause();
  }
  complete() {
    this.animation.complete();
  }
  cancel() {
    this._animation && this.animation.cancel(), this.keyframeResolver?.cancel();
  }
}
const Pl = (
  // eslint-disable-next-line redos-detector/no-unsafe-regex -- false positive, as it can match a lot of words
  /^var\(--(?:([\w-]+)|([\w-]+), ?([a-zA-Z\d ()%#.,-]+))\)/u
);
function Al(e) {
  const t = Pl.exec(e);
  if (!t)
    return [,];
  const [, n, i, s] = t;
  return [`--${n ?? i}`, s];
}
function zr(e, t, n = 1) {
  const [i, s] = Al(e);
  if (!i)
    return;
  const o = window.getComputedStyle(t).getPropertyValue(i);
  if (o) {
    const r = o.trim();
    return rr(r) ? parseFloat(r) : r;
  }
  return Jn(s) ? zr(s, t, n + 1) : s;
}
function oi(e, t) {
  return e?.[t] ?? e?.default ?? e;
}
const jr = /* @__PURE__ */ new Set([
  "width",
  "height",
  "top",
  "left",
  "right",
  "bottom",
  ...Je
]), Vl = {
  test: (e) => e === "auto",
  parse: (e) => e
}, Wr = (e) => (t) => t.test(e), Or = [Ze, M, be, Me, wa, Fa, Vl], Ui = (e) => Or.find(Wr(e));
function El(e) {
  return typeof e == "number" ? e === 0 : e !== null ? e === "none" || e === "0" || ar(e) : !0;
}
const Il = /* @__PURE__ */ new Set(["brightness", "contrast", "saturate", "opacity"]);
function Nl(e) {
  const [t, n] = e.slice(0, -1).split("(");
  if (t === "drop-shadow")
    return e;
  const [i] = n.match(Qn) || [];
  if (!i)
    return e;
  const s = n.replace(i, "");
  let o = Il.has(t) ? 1 : 0;
  return i !== n && (o *= 100), t + "(" + o + s + ")";
}
const Dl = /\b([a-z-]*)\(.*?\)/gu, Pn = {
  ...Pe,
  getAnimatableNone: (e) => {
    const t = e.match(Dl);
    return t ? t.map(Nl).join(" ") : e;
  }
}, Gi = {
  ...Ze,
  transform: Math.round
}, Bl = {
  rotate: Me,
  rotateX: Me,
  rotateY: Me,
  rotateZ: Me,
  scale: Vt,
  scaleX: Vt,
  scaleY: Vt,
  scaleZ: Vt,
  skew: Me,
  skewX: Me,
  skewY: Me,
  distance: M,
  translateX: M,
  translateY: M,
  translateZ: M,
  x: M,
  y: M,
  z: M,
  perspective: M,
  transformPerspective: M,
  opacity: pt,
  originX: Ii,
  originY: Ii,
  originZ: M
}, ai = {
  // Border props
  borderWidth: M,
  borderTopWidth: M,
  borderRightWidth: M,
  borderBottomWidth: M,
  borderLeftWidth: M,
  borderRadius: M,
  radius: M,
  borderTopLeftRadius: M,
  borderTopRightRadius: M,
  borderBottomRightRadius: M,
  borderBottomLeftRadius: M,
  // Positioning props
  width: M,
  maxWidth: M,
  height: M,
  maxHeight: M,
  top: M,
  right: M,
  bottom: M,
  left: M,
  // Spacing props
  padding: M,
  paddingTop: M,
  paddingRight: M,
  paddingBottom: M,
  paddingLeft: M,
  margin: M,
  marginTop: M,
  marginRight: M,
  marginBottom: M,
  marginLeft: M,
  // Misc
  backgroundPositionX: M,
  backgroundPositionY: M,
  ...Bl,
  zIndex: Gi,
  // SVG
  fillOpacity: pt,
  strokeOpacity: pt,
  numOctaves: Gi
}, Rl = {
  ...ai,
  // Color props
  color: Z,
  backgroundColor: Z,
  outlineColor: Z,
  fill: Z,
  stroke: Z,
  // Border props
  borderColor: Z,
  borderTopColor: Z,
  borderRightColor: Z,
  borderBottomColor: Z,
  borderLeftColor: Z,
  filter: Pn,
  WebkitFilter: Pn
}, _r = (e) => Rl[e];
function $r(e, t) {
  let n = _r(e);
  return n !== Pn && (n = Pe), n.getAnimatableNone ? n.getAnimatableNone(t) : void 0;
}
const Ll = /* @__PURE__ */ new Set(["auto", "none", "0"]);
function zl(e, t, n) {
  let i = 0, s;
  for (; i < e.length && !s; ) {
    const o = e[i];
    typeof o == "string" && !Ll.has(o) && mt(o).values.length && (s = e[i]), i++;
  }
  if (s && n)
    for (const o of t)
      e[o] = $r(n, s);
}
class jl extends ri {
  constructor(t, n, i, s, o) {
    super(t, n, i, s, o, !0);
  }
  readKeyframes() {
    const { unresolvedKeyframes: t, element: n, name: i } = this;
    if (!n || !n.current)
      return;
    super.readKeyframes();
    for (let a = 0; a < t.length; a++) {
      let d = t[a];
      if (typeof d == "string" && (d = d.trim(), Jn(d))) {
        const u = zr(d, n.current);
        u !== void 0 && (t[a] = u), a === t.length - 1 && (this.finalKeyframe = d);
      }
    }
    if (this.resolveNoneKeyframes(), !jr.has(i) || t.length !== 2)
      return;
    const [s, o] = t, r = Ui(s), l = Ui(o);
    if (r !== l)
      if (Wi(r) && Wi(l))
        for (let a = 0; a < t.length; a++) {
          const d = t[a];
          typeof d == "string" && (t[a] = parseFloat(d));
        }
      else Be[i] && (this.needsMeasurement = !0);
  }
  resolveNoneKeyframes() {
    const { unresolvedKeyframes: t, name: n } = this, i = [];
    for (let s = 0; s < t.length; s++)
      (t[s] === null || El(t[s])) && i.push(s);
    i.length && zl(t, i, n);
  }
  measureInitialState() {
    const { element: t, unresolvedKeyframes: n, name: i } = this;
    if (!t || !t.current)
      return;
    i === "height" && (this.suspendedScrollY = window.pageYOffset), this.measuredOrigin = Be[i](t.measureViewportBox(), window.getComputedStyle(t.current)), n[0] = this.measuredOrigin;
    const s = n[n.length - 1];
    s !== void 0 && t.getValue(i, s).jump(s, !1);
  }
  measureEndState() {
    const { element: t, name: n, unresolvedKeyframes: i } = this;
    if (!t || !t.current)
      return;
    const s = t.getValue(n);
    s && s.jump(this.measuredOrigin, !1);
    const o = i.length - 1, r = i[o];
    i[o] = Be[n](t.measureViewportBox(), window.getComputedStyle(t.current)), r !== null && this.finalKeyframe === void 0 && (this.finalKeyframe = r), this.removedTransforms?.length && this.removedTransforms.forEach(([l, a]) => {
      t.getValue(l).set(a);
    }), this.resolveNoneKeyframes();
  }
}
function Wl(e, t, n) {
  if (e instanceof EventTarget)
    return [e];
  if (typeof e == "string") {
    let i = document;
    const s = n?.[e] ?? i.querySelectorAll(e);
    return s ? Array.from(s) : [];
  }
  return Array.from(e);
}
const Ur = (e, t) => t && typeof e == "number" ? t.transform(e) : e;
function Gr(e) {
  return or(e) && "offsetHeight" in e;
}
const Hi = 30, Ol = (e) => !isNaN(parseFloat(e)), lt = {
  current: void 0
};
class _l {
  /**
   * @param init - The initiating value
   * @param config - Optional configuration options
   *
   * -  `transformer`: A function to transform incoming values with.
   */
  constructor(t, n = {}) {
    this.canTrackVelocity = null, this.events = {}, this.updateAndNotify = (i) => {
      const s = ae.now();
      if (this.updatedAt !== s && this.setPrevFrameValue(), this.prev = this.current, this.setCurrent(i), this.current !== this.prev && (this.events.change?.notify(this.current), this.dependents))
        for (const o of this.dependents)
          o.dirty();
    }, this.hasAnimated = !1, this.setCurrent(t), this.owner = n.owner;
  }
  setCurrent(t) {
    this.current = t, this.updatedAt = ae.now(), this.canTrackVelocity === null && t !== void 0 && (this.canTrackVelocity = Ol(this.current));
  }
  setPrevFrameValue(t = this.current) {
    this.prevFrameValue = t, this.prevUpdatedAt = this.updatedAt;
  }
  /**
   * Adds a function that will be notified when the `MotionValue` is updated.
   *
   * It returns a function that, when called, will cancel the subscription.
   *
   * When calling `onChange` inside a React component, it should be wrapped with the
   * `useEffect` hook. As it returns an unsubscribe function, this should be returned
   * from the `useEffect` function to ensure you don't add duplicate subscribers..
   *
   * ```jsx
   * export const MyComponent = () => {
   *   const x = useMotionValue(0)
   *   const y = useMotionValue(0)
   *   const opacity = useMotionValue(1)
   *
   *   useEffect(() => {
   *     function updateOpacity() {
   *       const maxXY = Math.max(x.get(), y.get())
   *       const newOpacity = transform(maxXY, [0, 100], [1, 0])
   *       opacity.set(newOpacity)
   *     }
   *
   *     const unsubscribeX = x.on("change", updateOpacity)
   *     const unsubscribeY = y.on("change", updateOpacity)
   *
   *     return () => {
   *       unsubscribeX()
   *       unsubscribeY()
   *     }
   *   }, [])
   *
   *   return <motion.div style={{ x }} />
   * }
   * ```
   *
   * @param subscriber - A function that receives the latest value.
   * @returns A function that, when called, will cancel this subscription.
   *
   * @deprecated
   */
  onChange(t) {
    return this.on("change", t);
  }
  on(t, n) {
    this.events[t] || (this.events[t] = new qn());
    const i = this.events[t].add(n);
    return t === "change" ? () => {
      i(), $.read(() => {
        this.events.change.getSize() || this.stop();
      });
    } : i;
  }
  clearListeners() {
    for (const t in this.events)
      this.events[t].clear();
  }
  /**
   * Attaches a passive effect to the `MotionValue`.
   */
  attach(t, n) {
    this.passiveEffect = t, this.stopPassiveEffect = n;
  }
  /**
   * Sets the state of the `MotionValue`.
   *
   * @remarks
   *
   * ```jsx
   * const x = useMotionValue(0)
   * x.set(10)
   * ```
   *
   * @param latest - Latest value to set.
   * @param render - Whether to notify render subscribers. Defaults to `true`
   *
   * @public
   */
  set(t) {
    this.passiveEffect ? this.passiveEffect(t, this.updateAndNotify) : this.updateAndNotify(t);
  }
  setWithVelocity(t, n, i) {
    this.set(n), this.prev = void 0, this.prevFrameValue = t, this.prevUpdatedAt = this.updatedAt - i;
  }
  /**
   * Set the state of the `MotionValue`, stopping any active animations,
   * effects, and resets velocity to `0`.
   */
  jump(t, n = !0) {
    this.updateAndNotify(t), this.prev = t, this.prevUpdatedAt = this.prevFrameValue = void 0, n && this.stop(), this.stopPassiveEffect && this.stopPassiveEffect();
  }
  dirty() {
    this.events.change?.notify(this.current);
  }
  addDependent(t) {
    this.dependents || (this.dependents = /* @__PURE__ */ new Set()), this.dependents.add(t);
  }
  removeDependent(t) {
    this.dependents && this.dependents.delete(t);
  }
  /**
   * Returns the latest state of `MotionValue`
   *
   * @returns - The latest state of `MotionValue`
   *
   * @public
   */
  get() {
    return lt.current && lt.current.push(this), this.current;
  }
  /**
   * @public
   */
  getPrevious() {
    return this.prev;
  }
  /**
   * Returns the latest velocity of `MotionValue`
   *
   * @returns - The latest velocity of `MotionValue`. Returns `0` if the state is non-numerical.
   *
   * @public
   */
  getVelocity() {
    const t = ae.now();
    if (!this.canTrackVelocity || this.prevFrameValue === void 0 || t - this.updatedAt > Hi)
      return 0;
    const n = Math.min(this.updatedAt - this.prevUpdatedAt, Hi);
    return lr(parseFloat(this.current) - parseFloat(this.prevFrameValue), n);
  }
  /**
   * Registers a new animation to control this `MotionValue`. Only one
   * animation can drive a `MotionValue` at one time.
   *
   * ```jsx
   * value.start()
   * ```
   *
   * @param animation - A function that starts the provided animation
   */
  start(t) {
    return this.stop(), new Promise((n) => {
      this.hasAnimated = !0, this.animation = t(n), this.events.animationStart && this.events.animationStart.notify();
    }).then(() => {
      this.events.animationComplete && this.events.animationComplete.notify(), this.clearAnimation();
    });
  }
  /**
   * Stop the currently active animation.
   *
   * @public
   */
  stop() {
    this.animation && (this.animation.stop(), this.events.animationCancel && this.events.animationCancel.notify()), this.clearAnimation();
  }
  /**
   * Returns `true` if this value is currently animating.
   *
   * @public
   */
  isAnimating() {
    return !!this.animation;
  }
  clearAnimation() {
    delete this.animation;
  }
  /**
   * Destroy and clean up subscribers to this `MotionValue`.
   *
   * The `MotionValue` hooks like `useMotionValue` and `useTransform` automatically
   * handle the lifecycle of the returned `MotionValue`, so this method is only necessary if you've manually
   * created a `MotionValue` via the `motionValue` function.
   *
   * @public
   */
  destroy() {
    this.dependents?.clear(), this.events.destroy?.notify(), this.clearListeners(), this.stop(), this.stopPassiveEffect && this.stopPassiveEffect();
  }
}
function ze(e, t) {
  return new _l(e, t);
}
const { schedule: li } = /* @__PURE__ */ br(queueMicrotask, !1), me = {
  x: !1,
  y: !1
};
function Hr() {
  return me.x || me.y;
}
function $l(e) {
  return e === "x" || e === "y" ? me[e] ? null : (me[e] = !0, () => {
    me[e] = !1;
  }) : me.x || me.y ? null : (me.x = me.y = !0, () => {
    me.x = me.y = !1;
  });
}
function Kr(e, t) {
  const n = Wl(e), i = new AbortController(), s = {
    passive: !0,
    ...t,
    signal: i.signal
  };
  return [n, s, () => i.abort()];
}
function Ki(e) {
  return !(e.pointerType === "touch" || Hr());
}
function Ul(e, t, n = {}) {
  const [i, s, o] = Kr(e, n), r = (l) => {
    if (!Ki(l))
      return;
    const { target: a } = l, d = t(a, l);
    if (typeof d != "function" || !a)
      return;
    const u = (h) => {
      Ki(h) && (d(h), a.removeEventListener("pointerleave", u));
    };
    a.addEventListener("pointerleave", u, s);
  };
  return i.forEach((l) => {
    l.addEventListener("pointerenter", r, s);
  }), o;
}
const qr = (e, t) => t ? e === t ? !0 : qr(e, t.parentElement) : !1, ci = (e) => e.pointerType === "mouse" ? typeof e.button != "number" || e.button <= 0 : e.isPrimary !== !1, Gl = /* @__PURE__ */ new Set([
  "BUTTON",
  "INPUT",
  "SELECT",
  "TEXTAREA",
  "A"
]);
function Hl(e) {
  return Gl.has(e.tagName) || e.tabIndex !== -1;
}
const Bt = /* @__PURE__ */ new WeakSet();
function qi(e) {
  return (t) => {
    t.key === "Enter" && e(t);
  };
}
function rn(e, t) {
  e.dispatchEvent(new PointerEvent("pointer" + t, { isPrimary: !0, bubbles: !0 }));
}
const Kl = (e, t) => {
  const n = e.currentTarget;
  if (!n)
    return;
  const i = qi(() => {
    if (Bt.has(n))
      return;
    rn(n, "down");
    const s = qi(() => {
      rn(n, "up");
    }), o = () => rn(n, "cancel");
    n.addEventListener("keyup", s, t), n.addEventListener("blur", o, t);
  });
  n.addEventListener("keydown", i, t), n.addEventListener("blur", () => n.removeEventListener("keydown", i), t);
};
function Xi(e) {
  return ci(e) && !Hr();
}
function ql(e, t, n = {}) {
  const [i, s, o] = Kr(e, n), r = (l) => {
    const a = l.currentTarget;
    if (!Xi(l))
      return;
    Bt.add(a);
    const d = t(a, l), u = (g, b) => {
      window.removeEventListener("pointerup", h), window.removeEventListener("pointercancel", p), Bt.has(a) && Bt.delete(a), Xi(g) && typeof d == "function" && d(g, { success: b });
    }, h = (g) => {
      u(g, a === window || a === document || n.useGlobalTarget || qr(a, g.target));
    }, p = (g) => {
      u(g, !1);
    };
    window.addEventListener("pointerup", h, s), window.addEventListener("pointercancel", p, s);
  };
  return i.forEach((l) => {
    (n.useGlobalTarget ? window : l).addEventListener("pointerdown", r, s), Gr(l) && (l.addEventListener("focus", (d) => Kl(d, s)), !Hl(l) && !l.hasAttribute("tabindex") && (l.tabIndex = 0));
  }), o;
}
function Xr(e) {
  return or(e) && "ownerSVGElement" in e;
}
function Xl(e) {
  return Xr(e) && e.tagName === "svg";
}
function Yl(...e) {
  const t = !Array.isArray(e[0]), n = t ? 0 : -1, i = e[0 + n], s = e[1 + n], o = e[2 + n], r = e[3 + n], l = Vr(s, o, r);
  return t ? l(i) : l;
}
const ee = (e) => !!(e && e.getVelocity);
function Zl(e, t, n) {
  const i = e.get();
  let s = null, o = i, r;
  const l = typeof i == "string" ? i.replace(/[\d.-]/g, "") : void 0, a = () => {
    s && (s.stop(), s = null);
  }, d = () => {
    a(), s = new Gt({
      keyframes: [Zi(e.get()), Zi(o)],
      velocity: e.getVelocity(),
      type: "spring",
      restDelta: 1e-3,
      restSpeed: 0.01,
      ...n,
      onUpdate: r
    });
  };
  if (e.attach((u, h) => {
    o = u, r = (p) => h(Yi(p, l)), $.postRender(d);
  }, a), ee(t)) {
    const u = t.on("change", (p) => e.set(Yi(p, l))), h = e.on("destroy", u);
    return () => {
      u(), h();
    };
  }
  return a;
}
function Yi(e, t) {
  return t ? e + t : e;
}
function Zi(e) {
  return typeof e == "number" ? e : parseFloat(e);
}
const Jl = [...Or, Z, Pe], Ql = (e) => Jl.find(Wr(e)), Tt = Ye({
  transformPagePoint: (e) => e,
  isStatic: !1,
  reducedMotion: "never"
});
function Ji(e, t) {
  if (typeof e == "function")
    return e(t);
  e != null && (e.current = t);
}
function ec(...e) {
  return (t) => {
    let n = !1;
    const i = e.map((s) => {
      const o = Ji(s, t);
      return !n && typeof o == "function" && (n = !0), o;
    });
    if (n)
      return () => {
        for (let s = 0; s < i.length; s++) {
          const o = i[s];
          typeof o == "function" ? o() : Ji(e[s], null);
        }
      };
  };
}
function tc(...e) {
  return Ke(ec(...e), e);
}
class nc extends ir {
  getSnapshotBeforeUpdate(t) {
    const n = this.props.childRef.current;
    if (n && t.isPresent && !this.props.isPresent) {
      const i = n.offsetParent, s = Gr(i) && i.offsetWidth || 0, o = this.props.sizeRef.current;
      o.height = n.offsetHeight || 0, o.width = n.offsetWidth || 0, o.top = n.offsetTop, o.left = n.offsetLeft, o.right = s - o.width - o.left;
    }
    return null;
  }
  /**
   * Required with getSnapshotBeforeUpdate to stop React complaining.
   */
  componentDidUpdate() {
  }
  render() {
    return this.props.children;
  }
}
function ic({ children: e, isPresent: t, anchorX: n, root: i }) {
  const s = jn(), o = Se(null), r = Se({
    width: 0,
    height: 0,
    top: 0,
    left: 0,
    right: 0
  }), { nonce: l } = Q(Tt), a = tc(o, e?.ref);
  return Wn(() => {
    const { width: d, height: u, top: h, left: p, right: g } = r.current;
    if (t || !o.current || !d || !u)
      return;
    const b = n === "left" ? `left: ${p}` : `right: ${g}`;
    o.current.dataset.motionPopId = s;
    const w = document.createElement("style");
    l && (w.nonce = l);
    const x = i ?? document.head;
    return x.appendChild(w), w.sheet && w.sheet.insertRule(`
          [data-motion-pop-id="${s}"] {
            position: absolute !important;
            width: ${d}px !important;
            height: ${u}px !important;
            ${b}px !important;
            top: ${h}px !important;
          }
        `), () => {
      x.contains(w) && x.removeChild(w);
    };
  }, [t]), c(nc, { isPresent: t, childRef: o, sizeRef: r, children: ea(e, { ref: a }) });
}
const sc = ({ children: e, initial: t, isPresent: n, onExitComplete: i, custom: s, presenceAffectsLayout: o, mode: r, anchorX: l, root: a }) => {
  const d = xt(rc), u = jn();
  let h = !0, p = Le(() => (h = !1, {
    id: u,
    initial: t,
    isPresent: n,
    custom: s,
    onExitComplete: (g) => {
      d.set(g, !0);
      for (const b of d.values())
        if (!b)
          return;
      i && i();
    },
    register: (g) => (d.set(g, !1), () => d.delete(g))
  }), [n, d, i]);
  return o && h && (p = { ...p }), Le(() => {
    d.forEach((g, b) => d.set(b, !1));
  }, [n]), xe(() => {
    !n && !d.size && i && i();
  }, [n]), r === "popLayout" && (e = c(ic, { isPresent: n, anchorX: l, root: a, children: e })), c(Ut.Provider, { value: p, children: e });
};
function rc() {
  return /* @__PURE__ */ new Map();
}
function Yr(e = !0) {
  const t = Q(Ut);
  if (t === null)
    return [!0, null];
  const { isPresent: n, onExitComplete: i, register: s } = t, o = jn();
  xe(() => {
    if (e)
      return s(o);
  }, [e]);
  const r = Ke(() => e && i && i(o), [o, i, e]);
  return !n && i ? [!1, r] : [!0];
}
const Et = (e) => e.key || "";
function Qi(e) {
  const t = [];
  return Qo.forEach(e, (n) => {
    ta(n) && t.push(n);
  }), t;
}
const qe = ({ children: e, custom: t, initial: n = !0, onExitComplete: i, presenceAffectsLayout: s = !0, mode: o = "sync", propagate: r = !1, anchorX: l = "left", root: a }) => {
  const [d, u] = Yr(r), h = Le(() => Qi(e), [e]), p = r && !d ? [] : h.map(Et), g = Se(!0), b = Se(h), w = xt(() => /* @__PURE__ */ new Map()), [x, F] = W(h), [S, T] = W(h);
  $n(() => {
    g.current = !1, b.current = h;
    for (let I = 0; I < S.length; I++) {
      const B = Et(S[I]);
      p.includes(B) ? w.delete(B) : w.get(B) !== !0 && w.set(B, !1);
    }
  }, [S, p.length, p.join("-")]);
  const E = [];
  if (h !== x) {
    let I = [...h];
    for (let B = 0; B < S.length; B++) {
      const A = S[B], Y = Et(A);
      p.includes(Y) || (I.splice(B, 0, A), E.push(A));
    }
    return o === "wait" && E.length && (I = E), T(Qi(I)), F(h), null;
  }
  const { forceRender: k } = Q(On);
  return c(er, { children: S.map((I) => {
    const B = Et(I), A = r && !d ? !1 : h === S || p.includes(B), Y = () => {
      if (w.has(B))
        w.set(B, !0);
      else
        return;
      let te = !0;
      w.forEach((ye) => {
        ye || (te = !1);
      }), te && (k?.(), T(b.current), r && u?.(), i && i());
    };
    return c(sc, { isPresent: A, initial: !g.current || n ? void 0 : !1, custom: t, presenceAffectsLayout: s, mode: o, root: a, onExitComplete: A ? void 0 : Y, anchorX: l, children: I }, B);
  }) });
}, Zr = Ye({ strict: !1 }), es = {
  animation: [
    "animate",
    "variants",
    "whileHover",
    "whileTap",
    "exit",
    "whileInView",
    "whileFocus",
    "whileDrag"
  ],
  exit: ["exit"],
  drag: ["drag", "dragControls"],
  focus: ["whileFocus"],
  hover: ["whileHover", "onHoverStart", "onHoverEnd"],
  tap: ["whileTap", "onTap", "onTapStart", "onTapCancel"],
  pan: ["onPan", "onPanStart", "onPanSessionStart", "onPanEnd"],
  inView: ["whileInView", "onViewportEnter", "onViewportLeave"],
  layout: ["layout", "layoutId"]
}, Xe = {};
for (const e in es)
  Xe[e] = {
    isEnabled: (t) => es[e].some((n) => !!t[n])
  };
function oc(e) {
  for (const t in e)
    Xe[t] = {
      ...Xe[t],
      ...e[t]
    };
}
const ac = /* @__PURE__ */ new Set([
  "animate",
  "exit",
  "variants",
  "initial",
  "style",
  "values",
  "variants",
  "transition",
  "transformTemplate",
  "custom",
  "inherit",
  "onBeforeLayoutMeasure",
  "onAnimationStart",
  "onAnimationComplete",
  "onUpdate",
  "onDragStart",
  "onDrag",
  "onDragEnd",
  "onMeasureDragConstraints",
  "onDirectionLock",
  "onDragTransitionEnd",
  "_dragX",
  "_dragY",
  "onHoverStart",
  "onHoverEnd",
  "onViewportEnter",
  "onViewportLeave",
  "globalTapTarget",
  "ignoreStrict",
  "viewport"
]);
function _t(e) {
  return e.startsWith("while") || e.startsWith("drag") && e !== "draggable" || e.startsWith("layout") || e.startsWith("onTap") || e.startsWith("onPan") || e.startsWith("onLayout") || ac.has(e);
}
let Jr = (e) => !_t(e);
function lc(e) {
  typeof e == "function" && (Jr = (t) => t.startsWith("on") ? !_t(t) : e(t));
}
try {
  lc(require("@emotion/is-prop-valid").default);
} catch {
}
function cc(e, t, n) {
  const i = {};
  for (const s in e)
    s === "values" && typeof e.values == "object" || (Jr(s) || n === !0 && _t(s) || !t && !_t(s) || // If trying to use native HTML drag events, forward drag listeners
    e.draggable && s.startsWith("onDrag")) && (i[s] = e[s]);
  return i;
}
const Ht = /* @__PURE__ */ Ye({});
function Kt(e) {
  return e !== null && typeof e == "object" && typeof e.start == "function";
}
function yt(e) {
  return typeof e == "string" || Array.isArray(e);
}
const di = [
  "animate",
  "whileInView",
  "whileFocus",
  "whileHover",
  "whileTap",
  "whileDrag",
  "exit"
], ui = ["initial", ...di];
function qt(e) {
  return Kt(e.animate) || ui.some((t) => yt(e[t]));
}
function Qr(e) {
  return !!(qt(e) || e.variants);
}
function dc(e, t) {
  if (qt(e)) {
    const { initial: n, animate: i } = e;
    return {
      initial: n === !1 || yt(n) ? n : void 0,
      animate: yt(i) ? i : void 0
    };
  }
  return e.inherit !== !1 ? t : {};
}
function uc(e) {
  const { initial: t, animate: n } = dc(e, Q(Ht));
  return Le(() => ({ initial: t, animate: n }), [ts(t), ts(n)]);
}
function ts(e) {
  return Array.isArray(e) ? e.join(" ") : e;
}
const gt = {};
function hc(e) {
  for (const t in e)
    gt[t] = e[t], Zn(t) && (gt[t].isCSSVariable = !0);
}
function eo(e, { layout: t, layoutId: n }) {
  return Qe.has(e) || e.startsWith("origin") || (t || n !== void 0) && (!!gt[e] || e === "opacity");
}
const fc = {
  x: "translateX",
  y: "translateY",
  z: "translateZ",
  transformPerspective: "perspective"
}, pc = Je.length;
function mc(e, t, n) {
  let i = "", s = !0;
  for (let o = 0; o < pc; o++) {
    const r = Je[o], l = e[r];
    if (l === void 0)
      continue;
    let a = !0;
    if (typeof l == "number" ? a = l === (r.startsWith("scale") ? 1 : 0) : a = parseFloat(l) === 0, !a || n) {
      const d = Ur(l, ai[r]);
      if (!a) {
        s = !1;
        const u = fc[r] || r;
        i += `${u}(${d}) `;
      }
      n && (t[r] = d);
    }
  }
  return i = i.trim(), n ? i = n(t, s ? "" : i) : s && (i = "none"), i;
}
function hi(e, t, n) {
  const { style: i, vars: s, transformOrigin: o } = e;
  let r = !1, l = !1;
  for (const a in t) {
    const d = t[a];
    if (Qe.has(a)) {
      r = !0;
      continue;
    } else if (Zn(a)) {
      s[a] = d;
      continue;
    } else {
      const u = Ur(d, ai[a]);
      a.startsWith("origin") ? (l = !0, o[a] = u) : i[a] = u;
    }
  }
  if (t.transform || (r || n ? i.transform = mc(t, e.transform, n) : i.transform && (i.transform = "none")), l) {
    const { originX: a = "50%", originY: d = "50%", originZ: u = 0 } = o;
    i.transformOrigin = `${a} ${d} ${u}`;
  }
}
const fi = () => ({
  style: {},
  transform: {},
  transformOrigin: {},
  vars: {}
});
function to(e, t, n) {
  for (const i in t)
    !ee(t[i]) && !eo(i, n) && (e[i] = t[i]);
}
function yc({ transformTemplate: e }, t) {
  return Le(() => {
    const n = fi();
    return hi(n, t, e), Object.assign({}, n.vars, n.style);
  }, [t]);
}
function gc(e, t) {
  const n = e.style || {}, i = {};
  return to(i, n, e), Object.assign(i, yc(e, t)), i;
}
function vc(e, t) {
  const n = {}, i = gc(e, t);
  return e.drag && e.dragListener !== !1 && (n.draggable = !1, i.userSelect = i.WebkitUserSelect = i.WebkitTouchCallout = "none", i.touchAction = e.drag === !0 ? "none" : `pan-${e.drag === "x" ? "y" : "x"}`), e.tabIndex === void 0 && (e.onTap || e.onTapStart || e.whileTap) && (n.tabIndex = 0), n.style = i, n;
}
const bc = {
  offset: "stroke-dashoffset",
  array: "stroke-dasharray"
}, xc = {
  offset: "strokeDashoffset",
  array: "strokeDasharray"
};
function Fc(e, t, n = 1, i = 0, s = !0) {
  e.pathLength = 1;
  const o = s ? bc : xc;
  e[o.offset] = M.transform(-i);
  const r = M.transform(t), l = M.transform(n);
  e[o.array] = `${r} ${l}`;
}
function no(e, {
  attrX: t,
  attrY: n,
  attrScale: i,
  pathLength: s,
  pathSpacing: o = 1,
  pathOffset: r = 0,
  // This is object creation, which we try to avoid per-frame.
  ...l
}, a, d, u) {
  if (hi(e, l, d), a) {
    e.style.viewBox && (e.attrs.viewBox = e.style.viewBox);
    return;
  }
  e.attrs = e.style, e.style = {};
  const { attrs: h, style: p } = e;
  h.transform && (p.transform = h.transform, delete h.transform), (p.transform || h.transformOrigin) && (p.transformOrigin = h.transformOrigin ?? "50% 50%", delete h.transformOrigin), p.transform && (p.transformBox = u?.transformBox ?? "fill-box", delete h.transformBox), t !== void 0 && (h.x = t), n !== void 0 && (h.y = n), i !== void 0 && (h.scale = i), s !== void 0 && Fc(h, s, o, r, !1);
}
const io = () => ({
  ...fi(),
  attrs: {}
}), so = (e) => typeof e == "string" && e.toLowerCase() === "svg";
function wc(e, t, n, i) {
  const s = Le(() => {
    const o = io();
    return no(o, t, so(i), e.transformTemplate, e.style), {
      ...o.attrs,
      style: { ...o.style }
    };
  }, [t]);
  if (e.style) {
    const o = {};
    to(o, e.style, e), s.style = { ...o, ...s.style };
  }
  return s;
}
const Sc = [
  "animate",
  "circle",
  "defs",
  "desc",
  "ellipse",
  "g",
  "image",
  "line",
  "filter",
  "marker",
  "mask",
  "metadata",
  "path",
  "pattern",
  "polygon",
  "polyline",
  "rect",
  "stop",
  "switch",
  "symbol",
  "svg",
  "text",
  "tspan",
  "use",
  "view"
];
function pi(e) {
  return (
    /**
     * If it's not a string, it's a custom React component. Currently we only support
     * HTML custom React components.
     */
    typeof e != "string" || /**
     * If it contains a dash, the element is a custom HTML webcomponent.
     */
    e.includes("-") ? !1 : (
      /**
       * If it's in our list of lowercase SVG tags, it's an SVG component
       */
      !!(Sc.indexOf(e) > -1 || /**
       * If it contains a capital letter, it's an SVG component
       */
      /[A-Z]/u.test(e))
    )
  );
}
function Tc(e, t, n, { latestValues: i }, s, o = !1) {
  const l = (pi(e) ? wc : vc)(t, i, s, e), a = cc(t, typeof e == "string", o), d = e !== sr ? { ...a, ...l, ref: n } : {}, { children: u } = t, h = Le(() => ee(u) ? u.get() : u, [u]);
  return zt(e, {
    ...d,
    children: h
  });
}
function ns(e) {
  const t = [{}, {}];
  return e?.values.forEach((n, i) => {
    t[0][i] = n.get(), t[1][i] = n.getVelocity();
  }), t;
}
function mi(e, t, n, i) {
  if (typeof t == "function") {
    const [s, o] = ns(i);
    t = t(n !== void 0 ? n : e.custom, s, o);
  }
  if (typeof t == "string" && (t = e.variants && e.variants[t]), typeof t == "function") {
    const [s, o] = ns(i);
    t = t(n !== void 0 ? n : e.custom, s, o);
  }
  return t;
}
function Rt(e) {
  return ee(e) ? e.get() : e;
}
function Cc({ scrapeMotionValuesFromProps: e, createRenderState: t }, n, i, s) {
  return {
    latestValues: kc(n, i, s, e),
    renderState: t()
  };
}
function kc(e, t, n, i) {
  const s = {}, o = i(e, {});
  for (const p in o)
    s[p] = Rt(o[p]);
  let { initial: r, animate: l } = e;
  const a = qt(e), d = Qr(e);
  t && d && !a && e.inherit !== !1 && (r === void 0 && (r = t.initial), l === void 0 && (l = t.animate));
  let u = n ? n.initial === !1 : !1;
  u = u || r === !1;
  const h = u ? l : r;
  if (h && typeof h != "boolean" && !Kt(h)) {
    const p = Array.isArray(h) ? h : [h];
    for (let g = 0; g < p.length; g++) {
      const b = mi(e, p[g]);
      if (b) {
        const { transitionEnd: w, transition: x, ...F } = b;
        for (const S in F) {
          let T = F[S];
          if (Array.isArray(T)) {
            const E = u ? T.length - 1 : 0;
            T = T[E];
          }
          T !== null && (s[S] = T);
        }
        for (const S in w)
          s[S] = w[S];
      }
    }
  }
  return s;
}
const ro = (e) => (t, n) => {
  const i = Q(Ht), s = Q(Ut), o = () => Cc(e, t, i, s);
  return n ? o() : xt(o);
};
function yi(e, t, n) {
  const { style: i } = e, s = {};
  for (const o in i)
    (ee(i[o]) || t.style && ee(t.style[o]) || eo(o, e) || n?.getValue(o)?.liveStyle !== void 0) && (s[o] = i[o]);
  return s;
}
const Mc = /* @__PURE__ */ ro({
  scrapeMotionValuesFromProps: yi,
  createRenderState: fi
});
function oo(e, t, n) {
  const i = yi(e, t, n);
  for (const s in e)
    if (ee(e[s]) || ee(t[s])) {
      const o = Je.indexOf(s) !== -1 ? "attr" + s.charAt(0).toUpperCase() + s.substring(1) : s;
      i[o] = e[s];
    }
  return i;
}
const Pc = /* @__PURE__ */ ro({
  scrapeMotionValuesFromProps: oo,
  createRenderState: io
}), Ac = Symbol.for("motionComponentSymbol");
function _e(e) {
  return e && typeof e == "object" && Object.prototype.hasOwnProperty.call(e, "current");
}
function Vc(e, t, n) {
  return Ke(
    (i) => {
      i && e.onMount && e.onMount(i), t && (i ? t.mount(i) : t.unmount()), n && (typeof n == "function" ? n(i) : _e(n) && (n.current = i));
    },
    /**
     * Include externalRef in dependencies to ensure the callback updates
     * when the ref changes, allowing proper ref forwarding.
     */
    [t]
  );
}
const gi = (e) => e.replace(/([a-z])([A-Z])/gu, "$1-$2").toLowerCase(), Ec = "framerAppearId", ao = "data-" + gi(Ec), lo = Ye({});
function Ic(e, t, n, i, s) {
  const { visualElement: o } = Q(Ht), r = Q(Zr), l = Q(Ut), a = Q(Tt).reducedMotion, d = Se(null);
  i = i || r.renderer, !d.current && i && (d.current = i(e, {
    visualState: t,
    parent: o,
    props: n,
    presenceContext: l,
    blockInitialAnimation: l ? l.initial === !1 : !1,
    reducedMotionConfig: a
  }));
  const u = d.current, h = Q(lo);
  u && !u.projection && s && (u.type === "html" || u.type === "svg") && Nc(d.current, n, s, h);
  const p = Se(!1);
  Wn(() => {
    u && p.current && u.update(n, l);
  });
  const g = n[ao], b = Se(!!g && !window.MotionHandoffIsComplete?.(g) && window.MotionHasOptimisedAnimation?.(g));
  return $n(() => {
    u && (p.current = !0, window.MotionIsMounted = !0, u.updateFeatures(), u.scheduleRenderMicrotask(), b.current && u.animationState && u.animationState.animateChanges());
  }), xe(() => {
    u && (!b.current && u.animationState && u.animationState.animateChanges(), b.current && (queueMicrotask(() => {
      window.MotionHandoffMarkAsComplete?.(g);
    }), b.current = !1), u.enteringChildren = void 0);
  }), u;
}
function Nc(e, t, n, i) {
  const { layoutId: s, layout: o, drag: r, dragConstraints: l, layoutScroll: a, layoutRoot: d, layoutCrossfade: u } = t;
  e.projection = new n(e.latestValues, t["data-framer-portal-id"] ? void 0 : co(e.parent)), e.projection.setOptions({
    layoutId: s,
    layout: o,
    alwaysMeasureLayout: !!r || l && _e(l),
    visualElement: e,
    /**
     * TODO: Update options in an effect. This could be tricky as it'll be too late
     * to update by the time layout animations run.
     * We also need to fix this safeToRemove by linking it up to the one returned by usePresence,
     * ensuring it gets called if there's no potential layout animations.
     *
     */
    animationType: typeof o == "string" ? o : "both",
    initialPromotionConfig: i,
    crossfade: u,
    layoutScroll: a,
    layoutRoot: d
  });
}
function co(e) {
  if (e)
    return e.options.allowProjection !== !1 ? e.projection : co(e.parent);
}
function on(e, { forwardMotionProps: t = !1 } = {}, n, i) {
  n && oc(n);
  const s = pi(e) ? Pc : Mc;
  function o(l, a) {
    let d;
    const u = {
      ...Q(Tt),
      ...l,
      layoutId: Dc(l)
    }, { isStatic: h } = u, p = uc(l), g = s(l, h);
    if (!h && _n) {
      Bc();
      const b = Rc(u);
      d = b.MeasureLayout, p.visualElement = Ic(e, g, u, i, b.ProjectionNode);
    }
    return y(Ht.Provider, { value: p, children: [d && p.visualElement ? c(d, { visualElement: p.visualElement, ...u }) : null, Tc(e, l, Vc(g, p.visualElement, a), g, h, t)] });
  }
  o.displayName = `motion.${typeof e == "string" ? e : `create(${e.displayName ?? e.name ?? ""})`}`;
  const r = zn(o);
  return r[Ac] = e, r;
}
function Dc({ layoutId: e }) {
  const t = Q(On).id;
  return t && e !== void 0 ? t + "-" + e : e;
}
function Bc(e, t) {
  Q(Zr).strict;
}
function Rc(e) {
  const { drag: t, layout: n } = Xe;
  if (!t && !n)
    return {};
  const i = { ...t, ...n };
  return {
    MeasureLayout: t?.isEnabled(e) || n?.isEnabled(e) ? i.MeasureLayout : void 0,
    ProjectionNode: i.ProjectionNode
  };
}
function Lc(e, t) {
  if (typeof Proxy > "u")
    return on;
  const n = /* @__PURE__ */ new Map(), i = (o, r) => on(o, r, e, t), s = (o, r) => i(o, r);
  return new Proxy(s, {
    /**
     * Called when `motion` is referenced with a prop: `motion.div`, `motion.input` etc.
     * The prop name is passed through as `key` and we can use that to generate a `motion`
     * DOM component with that name.
     */
    get: (o, r) => r === "create" ? i : (n.has(r) || n.set(r, on(r, void 0, e, t)), n.get(r))
  });
}
function uo({ top: e, left: t, right: n, bottom: i }) {
  return {
    x: { min: t, max: n },
    y: { min: e, max: i }
  };
}
function zc({ x: e, y: t }) {
  return { top: t.min, right: e.max, bottom: t.max, left: e.min };
}
function jc(e, t) {
  if (!t)
    return e;
  const n = t({ x: e.left, y: e.top }), i = t({ x: e.right, y: e.bottom });
  return {
    top: n.y,
    left: n.x,
    bottom: i.y,
    right: i.x
  };
}
function an(e) {
  return e === void 0 || e === 1;
}
function An({ scale: e, scaleX: t, scaleY: n }) {
  return !an(e) || !an(t) || !an(n);
}
function Ie(e) {
  return An(e) || ho(e) || e.z || e.rotate || e.rotateX || e.rotateY || e.skewX || e.skewY;
}
function ho(e) {
  return is(e.x) || is(e.y);
}
function is(e) {
  return e && e !== "0%";
}
function $t(e, t, n) {
  const i = e - n, s = t * i;
  return n + s;
}
function ss(e, t, n, i, s) {
  return s !== void 0 && (e = $t(e, s, i)), $t(e, n, i) + t;
}
function Vn(e, t = 0, n = 1, i, s) {
  e.min = ss(e.min, t, n, i, s), e.max = ss(e.max, t, n, i, s);
}
function fo(e, { x: t, y: n }) {
  Vn(e.x, t.translate, t.scale, t.originPoint), Vn(e.y, n.translate, n.scale, n.originPoint);
}
const rs = 0.999999999999, os = 1.0000000000001;
function Wc(e, t, n, i = !1) {
  const s = n.length;
  if (!s)
    return;
  t.x = t.y = 1;
  let o, r;
  for (let l = 0; l < s; l++) {
    o = n[l], r = o.projectionDelta;
    const { visualElement: a } = o.options;
    a && a.props.style && a.props.style.display === "contents" || (i && o.options.layoutScroll && o.scroll && o !== o.root && Ue(e, {
      x: -o.scroll.offset.x,
      y: -o.scroll.offset.y
    }), r && (t.x *= r.x.scale, t.y *= r.y.scale, fo(e, r)), i && Ie(o.latestValues) && Ue(e, o.latestValues));
  }
  t.x < os && t.x > rs && (t.x = 1), t.y < os && t.y > rs && (t.y = 1);
}
function $e(e, t) {
  e.min = e.min + t, e.max = e.max + t;
}
function as(e, t, n, i, s = 0.5) {
  const o = G(e.min, e.max, s);
  Vn(e, t, n, o, i);
}
function Ue(e, t) {
  as(e.x, t.x, t.scaleX, t.scale, t.originX), as(e.y, t.y, t.scaleY, t.scale, t.originY);
}
function po(e, t) {
  return uo(jc(e.getBoundingClientRect(), t));
}
function Oc(e, t, n) {
  const i = po(e, n), { scroll: s } = t;
  return s && ($e(i.x, s.offset.x), $e(i.y, s.offset.y)), i;
}
const ls = () => ({
  translate: 0,
  scale: 1,
  origin: 0,
  originPoint: 0
}), Ge = () => ({
  x: ls(),
  y: ls()
}), cs = () => ({ min: 0, max: 0 }), X = () => ({
  x: cs(),
  y: cs()
}), En = { current: null }, mo = { current: !1 };
function _c() {
  if (mo.current = !0, !!_n)
    if (window.matchMedia) {
      const e = window.matchMedia("(prefers-reduced-motion)"), t = () => En.current = e.matches;
      e.addEventListener("change", t), t();
    } else
      En.current = !1;
}
const $c = /* @__PURE__ */ new WeakMap();
function Uc(e, t, n) {
  for (const i in t) {
    const s = t[i], o = n[i];
    if (ee(s))
      e.addValue(i, s);
    else if (ee(o))
      e.addValue(i, ze(s, { owner: e }));
    else if (o !== s)
      if (e.hasValue(i)) {
        const r = e.getValue(i);
        r.liveStyle === !0 ? r.jump(s) : r.hasAnimated || r.set(s);
      } else {
        const r = e.getStaticValue(i);
        e.addValue(i, ze(r !== void 0 ? r : s, { owner: e }));
      }
  }
  for (const i in n)
    t[i] === void 0 && e.removeValue(i);
  return t;
}
const ds = [
  "AnimationStart",
  "AnimationComplete",
  "Update",
  "BeforeLayoutMeasure",
  "LayoutMeasure",
  "LayoutAnimationStart",
  "LayoutAnimationComplete"
];
class Gc {
  /**
   * This method takes React props and returns found MotionValues. For example, HTML
   * MotionValues will be found within the style prop, whereas for Three.js within attribute arrays.
   *
   * This isn't an abstract method as it needs calling in the constructor, but it is
   * intended to be one.
   */
  scrapeMotionValuesFromProps(t, n, i) {
    return {};
  }
  constructor({ parent: t, props: n, presenceContext: i, reducedMotionConfig: s, blockInitialAnimation: o, visualState: r }, l = {}) {
    this.current = null, this.children = /* @__PURE__ */ new Set(), this.isVariantNode = !1, this.isControllingVariants = !1, this.shouldReduceMotion = null, this.values = /* @__PURE__ */ new Map(), this.KeyframeResolver = ri, this.features = {}, this.valueSubscriptions = /* @__PURE__ */ new Map(), this.prevMotionValues = {}, this.events = {}, this.propEventSubscriptions = {}, this.notifyUpdate = () => this.notify("Update", this.latestValues), this.render = () => {
      this.current && (this.triggerBuild(), this.renderInstance(this.current, this.renderState, this.props.style, this.projection));
    }, this.renderScheduledAt = 0, this.scheduleRender = () => {
      const p = ae.now();
      this.renderScheduledAt < p && (this.renderScheduledAt = p, $.render(this.render, !1, !0));
    };
    const { latestValues: a, renderState: d } = r;
    this.latestValues = a, this.baseTarget = { ...a }, this.initialValues = n.initial ? { ...a } : {}, this.renderState = d, this.parent = t, this.props = n, this.presenceContext = i, this.depth = t ? t.depth + 1 : 0, this.reducedMotionConfig = s, this.options = l, this.blockInitialAnimation = !!o, this.isControllingVariants = qt(n), this.isVariantNode = Qr(n), this.isVariantNode && (this.variantChildren = /* @__PURE__ */ new Set()), this.manuallyAnimateOnMount = !!(t && t.current);
    const { willChange: u, ...h } = this.scrapeMotionValuesFromProps(n, {}, this);
    for (const p in h) {
      const g = h[p];
      a[p] !== void 0 && ee(g) && g.set(a[p]);
    }
  }
  mount(t) {
    this.current = t, $c.set(t, this), this.projection && !this.projection.instance && this.projection.mount(t), this.parent && this.isVariantNode && !this.isControllingVariants && (this.removeFromVariantTree = this.parent.addVariantChild(this)), this.values.forEach((n, i) => this.bindToMotionValue(i, n)), mo.current || _c(), this.shouldReduceMotion = this.reducedMotionConfig === "never" ? !1 : this.reducedMotionConfig === "always" ? !0 : En.current, this.parent?.addChild(this), this.update(this.props, this.presenceContext);
  }
  unmount() {
    this.projection && this.projection.unmount(), ke(this.notifyUpdate), ke(this.render), this.valueSubscriptions.forEach((t) => t()), this.valueSubscriptions.clear(), this.removeFromVariantTree && this.removeFromVariantTree(), this.parent?.removeChild(this);
    for (const t in this.events)
      this.events[t].clear();
    for (const t in this.features) {
      const n = this.features[t];
      n && (n.unmount(), n.isMounted = !1);
    }
    this.current = null;
  }
  addChild(t) {
    this.children.add(t), this.enteringChildren ?? (this.enteringChildren = /* @__PURE__ */ new Set()), this.enteringChildren.add(t);
  }
  removeChild(t) {
    this.children.delete(t), this.enteringChildren && this.enteringChildren.delete(t);
  }
  bindToMotionValue(t, n) {
    this.valueSubscriptions.has(t) && this.valueSubscriptions.get(t)();
    const i = Qe.has(t);
    i && this.onBindTransform && this.onBindTransform();
    const s = n.on("change", (r) => {
      this.latestValues[t] = r, this.props.onUpdate && $.preRender(this.notifyUpdate), i && this.projection && (this.projection.isTransformDirty = !0), this.scheduleRender();
    });
    let o;
    window.MotionCheckAppearSync && (o = window.MotionCheckAppearSync(this, t, n)), this.valueSubscriptions.set(t, () => {
      s(), o && o(), n.owner && n.stop();
    });
  }
  sortNodePosition(t) {
    return !this.current || !this.sortInstanceNodePosition || this.type !== t.type ? 0 : this.sortInstanceNodePosition(this.current, t.current);
  }
  updateFeatures() {
    let t = "animation";
    for (t in Xe) {
      const n = Xe[t];
      if (!n)
        continue;
      const { isEnabled: i, Feature: s } = n;
      if (!this.features[t] && s && i(this.props) && (this.features[t] = new s(this)), this.features[t]) {
        const o = this.features[t];
        o.isMounted ? o.update() : (o.mount(), o.isMounted = !0);
      }
    }
  }
  triggerBuild() {
    this.build(this.renderState, this.latestValues, this.props);
  }
  /**
   * Measure the current viewport box with or without transforms.
   * Only measures axis-aligned boxes, rotate and skew must be manually
   * removed with a re-render to work.
   */
  measureViewportBox() {
    return this.current ? this.measureInstanceViewportBox(this.current, this.props) : X();
  }
  getStaticValue(t) {
    return this.latestValues[t];
  }
  setStaticValue(t, n) {
    this.latestValues[t] = n;
  }
  /**
   * Update the provided props. Ensure any newly-added motion values are
   * added to our map, old ones removed, and listeners updated.
   */
  update(t, n) {
    (t.transformTemplate || this.props.transformTemplate) && this.scheduleRender(), this.prevProps = this.props, this.props = t, this.prevPresenceContext = this.presenceContext, this.presenceContext = n;
    for (let i = 0; i < ds.length; i++) {
      const s = ds[i];
      this.propEventSubscriptions[s] && (this.propEventSubscriptions[s](), delete this.propEventSubscriptions[s]);
      const o = "on" + s, r = t[o];
      r && (this.propEventSubscriptions[s] = this.on(s, r));
    }
    this.prevMotionValues = Uc(this, this.scrapeMotionValuesFromProps(t, this.prevProps, this), this.prevMotionValues), this.handleChildMotionValue && this.handleChildMotionValue();
  }
  getProps() {
    return this.props;
  }
  /**
   * Returns the variant definition with a given name.
   */
  getVariant(t) {
    return this.props.variants ? this.props.variants[t] : void 0;
  }
  /**
   * Returns the defined default transition on this component.
   */
  getDefaultTransition() {
    return this.props.transition;
  }
  getTransformPagePoint() {
    return this.props.transformPagePoint;
  }
  getClosestVariantNode() {
    return this.isVariantNode ? this : this.parent ? this.parent.getClosestVariantNode() : void 0;
  }
  /**
   * Add a child visual element to our set of children.
   */
  addVariantChild(t) {
    const n = this.getClosestVariantNode();
    if (n)
      return n.variantChildren && n.variantChildren.add(t), () => n.variantChildren.delete(t);
  }
  /**
   * Add a motion value and bind it to this visual element.
   */
  addValue(t, n) {
    const i = this.values.get(t);
    n !== i && (i && this.removeValue(t), this.bindToMotionValue(t, n), this.values.set(t, n), this.latestValues[t] = n.get());
  }
  /**
   * Remove a motion value and unbind any active subscriptions.
   */
  removeValue(t) {
    this.values.delete(t);
    const n = this.valueSubscriptions.get(t);
    n && (n(), this.valueSubscriptions.delete(t)), delete this.latestValues[t], this.removeValueFromRenderState(t, this.renderState);
  }
  /**
   * Check whether we have a motion value for this key
   */
  hasValue(t) {
    return this.values.has(t);
  }
  getValue(t, n) {
    if (this.props.values && this.props.values[t])
      return this.props.values[t];
    let i = this.values.get(t);
    return i === void 0 && n !== void 0 && (i = ze(n === null ? void 0 : n, { owner: this }), this.addValue(t, i)), i;
  }
  /**
   * If we're trying to animate to a previously unencountered value,
   * we need to check for it in our state and as a last resort read it
   * directly from the instance (which might have performance implications).
   */
  readValue(t, n) {
    let i = this.latestValues[t] !== void 0 || !this.current ? this.latestValues[t] : this.getBaseTargetFromProps(this.props, t) ?? this.readValueFromInstance(this.current, t, this.options);
    return i != null && (typeof i == "string" && (rr(i) || ar(i)) ? i = parseFloat(i) : !Ql(i) && Pe.test(n) && (i = $r(t, n)), this.setBaseTarget(t, ee(i) ? i.get() : i)), ee(i) ? i.get() : i;
  }
  /**
   * Set the base target to later animate back to. This is currently
   * only hydrated on creation and when we first read a value.
   */
  setBaseTarget(t, n) {
    this.baseTarget[t] = n;
  }
  /**
   * Find the base target for a value thats been removed from all animation
   * props.
   */
  getBaseTarget(t) {
    const { initial: n } = this.props;
    let i;
    if (typeof n == "string" || typeof n == "object") {
      const o = mi(this.props, n, this.presenceContext?.custom);
      o && (i = o[t]);
    }
    if (n && i !== void 0)
      return i;
    const s = this.getBaseTargetFromProps(this.props, t);
    return s !== void 0 && !ee(s) ? s : this.initialValues[t] !== void 0 && i === void 0 ? void 0 : this.baseTarget[t];
  }
  on(t, n) {
    return this.events[t] || (this.events[t] = new qn()), this.events[t].add(n);
  }
  notify(t, ...n) {
    this.events[t] && this.events[t].notify(...n);
  }
  scheduleRenderMicrotask() {
    li.render(this.render);
  }
}
class yo extends Gc {
  constructor() {
    super(...arguments), this.KeyframeResolver = jl;
  }
  sortInstanceNodePosition(t, n) {
    return t.compareDocumentPosition(n) & 2 ? 1 : -1;
  }
  getBaseTargetFromProps(t, n) {
    return t.style ? t.style[n] : void 0;
  }
  removeValueFromRenderState(t, { vars: n, style: i }) {
    delete n[t], delete i[t];
  }
  handleChildMotionValue() {
    this.childSubscription && (this.childSubscription(), delete this.childSubscription);
    const { children: t } = this.props;
    ee(t) && (this.childSubscription = t.on("change", (n) => {
      this.current && (this.current.textContent = `${n}`);
    }));
  }
}
function go(e, { style: t, vars: n }, i, s) {
  const o = e.style;
  let r;
  for (r in t)
    o[r] = t[r];
  s?.applyProjectionStyles(o, i);
  for (r in n)
    o.setProperty(r, n[r]);
}
function Hc(e) {
  return window.getComputedStyle(e);
}
class Kc extends yo {
  constructor() {
    super(...arguments), this.type = "html", this.renderInstance = go;
  }
  readValueFromInstance(t, n) {
    if (Qe.has(n))
      return this.projection?.isProjecting ? wn(n) : sl(t, n);
    {
      const i = Hc(t), s = (Zn(n) ? i.getPropertyValue(n) : i[n]) || 0;
      return typeof s == "string" ? s.trim() : s;
    }
  }
  measureInstanceViewportBox(t, { transformPagePoint: n }) {
    return po(t, n);
  }
  build(t, n, i) {
    hi(t, n, i.transformTemplate);
  }
  scrapeMotionValuesFromProps(t, n, i) {
    return yi(t, n, i);
  }
}
const vo = /* @__PURE__ */ new Set([
  "baseFrequency",
  "diffuseConstant",
  "kernelMatrix",
  "kernelUnitLength",
  "keySplines",
  "keyTimes",
  "limitingConeAngle",
  "markerHeight",
  "markerWidth",
  "numOctaves",
  "targetX",
  "targetY",
  "surfaceScale",
  "specularConstant",
  "specularExponent",
  "stdDeviation",
  "tableValues",
  "viewBox",
  "gradientTransform",
  "pathLength",
  "startOffset",
  "textLength",
  "lengthAdjust"
]);
function qc(e, t, n, i) {
  go(e, t, void 0, i);
  for (const s in t.attrs)
    e.setAttribute(vo.has(s) ? s : gi(s), t.attrs[s]);
}
class Xc extends yo {
  constructor() {
    super(...arguments), this.type = "svg", this.isSVGTag = !1, this.measureInstanceViewportBox = X;
  }
  getBaseTargetFromProps(t, n) {
    return t[n];
  }
  readValueFromInstance(t, n) {
    if (Qe.has(n)) {
      const i = _r(n);
      return i && i.default || 0;
    }
    return n = vo.has(n) ? n : gi(n), t.getAttribute(n);
  }
  scrapeMotionValuesFromProps(t, n, i) {
    return oo(t, n, i);
  }
  build(t, n, i) {
    no(t, n, this.isSVGTag, i.transformTemplate, i.style);
  }
  renderInstance(t, n, i, s) {
    qc(t, n, i, s);
  }
  mount(t) {
    this.isSVGTag = so(t.tagName), super.mount(t);
  }
}
const Yc = (e, t) => pi(e) ? new Xc(t) : new Kc(t, {
  allowProjection: e !== sr
});
function He(e, t, n) {
  const i = e.getProps();
  return mi(i, t, n !== void 0 ? n : i.custom, e);
}
const In = (e) => Array.isArray(e);
function Zc(e, t, n) {
  e.hasValue(t) ? e.getValue(t).set(n) : e.addValue(t, ze(n));
}
function Jc(e) {
  return In(e) ? e[e.length - 1] || 0 : e;
}
function Qc(e, t) {
  const n = He(e, t);
  let { transitionEnd: i = {}, transition: s = {}, ...o } = n || {};
  o = { ...o, ...i };
  for (const r in o) {
    const l = Jc(o[r]);
    Zc(e, r, l);
  }
}
function ed(e) {
  return !!(ee(e) && e.add);
}
function Nn(e, t) {
  const n = e.getValue("willChange");
  if (ed(n))
    return n.add(t);
  if (!n && Ce.WillChange) {
    const i = new Ce.WillChange("auto");
    e.addValue("willChange", i), i.add(t);
  }
}
function bo(e) {
  return e.props[ao];
}
const td = (e) => e !== null;
function nd(e, { repeat: t, repeatType: n = "loop" }, i) {
  const s = e.filter(td), o = t && n !== "loop" && t % 2 === 1 ? 0 : s.length - 1;
  return s[o];
}
const id = {
  type: "spring",
  stiffness: 500,
  damping: 25,
  restSpeed: 10
}, sd = (e) => ({
  type: "spring",
  stiffness: 550,
  damping: e === 0 ? 2 * Math.sqrt(550) : 30,
  restSpeed: 10
}), rd = {
  type: "keyframes",
  duration: 0.8
}, od = {
  type: "keyframes",
  ease: [0.25, 0.1, 0.35, 1],
  duration: 0.3
}, ad = (e, { keyframes: t }) => t.length > 2 ? rd : Qe.has(e) ? e.startsWith("scale") ? sd(t[1]) : id : od;
function ld({ when: e, delay: t, delayChildren: n, staggerChildren: i, staggerDirection: s, repeat: o, repeatType: r, repeatDelay: l, from: a, elapsed: d, ...u }) {
  return !!Object.keys(u).length;
}
const vi = (e, t, n, i = {}, s, o) => (r) => {
  const l = oi(i, e) || {}, a = l.delay || i.delay || 0;
  let { elapsed: d = 0 } = i;
  d = d - /* @__PURE__ */ ve(a);
  const u = {
    keyframes: Array.isArray(n) ? n : [null, n],
    ease: "easeOut",
    velocity: t.getVelocity(),
    ...l,
    delay: -d,
    onUpdate: (p) => {
      t.set(p), l.onUpdate && l.onUpdate(p);
    },
    onComplete: () => {
      r(), l.onComplete && l.onComplete();
    },
    name: e,
    motionValue: t,
    element: o ? void 0 : s
  };
  ld(l) || Object.assign(u, ad(e, u)), u.duration && (u.duration = /* @__PURE__ */ ve(u.duration)), u.repeatDelay && (u.repeatDelay = /* @__PURE__ */ ve(u.repeatDelay)), u.from !== void 0 && (u.keyframes[0] = u.from);
  let h = !1;
  if ((u.type === !1 || u.duration === 0 && !u.repeatDelay) && (Mn(u), u.delay === 0 && (h = !0)), (Ce.instantAnimations || Ce.skipAnimations) && (h = !0, Mn(u), u.delay = 0), u.allowFlatten = !l.type && !l.ease, h && !o && t.get() !== void 0) {
    const p = nd(u.keyframes, l);
    if (p !== void 0) {
      $.update(() => {
        u.onUpdate(p), u.onComplete();
      });
      return;
    }
  }
  return l.isSync ? new Gt(u) : new Ml(u);
};
function cd({ protectedKeys: e, needsAnimating: t }, n) {
  const i = e.hasOwnProperty(n) && t[n] !== !0;
  return t[n] = !1, i;
}
function xo(e, t, { delay: n = 0, transitionOverride: i, type: s } = {}) {
  let { transition: o = e.getDefaultTransition(), transitionEnd: r, ...l } = t;
  i && (o = i);
  const a = [], d = s && e.animationState && e.animationState.getState()[s];
  for (const u in l) {
    const h = e.getValue(u, e.latestValues[u] ?? null), p = l[u];
    if (p === void 0 || d && cd(d, u))
      continue;
    const g = {
      delay: n,
      ...oi(o || {}, u)
    }, b = h.get();
    if (b !== void 0 && !h.isAnimating && !Array.isArray(p) && p === b && !g.velocity)
      continue;
    let w = !1;
    if (window.MotionHandoffAnimation) {
      const F = bo(e);
      if (F) {
        const S = window.MotionHandoffAnimation(F, u, $);
        S !== null && (g.startTime = S, w = !0);
      }
    }
    Nn(e, u), h.start(vi(u, h, p, e.shouldReduceMotion && jr.has(u) ? { type: !1 } : g, e, w));
    const x = h.animation;
    x && a.push(x);
  }
  return r && Promise.all(a).then(() => {
    $.update(() => {
      r && Qc(e, r);
    });
  }), a;
}
function Fo(e, t, n, i = 0, s = 1) {
  const o = Array.from(e).sort((d, u) => d.sortNodePosition(u)).indexOf(t), r = e.size, l = (r - 1) * i;
  return typeof n == "function" ? n(o, r) : s === 1 ? o * i : l - o * i;
}
function Dn(e, t, n = {}) {
  const i = He(e, t, n.type === "exit" ? e.presenceContext?.custom : void 0);
  let { transition: s = e.getDefaultTransition() || {} } = i || {};
  n.transitionOverride && (s = n.transitionOverride);
  const o = i ? () => Promise.all(xo(e, i, n)) : () => Promise.resolve(), r = e.variantChildren && e.variantChildren.size ? (a = 0) => {
    const { delayChildren: d = 0, staggerChildren: u, staggerDirection: h } = s;
    return dd(e, t, a, d, u, h, n);
  } : () => Promise.resolve(), { when: l } = s;
  if (l) {
    const [a, d] = l === "beforeChildren" ? [o, r] : [r, o];
    return a().then(() => d());
  } else
    return Promise.all([o(), r(n.delay)]);
}
function dd(e, t, n = 0, i = 0, s = 0, o = 1, r) {
  const l = [];
  for (const a of e.variantChildren)
    a.notify("AnimationStart", t), l.push(Dn(a, t, {
      ...r,
      delay: n + (typeof i == "function" ? 0 : i) + Fo(e.variantChildren, a, i, s, o)
    }).then(() => a.notify("AnimationComplete", t)));
  return Promise.all(l);
}
function ud(e, t, n = {}) {
  e.notify("AnimationStart", t);
  let i;
  if (Array.isArray(t)) {
    const s = t.map((o) => Dn(e, o, n));
    i = Promise.all(s);
  } else if (typeof t == "string")
    i = Dn(e, t, n);
  else {
    const s = typeof t == "function" ? He(e, t, n.custom) : t;
    i = Promise.all(xo(e, s, n));
  }
  return i.then(() => {
    e.notify("AnimationComplete", t);
  });
}
function wo(e, t) {
  if (!Array.isArray(t))
    return !1;
  const n = t.length;
  if (n !== e.length)
    return !1;
  for (let i = 0; i < n; i++)
    if (t[i] !== e[i])
      return !1;
  return !0;
}
const hd = ui.length;
function So(e) {
  if (!e)
    return;
  if (!e.isControllingVariants) {
    const n = e.parent ? So(e.parent) || {} : {};
    return e.props.initial !== void 0 && (n.initial = e.props.initial), n;
  }
  const t = {};
  for (let n = 0; n < hd; n++) {
    const i = ui[n], s = e.props[i];
    (yt(s) || s === !1) && (t[i] = s);
  }
  return t;
}
const fd = [...di].reverse(), pd = di.length;
function md(e) {
  return (t) => Promise.all(t.map(({ animation: n, options: i }) => ud(e, n, i)));
}
function yd(e) {
  let t = md(e), n = us(), i = !0;
  const s = (a) => (d, u) => {
    const h = He(e, u, a === "exit" ? e.presenceContext?.custom : void 0);
    if (h) {
      const { transition: p, transitionEnd: g, ...b } = h;
      d = { ...d, ...b, ...g };
    }
    return d;
  };
  function o(a) {
    t = a(e);
  }
  function r(a) {
    const { props: d } = e, u = So(e.parent) || {}, h = [], p = /* @__PURE__ */ new Set();
    let g = {}, b = 1 / 0;
    for (let x = 0; x < pd; x++) {
      const F = fd[x], S = n[F], T = d[F] !== void 0 ? d[F] : u[F], E = yt(T), k = F === a ? S.isActive : null;
      k === !1 && (b = x);
      let I = T === u[F] && T !== d[F] && E;
      if (I && i && e.manuallyAnimateOnMount && (I = !1), S.protectedKeys = { ...g }, // If it isn't active and hasn't *just* been set as inactive
      !S.isActive && k === null || // If we didn't and don't have any defined prop for this animation type
      !T && !S.prevProp || // Or if the prop doesn't define an animation
      Kt(T) || typeof T == "boolean")
        continue;
      const B = gd(S.prevProp, T);
      let A = B || // If we're making this variant active, we want to always make it active
      F === a && S.isActive && !I && E || // If we removed a higher-priority variant (i is in reverse order)
      x > b && E, Y = !1;
      const te = Array.isArray(T) ? T : [T];
      let ye = te.reduce(s(F), {});
      k === !1 && (ye = {});
      const { prevResolvedValues: Mt = {} } = S, Yt = {
        ...Mt,
        ...ye
      }, et = (J) => {
        A = !0, p.has(J) && (Y = !0, p.delete(J)), S.needsAnimating[J] = !0;
        const re = e.getValue(J);
        re && (re.liveStyle = !1);
      };
      for (const J in Yt) {
        const re = ye[J], Fe = Mt[J];
        if (g.hasOwnProperty(J))
          continue;
        let m = !1;
        In(re) && In(Fe) ? m = !wo(re, Fe) : m = re !== Fe, m ? re != null ? et(J) : p.add(J) : re !== void 0 && p.has(J) ? et(J) : S.protectedKeys[J] = !0;
      }
      S.prevProp = T, S.prevResolvedValues = ye, S.isActive && (g = { ...g, ...ye }), i && e.blockInitialAnimation && (A = !1);
      const We = I && B;
      A && (!We || Y) && h.push(...te.map((J) => {
        const re = { type: F };
        if (typeof J == "string" && i && !We && e.manuallyAnimateOnMount && e.parent) {
          const { parent: Fe } = e, m = He(Fe, J);
          if (Fe.enteringChildren && m) {
            const { delayChildren: f } = m.transition || {};
            re.delay = Fo(Fe.enteringChildren, e, f);
          }
        }
        return {
          animation: J,
          options: re
        };
      }));
    }
    if (p.size) {
      const x = {};
      if (typeof d.initial != "boolean") {
        const F = He(e, Array.isArray(d.initial) ? d.initial[0] : d.initial);
        F && F.transition && (x.transition = F.transition);
      }
      p.forEach((F) => {
        const S = e.getBaseTarget(F), T = e.getValue(F);
        T && (T.liveStyle = !0), x[F] = S ?? null;
      }), h.push({ animation: x });
    }
    let w = !!h.length;
    return i && (d.initial === !1 || d.initial === d.animate) && !e.manuallyAnimateOnMount && (w = !1), i = !1, w ? t(h) : Promise.resolve();
  }
  function l(a, d) {
    if (n[a].isActive === d)
      return Promise.resolve();
    e.variantChildren?.forEach((h) => h.animationState?.setActive(a, d)), n[a].isActive = d;
    const u = r(a);
    for (const h in n)
      n[h].protectedKeys = {};
    return u;
  }
  return {
    animateChanges: r,
    setActive: l,
    setAnimateFunction: o,
    getState: () => n,
    reset: () => {
      n = us();
    }
  };
}
function gd(e, t) {
  return typeof t == "string" ? t !== e : Array.isArray(t) ? !wo(t, e) : !1;
}
function Ee(e = !1) {
  return {
    isActive: e,
    protectedKeys: {},
    needsAnimating: {},
    prevResolvedValues: {}
  };
}
function us() {
  return {
    animate: Ee(!0),
    whileInView: Ee(),
    whileHover: Ee(),
    whileTap: Ee(),
    whileDrag: Ee(),
    whileFocus: Ee(),
    exit: Ee()
  };
}
class Ae {
  constructor(t) {
    this.isMounted = !1, this.node = t;
  }
  update() {
  }
}
class vd extends Ae {
  /**
   * We dynamically generate the AnimationState manager as it contains a reference
   * to the underlying animation library. We only want to load that if we load this,
   * so people can optionally code split it out using the `m` component.
   */
  constructor(t) {
    super(t), t.animationState || (t.animationState = yd(t));
  }
  updateAnimationControlsSubscription() {
    const { animate: t } = this.node.getProps();
    Kt(t) && (this.unmountControls = t.subscribe(this.node));
  }
  /**
   * Subscribe any provided AnimationControls to the component's VisualElement
   */
  mount() {
    this.updateAnimationControlsSubscription();
  }
  update() {
    const { animate: t } = this.node.getProps(), { animate: n } = this.node.prevProps || {};
    t !== n && this.updateAnimationControlsSubscription();
  }
  unmount() {
    this.node.animationState.reset(), this.unmountControls?.();
  }
}
let bd = 0;
class xd extends Ae {
  constructor() {
    super(...arguments), this.id = bd++;
  }
  update() {
    if (!this.node.presenceContext)
      return;
    const { isPresent: t, onExitComplete: n } = this.node.presenceContext, { isPresent: i } = this.node.prevPresenceContext || {};
    if (!this.node.animationState || t === i)
      return;
    const s = this.node.animationState.setActive("exit", !t);
    n && !t && s.then(() => {
      n(this.id);
    });
  }
  mount() {
    const { register: t, onExitComplete: n } = this.node.presenceContext || {};
    n && n(this.id), t && (this.unmount = t(this.id));
  }
  unmount() {
  }
}
const Fd = {
  animation: {
    Feature: vd
  },
  exit: {
    Feature: xd
  }
};
function vt(e, t, n, i = { passive: !0 }) {
  return e.addEventListener(t, n, i), () => e.removeEventListener(t, n);
}
function Ct(e) {
  return {
    point: {
      x: e.pageX,
      y: e.pageY
    }
  };
}
const wd = (e) => (t) => ci(t) && e(t, Ct(t));
function ct(e, t, n, i) {
  return vt(e, t, wd(n), i);
}
const To = 1e-4, Sd = 1 - To, Td = 1 + To, Co = 0.01, Cd = 0 - Co, kd = 0 + Co;
function se(e) {
  return e.max - e.min;
}
function Md(e, t, n) {
  return Math.abs(e - t) <= n;
}
function hs(e, t, n, i = 0.5) {
  e.origin = i, e.originPoint = G(t.min, t.max, e.origin), e.scale = se(n) / se(t), e.translate = G(n.min, n.max, e.origin) - e.originPoint, (e.scale >= Sd && e.scale <= Td || isNaN(e.scale)) && (e.scale = 1), (e.translate >= Cd && e.translate <= kd || isNaN(e.translate)) && (e.translate = 0);
}
function dt(e, t, n, i) {
  hs(e.x, t.x, n.x, i ? i.originX : void 0), hs(e.y, t.y, n.y, i ? i.originY : void 0);
}
function fs(e, t, n) {
  e.min = n.min + t.min, e.max = e.min + se(t);
}
function Pd(e, t, n) {
  fs(e.x, t.x, n.x), fs(e.y, t.y, n.y);
}
function ps(e, t, n) {
  e.min = t.min - n.min, e.max = e.min + se(t);
}
function ut(e, t, n) {
  ps(e.x, t.x, n.x), ps(e.y, t.y, n.y);
}
function ce(e) {
  return [e("x"), e("y")];
}
const ko = ({ current: e }) => e ? e.ownerDocument.defaultView : null, ms = (e, t) => Math.abs(e - t);
function Ad(e, t) {
  const n = ms(e.x, t.x), i = ms(e.y, t.y);
  return Math.sqrt(n ** 2 + i ** 2);
}
class Mo {
  constructor(t, n, { transformPagePoint: i, contextWindow: s = window, dragSnapToOrigin: o = !1, distanceThreshold: r = 3 } = {}) {
    if (this.startEvent = null, this.lastMoveEvent = null, this.lastMoveEventInfo = null, this.handlers = {}, this.contextWindow = window, this.updatePoint = () => {
      if (!(this.lastMoveEvent && this.lastMoveEventInfo))
        return;
      const p = cn(this.lastMoveEventInfo, this.history), g = this.startEvent !== null, b = Ad(p.offset, { x: 0, y: 0 }) >= this.distanceThreshold;
      if (!g && !b)
        return;
      const { point: w } = p, { timestamp: x } = ie;
      this.history.push({ ...w, timestamp: x });
      const { onStart: F, onMove: S } = this.handlers;
      g || (F && F(this.lastMoveEvent, p), this.startEvent = this.lastMoveEvent), S && S(this.lastMoveEvent, p);
    }, this.handlePointerMove = (p, g) => {
      this.lastMoveEvent = p, this.lastMoveEventInfo = ln(g, this.transformPagePoint), $.update(this.updatePoint, !0);
    }, this.handlePointerUp = (p, g) => {
      this.end();
      const { onEnd: b, onSessionEnd: w, resumeAnimation: x } = this.handlers;
      if (this.dragSnapToOrigin && x && x(), !(this.lastMoveEvent && this.lastMoveEventInfo))
        return;
      const F = cn(p.type === "pointercancel" ? this.lastMoveEventInfo : ln(g, this.transformPagePoint), this.history);
      this.startEvent && b && b(p, F), w && w(p, F);
    }, !ci(t))
      return;
    this.dragSnapToOrigin = o, this.handlers = n, this.transformPagePoint = i, this.distanceThreshold = r, this.contextWindow = s || window;
    const l = Ct(t), a = ln(l, this.transformPagePoint), { point: d } = a, { timestamp: u } = ie;
    this.history = [{ ...d, timestamp: u }];
    const { onSessionStart: h } = n;
    h && h(t, cn(a, this.history)), this.removeListeners = Ft(ct(this.contextWindow, "pointermove", this.handlePointerMove), ct(this.contextWindow, "pointerup", this.handlePointerUp), ct(this.contextWindow, "pointercancel", this.handlePointerUp));
  }
  updateHandlers(t) {
    this.handlers = t;
  }
  end() {
    this.removeListeners && this.removeListeners(), ke(this.updatePoint);
  }
}
function ln(e, t) {
  return t ? { point: t(e.point) } : e;
}
function ys(e, t) {
  return { x: e.x - t.x, y: e.y - t.y };
}
function cn({ point: e }, t) {
  return {
    point: e,
    delta: ys(e, Po(t)),
    offset: ys(e, Vd(t)),
    velocity: Ed(t, 0.1)
  };
}
function Vd(e) {
  return e[0];
}
function Po(e) {
  return e[e.length - 1];
}
function Ed(e, t) {
  if (e.length < 2)
    return { x: 0, y: 0 };
  let n = e.length - 1, i = null;
  const s = Po(e);
  for (; n >= 0 && (i = e[n], !(s.timestamp - i.timestamp > /* @__PURE__ */ ve(t))); )
    n--;
  if (!i)
    return { x: 0, y: 0 };
  const o = /* @__PURE__ */ ue(s.timestamp - i.timestamp);
  if (o === 0)
    return { x: 0, y: 0 };
  const r = {
    x: (s.x - i.x) / o,
    y: (s.y - i.y) / o
  };
  return r.x === 1 / 0 && (r.x = 0), r.y === 1 / 0 && (r.y = 0), r;
}
function Id(e, { min: t, max: n }, i) {
  return t !== void 0 && e < t ? e = i ? G(t, e, i.min) : Math.max(e, t) : n !== void 0 && e > n && (e = i ? G(n, e, i.max) : Math.min(e, n)), e;
}
function gs(e, t, n) {
  return {
    min: t !== void 0 ? e.min + t : void 0,
    max: n !== void 0 ? e.max + n - (e.max - e.min) : void 0
  };
}
function Nd(e, { top: t, left: n, bottom: i, right: s }) {
  return {
    x: gs(e.x, n, s),
    y: gs(e.y, t, i)
  };
}
function vs(e, t) {
  let n = t.min - e.min, i = t.max - e.max;
  return t.max - t.min < e.max - e.min && ([n, i] = [i, n]), { min: n, max: i };
}
function Dd(e, t) {
  return {
    x: vs(e.x, t.x),
    y: vs(e.y, t.y)
  };
}
function Bd(e, t) {
  let n = 0.5;
  const i = se(e), s = se(t);
  return s > i ? n = /* @__PURE__ */ ft(t.min, t.max - i, e.min) : i > s && (n = /* @__PURE__ */ ft(e.min, e.max - s, t.min)), Te(0, 1, n);
}
function Rd(e, t) {
  const n = {};
  return t.min !== void 0 && (n.min = t.min - e.min), t.max !== void 0 && (n.max = t.max - e.min), n;
}
const Bn = 0.35;
function Ld(e = Bn) {
  return e === !1 ? e = 0 : e === !0 && (e = Bn), {
    x: bs(e, "left", "right"),
    y: bs(e, "top", "bottom")
  };
}
function bs(e, t, n) {
  return {
    min: xs(e, t),
    max: xs(e, n)
  };
}
function xs(e, t) {
  return typeof e == "number" ? e : e[t] || 0;
}
const zd = /* @__PURE__ */ new WeakMap();
class jd {
  constructor(t) {
    this.openDragLock = null, this.isDragging = !1, this.currentDirection = null, this.originPoint = { x: 0, y: 0 }, this.constraints = !1, this.hasMutatedConstraints = !1, this.elastic = X(), this.latestPointerEvent = null, this.latestPanInfo = null, this.visualElement = t;
  }
  start(t, { snapToCursor: n = !1, distanceThreshold: i } = {}) {
    const { presenceContext: s } = this.visualElement;
    if (s && s.isPresent === !1)
      return;
    const o = (h) => {
      const { dragSnapToOrigin: p } = this.getProps();
      p ? this.pauseAnimation() : this.stopAnimation(), n && this.snapToCursor(Ct(h).point);
    }, r = (h, p) => {
      const { drag: g, dragPropagation: b, onDragStart: w } = this.getProps();
      if (g && !b && (this.openDragLock && this.openDragLock(), this.openDragLock = $l(g), !this.openDragLock))
        return;
      this.latestPointerEvent = h, this.latestPanInfo = p, this.isDragging = !0, this.currentDirection = null, this.resolveConstraints(), this.visualElement.projection && (this.visualElement.projection.isAnimationBlocked = !0, this.visualElement.projection.target = void 0), ce((F) => {
        let S = this.getAxisMotionValue(F).get() || 0;
        if (be.test(S)) {
          const { projection: T } = this.visualElement;
          if (T && T.layout) {
            const E = T.layout.layoutBox[F];
            E && (S = se(E) * (parseFloat(S) / 100));
          }
        }
        this.originPoint[F] = S;
      }), w && $.postRender(() => w(h, p)), Nn(this.visualElement, "transform");
      const { animationState: x } = this.visualElement;
      x && x.setActive("whileDrag", !0);
    }, l = (h, p) => {
      this.latestPointerEvent = h, this.latestPanInfo = p;
      const { dragPropagation: g, dragDirectionLock: b, onDirectionLock: w, onDrag: x } = this.getProps();
      if (!g && !this.openDragLock)
        return;
      const { offset: F } = p;
      if (b && this.currentDirection === null) {
        this.currentDirection = Wd(F), this.currentDirection !== null && w && w(this.currentDirection);
        return;
      }
      this.updateAxis("x", p.point, F), this.updateAxis("y", p.point, F), this.visualElement.render(), x && x(h, p);
    }, a = (h, p) => {
      this.latestPointerEvent = h, this.latestPanInfo = p, this.stop(h, p), this.latestPointerEvent = null, this.latestPanInfo = null;
    }, d = () => ce((h) => this.getAnimationState(h) === "paused" && this.getAxisMotionValue(h).animation?.play()), { dragSnapToOrigin: u } = this.getProps();
    this.panSession = new Mo(t, {
      onSessionStart: o,
      onStart: r,
      onMove: l,
      onSessionEnd: a,
      resumeAnimation: d
    }, {
      transformPagePoint: this.visualElement.getTransformPagePoint(),
      dragSnapToOrigin: u,
      distanceThreshold: i,
      contextWindow: ko(this.visualElement)
    });
  }
  /**
   * @internal
   */
  stop(t, n) {
    const i = t || this.latestPointerEvent, s = n || this.latestPanInfo, o = this.isDragging;
    if (this.cancel(), !o || !s || !i)
      return;
    const { velocity: r } = s;
    this.startAnimation(r);
    const { onDragEnd: l } = this.getProps();
    l && $.postRender(() => l(i, s));
  }
  /**
   * @internal
   */
  cancel() {
    this.isDragging = !1;
    const { projection: t, animationState: n } = this.visualElement;
    t && (t.isAnimationBlocked = !1), this.panSession && this.panSession.end(), this.panSession = void 0;
    const { dragPropagation: i } = this.getProps();
    !i && this.openDragLock && (this.openDragLock(), this.openDragLock = null), n && n.setActive("whileDrag", !1);
  }
  updateAxis(t, n, i) {
    const { drag: s } = this.getProps();
    if (!i || !It(t, s, this.currentDirection))
      return;
    const o = this.getAxisMotionValue(t);
    let r = this.originPoint[t] + i[t];
    this.constraints && this.constraints[t] && (r = Id(r, this.constraints[t], this.elastic[t])), o.set(r);
  }
  resolveConstraints() {
    const { dragConstraints: t, dragElastic: n } = this.getProps(), i = this.visualElement.projection && !this.visualElement.projection.layout ? this.visualElement.projection.measure(!1) : this.visualElement.projection?.layout, s = this.constraints;
    t && _e(t) ? this.constraints || (this.constraints = this.resolveRefConstraints()) : t && i ? this.constraints = Nd(i.layoutBox, t) : this.constraints = !1, this.elastic = Ld(n), s !== this.constraints && i && this.constraints && !this.hasMutatedConstraints && ce((o) => {
      this.constraints !== !1 && this.getAxisMotionValue(o) && (this.constraints[o] = Rd(i.layoutBox[o], this.constraints[o]));
    });
  }
  resolveRefConstraints() {
    const { dragConstraints: t, onMeasureDragConstraints: n } = this.getProps();
    if (!t || !_e(t))
      return !1;
    const i = t.current, { projection: s } = this.visualElement;
    if (!s || !s.layout)
      return !1;
    const o = Oc(i, s.root, this.visualElement.getTransformPagePoint());
    let r = Dd(s.layout.layoutBox, o);
    if (n) {
      const l = n(zc(r));
      this.hasMutatedConstraints = !!l, l && (r = uo(l));
    }
    return r;
  }
  startAnimation(t) {
    const { drag: n, dragMomentum: i, dragElastic: s, dragTransition: o, dragSnapToOrigin: r, onDragTransitionEnd: l } = this.getProps(), a = this.constraints || {}, d = ce((u) => {
      if (!It(u, n, this.currentDirection))
        return;
      let h = a && a[u] || {};
      r && (h = { min: 0, max: 0 });
      const p = s ? 200 : 1e6, g = s ? 40 : 1e7, b = {
        type: "inertia",
        velocity: i ? t[u] : 0,
        bounceStiffness: p,
        bounceDamping: g,
        timeConstant: 750,
        restDelta: 1,
        restSpeed: 10,
        ...o,
        ...h
      };
      return this.startAxisValueAnimation(u, b);
    });
    return Promise.all(d).then(l);
  }
  startAxisValueAnimation(t, n) {
    const i = this.getAxisMotionValue(t);
    return Nn(this.visualElement, t), i.start(vi(t, i, 0, n, this.visualElement, !1));
  }
  stopAnimation() {
    ce((t) => this.getAxisMotionValue(t).stop());
  }
  pauseAnimation() {
    ce((t) => this.getAxisMotionValue(t).animation?.pause());
  }
  getAnimationState(t) {
    return this.getAxisMotionValue(t).animation?.state;
  }
  /**
   * Drag works differently depending on which props are provided.
   *
   * - If _dragX and _dragY are provided, we output the gesture delta directly to those motion values.
   * - Otherwise, we apply the delta to the x/y motion values.
   */
  getAxisMotionValue(t) {
    const n = `_drag${t.toUpperCase()}`, i = this.visualElement.getProps(), s = i[n];
    return s || this.visualElement.getValue(t, (i.initial ? i.initial[t] : void 0) || 0);
  }
  snapToCursor(t) {
    ce((n) => {
      const { drag: i } = this.getProps();
      if (!It(n, i, this.currentDirection))
        return;
      const { projection: s } = this.visualElement, o = this.getAxisMotionValue(n);
      if (s && s.layout) {
        const { min: r, max: l } = s.layout.layoutBox[n];
        o.set(t[n] - G(r, l, 0.5));
      }
    });
  }
  /**
   * When the viewport resizes we want to check if the measured constraints
   * have changed and, if so, reposition the element within those new constraints
   * relative to where it was before the resize.
   */
  scalePositionWithinConstraints() {
    if (!this.visualElement.current)
      return;
    const { drag: t, dragConstraints: n } = this.getProps(), { projection: i } = this.visualElement;
    if (!_e(n) || !i || !this.constraints)
      return;
    this.stopAnimation();
    const s = { x: 0, y: 0 };
    ce((r) => {
      const l = this.getAxisMotionValue(r);
      if (l && this.constraints !== !1) {
        const a = l.get();
        s[r] = Bd({ min: a, max: a }, this.constraints[r]);
      }
    });
    const { transformTemplate: o } = this.visualElement.getProps();
    this.visualElement.current.style.transform = o ? o({}, "") : "none", i.root && i.root.updateScroll(), i.updateLayout(), this.resolveConstraints(), ce((r) => {
      if (!It(r, t, null))
        return;
      const l = this.getAxisMotionValue(r), { min: a, max: d } = this.constraints[r];
      l.set(G(a, d, s[r]));
    });
  }
  addListeners() {
    if (!this.visualElement.current)
      return;
    zd.set(this.visualElement, this);
    const t = this.visualElement.current, n = ct(t, "pointerdown", (a) => {
      const { drag: d, dragListener: u = !0 } = this.getProps();
      d && u && this.start(a);
    }), i = () => {
      const { dragConstraints: a } = this.getProps();
      _e(a) && a.current && (this.constraints = this.resolveRefConstraints());
    }, { projection: s } = this.visualElement, o = s.addEventListener("measure", i);
    s && !s.layout && (s.root && s.root.updateScroll(), s.updateLayout()), $.read(i);
    const r = vt(window, "resize", () => this.scalePositionWithinConstraints()), l = s.addEventListener("didUpdate", (({ delta: a, hasLayoutChanged: d }) => {
      this.isDragging && d && (ce((u) => {
        const h = this.getAxisMotionValue(u);
        h && (this.originPoint[u] += a[u].translate, h.set(h.get() + a[u].translate));
      }), this.visualElement.render());
    }));
    return () => {
      r(), n(), o(), l && l();
    };
  }
  getProps() {
    const t = this.visualElement.getProps(), { drag: n = !1, dragDirectionLock: i = !1, dragPropagation: s = !1, dragConstraints: o = !1, dragElastic: r = Bn, dragMomentum: l = !0 } = t;
    return {
      ...t,
      drag: n,
      dragDirectionLock: i,
      dragPropagation: s,
      dragConstraints: o,
      dragElastic: r,
      dragMomentum: l
    };
  }
}
function It(e, t, n) {
  return (t === !0 || t === e) && (n === null || n === e);
}
function Wd(e, t = 10) {
  let n = null;
  return Math.abs(e.y) > t ? n = "y" : Math.abs(e.x) > t && (n = "x"), n;
}
class Od extends Ae {
  constructor(t) {
    super(t), this.removeGroupControls = he, this.removeListeners = he, this.controls = new jd(t);
  }
  mount() {
    const { dragControls: t } = this.node.getProps();
    t && (this.removeGroupControls = t.subscribe(this.controls)), this.removeListeners = this.controls.addListeners() || he;
  }
  unmount() {
    this.removeGroupControls(), this.removeListeners();
  }
}
const Fs = (e) => (t, n) => {
  e && $.postRender(() => e(t, n));
};
class _d extends Ae {
  constructor() {
    super(...arguments), this.removePointerDownListener = he;
  }
  onPointerDown(t) {
    this.session = new Mo(t, this.createPanHandlers(), {
      transformPagePoint: this.node.getTransformPagePoint(),
      contextWindow: ko(this.node)
    });
  }
  createPanHandlers() {
    const { onPanSessionStart: t, onPanStart: n, onPan: i, onPanEnd: s } = this.node.getProps();
    return {
      onSessionStart: Fs(t),
      onStart: Fs(n),
      onMove: i,
      onEnd: (o, r) => {
        delete this.session, s && $.postRender(() => s(o, r));
      }
    };
  }
  mount() {
    this.removePointerDownListener = ct(this.node.current, "pointerdown", (t) => this.onPointerDown(t));
  }
  update() {
    this.session && this.session.updateHandlers(this.createPanHandlers());
  }
  unmount() {
    this.removePointerDownListener(), this.session && this.session.end();
  }
}
const Lt = {
  /**
   * Global flag as to whether the tree has animated since the last time
   * we resized the window
   */
  hasAnimatedSinceResize: !0,
  /**
   * We set this to true once, on the first update. Any nodes added to the tree beyond that
   * update will be given a `data-projection-id` attribute.
   */
  hasEverUpdated: !1
};
function ws(e, t) {
  return t.max === t.min ? 0 : e / (t.max - t.min) * 100;
}
const nt = {
  correct: (e, t) => {
    if (!t.target)
      return e;
    if (typeof e == "string")
      if (M.test(e))
        e = parseFloat(e);
      else
        return e;
    const n = ws(e, t.target.x), i = ws(e, t.target.y);
    return `${n}% ${i}%`;
  }
}, $d = {
  correct: (e, { treeScale: t, projectionDelta: n }) => {
    const i = e, s = Pe.parse(e);
    if (s.length > 5)
      return i;
    const o = Pe.createTransformer(e), r = typeof s[0] != "number" ? 1 : 0, l = n.x.scale * t.x, a = n.y.scale * t.y;
    s[0 + r] /= l, s[1 + r] /= a;
    const d = G(l, a, 0.5);
    return typeof s[2 + r] == "number" && (s[2 + r] /= d), typeof s[3 + r] == "number" && (s[3 + r] /= d), o(s);
  }
};
let dn = !1;
class Ud extends ir {
  /**
   * This only mounts projection nodes for components that
   * need measuring, we might want to do it for all components
   * in order to incorporate transforms
   */
  componentDidMount() {
    const { visualElement: t, layoutGroup: n, switchLayoutGroup: i, layoutId: s } = this.props, { projection: o } = t;
    hc(Gd), o && (n.group && n.group.add(o), i && i.register && s && i.register(o), dn && o.root.didUpdate(), o.addEventListener("animationComplete", () => {
      this.safeToRemove();
    }), o.setOptions({
      ...o.options,
      onExitComplete: () => this.safeToRemove()
    })), Lt.hasEverUpdated = !0;
  }
  getSnapshotBeforeUpdate(t) {
    const { layoutDependency: n, visualElement: i, drag: s, isPresent: o } = this.props, { projection: r } = i;
    return r && (r.isPresent = o, dn = !0, s || t.layoutDependency !== n || n === void 0 || t.isPresent !== o ? r.willUpdate() : this.safeToRemove(), t.isPresent !== o && (o ? r.promote() : r.relegate() || $.postRender(() => {
      const l = r.getStack();
      (!l || !l.members.length) && this.safeToRemove();
    }))), null;
  }
  componentDidUpdate() {
    const { projection: t } = this.props.visualElement;
    t && (t.root.didUpdate(), li.postRender(() => {
      !t.currentAnimation && t.isLead() && this.safeToRemove();
    }));
  }
  componentWillUnmount() {
    const { visualElement: t, layoutGroup: n, switchLayoutGroup: i } = this.props, { projection: s } = t;
    dn = !0, s && (s.scheduleCheckAfterUnmount(), n && n.group && n.group.remove(s), i && i.deregister && i.deregister(s));
  }
  safeToRemove() {
    const { safeToRemove: t } = this.props;
    t && t();
  }
  render() {
    return null;
  }
}
function Ao(e) {
  const [t, n] = Yr(), i = Q(On);
  return c(Ud, { ...e, layoutGroup: i, switchLayoutGroup: Q(lo), isPresent: t, safeToRemove: n });
}
const Gd = {
  borderRadius: {
    ...nt,
    applyTo: [
      "borderTopLeftRadius",
      "borderTopRightRadius",
      "borderBottomLeftRadius",
      "borderBottomRightRadius"
    ]
  },
  borderTopLeftRadius: nt,
  borderTopRightRadius: nt,
  borderBottomLeftRadius: nt,
  borderBottomRightRadius: nt,
  boxShadow: $d
};
function Hd(e, t, n) {
  const i = ee(e) ? e : ze(e);
  return i.start(vi("", i, t, n)), i.animation;
}
const Kd = (e, t) => e.depth - t.depth;
class qd {
  constructor() {
    this.children = [], this.isDirty = !1;
  }
  add(t) {
    Un(this.children, t), this.isDirty = !0;
  }
  remove(t) {
    Gn(this.children, t), this.isDirty = !0;
  }
  forEach(t) {
    this.isDirty && this.children.sort(Kd), this.isDirty = !1, this.children.forEach(t);
  }
}
function Xd(e, t) {
  const n = ae.now(), i = ({ timestamp: s }) => {
    const o = s - n;
    o >= t && (ke(i), e(o - t));
  };
  return $.setup(i, !0), () => ke(i);
}
const Vo = ["TopLeft", "TopRight", "BottomLeft", "BottomRight"], Yd = Vo.length, Ss = (e) => typeof e == "string" ? parseFloat(e) : e, Ts = (e) => typeof e == "number" || M.test(e);
function Zd(e, t, n, i, s, o) {
  s ? (e.opacity = G(0, n.opacity ?? 1, Jd(i)), e.opacityExit = G(t.opacity ?? 1, 0, Qd(i))) : o && (e.opacity = G(t.opacity ?? 1, n.opacity ?? 1, i));
  for (let r = 0; r < Yd; r++) {
    const l = `border${Vo[r]}Radius`;
    let a = Cs(t, l), d = Cs(n, l);
    if (a === void 0 && d === void 0)
      continue;
    a || (a = 0), d || (d = 0), a === 0 || d === 0 || Ts(a) === Ts(d) ? (e[l] = Math.max(G(Ss(a), Ss(d), i), 0), (be.test(d) || be.test(a)) && (e[l] += "%")) : e[l] = d;
  }
  (t.rotate || n.rotate) && (e.rotate = G(t.rotate || 0, n.rotate || 0, i));
}
function Cs(e, t) {
  return e[t] !== void 0 ? e[t] : e.borderRadius;
}
const Jd = /* @__PURE__ */ Eo(0, 0.5, mr), Qd = /* @__PURE__ */ Eo(0.5, 0.95, he);
function Eo(e, t, n) {
  return (i) => i < e ? 0 : i > t ? 1 : n(/* @__PURE__ */ ft(e, t, i));
}
function ks(e, t) {
  e.min = t.min, e.max = t.max;
}
function le(e, t) {
  ks(e.x, t.x), ks(e.y, t.y);
}
function Ms(e, t) {
  e.translate = t.translate, e.scale = t.scale, e.originPoint = t.originPoint, e.origin = t.origin;
}
function Ps(e, t, n, i, s) {
  return e -= t, e = $t(e, 1 / n, i), s !== void 0 && (e = $t(e, 1 / s, i)), e;
}
function eu(e, t = 0, n = 1, i = 0.5, s, o = e, r = e) {
  if (be.test(t) && (t = parseFloat(t), t = G(r.min, r.max, t / 100) - r.min), typeof t != "number")
    return;
  let l = G(o.min, o.max, i);
  e === o && (l -= t), e.min = Ps(e.min, t, n, l, s), e.max = Ps(e.max, t, n, l, s);
}
function As(e, t, [n, i, s], o, r) {
  eu(e, t[n], t[i], t[s], t.scale, o, r);
}
const tu = ["x", "scaleX", "originX"], nu = ["y", "scaleY", "originY"];
function Vs(e, t, n, i) {
  As(e.x, t, tu, n ? n.x : void 0, i ? i.x : void 0), As(e.y, t, nu, n ? n.y : void 0, i ? i.y : void 0);
}
function Es(e) {
  return e.translate === 0 && e.scale === 1;
}
function Io(e) {
  return Es(e.x) && Es(e.y);
}
function Is(e, t) {
  return e.min === t.min && e.max === t.max;
}
function iu(e, t) {
  return Is(e.x, t.x) && Is(e.y, t.y);
}
function Ns(e, t) {
  return Math.round(e.min) === Math.round(t.min) && Math.round(e.max) === Math.round(t.max);
}
function No(e, t) {
  return Ns(e.x, t.x) && Ns(e.y, t.y);
}
function Ds(e) {
  return se(e.x) / se(e.y);
}
function Bs(e, t) {
  return e.translate === t.translate && e.scale === t.scale && e.originPoint === t.originPoint;
}
class su {
  constructor() {
    this.members = [];
  }
  add(t) {
    Un(this.members, t), t.scheduleRender();
  }
  remove(t) {
    if (Gn(this.members, t), t === this.prevLead && (this.prevLead = void 0), t === this.lead) {
      const n = this.members[this.members.length - 1];
      n && this.promote(n);
    }
  }
  relegate(t) {
    const n = this.members.findIndex((s) => t === s);
    if (n === 0)
      return !1;
    let i;
    for (let s = n; s >= 0; s--) {
      const o = this.members[s];
      if (o.isPresent !== !1) {
        i = o;
        break;
      }
    }
    return i ? (this.promote(i), !0) : !1;
  }
  promote(t, n) {
    const i = this.lead;
    if (t !== i && (this.prevLead = i, this.lead = t, t.show(), i)) {
      i.instance && i.scheduleRender(), t.scheduleRender(), t.resumeFrom = i, n && (t.resumeFrom.preserveOpacity = !0), i.snapshot && (t.snapshot = i.snapshot, t.snapshot.latestValues = i.animationValues || i.latestValues), t.root && t.root.isUpdating && (t.isLayoutDirty = !0);
      const { crossfade: s } = t.options;
      s === !1 && i.hide();
    }
  }
  exitAnimationComplete() {
    this.members.forEach((t) => {
      const { options: n, resumingFrom: i } = t;
      n.onExitComplete && n.onExitComplete(), i && i.options.onExitComplete && i.options.onExitComplete();
    });
  }
  scheduleRender() {
    this.members.forEach((t) => {
      t.instance && t.scheduleRender(!1);
    });
  }
  /**
   * Clear any leads that have been removed this render to prevent them from being
   * used in future animations and to prevent memory leaks
   */
  removeLeadSnapshot() {
    this.lead && this.lead.snapshot && (this.lead.snapshot = void 0);
  }
}
function ru(e, t, n) {
  let i = "";
  const s = e.x.translate / t.x, o = e.y.translate / t.y, r = n?.z || 0;
  if ((s || o || r) && (i = `translate3d(${s}px, ${o}px, ${r}px) `), (t.x !== 1 || t.y !== 1) && (i += `scale(${1 / t.x}, ${1 / t.y}) `), n) {
    const { transformPerspective: d, rotate: u, rotateX: h, rotateY: p, skewX: g, skewY: b } = n;
    d && (i = `perspective(${d}px) ${i}`), u && (i += `rotate(${u}deg) `), h && (i += `rotateX(${h}deg) `), p && (i += `rotateY(${p}deg) `), g && (i += `skewX(${g}deg) `), b && (i += `skewY(${b}deg) `);
  }
  const l = e.x.scale * t.x, a = e.y.scale * t.y;
  return (l !== 1 || a !== 1) && (i += `scale(${l}, ${a})`), i || "none";
}
const un = ["", "X", "Y", "Z"], ou = 1e3;
let au = 0;
function hn(e, t, n, i) {
  const { latestValues: s } = t;
  s[e] && (n[e] = s[e], t.setStaticValue(e, 0), i && (i[e] = 0));
}
function Do(e) {
  if (e.hasCheckedOptimisedAppear = !0, e.root === e)
    return;
  const { visualElement: t } = e.options;
  if (!t)
    return;
  const n = bo(t);
  if (window.MotionHasOptimisedAnimation(n, "transform")) {
    const { layout: s, layoutId: o } = e.options;
    window.MotionCancelOptimisedAnimation(n, "transform", $, !(s || o));
  }
  const { parent: i } = e;
  i && !i.hasCheckedOptimisedAppear && Do(i);
}
function Bo({ attachResizeListener: e, defaultParent: t, measureScroll: n, checkIsScrollRoot: i, resetTransform: s }) {
  return class {
    constructor(r = {}, l = t?.()) {
      this.id = au++, this.animationId = 0, this.animationCommitId = 0, this.children = /* @__PURE__ */ new Set(), this.options = {}, this.isTreeAnimating = !1, this.isAnimationBlocked = !1, this.isLayoutDirty = !1, this.isProjectionDirty = !1, this.isSharedProjectionDirty = !1, this.isTransformDirty = !1, this.updateManuallyBlocked = !1, this.updateBlockedByResize = !1, this.isUpdating = !1, this.isSVG = !1, this.needsReset = !1, this.shouldResetTransform = !1, this.hasCheckedOptimisedAppear = !1, this.treeScale = { x: 1, y: 1 }, this.eventHandlers = /* @__PURE__ */ new Map(), this.hasTreeAnimated = !1, this.updateScheduled = !1, this.scheduleUpdate = () => this.update(), this.projectionUpdateScheduled = !1, this.checkUpdateFailed = () => {
        this.isUpdating && (this.isUpdating = !1, this.clearAllSnapshots());
      }, this.updateProjection = () => {
        this.projectionUpdateScheduled = !1, this.nodes.forEach(du), this.nodes.forEach(pu), this.nodes.forEach(mu), this.nodes.forEach(uu);
      }, this.resolvedRelativeTargetAt = 0, this.hasProjected = !1, this.isVisible = !0, this.animationProgress = 0, this.sharedNodes = /* @__PURE__ */ new Map(), this.latestValues = r, this.root = l ? l.root || l : this, this.path = l ? [...l.path, l] : [], this.parent = l, this.depth = l ? l.depth + 1 : 0;
      for (let a = 0; a < this.path.length; a++)
        this.path[a].shouldResetTransform = !0;
      this.root === this && (this.nodes = new qd());
    }
    addEventListener(r, l) {
      return this.eventHandlers.has(r) || this.eventHandlers.set(r, new qn()), this.eventHandlers.get(r).add(l);
    }
    notifyListeners(r, ...l) {
      const a = this.eventHandlers.get(r);
      a && a.notify(...l);
    }
    hasListeners(r) {
      return this.eventHandlers.has(r);
    }
    /**
     * Lifecycles
     */
    mount(r) {
      if (this.instance)
        return;
      this.isSVG = Xr(r) && !Xl(r), this.instance = r;
      const { layoutId: l, layout: a, visualElement: d } = this.options;
      if (d && !d.current && d.mount(r), this.root.nodes.add(this), this.parent && this.parent.children.add(this), this.root.hasTreeAnimated && (a || l) && (this.isLayoutDirty = !0), e) {
        let u, h = 0;
        const p = () => this.root.updateBlockedByResize = !1;
        $.read(() => {
          h = window.innerWidth;
        }), e(r, () => {
          const g = window.innerWidth;
          g !== h && (h = g, this.root.updateBlockedByResize = !0, u && u(), u = Xd(p, 250), Lt.hasAnimatedSinceResize && (Lt.hasAnimatedSinceResize = !1, this.nodes.forEach(zs)));
        });
      }
      l && this.root.registerSharedNode(l, this), this.options.animate !== !1 && d && (l || a) && this.addEventListener("didUpdate", ({ delta: u, hasLayoutChanged: h, hasRelativeLayoutChanged: p, layout: g }) => {
        if (this.isTreeAnimationBlocked()) {
          this.target = void 0, this.relativeTarget = void 0;
          return;
        }
        const b = this.options.transition || d.getDefaultTransition() || xu, { onLayoutAnimationStart: w, onLayoutAnimationComplete: x } = d.getProps(), F = !this.targetLayout || !No(this.targetLayout, g), S = !h && p;
        if (this.options.layoutRoot || this.resumeFrom || S || h && (F || !this.currentAnimation)) {
          this.resumeFrom && (this.resumingFrom = this.resumeFrom, this.resumingFrom.resumingFrom = void 0);
          const T = {
            ...oi(b, "layout"),
            onPlay: w,
            onComplete: x
          };
          (d.shouldReduceMotion || this.options.layoutRoot) && (T.delay = 0, T.type = !1), this.startAnimation(T), this.setAnimationOrigin(u, S);
        } else
          h || zs(this), this.isLead() && this.options.onExitComplete && this.options.onExitComplete();
        this.targetLayout = g;
      });
    }
    unmount() {
      this.options.layoutId && this.willUpdate(), this.root.nodes.remove(this);
      const r = this.getStack();
      r && r.remove(this), this.parent && this.parent.children.delete(this), this.instance = void 0, this.eventHandlers.clear(), ke(this.updateProjection);
    }
    // only on the root
    blockUpdate() {
      this.updateManuallyBlocked = !0;
    }
    unblockUpdate() {
      this.updateManuallyBlocked = !1;
    }
    isUpdateBlocked() {
      return this.updateManuallyBlocked || this.updateBlockedByResize;
    }
    isTreeAnimationBlocked() {
      return this.isAnimationBlocked || this.parent && this.parent.isTreeAnimationBlocked() || !1;
    }
    // Note: currently only running on root node
    startUpdate() {
      this.isUpdateBlocked() || (this.isUpdating = !0, this.nodes && this.nodes.forEach(yu), this.animationId++);
    }
    getTransformTemplate() {
      const { visualElement: r } = this.options;
      return r && r.getProps().transformTemplate;
    }
    willUpdate(r = !0) {
      if (this.root.hasTreeAnimated = !0, this.root.isUpdateBlocked()) {
        this.options.onExitComplete && this.options.onExitComplete();
        return;
      }
      if (window.MotionCancelOptimisedAnimation && !this.hasCheckedOptimisedAppear && Do(this), !this.root.isUpdating && this.root.startUpdate(), this.isLayoutDirty)
        return;
      this.isLayoutDirty = !0;
      for (let u = 0; u < this.path.length; u++) {
        const h = this.path[u];
        h.shouldResetTransform = !0, h.updateScroll("snapshot"), h.options.layoutRoot && h.willUpdate(!1);
      }
      const { layoutId: l, layout: a } = this.options;
      if (l === void 0 && !a)
        return;
      const d = this.getTransformTemplate();
      this.prevTransformTemplateValue = d ? d(this.latestValues, "") : void 0, this.updateSnapshot(), r && this.notifyListeners("willUpdate");
    }
    update() {
      if (this.updateScheduled = !1, this.isUpdateBlocked()) {
        this.unblockUpdate(), this.clearAllSnapshots(), this.nodes.forEach(Rs);
        return;
      }
      if (this.animationId <= this.animationCommitId) {
        this.nodes.forEach(Ls);
        return;
      }
      this.animationCommitId = this.animationId, this.isUpdating ? (this.isUpdating = !1, this.nodes.forEach(fu), this.nodes.forEach(lu), this.nodes.forEach(cu)) : this.nodes.forEach(Ls), this.clearAllSnapshots();
      const l = ae.now();
      ie.delta = Te(0, 1e3 / 60, l - ie.timestamp), ie.timestamp = l, ie.isProcessing = !0, Qt.update.process(ie), Qt.preRender.process(ie), Qt.render.process(ie), ie.isProcessing = !1;
    }
    didUpdate() {
      this.updateScheduled || (this.updateScheduled = !0, li.read(this.scheduleUpdate));
    }
    clearAllSnapshots() {
      this.nodes.forEach(hu), this.sharedNodes.forEach(gu);
    }
    scheduleUpdateProjection() {
      this.projectionUpdateScheduled || (this.projectionUpdateScheduled = !0, $.preRender(this.updateProjection, !1, !0));
    }
    scheduleCheckAfterUnmount() {
      $.postRender(() => {
        this.isLayoutDirty ? this.root.didUpdate() : this.root.checkUpdateFailed();
      });
    }
    /**
     * Update measurements
     */
    updateSnapshot() {
      this.snapshot || !this.instance || (this.snapshot = this.measure(), this.snapshot && !se(this.snapshot.measuredBox.x) && !se(this.snapshot.measuredBox.y) && (this.snapshot = void 0));
    }
    updateLayout() {
      if (!this.instance || (this.updateScroll(), !(this.options.alwaysMeasureLayout && this.isLead()) && !this.isLayoutDirty))
        return;
      if (this.resumeFrom && !this.resumeFrom.instance)
        for (let a = 0; a < this.path.length; a++)
          this.path[a].updateScroll();
      const r = this.layout;
      this.layout = this.measure(!1), this.layoutCorrected = X(), this.isLayoutDirty = !1, this.projectionDelta = void 0, this.notifyListeners("measure", this.layout.layoutBox);
      const { visualElement: l } = this.options;
      l && l.notify("LayoutMeasure", this.layout.layoutBox, r ? r.layoutBox : void 0);
    }
    updateScroll(r = "measure") {
      let l = !!(this.options.layoutScroll && this.instance);
      if (this.scroll && this.scroll.animationId === this.root.animationId && this.scroll.phase === r && (l = !1), l && this.instance) {
        const a = i(this.instance);
        this.scroll = {
          animationId: this.root.animationId,
          phase: r,
          isRoot: a,
          offset: n(this.instance),
          wasRoot: this.scroll ? this.scroll.isRoot : a
        };
      }
    }
    resetTransform() {
      if (!s)
        return;
      const r = this.isLayoutDirty || this.shouldResetTransform || this.options.alwaysMeasureLayout, l = this.projectionDelta && !Io(this.projectionDelta), a = this.getTransformTemplate(), d = a ? a(this.latestValues, "") : void 0, u = d !== this.prevTransformTemplateValue;
      r && this.instance && (l || Ie(this.latestValues) || u) && (s(this.instance, d), this.shouldResetTransform = !1, this.scheduleRender());
    }
    measure(r = !0) {
      const l = this.measurePageBox();
      let a = this.removeElementScroll(l);
      return r && (a = this.removeTransform(a)), Fu(a), {
        animationId: this.root.animationId,
        measuredBox: l,
        layoutBox: a,
        latestValues: {},
        source: this.id
      };
    }
    measurePageBox() {
      const { visualElement: r } = this.options;
      if (!r)
        return X();
      const l = r.measureViewportBox();
      if (!(this.scroll?.wasRoot || this.path.some(wu))) {
        const { scroll: d } = this.root;
        d && ($e(l.x, d.offset.x), $e(l.y, d.offset.y));
      }
      return l;
    }
    removeElementScroll(r) {
      const l = X();
      if (le(l, r), this.scroll?.wasRoot)
        return l;
      for (let a = 0; a < this.path.length; a++) {
        const d = this.path[a], { scroll: u, options: h } = d;
        d !== this.root && u && h.layoutScroll && (u.wasRoot && le(l, r), $e(l.x, u.offset.x), $e(l.y, u.offset.y));
      }
      return l;
    }
    applyTransform(r, l = !1) {
      const a = X();
      le(a, r);
      for (let d = 0; d < this.path.length; d++) {
        const u = this.path[d];
        !l && u.options.layoutScroll && u.scroll && u !== u.root && Ue(a, {
          x: -u.scroll.offset.x,
          y: -u.scroll.offset.y
        }), Ie(u.latestValues) && Ue(a, u.latestValues);
      }
      return Ie(this.latestValues) && Ue(a, this.latestValues), a;
    }
    removeTransform(r) {
      const l = X();
      le(l, r);
      for (let a = 0; a < this.path.length; a++) {
        const d = this.path[a];
        if (!d.instance || !Ie(d.latestValues))
          continue;
        An(d.latestValues) && d.updateSnapshot();
        const u = X(), h = d.measurePageBox();
        le(u, h), Vs(l, d.latestValues, d.snapshot ? d.snapshot.layoutBox : void 0, u);
      }
      return Ie(this.latestValues) && Vs(l, this.latestValues), l;
    }
    setTargetDelta(r) {
      this.targetDelta = r, this.root.scheduleUpdateProjection(), this.isProjectionDirty = !0;
    }
    setOptions(r) {
      this.options = {
        ...this.options,
        ...r,
        crossfade: r.crossfade !== void 0 ? r.crossfade : !0
      };
    }
    clearMeasurements() {
      this.scroll = void 0, this.layout = void 0, this.snapshot = void 0, this.prevTransformTemplateValue = void 0, this.targetDelta = void 0, this.target = void 0, this.isLayoutDirty = !1;
    }
    forceRelativeParentToResolveTarget() {
      this.relativeParent && this.relativeParent.resolvedRelativeTargetAt !== ie.timestamp && this.relativeParent.resolveTargetDelta(!0);
    }
    resolveTargetDelta(r = !1) {
      const l = this.getLead();
      this.isProjectionDirty || (this.isProjectionDirty = l.isProjectionDirty), this.isTransformDirty || (this.isTransformDirty = l.isTransformDirty), this.isSharedProjectionDirty || (this.isSharedProjectionDirty = l.isSharedProjectionDirty);
      const a = !!this.resumingFrom || this !== l;
      if (!(r || a && this.isSharedProjectionDirty || this.isProjectionDirty || this.parent?.isProjectionDirty || this.attemptToResolveRelativeTarget || this.root.updateBlockedByResize))
        return;
      const { layout: u, layoutId: h } = this.options;
      if (!(!this.layout || !(u || h))) {
        if (this.resolvedRelativeTargetAt = ie.timestamp, !this.targetDelta && !this.relativeTarget) {
          const p = this.getClosestProjectingParent();
          p && p.layout && this.animationProgress !== 1 ? (this.relativeParent = p, this.forceRelativeParentToResolveTarget(), this.relativeTarget = X(), this.relativeTargetOrigin = X(), ut(this.relativeTargetOrigin, this.layout.layoutBox, p.layout.layoutBox), le(this.relativeTarget, this.relativeTargetOrigin)) : this.relativeParent = this.relativeTarget = void 0;
        }
        if (!(!this.relativeTarget && !this.targetDelta) && (this.target || (this.target = X(), this.targetWithTransforms = X()), this.relativeTarget && this.relativeTargetOrigin && this.relativeParent && this.relativeParent.target ? (this.forceRelativeParentToResolveTarget(), Pd(this.target, this.relativeTarget, this.relativeParent.target)) : this.targetDelta ? (this.resumingFrom ? this.target = this.applyTransform(this.layout.layoutBox) : le(this.target, this.layout.layoutBox), fo(this.target, this.targetDelta)) : le(this.target, this.layout.layoutBox), this.attemptToResolveRelativeTarget)) {
          this.attemptToResolveRelativeTarget = !1;
          const p = this.getClosestProjectingParent();
          p && !!p.resumingFrom == !!this.resumingFrom && !p.options.layoutScroll && p.target && this.animationProgress !== 1 ? (this.relativeParent = p, this.forceRelativeParentToResolveTarget(), this.relativeTarget = X(), this.relativeTargetOrigin = X(), ut(this.relativeTargetOrigin, this.target, p.target), le(this.relativeTarget, this.relativeTargetOrigin)) : this.relativeParent = this.relativeTarget = void 0;
        }
      }
    }
    getClosestProjectingParent() {
      if (!(!this.parent || An(this.parent.latestValues) || ho(this.parent.latestValues)))
        return this.parent.isProjecting() ? this.parent : this.parent.getClosestProjectingParent();
    }
    isProjecting() {
      return !!((this.relativeTarget || this.targetDelta || this.options.layoutRoot) && this.layout);
    }
    calcProjection() {
      const r = this.getLead(), l = !!this.resumingFrom || this !== r;
      let a = !0;
      if ((this.isProjectionDirty || this.parent?.isProjectionDirty) && (a = !1), l && (this.isSharedProjectionDirty || this.isTransformDirty) && (a = !1), this.resolvedRelativeTargetAt === ie.timestamp && (a = !1), a)
        return;
      const { layout: d, layoutId: u } = this.options;
      if (this.isTreeAnimating = !!(this.parent && this.parent.isTreeAnimating || this.currentAnimation || this.pendingAnimation), this.isTreeAnimating || (this.targetDelta = this.relativeTarget = void 0), !this.layout || !(d || u))
        return;
      le(this.layoutCorrected, this.layout.layoutBox);
      const h = this.treeScale.x, p = this.treeScale.y;
      Wc(this.layoutCorrected, this.treeScale, this.path, l), r.layout && !r.target && (this.treeScale.x !== 1 || this.treeScale.y !== 1) && (r.target = r.layout.layoutBox, r.targetWithTransforms = X());
      const { target: g } = r;
      if (!g) {
        this.prevProjectionDelta && (this.createProjectionDeltas(), this.scheduleRender());
        return;
      }
      !this.projectionDelta || !this.prevProjectionDelta ? this.createProjectionDeltas() : (Ms(this.prevProjectionDelta.x, this.projectionDelta.x), Ms(this.prevProjectionDelta.y, this.projectionDelta.y)), dt(this.projectionDelta, this.layoutCorrected, g, this.latestValues), (this.treeScale.x !== h || this.treeScale.y !== p || !Bs(this.projectionDelta.x, this.prevProjectionDelta.x) || !Bs(this.projectionDelta.y, this.prevProjectionDelta.y)) && (this.hasProjected = !0, this.scheduleRender(), this.notifyListeners("projectionUpdate", g));
    }
    hide() {
      this.isVisible = !1;
    }
    show() {
      this.isVisible = !0;
    }
    scheduleRender(r = !0) {
      if (this.options.visualElement?.scheduleRender(), r) {
        const l = this.getStack();
        l && l.scheduleRender();
      }
      this.resumingFrom && !this.resumingFrom.instance && (this.resumingFrom = void 0);
    }
    createProjectionDeltas() {
      this.prevProjectionDelta = Ge(), this.projectionDelta = Ge(), this.projectionDeltaWithTransform = Ge();
    }
    setAnimationOrigin(r, l = !1) {
      const a = this.snapshot, d = a ? a.latestValues : {}, u = { ...this.latestValues }, h = Ge();
      (!this.relativeParent || !this.relativeParent.options.layoutRoot) && (this.relativeTarget = this.relativeTargetOrigin = void 0), this.attemptToResolveRelativeTarget = !l;
      const p = X(), g = a ? a.source : void 0, b = this.layout ? this.layout.source : void 0, w = g !== b, x = this.getStack(), F = !x || x.members.length <= 1, S = !!(w && !F && this.options.crossfade === !0 && !this.path.some(bu));
      this.animationProgress = 0;
      let T;
      this.mixTargetDelta = (E) => {
        const k = E / 1e3;
        js(h.x, r.x, k), js(h.y, r.y, k), this.setTargetDelta(h), this.relativeTarget && this.relativeTargetOrigin && this.layout && this.relativeParent && this.relativeParent.layout && (ut(p, this.layout.layoutBox, this.relativeParent.layout.layoutBox), vu(this.relativeTarget, this.relativeTargetOrigin, p, k), T && iu(this.relativeTarget, T) && (this.isProjectionDirty = !1), T || (T = X()), le(T, this.relativeTarget)), w && (this.animationValues = u, Zd(u, d, this.latestValues, k, S, F)), this.root.scheduleUpdateProjection(), this.scheduleRender(), this.animationProgress = k;
      }, this.mixTargetDelta(this.options.layoutRoot ? 1e3 : 0);
    }
    startAnimation(r) {
      this.notifyListeners("animationStart"), this.currentAnimation?.stop(), this.resumingFrom?.currentAnimation?.stop(), this.pendingAnimation && (ke(this.pendingAnimation), this.pendingAnimation = void 0), this.pendingAnimation = $.update(() => {
        Lt.hasAnimatedSinceResize = !0, this.motionValue || (this.motionValue = ze(0)), this.currentAnimation = Hd(this.motionValue, [0, 1e3], {
          ...r,
          velocity: 0,
          isSync: !0,
          onUpdate: (l) => {
            this.mixTargetDelta(l), r.onUpdate && r.onUpdate(l);
          },
          onStop: () => {
          },
          onComplete: () => {
            r.onComplete && r.onComplete(), this.completeAnimation();
          }
        }), this.resumingFrom && (this.resumingFrom.currentAnimation = this.currentAnimation), this.pendingAnimation = void 0;
      });
    }
    completeAnimation() {
      this.resumingFrom && (this.resumingFrom.currentAnimation = void 0, this.resumingFrom.preserveOpacity = void 0);
      const r = this.getStack();
      r && r.exitAnimationComplete(), this.resumingFrom = this.currentAnimation = this.animationValues = void 0, this.notifyListeners("animationComplete");
    }
    finishAnimation() {
      this.currentAnimation && (this.mixTargetDelta && this.mixTargetDelta(ou), this.currentAnimation.stop()), this.completeAnimation();
    }
    applyTransformsToTarget() {
      const r = this.getLead();
      let { targetWithTransforms: l, target: a, layout: d, latestValues: u } = r;
      if (!(!l || !a || !d)) {
        if (this !== r && this.layout && d && Ro(this.options.animationType, this.layout.layoutBox, d.layoutBox)) {
          a = this.target || X();
          const h = se(this.layout.layoutBox.x);
          a.x.min = r.target.x.min, a.x.max = a.x.min + h;
          const p = se(this.layout.layoutBox.y);
          a.y.min = r.target.y.min, a.y.max = a.y.min + p;
        }
        le(l, a), Ue(l, u), dt(this.projectionDeltaWithTransform, this.layoutCorrected, l, u);
      }
    }
    registerSharedNode(r, l) {
      this.sharedNodes.has(r) || this.sharedNodes.set(r, new su()), this.sharedNodes.get(r).add(l);
      const d = l.options.initialPromotionConfig;
      l.promote({
        transition: d ? d.transition : void 0,
        preserveFollowOpacity: d && d.shouldPreserveFollowOpacity ? d.shouldPreserveFollowOpacity(l) : void 0
      });
    }
    isLead() {
      const r = this.getStack();
      return r ? r.lead === this : !0;
    }
    getLead() {
      const { layoutId: r } = this.options;
      return r ? this.getStack()?.lead || this : this;
    }
    getPrevLead() {
      const { layoutId: r } = this.options;
      return r ? this.getStack()?.prevLead : void 0;
    }
    getStack() {
      const { layoutId: r } = this.options;
      if (r)
        return this.root.sharedNodes.get(r);
    }
    promote({ needsReset: r, transition: l, preserveFollowOpacity: a } = {}) {
      const d = this.getStack();
      d && d.promote(this, a), r && (this.projectionDelta = void 0, this.needsReset = !0), l && this.setOptions({ transition: l });
    }
    relegate() {
      const r = this.getStack();
      return r ? r.relegate(this) : !1;
    }
    resetSkewAndRotation() {
      const { visualElement: r } = this.options;
      if (!r)
        return;
      let l = !1;
      const { latestValues: a } = r;
      if ((a.z || a.rotate || a.rotateX || a.rotateY || a.rotateZ || a.skewX || a.skewY) && (l = !0), !l)
        return;
      const d = {};
      a.z && hn("z", r, d, this.animationValues);
      for (let u = 0; u < un.length; u++)
        hn(`rotate${un[u]}`, r, d, this.animationValues), hn(`skew${un[u]}`, r, d, this.animationValues);
      r.render();
      for (const u in d)
        r.setStaticValue(u, d[u]), this.animationValues && (this.animationValues[u] = d[u]);
      r.scheduleRender();
    }
    applyProjectionStyles(r, l) {
      if (!this.instance || this.isSVG)
        return;
      if (!this.isVisible) {
        r.visibility = "hidden";
        return;
      }
      const a = this.getTransformTemplate();
      if (this.needsReset) {
        this.needsReset = !1, r.visibility = "", r.opacity = "", r.pointerEvents = Rt(l?.pointerEvents) || "", r.transform = a ? a(this.latestValues, "") : "none";
        return;
      }
      const d = this.getLead();
      if (!this.projectionDelta || !this.layout || !d.target) {
        this.options.layoutId && (r.opacity = this.latestValues.opacity !== void 0 ? this.latestValues.opacity : 1, r.pointerEvents = Rt(l?.pointerEvents) || ""), this.hasProjected && !Ie(this.latestValues) && (r.transform = a ? a({}, "") : "none", this.hasProjected = !1);
        return;
      }
      r.visibility = "";
      const u = d.animationValues || d.latestValues;
      this.applyTransformsToTarget();
      let h = ru(this.projectionDeltaWithTransform, this.treeScale, u);
      a && (h = a(u, h)), r.transform = h;
      const { x: p, y: g } = this.projectionDelta;
      r.transformOrigin = `${p.origin * 100}% ${g.origin * 100}% 0`, d.animationValues ? r.opacity = d === this ? u.opacity ?? this.latestValues.opacity ?? 1 : this.preserveOpacity ? this.latestValues.opacity : u.opacityExit : r.opacity = d === this ? u.opacity !== void 0 ? u.opacity : "" : u.opacityExit !== void 0 ? u.opacityExit : 0;
      for (const b in gt) {
        if (u[b] === void 0)
          continue;
        const { correct: w, applyTo: x, isCSSVariable: F } = gt[b], S = h === "none" ? u[b] : w(u[b], d);
        if (x) {
          const T = x.length;
          for (let E = 0; E < T; E++)
            r[x[E]] = S;
        } else
          F ? this.options.visualElement.renderState.vars[b] = S : r[b] = S;
      }
      this.options.layoutId && (r.pointerEvents = d === this ? Rt(l?.pointerEvents) || "" : "none");
    }
    clearSnapshot() {
      this.resumeFrom = this.snapshot = void 0;
    }
    // Only run on root
    resetTree() {
      this.root.nodes.forEach((r) => r.currentAnimation?.stop()), this.root.nodes.forEach(Rs), this.root.sharedNodes.clear();
    }
  };
}
function lu(e) {
  e.updateLayout();
}
function cu(e) {
  const t = e.resumeFrom?.snapshot || e.snapshot;
  if (e.isLead() && e.layout && t && e.hasListeners("didUpdate")) {
    const { layoutBox: n, measuredBox: i } = e.layout, { animationType: s } = e.options, o = t.source !== e.layout.source;
    s === "size" ? ce((u) => {
      const h = o ? t.measuredBox[u] : t.layoutBox[u], p = se(h);
      h.min = n[u].min, h.max = h.min + p;
    }) : Ro(s, t.layoutBox, n) && ce((u) => {
      const h = o ? t.measuredBox[u] : t.layoutBox[u], p = se(n[u]);
      h.max = h.min + p, e.relativeTarget && !e.currentAnimation && (e.isProjectionDirty = !0, e.relativeTarget[u].max = e.relativeTarget[u].min + p);
    });
    const r = Ge();
    dt(r, n, t.layoutBox);
    const l = Ge();
    o ? dt(l, e.applyTransform(i, !0), t.measuredBox) : dt(l, n, t.layoutBox);
    const a = !Io(r);
    let d = !1;
    if (!e.resumeFrom) {
      const u = e.getClosestProjectingParent();
      if (u && !u.resumeFrom) {
        const { snapshot: h, layout: p } = u;
        if (h && p) {
          const g = X();
          ut(g, t.layoutBox, h.layoutBox);
          const b = X();
          ut(b, n, p.layoutBox), No(g, b) || (d = !0), u.options.layoutRoot && (e.relativeTarget = b, e.relativeTargetOrigin = g, e.relativeParent = u);
        }
      }
    }
    e.notifyListeners("didUpdate", {
      layout: n,
      snapshot: t,
      delta: l,
      layoutDelta: r,
      hasLayoutChanged: a,
      hasRelativeLayoutChanged: d
    });
  } else if (e.isLead()) {
    const { onExitComplete: n } = e.options;
    n && n();
  }
  e.options.transition = void 0;
}
function du(e) {
  e.parent && (e.isProjecting() || (e.isProjectionDirty = e.parent.isProjectionDirty), e.isSharedProjectionDirty || (e.isSharedProjectionDirty = !!(e.isProjectionDirty || e.parent.isProjectionDirty || e.parent.isSharedProjectionDirty)), e.isTransformDirty || (e.isTransformDirty = e.parent.isTransformDirty));
}
function uu(e) {
  e.isProjectionDirty = e.isSharedProjectionDirty = e.isTransformDirty = !1;
}
function hu(e) {
  e.clearSnapshot();
}
function Rs(e) {
  e.clearMeasurements();
}
function Ls(e) {
  e.isLayoutDirty = !1;
}
function fu(e) {
  const { visualElement: t } = e.options;
  t && t.getProps().onBeforeLayoutMeasure && t.notify("BeforeLayoutMeasure"), e.resetTransform();
}
function zs(e) {
  e.finishAnimation(), e.targetDelta = e.relativeTarget = e.target = void 0, e.isProjectionDirty = !0;
}
function pu(e) {
  e.resolveTargetDelta();
}
function mu(e) {
  e.calcProjection();
}
function yu(e) {
  e.resetSkewAndRotation();
}
function gu(e) {
  e.removeLeadSnapshot();
}
function js(e, t, n) {
  e.translate = G(t.translate, 0, n), e.scale = G(t.scale, 1, n), e.origin = t.origin, e.originPoint = t.originPoint;
}
function Ws(e, t, n, i) {
  e.min = G(t.min, n.min, i), e.max = G(t.max, n.max, i);
}
function vu(e, t, n, i) {
  Ws(e.x, t.x, n.x, i), Ws(e.y, t.y, n.y, i);
}
function bu(e) {
  return e.animationValues && e.animationValues.opacityExit !== void 0;
}
const xu = {
  duration: 0.45,
  ease: [0.4, 0, 0.1, 1]
}, Os = (e) => typeof navigator < "u" && navigator.userAgent && navigator.userAgent.toLowerCase().includes(e), _s = Os("applewebkit/") && !Os("chrome/") ? Math.round : he;
function $s(e) {
  e.min = _s(e.min), e.max = _s(e.max);
}
function Fu(e) {
  $s(e.x), $s(e.y);
}
function Ro(e, t, n) {
  return e === "position" || e === "preserve-aspect" && !Md(Ds(t), Ds(n), 0.2);
}
function wu(e) {
  return e !== e.root && e.scroll?.wasRoot;
}
const Su = Bo({
  attachResizeListener: (e, t) => vt(e, "resize", t),
  measureScroll: () => ({
    x: document.documentElement.scrollLeft || document.body.scrollLeft,
    y: document.documentElement.scrollTop || document.body.scrollTop
  }),
  checkIsScrollRoot: () => !0
}), fn = {
  current: void 0
}, Lo = Bo({
  measureScroll: (e) => ({
    x: e.scrollLeft,
    y: e.scrollTop
  }),
  defaultParent: () => {
    if (!fn.current) {
      const e = new Su({});
      e.mount(window), e.setOptions({ layoutScroll: !0 }), fn.current = e;
    }
    return fn.current;
  },
  resetTransform: (e, t) => {
    e.style.transform = t !== void 0 ? t : "none";
  },
  checkIsScrollRoot: (e) => window.getComputedStyle(e).position === "fixed"
}), Tu = {
  pan: {
    Feature: _d
  },
  drag: {
    Feature: Od,
    ProjectionNode: Lo,
    MeasureLayout: Ao
  }
};
function Us(e, t, n) {
  const { props: i } = e;
  e.animationState && i.whileHover && e.animationState.setActive("whileHover", n === "Start");
  const s = "onHover" + n, o = i[s];
  o && $.postRender(() => o(t, Ct(t)));
}
class Cu extends Ae {
  mount() {
    const { current: t } = this.node;
    t && (this.unmount = Ul(t, (n, i) => (Us(this.node, i, "Start"), (s) => Us(this.node, s, "End"))));
  }
  unmount() {
  }
}
class ku extends Ae {
  constructor() {
    super(...arguments), this.isActive = !1;
  }
  onFocus() {
    let t = !1;
    try {
      t = this.node.current.matches(":focus-visible");
    } catch {
      t = !0;
    }
    !t || !this.node.animationState || (this.node.animationState.setActive("whileFocus", !0), this.isActive = !0);
  }
  onBlur() {
    !this.isActive || !this.node.animationState || (this.node.animationState.setActive("whileFocus", !1), this.isActive = !1);
  }
  mount() {
    this.unmount = Ft(vt(this.node.current, "focus", () => this.onFocus()), vt(this.node.current, "blur", () => this.onBlur()));
  }
  unmount() {
  }
}
function Gs(e, t, n) {
  const { props: i } = e;
  if (e.current instanceof HTMLButtonElement && e.current.disabled)
    return;
  e.animationState && i.whileTap && e.animationState.setActive("whileTap", n === "Start");
  const s = "onTap" + (n === "End" ? "" : n), o = i[s];
  o && $.postRender(() => o(t, Ct(t)));
}
class Mu extends Ae {
  mount() {
    const { current: t } = this.node;
    t && (this.unmount = ql(t, (n, i) => (Gs(this.node, i, "Start"), (s, { success: o }) => Gs(this.node, s, o ? "End" : "Cancel")), { useGlobalTarget: this.node.props.globalTapTarget }));
  }
  unmount() {
  }
}
const Rn = /* @__PURE__ */ new WeakMap(), pn = /* @__PURE__ */ new WeakMap(), Pu = (e) => {
  const t = Rn.get(e.target);
  t && t(e);
}, Au = (e) => {
  e.forEach(Pu);
};
function Vu({ root: e, ...t }) {
  const n = e || document;
  pn.has(n) || pn.set(n, {});
  const i = pn.get(n), s = JSON.stringify(t);
  return i[s] || (i[s] = new IntersectionObserver(Au, { root: e, ...t })), i[s];
}
function Eu(e, t, n) {
  const i = Vu(t);
  return Rn.set(e, n), i.observe(e), () => {
    Rn.delete(e), i.unobserve(e);
  };
}
const Iu = {
  some: 0,
  all: 1
};
class Nu extends Ae {
  constructor() {
    super(...arguments), this.hasEnteredView = !1, this.isInView = !1;
  }
  startObserver() {
    this.unmount();
    const { viewport: t = {} } = this.node.getProps(), { root: n, margin: i, amount: s = "some", once: o } = t, r = {
      root: n ? n.current : void 0,
      rootMargin: i,
      threshold: typeof s == "number" ? s : Iu[s]
    }, l = (a) => {
      const { isIntersecting: d } = a;
      if (this.isInView === d || (this.isInView = d, o && !d && this.hasEnteredView))
        return;
      d && (this.hasEnteredView = !0), this.node.animationState && this.node.animationState.setActive("whileInView", d);
      const { onViewportEnter: u, onViewportLeave: h } = this.node.getProps(), p = d ? u : h;
      p && p(a);
    };
    return Eu(this.node.current, r, l);
  }
  mount() {
    this.startObserver();
  }
  update() {
    if (typeof IntersectionObserver > "u")
      return;
    const { props: t, prevProps: n } = this.node;
    ["amount", "margin", "root"].some(Du(t, n)) && this.startObserver();
  }
  unmount() {
  }
}
function Du({ viewport: e = {} }, { viewport: t = {} } = {}) {
  return (n) => e[n] !== t[n];
}
const Bu = {
  inView: {
    Feature: Nu
  },
  tap: {
    Feature: Mu
  },
  focus: {
    Feature: ku
  },
  hover: {
    Feature: Cu
  }
}, Ru = {
  layout: {
    ProjectionNode: Lo,
    MeasureLayout: Ao
  }
}, Lu = {
  ...Fd,
  ...Bu,
  ...Tu,
  ...Ru
}, v = /* @__PURE__ */ Lc(Lu, Yc);
function bi(e) {
  const t = xt(() => ze(e)), { isStatic: n } = Q(Tt);
  if (n) {
    const [, i] = W(e);
    xe(() => t.on("change", i), []);
  }
  return t;
}
function zo(e, t) {
  const n = bi(t()), i = () => n.set(t());
  return i(), $n(() => {
    const s = () => $.preRender(i, !1, !0), o = e.map((r) => r.on("change", s));
    return () => {
      o.forEach((r) => r()), ke(i);
    };
  }), n;
}
function zu(e) {
  lt.current = [], e();
  const t = zo(lt.current, e);
  return lt.current = void 0, t;
}
function ht(e, t, n, i) {
  if (typeof e == "function")
    return zu(e);
  const s = typeof t == "function" ? t : Yl(t, n, i);
  return Array.isArray(e) ? Hs(e, s) : Hs([e], ([o]) => s(o));
}
function Hs(e, t) {
  const n = xt(() => []);
  return zo(e, () => {
    n.length = 0;
    const i = e.length;
    for (let s = 0; s < i; s++)
      n[s] = e[s].get();
    return t(n);
  });
}
function ju(e, t = {}) {
  const { isStatic: n } = Q(Tt), i = () => ee(e) ? e.get() : e;
  if (n)
    return ht(i);
  const s = bi(i());
  return Wn(() => Zl(s, e, t), [s, JSON.stringify(t)]), s;
}
function Wu() {
  const e = Se(null);
  return xe(() => {
    const t = e.current;
    if (!t) return;
    const n = t.getContext("2d");
    if (!n) return;
    let i, s = 0;
    const o = () => {
      t.width = window.innerWidth, t.height = window.innerHeight;
    };
    o(), window.addEventListener("resize", o);
    const r = [
      { x: 0.3, y: 0.2, r: 300, color: [99, 102, 241], speed: 3e-4, phase: 0 },
      { x: 0.7, y: 0.4, r: 250, color: [129, 140, 248], speed: 4e-4, phase: 2 },
      { x: 0.5, y: 0.7, r: 280, color: [67, 56, 202], speed: 35e-5, phase: 4 },
      { x: 0.2, y: 0.8, r: 220, color: [139, 92, 246], speed: 45e-5, phase: 1 },
      { x: 0.8, y: 0.15, r: 200, color: [79, 70, 229], speed: 5e-4, phase: 3 }
    ], l = () => {
      s++, n.fillStyle = "#0E0E1A", n.fillRect(0, 0, t.width, t.height), r.forEach((a) => {
        const d = t.width * (a.x + 0.15 * Math.sin(s * a.speed + a.phase)), u = t.height * (a.y + 0.1 * Math.cos(s * a.speed * 1.3 + a.phase)), h = n.createRadialGradient(d, u, 0, d, u, a.r * (t.width / 400));
        h.addColorStop(0, `rgba(${a.color.join(",")}, 0.35)`), h.addColorStop(0.5, `rgba(${a.color.join(",")}, 0.12)`), h.addColorStop(1, `rgba(${a.color.join(",")}, 0)`), n.fillStyle = h, n.fillRect(0, 0, t.width, t.height);
      }), i = requestAnimationFrame(l);
    };
    return l(), () => {
      cancelAnimationFrame(i), window.removeEventListener("resize", o);
    };
  }, []), /* @__PURE__ */ c(
    "canvas",
    {
      ref: e,
      className: "fixed inset-0 w-full h-full",
      style: { zIndex: 0 }
    }
  );
}
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Ou = (e) => e.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase(), _u = (e) => e.replace(
  /^([A-Z])|[\s-_]+(\w)/g,
  (t, n, i) => i ? i.toUpperCase() : n.toLowerCase()
), Ks = (e) => {
  const t = _u(e);
  return t.charAt(0).toUpperCase() + t.slice(1);
}, jo = (...e) => e.filter((t, n, i) => !!t && t.trim() !== "" && i.indexOf(t) === n).join(" ").trim();
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
var $u = {
  xmlns: "http://www.w3.org/2000/svg",
  width: 24,
  height: 24,
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 2,
  strokeLinecap: "round",
  strokeLinejoin: "round"
};
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Uu = zn(
  ({
    color: e = "currentColor",
    size: t = 24,
    strokeWidth: n = 2,
    absoluteStrokeWidth: i,
    className: s = "",
    children: o,
    iconNode: r,
    ...l
  }, a) => zt(
    "svg",
    {
      ref: a,
      ...$u,
      width: t,
      height: t,
      stroke: e,
      strokeWidth: i ? Number(n) * 24 / Number(t) : n,
      className: jo("lucide", s),
      ...l
    },
    [
      ...r.map(([d, u]) => zt(d, u)),
      ...Array.isArray(o) ? o : [o]
    ]
  )
);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const j = (e, t) => {
  const n = zn(
    ({ className: i, ...s }, o) => zt(Uu, {
      ref: o,
      iconNode: t,
      className: jo(
        `lucide-${Ou(Ks(e))}`,
        `lucide-${e}`,
        i
      ),
      ...s
    })
  );
  return n.displayName = Ks(e), n;
};
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Gu = [
  ["path", { d: "m12 19-7-7 7-7", key: "1l729n" }],
  ["path", { d: "M19 12H5", key: "x3x0zl" }]
], Hu = j("arrow-left", Gu);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Ku = [
  ["path", { d: "M12 7v14", key: "1akyts" }],
  [
    "path",
    {
      d: "M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z",
      key: "ruj8y"
    }
  ]
], kt = j("book-open", Ku);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const qu = [
  [
    "path",
    {
      d: "M12 5a3 3 0 1 0-5.997.125 4 4 0 0 0-2.526 5.77 4 4 0 0 0 .556 6.588A4 4 0 1 0 12 18Z",
      key: "l5xja"
    }
  ],
  [
    "path",
    {
      d: "M12 5a3 3 0 1 1 5.997.125 4 4 0 0 1 2.526 5.77 4 4 0 0 1-.556 6.588A4 4 0 1 1 12 18Z",
      key: "ep3f8r"
    }
  ],
  ["path", { d: "M15 13a4.5 4.5 0 0 1-3-4 4.5 4.5 0 0 1-3 4", key: "1p4c4q" }],
  ["path", { d: "M17.599 6.5a3 3 0 0 0 .399-1.375", key: "tmeiqw" }],
  ["path", { d: "M6.003 5.125A3 3 0 0 0 6.401 6.5", key: "105sqy" }],
  ["path", { d: "M3.477 10.896a4 4 0 0 1 .585-.396", key: "ql3yin" }],
  ["path", { d: "M19.938 10.5a4 4 0 0 1 .585.396", key: "1qfode" }],
  ["path", { d: "M6 18a4 4 0 0 1-1.967-.516", key: "2e4loj" }],
  ["path", { d: "M19.967 17.484A4 4 0 0 1 18 18", key: "159ez6" }]
], bt = j("brain", qu);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Xu = [
  ["path", { d: "M8 2v4", key: "1cmpym" }],
  ["path", { d: "M16 2v4", key: "4m81vk" }],
  ["rect", { width: "18", height: "18", x: "3", y: "4", rx: "2", key: "1hopcy" }],
  ["path", { d: "M3 10h18", key: "8toen8" }],
  ["path", { d: "M8 14h.01", key: "6423bh" }],
  ["path", { d: "M12 14h.01", key: "1etili" }],
  ["path", { d: "M16 14h.01", key: "1gbofw" }],
  ["path", { d: "M8 18h.01", key: "lrp35t" }],
  ["path", { d: "M12 18h.01", key: "mhygvu" }],
  ["path", { d: "M16 18h.01", key: "kzsmim" }]
], Yu = j("calendar-days", Xu);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Zu = [
  ["path", { d: "M8 2v4", key: "1cmpym" }],
  ["path", { d: "M16 2v4", key: "4m81vk" }],
  ["rect", { width: "18", height: "18", x: "3", y: "4", rx: "2", key: "1hopcy" }],
  ["path", { d: "M3 10h18", key: "8toen8" }]
], Ju = j("calendar", Zu);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Qu = [
  ["path", { d: "M3 3v16a2 2 0 0 0 2 2h16", key: "c24i48" }],
  ["path", { d: "M18 17V9", key: "2bz60n" }],
  ["path", { d: "M13 17V5", key: "1frdt8" }],
  ["path", { d: "M8 17v-3", key: "17ska0" }]
], Wo = j("chart-column", Qu);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const eh = [["path", { d: "M20 6 9 17l-5-5", key: "1gmf2c" }]], xi = j("check", eh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const th = [["path", { d: "m9 18 6-6-6-6", key: "mthhwq" }]], Fi = j("chevron-right", th);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const nh = [
  ["circle", { cx: "12", cy: "12", r: "10", key: "1mglay" }],
  ["path", { d: "m9 12 2 2 4-4", key: "dzmm74" }]
], ih = j("circle-check", nh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const sh = [
  ["rect", { width: "8", height: "4", x: "8", y: "2", rx: "1", ry: "1", key: "tgr4d6" }],
  [
    "path",
    {
      d: "M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2",
      key: "116196"
    }
  ],
  ["path", { d: "M12 11h4", key: "1jrz19" }],
  ["path", { d: "M12 16h4", key: "n85exb" }],
  ["path", { d: "M8 11h.01", key: "1dfujw" }],
  ["path", { d: "M8 16h.01", key: "18s6g9" }]
], rh = j("clipboard-list", sh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const oh = [
  ["circle", { cx: "12", cy: "12", r: "10", key: "1mglay" }],
  ["polyline", { points: "12 6 12 12 16 14", key: "68esgv" }]
], wi = j("clock", oh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const ah = [
  ["path", { d: "M12 13v8", key: "1l5pq0" }],
  ["path", { d: "M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242", key: "1pljnt" }],
  ["path", { d: "m8 17 4-4 4 4", key: "1quai1" }]
], lh = j("cloud-upload", ah);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const ch = [
  ["path", { d: "M10 2v2", key: "7u0qdc" }],
  ["path", { d: "M14 2v2", key: "6buw04" }],
  [
    "path",
    {
      d: "M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1",
      key: "pwadti"
    }
  ],
  ["path", { d: "M6 2v2", key: "colzsn" }]
], dh = j("coffee", ch);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const uh = [
  [
    "path",
    {
      d: "M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z",
      key: "96xj49"
    }
  ]
], hh = j("flame", uh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const fh = [
  ["circle", { cx: "9", cy: "12", r: "1", key: "1vctgf" }],
  ["circle", { cx: "9", cy: "5", r: "1", key: "hp0tcf" }],
  ["circle", { cx: "9", cy: "19", r: "1", key: "fkjjf6" }],
  ["circle", { cx: "15", cy: "12", r: "1", key: "1tmaij" }],
  ["circle", { cx: "15", cy: "5", r: "1", key: "19l28e" }],
  ["circle", { cx: "15", cy: "19", r: "1", key: "f4zoj3" }]
], qs = j("grip-vertical", fh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const ph = [
  ["path", { d: "M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8", key: "5wwlr5" }],
  [
    "path",
    {
      d: "M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z",
      key: "1d0kgt"
    }
  ]
], mh = j("house", ph);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const yh = [
  ["rect", { width: "18", height: "11", x: "3", y: "11", rx: "2", ry: "2", key: "1w4ew1" }],
  ["path", { d: "M7 11V7a5 5 0 0 1 10 0v4", key: "fwvmzm" }]
], gh = j("lock", yh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const vh = [
  ["line", { x1: "4", x2: "20", y1: "12", y2: "12", key: "1e0a9i" }],
  ["line", { x1: "4", x2: "20", y1: "6", y2: "6", key: "1owob3" }],
  ["line", { x1: "4", x2: "20", y1: "18", y2: "18", key: "yk5zj1" }]
], bh = j("menu", vh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const xh = [
  ["path", { d: "M6 18h8", key: "1borvv" }],
  ["path", { d: "M3 22h18", key: "8prr45" }],
  ["path", { d: "M14 22a7 7 0 1 0 0-14h-1", key: "1jwaiy" }],
  ["path", { d: "M9 14h2", key: "197e7h" }],
  ["path", { d: "M9 12a2 2 0 0 1-2-2V6h6v4a2 2 0 0 1-2 2Z", key: "1bmzmy" }],
  ["path", { d: "M12 6V3a1 1 0 0 0-1-1H9a1 1 0 0 0-1 1v3", key: "1drr47" }]
], Si = j("microscope", xh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Fh = [["path", { d: "M5 12h14", key: "1ays0h" }]], wh = j("minus", Fh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Sh = [
  ["rect", { width: "20", height: "14", x: "2", y: "3", rx: "2", key: "48i651" }],
  ["line", { x1: "8", x2: "16", y1: "21", y2: "21", key: "1svkeh" }],
  ["line", { x1: "12", x2: "12", y1: "17", y2: "21", key: "vw1qmm" }]
], Th = j("monitor", Sh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Ch = [
  ["path", { d: "M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z", key: "a7tn18" }]
], Oo = j("moon", Ch);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const kh = [
  ["circle", { cx: "13.5", cy: "6.5", r: ".5", fill: "currentColor", key: "1okk4w" }],
  ["circle", { cx: "17.5", cy: "10.5", r: ".5", fill: "currentColor", key: "f64h9f" }],
  ["circle", { cx: "8.5", cy: "7.5", r: ".5", fill: "currentColor", key: "fotxhn" }],
  ["circle", { cx: "6.5", cy: "12.5", r: ".5", fill: "currentColor", key: "qy21gx" }],
  [
    "path",
    {
      d: "M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z",
      key: "12rzf8"
    }
  ]
], Mh = j("palette", kh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Ph = [["polygon", { points: "6 3 20 12 6 21 6 3", key: "1oa8hb" }]], Ah = j("play", Ph);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Vh = [
  ["path", { d: "M5 12h14", key: "1ays0h" }],
  ["path", { d: "M12 5v14", key: "s699le" }]
], Xt = j("plus", Vh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Eh = [
  ["path", { d: "M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8", key: "1357e3" }],
  ["path", { d: "M3 3v5h5", key: "1xhq8a" }]
], Ti = j("rotate-ccw", Eh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Ih = [
  [
    "path",
    {
      d: "M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z",
      key: "1qme2f"
    }
  ],
  ["circle", { cx: "12", cy: "12", r: "3", key: "1v7zrd" }]
], Nh = j("settings", Ih);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Dh = [
  [
    "path",
    {
      d: "M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z",
      key: "4pj2yx"
    }
  ],
  ["path", { d: "M20 3v4", key: "1olli1" }],
  ["path", { d: "M22 5h-4", key: "1gvqau" }],
  ["path", { d: "M4 17v2", key: "vumght" }],
  ["path", { d: "M5 18H3", key: "zchphs" }]
], Xs = j("sparkles", Dh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Bh = [
  ["circle", { cx: "12", cy: "12", r: "4", key: "4exip2" }],
  ["path", { d: "M12 2v2", key: "tus03m" }],
  ["path", { d: "M12 20v2", key: "1lh1kg" }],
  ["path", { d: "m4.93 4.93 1.41 1.41", key: "149t6j" }],
  ["path", { d: "m17.66 17.66 1.41 1.41", key: "ptbguv" }],
  ["path", { d: "M2 12h2", key: "1t8f8n" }],
  ["path", { d: "M20 12h2", key: "1q8mjw" }],
  ["path", { d: "m6.34 17.66-1.41 1.41", key: "1m8zz5" }],
  ["path", { d: "m19.07 4.93-1.41 1.41", key: "1shlcs" }]
], Rh = j("sun", Bh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Lh = [
  ["circle", { cx: "12", cy: "12", r: "10", key: "1mglay" }],
  ["circle", { cx: "12", cy: "12", r: "6", key: "1vlfrh" }],
  ["circle", { cx: "12", cy: "12", r: "2", key: "1c9p78" }]
], _o = j("target", Lh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const zh = [
  ["polyline", { points: "4 17 10 11 4 5", key: "akl6gq" }],
  ["line", { x1: "12", x2: "20", y1: "19", y2: "19", key: "q2wloq" }]
], $o = j("terminal", zh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const jh = [
  [
    "path",
    {
      d: "m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3",
      key: "wmoenq"
    }
  ],
  ["path", { d: "M12 9v4", key: "juzpu7" }],
  ["path", { d: "M12 17h.01", key: "p32p05" }]
], Wh = j("triangle-alert", jh);
/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const Oh = [
  ["path", { d: "M18 6 6 18", key: "1bl5f8" }],
  ["path", { d: "m6 6 12 12", key: "d8bk6v" }]
], Uo = j("x", Oh), _h = [
  { id: "dashboard", icon: mh, label: "Home" },
  { id: "plan", icon: Yu, label: "Plan" },
  { id: "tracker", icon: kt, label: "Tracker" },
  { id: "analytics", icon: Wo, label: "Stats" },
  { id: "more", icon: bh, label: "More" }
];
function $h({ active: e, onNavigate: t }) {
  return /* @__PURE__ */ c(
    v.div,
    {
      initial: { y: 100 },
      animate: { y: 0 },
      transition: { type: "spring", stiffness: 200, damping: 25 },
      className: "fixed bottom-0 left-0 right-0 z-50 flex justify-center pb-6 px-4",
      children: /* @__PURE__ */ c(
        "div",
        {
          className: "flex items-center justify-around w-full max-w-md rounded-3xl px-2",
          style: {
            height: 72,
            background: "rgba(14,14,26,0.75)",
            backdropFilter: "blur(40px)",
            WebkitBackdropFilter: "blur(40px)",
            border: "1px solid rgba(99,102,241,0.25)",
            boxShadow: "0 -4px 30px rgba(99,102,241,0.15), inset 0 1px 0 rgba(255,255,255,0.08)"
          },
          children: _h.map((n) => {
            const i = e === n.id, s = n.icon;
            return /* @__PURE__ */ y(
              v.button,
              {
                onClick: () => t(n.id),
                whileTap: { scale: 0.85 },
                className: "flex flex-col items-center justify-center gap-1 relative",
                style: { minWidth: 56, minHeight: 44 },
                children: [
                  /* @__PURE__ */ c(
                    v.div,
                    {
                      animate: {
                        scale: i ? 1.15 : 1,
                        color: i ? "#818CF8" : "#6B7280"
                      },
                      transition: { type: "spring", stiffness: 300, damping: 20 },
                      children: /* @__PURE__ */ c(s, { size: 22, strokeWidth: 1.5 })
                    }
                  ),
                  /* @__PURE__ */ c(
                    "span",
                    {
                      className: "transition-colors",
                      style: {
                        fontSize: 10,
                        fontFamily: "Inter, sans-serif",
                        fontWeight: 500,
                        color: i ? "#818CF8" : "#6B7280"
                      },
                      children: n.label
                    }
                  ),
                  i && /* @__PURE__ */ c(
                    v.div,
                    {
                      layoutId: "nav-glow",
                      className: "absolute -bottom-1 w-5 h-1 rounded-full",
                      style: {
                        background: "#6366F1",
                        boxShadow: "0 0 12px rgba(99,102,241,0.6)"
                      },
                      transition: { type: "spring", stiffness: 300, damping: 25 }
                    }
                  )
                ]
              },
              n.id
            );
          })
        }
      )
    }
  );
}
function _({
  children: e,
  className: t = "",
  delay: n = 0,
  glowColor: i,
  onClick: s,
  hero: o = !1
}) {
  const [r, l] = W(!1);
  return /* @__PURE__ */ y(
    v.div,
    {
      initial: { opacity: 0, y: 30, scale: 0.92 },
      animate: { opacity: 1, y: 0, scale: 1 },
      transition: {
        type: "spring",
        stiffness: 180,
        damping: 20,
        delay: n * 0.06
      },
      whileTap: { scale: 0.97 },
      onClick: () => {
        l(!0), setTimeout(() => l(!1), 600), s?.();
      },
      className: `relative overflow-hidden rounded-2xl p-5 ${t}`,
      style: {
        background: "rgba(255,255,255,0.08)",
        backdropFilter: o ? "blur(40px)" : "blur(24px)",
        WebkitBackdropFilter: o ? "blur(40px)" : "blur(24px)",
        border: "1px solid rgba(99,102,241,0.3)",
        boxShadow: i ? `0 0 30px ${i}, inset 0 1px 0 rgba(255,255,255,0.1)` : "0 0 20px rgba(99,102,241,0.15), inset 0 1px 0 rgba(255,255,255,0.1)"
      },
      children: [
        /* @__PURE__ */ c(
          v.div,
          {
            className: "absolute inset-0 pointer-events-none",
            style: {
              background: "linear-gradient(105deg, transparent 40%, rgba(255,255,255,0.08) 45%, rgba(255,255,255,0.15) 50%, rgba(255,255,255,0.08) 55%, transparent 60%)",
              backgroundSize: "200% 100%"
            },
            animate: { backgroundPosition: ["200% 0", "-200% 0"] },
            transition: { duration: 4, repeat: 1 / 0, repeatDelay: 3, ease: "linear" }
          }
        ),
        r && /* @__PURE__ */ c(
          v.div,
          {
            className: "absolute inset-0 pointer-events-none",
            initial: { opacity: 0.3 },
            animate: { opacity: 0 },
            transition: { duration: 0.6 },
            style: {
              background: "radial-gradient(circle at center, rgba(99,102,241,0.3), transparent 70%)"
            }
          }
        ),
        /* @__PURE__ */ c("div", { className: "relative z-10", children: e })
      ]
    }
  );
}
function de({
  value: e,
  decimals: t = 0,
  suffix: n = "",
  prefix: i = "",
  className: s = "",
  duration: o = 0.8
}) {
  const r = ju(0, { stiffness: 100, damping: 30 }), l = ht(r, (a) => `${i}${a.toFixed(t)}${n}`);
  return xe(() => {
    r.set(e);
  }, [e, r]), /* @__PURE__ */ c(v.span, { className: s, children: l });
}
function je({
  progress: e,
  color: t = "#6366F1",
  delay: n = 0,
  height: i = 6
}) {
  return /* @__PURE__ */ c(
    "div",
    {
      className: "w-full rounded-full overflow-hidden",
      style: { height: i, background: "rgba(255,255,255,0.1)" },
      children: /* @__PURE__ */ c(
        v.div,
        {
          className: "h-full rounded-full",
          initial: { width: "0%" },
          animate: { width: `${e}%` },
          transition: {
            type: "spring",
            stiffness: 60,
            damping: 15,
            delay: n * 0.06 + 0.3
          },
          style: {
            background: `linear-gradient(90deg, ${t}, ${t}cc)`,
            boxShadow: `0 0 12px ${t}60`
          }
        }
      )
    }
  );
}
const Ys = [
  '"The expert in anything was once a beginner."',
  '"Medicine is not only a science; it is also an art."',
  `"What we know is a drop, what we don't know is an ocean."`
];
function Zs() {
  const [e, t] = W(0), [n, i] = W(""), s = "Day 18 of 123. Every page matters.";
  xe(() => {
    let r = 0;
    const l = setInterval(() => {
      r <= s.length ? (i(s.slice(0, r)), r++) : clearInterval(l);
    }, 35);
    return () => clearInterval(l);
  }, []), xe(() => {
    const r = setInterval(() => {
      t((l) => (l + 1) % Ys.length);
    }, 5e3);
    return () => clearInterval(r);
  }, []);
  const o = [
    { icon: kt, label: "FA Pages", current: 6, target: 10, color: "#6366F1", done: !1 },
    { icon: bt, label: "Anki", current: 1, target: 1, color: "#22C55E", done: !0 },
    { icon: Si, label: "Sketchy Micro", current: 1, target: 2, color: "#818CF8", done: !1 },
    { icon: Ti, label: "Revision", current: 3, target: 3, color: "#F59E0B", done: !0 }
  ];
  return /* @__PURE__ */ y("div", { className: "space-y-4", children: [
    /* @__PURE__ */ y(
      v.div,
      {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20 },
        children: [
          /* @__PURE__ */ c(
            "h1",
            {
              style: {
                fontFamily: "Inter, sans-serif",
                fontWeight: 700,
                fontSize: 30,
                color: "#F4F4FF"
              },
              children: "Good morning, Arsh 🌅"
            }
          ),
          /* @__PURE__ */ y(
            "p",
            {
              style: {
                fontFamily: "Inter, sans-serif",
                fontWeight: 400,
                fontSize: 14,
                color: "#6B7280",
                minHeight: 20
              },
              children: [
                n,
                /* @__PURE__ */ c(
                  v.span,
                  {
                    animate: { opacity: [1, 0] },
                    transition: { duration: 0.5, repeat: 1 / 0 },
                    style: { color: "#6366F1" },
                    children: "|"
                  }
                )
              ]
            }
          )
        ]
      }
    ),
    /* @__PURE__ */ y("div", { className: "grid grid-cols-2 gap-3", children: [
      /* @__PURE__ */ c(_, { delay: 1, hero: !0, glowColor: "rgba(99,102,241,0.25)", children: /* @__PURE__ */ y("div", { className: "flex flex-col items-center gap-2", children: [
        /* @__PURE__ */ c(Js, { progress: 65, color: "#6366F1" }),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 12, color: "#818CF8", letterSpacing: 1 }, children: "FMGE" }),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 800, fontSize: 28, color: "#F4F4FF" }, children: /* @__PURE__ */ c(de, { value: 107 }) }),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 11, color: "#6B7280" }, children: "days remaining" })
      ] }) }),
      /* @__PURE__ */ c(_, { delay: 2, hero: !0, glowColor: "rgba(139,92,246,0.25)", children: /* @__PURE__ */ y("div", { className: "flex flex-col items-center gap-2", children: [
        /* @__PURE__ */ c(Js, { progress: 58, color: "#8B5CF6" }),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 12, color: "#A78BFA", letterSpacing: 1 }, children: "USMLE STEP 1" }),
        /* @__PURE__ */ y("span", { style: { fontFamily: "Inter", fontWeight: 800, fontSize: 28, color: "#F4F4FF" }, children: [
          "~",
          /* @__PURE__ */ c(de, { value: 102 })
        ] }),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 11, color: "#6B7280" }, children: "days remaining" })
      ] }) })
    ] }),
    /* @__PURE__ */ c(_, { delay: 3, children: /* @__PURE__ */ y("div", { className: "flex items-start gap-3", children: [
      /* @__PURE__ */ c(
        v.div,
        {
          className: "w-1 self-stretch rounded-full",
          style: { background: "linear-gradient(to bottom, #6366F1, #8B5CF6)" },
          animate: { opacity: [0.6, 1, 0.6] },
          transition: { duration: 2, repeat: 1 / 0 }
        }
      ),
      /* @__PURE__ */ y("div", { className: "flex-1 space-y-2", children: [
        /* @__PURE__ */ y("div", { className: "flex items-center justify-between", children: [
          /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }, children: "Your Pace" }),
          /* @__PURE__ */ c(Uh, {})
        ] }),
        /* @__PURE__ */ c("div", { style: { fontFamily: "Inter", fontWeight: 800, fontSize: 32, color: "#F4F4FF" }, children: /* @__PURE__ */ c(de, { value: 8.3, decimals: 1, suffix: " pages/day" }) }),
        /* @__PURE__ */ y("div", { className: "flex flex-wrap gap-2", children: [
          /* @__PURE__ */ c(
            "span",
            {
              className: "px-2 py-0.5 rounded-full",
              style: { fontSize: 11, fontFamily: "Inter", fontWeight: 500, background: "rgba(34,197,94,0.15)", color: "#22C55E" },
              children: "✅ On track for FMGE"
            }
          ),
          /* @__PURE__ */ c(
            "span",
            {
              className: "px-2 py-0.5 rounded-full",
              style: { fontSize: 11, fontFamily: "Inter", fontWeight: 500, background: "rgba(245,158,11,0.15)", color: "#F59E0B" },
              children: "⚠️ Push harder for Step 1"
            }
          )
        ] }),
        /* @__PURE__ */ c("span", { style: { fontSize: 12, color: "#6B7280", fontFamily: "Inter" }, children: "FA done: May 1" })
      ] })
    ] }) }),
    /* @__PURE__ */ y(_, { delay: 4, children: [
      /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }, children: "Today's Time Budget" }),
      /* @__PURE__ */ y("div", { className: "mt-3 flex rounded-xl overflow-hidden h-5", children: [
        /* @__PURE__ */ c(Nt, { width: 33, color: "#1E1E2E", label: "Sleep", delay: 0 }),
        /* @__PURE__ */ c(Nt, { width: 10, color: "rgba(99,102,241,0.4)", label: "Prayer", delay: 0.15 }),
        /* @__PURE__ */ c(Nt, { width: 27, color: "#6366F1", label: "Study", delay: 0.3 }),
        /* @__PURE__ */ c(Nt, { width: 30, color: "rgba(99,102,241,0.15)", label: "Free", delay: 0.45 })
      ] }),
      /* @__PURE__ */ y("div", { className: "mt-2 flex items-baseline gap-2", children: [
        /* @__PURE__ */ y("span", { style: { fontFamily: "Inter", fontWeight: 800, fontSize: 26, color: "#F4F4FF" }, children: [
          /* @__PURE__ */ c(de, { value: 7, suffix: "h " }),
          /* @__PURE__ */ c(de, { value: 20, suffix: "min" })
        ] }),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 13, color: "#6B7280" }, children: "FREE" })
      ] })
    ] }),
    /* @__PURE__ */ y(_, { delay: 5, children: [
      /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }, children: "Today's Goals" }),
      /* @__PURE__ */ c("div", { className: "mt-3 space-y-3", children: o.map((r, l) => /* @__PURE__ */ y(
        v.div,
        {
          initial: { opacity: 0, x: -20 },
          animate: { opacity: 1, x: 0 },
          transition: { type: "spring", stiffness: 150, damping: 20, delay: 0.4 + l * 0.06 },
          className: "flex items-center gap-3",
          children: [
            /* @__PURE__ */ c(
              v.div,
              {
                animate: r.done ? { scale: [1, 1.2, 1] } : {},
                transition: { type: "spring", stiffness: 300, damping: 15, delay: 0.8 + l * 0.06 },
                style: {
                  color: r.done ? "#22C55E" : r.color,
                  filter: r.done ? "drop-shadow(0 0 6px rgba(34,197,94,0.5))" : void 0
                },
                children: r.done ? /* @__PURE__ */ c(ih, { size: 20, strokeWidth: 1.5 }) : /* @__PURE__ */ c(r.icon, { size: 20, strokeWidth: 1.5 })
              }
            ),
            /* @__PURE__ */ y("div", { className: "flex-1", children: [
              /* @__PURE__ */ y("div", { className: "flex justify-between", children: [
                /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#F4F4FF" }, children: r.label }),
                /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 12, color: r.done ? "#22C55E" : "#6B7280" }, children: r.done ? "Done ✓" : `${r.current}/${r.target}` })
              ] }),
              /* @__PURE__ */ c(
                je,
                {
                  progress: r.current / r.target * 100,
                  color: r.done ? "#22C55E" : r.color,
                  delay: l + 6,
                  height: 4
                }
              )
            ] })
          ]
        },
        r.label
      )) })
    ] }),
    /* @__PURE__ */ y(_, { delay: 7, children: [
      /* @__PURE__ */ y("div", { className: "flex items-center gap-3", children: [
        /* @__PURE__ */ c(
          v.div,
          {
            animate: { scale: [1, 1.15, 1], filter: ["drop-shadow(0 0 6px rgba(245,158,11,0.4))", "drop-shadow(0 0 12px rgba(245,158,11,0.7))", "drop-shadow(0 0 6px rgba(245,158,11,0.4))"] },
            transition: { duration: 2, repeat: 1 / 0 },
            children: /* @__PURE__ */ c(hh, { size: 28, color: "#F59E0B" })
          }
        ),
        /* @__PURE__ */ c("div", { children: /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 18, color: "#F4F4FF" }, children: "Day 4 streak" }) })
      ] }),
      /* @__PURE__ */ c(
        v.div,
        {
          className: "mt-3 px-3 py-2 rounded-xl",
          style: { background: "rgba(99,102,241,0.1)", border: "1px solid rgba(99,102,241,0.15)" },
          initial: { opacity: 0, y: 10 },
          animate: { opacity: 1, y: 0 },
          exit: { opacity: 0, y: -10 },
          transition: { duration: 0.5 },
          children: /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 13, color: "#818CF8", fontStyle: "italic" }, children: Ys[e] })
        },
        e
      )
    ] })
  ] });
}
function Js({ progress: e, color: t }) {
  const i = 2 * Math.PI * 32, s = i - e / 100 * i;
  return /* @__PURE__ */ y("svg", { width: 76, height: 76, viewBox: "0 0 76 76", children: [
    /* @__PURE__ */ c("circle", { cx: 38, cy: 38, r: 32, fill: "none", stroke: "rgba(255,255,255,0.06)", strokeWidth: 4 }),
    /* @__PURE__ */ c(
      v.circle,
      {
        cx: 38,
        cy: 38,
        r: 32,
        fill: "none",
        stroke: t,
        strokeWidth: 4,
        strokeLinecap: "round",
        strokeDasharray: i,
        initial: { strokeDashoffset: i },
        animate: { strokeDashoffset: s },
        transition: { type: "spring", stiffness: 40, damping: 12, delay: 0.5 },
        style: {
          filter: `drop-shadow(0 0 6px ${t}80)`,
          transform: "rotate(-90deg)",
          transformOrigin: "center"
        }
      }
    )
  ] });
}
function Uh() {
  const e = [4, 7, 5, 9, 8, 10, 8.3], t = 12, n = 80, i = 28, s = e.map((o, r) => `${r === 0 ? "M" : "L"} ${r / (e.length - 1) * n} ${i - o / t * i}`).join(" ");
  return /* @__PURE__ */ y("svg", { width: n, height: i, className: "overflow-visible", children: [
    /* @__PURE__ */ c("defs", { children: /* @__PURE__ */ y("linearGradient", { id: "spark-grad", x1: "0", y1: "0", x2: "1", y2: "0", children: [
      /* @__PURE__ */ c("stop", { offset: "0%", stopColor: "#6366F1" }),
      /* @__PURE__ */ c("stop", { offset: "100%", stopColor: "#818CF8" })
    ] }) }),
    /* @__PURE__ */ c(
      v.path,
      {
        d: s,
        fill: "none",
        stroke: "url(#spark-grad)",
        strokeWidth: 2,
        strokeLinecap: "round",
        initial: { pathLength: 0 },
        animate: { pathLength: 1 },
        transition: { duration: 1.2, delay: 0.5, ease: "easeOut" }
      }
    )
  ] });
}
function Nt({ width: e, color: t, label: n, delay: i }) {
  return /* @__PURE__ */ c(
    v.div,
    {
      initial: { width: "0%" },
      animate: { width: `${e}%` },
      transition: { type: "spring", stiffness: 60, damping: 15, delay: 0.4 + i },
      className: "h-full flex items-center justify-center overflow-hidden",
      style: { background: t },
      children: e > 12 && /* @__PURE__ */ c("span", { style: { fontSize: 8, fontFamily: "Inter", fontWeight: 600, color: "#F4F4FF", whiteSpace: "nowrap" }, children: n })
    }
  );
}
const Gh = [
  { name: "Fajr", time: "05:25" },
  { name: "Dhuhr", time: "12:38" },
  { name: "Asr", time: "16:08" },
  { name: "Maghrib", time: "18:12" },
  { name: "Isha", time: "19:38" }
], Hh = [
  {
    title: "FA Reading",
    subtitle: "FA Pages 50–59 | Biochemistry",
    time: "07:00 – 09:30",
    icon: kt,
    gradient: "linear-gradient(135deg, rgba(99,102,241,0.2), rgba(139,92,246,0.2))",
    border: "rgba(139,92,246,0.35)",
    iconColor: "#8B5CF6"
  },
  {
    title: "Anki Review",
    subtitle: "Flashcards for Pages 46–49",
    time: "09:45 – 10:45",
    icon: bt,
    gradient: "linear-gradient(135deg, rgba(245,158,11,0.15), rgba(245,158,11,0.08))",
    border: "rgba(245,158,11,0.35)",
    iconColor: "#F59E0B"
  },
  {
    title: "Sketchy Micro",
    subtitle: "Staphylococcus + Streptococcus",
    time: "11:00 – 12:30",
    icon: Si,
    gradient: "linear-gradient(135deg, rgba(20,184,166,0.15), rgba(20,184,166,0.08))",
    border: "rgba(20,184,166,0.35)",
    iconColor: "#14B8A6"
  },
  {
    title: "UWorld Practice",
    subtitle: "Biochemistry Block — 20 Qs",
    time: "15:00 – 16:00",
    icon: _o,
    gradient: "linear-gradient(135deg, rgba(34,197,94,0.15), rgba(34,197,94,0.08))",
    border: "rgba(34,197,94,0.35)",
    iconColor: "#22C55E"
  }
];
function Kh() {
  const [e, t] = W(!0);
  return /* @__PURE__ */ y("div", { className: "space-y-4", children: [
    /* @__PURE__ */ y(
      v.div,
      {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20 },
        children: [
          /* @__PURE__ */ c("h1", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }, children: "Friday, March 13" }),
          /* @__PURE__ */ c("div", { className: "flex items-center gap-2 mt-1", children: /* @__PURE__ */ c(
            v.span,
            {
              initial: { scale: 0 },
              animate: { scale: 1 },
              transition: { type: "spring", stiffness: 200, damping: 15, delay: 0.2 },
              className: "px-3 py-1 rounded-full",
              style: { background: "rgba(99,102,241,0.2)", border: "1px solid rgba(99,102,241,0.3)" },
              children: /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 12, color: "#818CF8" }, children: "Available: 7h 20min" })
            }
          ) })
        ]
      }
    ),
    /* @__PURE__ */ y(
      v.div,
      {
        initial: { opacity: 0, y: -20 },
        animate: { opacity: 1, y: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20, delay: 0.3 },
        className: "flex items-center gap-2 px-4 py-2.5 rounded-2xl",
        style: {
          background: "rgba(245,158,11,0.12)",
          border: "1px solid rgba(245,158,11,0.3)",
          backdropFilter: "blur(20px)"
        },
        children: [
          /* @__PURE__ */ c(
            v.div,
            {
              animate: { scale: [1, 1.1, 1] },
              transition: { duration: 1.5, repeat: 1 / 0 },
              children: /* @__PURE__ */ c(Wh, { size: 16, color: "#F59E0B" })
            }
          ),
          /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#F59E0B" }, children: "40 min over budget — consider trimming a block" })
        ]
      }
    ),
    /* @__PURE__ */ y("div", { children: [
      /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }, children: "PRAYERS" }),
      /* @__PURE__ */ c("div", { className: "mt-2 space-y-2", children: Gh.map((n, i) => /* @__PURE__ */ y(
        v.div,
        {
          initial: { opacity: 0, x: -20 },
          animate: { opacity: 1, x: 0 },
          transition: { type: "spring", stiffness: 150, damping: 20, delay: 0.2 + i * 0.05 },
          className: "flex items-center gap-3 px-4 py-3 rounded-xl",
          style: {
            background: "rgba(99,102,241,0.06)",
            border: "1px solid rgba(99,102,241,0.15)",
            borderLeft: "2px dashed rgba(99,102,241,0.4)",
            backdropFilter: "blur(16px)"
          },
          children: [
            /* @__PURE__ */ c("span", { style: { fontSize: 14 }, children: "🕌" }),
            /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 14, color: "#F4F4FF", flex: 1 }, children: n.name }),
            /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#818CF8" }, children: n.time }),
            /* @__PURE__ */ c(gh, { size: 12, color: "#6B7280" })
          ]
        },
        n.name
      )) })
    ] }),
    /* @__PURE__ */ y("div", { children: [
      /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }, children: "STUDY BLOCKS" }),
      /* @__PURE__ */ c("div", { className: "mt-2 space-y-3", children: Hh.map((n, i) => /* @__PURE__ */ c(
        v.div,
        {
          initial: { opacity: 0, y: 30, scale: 0.92 },
          animate: { opacity: 1, y: 0, scale: 1 },
          transition: { type: "spring", stiffness: 180, damping: 20, delay: 0.4 + i * 0.08 },
          whileTap: { scale: 0.97 },
          className: "rounded-2xl p-4 relative overflow-hidden",
          style: {
            background: n.gradient,
            backdropFilter: "blur(24px)",
            border: `1px solid ${n.border}`,
            boxShadow: `0 0 20px ${n.border}40`
          },
          children: /* @__PURE__ */ y("div", { className: "flex items-start gap-3", children: [
            /* @__PURE__ */ c(
              v.div,
              {
                animate: { rotate: n.title === "Anki Review" ? [0, 180, 360] : 0 },
                transition: { duration: 2, repeat: n.title === "Anki Review" ? 1 / 0 : 0, repeatDelay: 3 },
                style: { color: n.iconColor },
                children: /* @__PURE__ */ c(n.icon, { size: 22, strokeWidth: 1.5 })
              }
            ),
            /* @__PURE__ */ y("div", { className: "flex-1", children: [
              /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF", display: "block" }, children: n.title }),
              /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 12, color: "#6B7280", display: "block", marginTop: 2 }, children: n.subtitle })
            ] }),
            /* @__PURE__ */ c(
              "span",
              {
                className: "px-2 py-1 rounded-lg",
                style: {
                  fontFamily: "Inter",
                  fontWeight: 600,
                  fontSize: 11,
                  color: n.iconColor,
                  background: `${n.iconColor}15`
                },
                children: n.time
              }
            )
          ] })
        },
        n.title
      )) })
    ] }),
    /* @__PURE__ */ c(_, { delay: 8, children: /* @__PURE__ */ y("div", { className: "flex items-center justify-between", children: [
      /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#6B7280" }, children: "Total Scheduled" }),
      /* @__PURE__ */ y("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 18, color: "#F4F4FF" }, children: [
        /* @__PURE__ */ c(de, { value: 8, suffix: "h " }),
        /* @__PURE__ */ c(de, { value: 0, suffix: "min" })
      ] })
    ] }) }),
    /* @__PURE__ */ y(
      v.button,
      {
        className: "fixed bottom-24 right-5 w-14 h-14 rounded-full flex items-center justify-center z-40",
        style: {
          background: "linear-gradient(135deg, #6366F1, #8B5CF6)",
          boxShadow: "0 0 30px rgba(99,102,241,0.4)"
        },
        whileTap: { scale: 0.9 },
        initial: { scale: 0 },
        animate: { scale: 1 },
        transition: { type: "spring", stiffness: 200, damping: 15, delay: 0.8 },
        children: [
          /* @__PURE__ */ c(
            v.div,
            {
              className: "absolute inset-0 rounded-full",
              style: { border: "2px solid rgba(99,102,241,0.5)" },
              animate: { scale: [1, 1.4, 1], opacity: [0.5, 0, 0.5] },
              transition: { duration: 2, repeat: 1 / 0 }
            }
          ),
          /* @__PURE__ */ c(Xt, { size: 24, color: "#fff" })
        ]
      }
    )
  ] });
}
const qh = ["FA 2025", "Sketchy", "Pathoma", "UWorld"], Qs = [
  { name: "Biochemistry", pages: "1–89", progress: 67, read: 60, total: 89, color: "#6366F1" },
  { name: "Immunology", pages: "90–120", progress: 45, read: 14, total: 30, color: "#818CF8" },
  { name: "Microbiology", pages: "121–195", progress: 30, read: 22, total: 75, color: "#8B5CF6" },
  { name: "Pathology", pages: "196–400", progress: 12, read: 25, total: 205, color: "#A78BFA" },
  { name: "Pharmacology", pages: "401–490", progress: 55, read: 49, total: 90, color: "#7C3AED" }
], Xh = [
  { name: "Staphylococcus", status: 2, color: "#22C55E" },
  { name: "Streptococcus", status: 1, color: "#F59E0B" },
  { name: "Enterococcus", status: 0, color: "#6B7280" },
  { name: "Neisseria", status: 2, color: "#22C55E" },
  { name: "Haemophilus", status: 1, color: "#F59E0B" },
  { name: "Clostridium", status: 0, color: "#6B7280" }
], Yh = [
  { name: "Ch 1: Growth Adaptations", watched: !0, videos: 4 },
  { name: "Ch 2: Neoplasia", watched: !0, videos: 6 },
  { name: "Ch 3: Hemodynamics", watched: !1, videos: 5 },
  { name: "Ch 4: Hematopathology", watched: !1, videos: 8 },
  { name: "Ch 5: RBC Disorders", watched: !1, videos: 7 }
], Zh = [
  { name: "Biochemistry", qs: 45, correct: 78 },
  { name: "Microbiology", qs: 30, correct: 65 },
  { name: "Pharmacology", qs: 25, correct: 72 },
  { name: "Pathology", qs: 60, correct: 60 }
];
function Jh() {
  const [e, t] = W(0), [n, i] = W("All"), [s, o] = W(null), [r, l] = W("Micro");
  return /* @__PURE__ */ y("div", { className: "space-y-4", children: [
    /* @__PURE__ */ c("div", { className: "flex gap-1 p-1 rounded-2xl", style: { background: "rgba(255,255,255,0.06)" }, children: qh.map((a, d) => /* @__PURE__ */ y(
      v.button,
      {
        onClick: () => t(d),
        className: "flex-1 py-2 rounded-xl relative",
        whileTap: { scale: 0.95 },
        children: [
          e === d && /* @__PURE__ */ c(
            v.div,
            {
              layoutId: "tab-bg",
              className: "absolute inset-0 rounded-xl",
              style: {
                background: "rgba(99,102,241,0.2)",
                border: "1px solid rgba(99,102,241,0.3)"
              },
              transition: { type: "spring", stiffness: 300, damping: 25 }
            }
          ),
          /* @__PURE__ */ c(
            "span",
            {
              className: "relative z-10",
              style: {
                fontFamily: "Inter",
                fontWeight: e === d ? 600 : 400,
                fontSize: 13,
                color: e === d ? "#818CF8" : "#6B7280"
              },
              children: a
            }
          )
        ]
      },
      a
    )) }),
    /* @__PURE__ */ c(qe, { mode: "wait", children: /* @__PURE__ */ y(
      v.div,
      {
        initial: { opacity: 0, x: 30 },
        animate: { opacity: 1, x: 0 },
        exit: { opacity: 0, x: -30 },
        transition: { type: "spring", stiffness: 200, damping: 25 },
        children: [
          e === 0 && /* @__PURE__ */ y("div", { className: "space-y-3", children: [
            /* @__PURE__ */ c("div", { className: "flex gap-2 overflow-x-auto pb-1", style: { scrollbarWidth: "none" }, children: ["All", ...Qs.map((a) => a.name.slice(0, 5))].map((a) => /* @__PURE__ */ c(
              v.button,
              {
                onClick: () => i(a),
                whileTap: { scale: 0.9 },
                className: "px-3 py-1.5 rounded-full whitespace-nowrap",
                style: {
                  background: n === a ? "rgba(99,102,241,0.25)" : "rgba(255,255,255,0.06)",
                  border: `1px solid ${n === a ? "rgba(99,102,241,0.4)" : "rgba(255,255,255,0.08)"}`
                },
                children: /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: n === a ? "#818CF8" : "#6B7280" }, children: a })
              },
              a
            )) }),
            Qs.map((a, d) => /* @__PURE__ */ y(_, { delay: d + 1, children: [
              /* @__PURE__ */ y("div", { className: "flex items-center justify-between mb-2", children: [
                /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }, children: a.name }),
                /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 14, color: a.color }, children: /* @__PURE__ */ c(de, { value: a.progress, suffix: "%" }) })
              ] }),
              /* @__PURE__ */ c(je, { progress: a.progress, color: a.color, delay: d + 1 }),
              /* @__PURE__ */ y("div", { className: "mt-2 flex justify-between", children: [
                /* @__PURE__ */ y("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 12, color: "#6B7280" }, children: [
                  "Pages ",
                  a.pages
                ] }),
                /* @__PURE__ */ y("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: "#6B7280" }, children: [
                  a.read,
                  "/",
                  a.total,
                  " read"
                ] })
              ] })
            ] }, a.name))
          ] }),
          e === 1 && /* @__PURE__ */ y("div", { className: "space-y-3", children: [
            /* @__PURE__ */ c("div", { className: "flex gap-1 p-1 rounded-xl w-48", style: { background: "rgba(255,255,255,0.06)" }, children: ["Micro", "Pharma"].map((a) => /* @__PURE__ */ y(
              v.button,
              {
                onClick: () => l(a),
                className: "flex-1 py-1.5 rounded-lg relative",
                whileTap: { scale: 0.95 },
                children: [
                  r === a && /* @__PURE__ */ c(
                    v.div,
                    {
                      layoutId: "sketchy-pill",
                      className: "absolute inset-0 rounded-lg",
                      style: { background: "rgba(99,102,241,0.2)", border: "1px solid rgba(99,102,241,0.3)" },
                      transition: { type: "spring", stiffness: 300, damping: 25 }
                    }
                  ),
                  /* @__PURE__ */ c("span", { className: "relative z-10", style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: r === a ? "#818CF8" : "#6B7280" }, children: a })
                ]
              },
              a
            )) }),
            Xh.map((a, d) => /* @__PURE__ */ c(_, { delay: d + 1, children: /* @__PURE__ */ y("div", { className: "flex items-center justify-between", children: [
              /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 14, color: "#F4F4FF" }, children: a.name }),
              /* @__PURE__ */ c("div", { className: "flex gap-1.5", children: [0, 1, 2].map((u) => /* @__PURE__ */ c(
                v.div,
                {
                  className: "w-3 h-3 rounded-full",
                  initial: { scale: 0 },
                  animate: { scale: 1 },
                  transition: { type: "spring", stiffness: 300, damping: 15, delay: 0.3 + d * 0.05 + u * 0.1 },
                  style: {
                    background: u <= a.status ? a.color : "rgba(255,255,255,0.1)",
                    boxShadow: u <= a.status && a.status === 2 ? `0 0 8px ${a.color}60` : void 0
                  }
                },
                u
              )) })
            ] }) }, a.name))
          ] }),
          e === 2 && /* @__PURE__ */ c("div", { className: "space-y-3", children: Yh.map((a, d) => /* @__PURE__ */ y(_, { delay: d + 1, onClick: () => o(s === d ? null : d), children: [
            /* @__PURE__ */ y("div", { className: "flex items-center justify-between", children: [
              /* @__PURE__ */ y("div", { className: "flex items-center gap-3", children: [
                a.watched ? /* @__PURE__ */ c(xi, { size: 18, color: "#22C55E" }) : /* @__PURE__ */ c(
                  v.div,
                  {
                    animate: { scale: [1, 1.15, 1] },
                    transition: { duration: 1.5, repeat: 1 / 0 },
                    children: /* @__PURE__ */ c(Ah, { size: 18, color: "#818CF8" })
                  }
                ),
                /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 14, color: "#F4F4FF" }, children: a.name })
              ] }),
              /* @__PURE__ */ c(v.div, { animate: { rotate: s === d ? 90 : 0 }, transition: { type: "spring", stiffness: 300, damping: 20 }, children: /* @__PURE__ */ c(Fi, { size: 16, color: "#6B7280" }) })
            ] }),
            /* @__PURE__ */ c(qe, { children: s === d && /* @__PURE__ */ c(
              v.div,
              {
                initial: { height: 0, opacity: 0 },
                animate: { height: "auto", opacity: 1 },
                exit: { height: 0, opacity: 0 },
                transition: { type: "spring", stiffness: 200, damping: 25 },
                className: "overflow-hidden",
                children: /* @__PURE__ */ c("div", { className: "pt-3 mt-3", style: { borderTop: "1px solid rgba(255,255,255,0.06)" }, children: /* @__PURE__ */ y("span", { style: { fontFamily: "Inter", fontSize: 12, color: "#6B7280" }, children: [
                  a.videos,
                  " videos · ",
                  a.watched ? "Completed" : "In Progress"
                ] }) })
              }
            ) })
          ] }, a.name)) }),
          e === 3 && /* @__PURE__ */ y("div", { className: "space-y-3", children: [
            Zh.map((a, d) => /* @__PURE__ */ y(_, { delay: d + 1, children: [
              /* @__PURE__ */ y("div", { className: "flex items-center justify-between mb-2", children: [
                /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 14, color: "#F4F4FF" }, children: a.name }),
                /* @__PURE__ */ c("span", { style: {
                  fontFamily: "Inter",
                  fontWeight: 700,
                  fontSize: 14,
                  color: a.correct >= 70 ? "#22C55E" : a.correct >= 60 ? "#F59E0B" : "#EF4444"
                }, children: /* @__PURE__ */ c(de, { value: a.correct, suffix: "%" }) })
              ] }),
              /* @__PURE__ */ c(
                je,
                {
                  progress: a.correct,
                  color: a.correct >= 70 ? "#22C55E" : a.correct >= 60 ? "#F59E0B" : "#EF4444",
                  delay: d + 1
                }
              ),
              /* @__PURE__ */ y("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 12, color: "#6B7280", marginTop: 4, display: "block" }, children: [
                a.qs,
                " questions attempted"
              ] })
            ] }, a.name)),
            /* @__PURE__ */ y(
              v.button,
              {
                whileTap: { scale: 0.95 },
                className: "w-full py-3 rounded-2xl flex items-center justify-center gap-2",
                style: {
                  background: "rgba(99,102,241,0.15)",
                  border: "1px solid rgba(99,102,241,0.3)",
                  backdropFilter: "blur(20px)"
                },
                children: [
                  /* @__PURE__ */ c(Xt, { size: 18, color: "#818CF8" }),
                  /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 14, color: "#818CF8" }, children: "Add Session" })
                ]
              }
            )
          ] })
        ]
      },
      e
    ) })
  ] });
}
var Ci = {};
(function e(t, n, i, s) {
  var o = !!(t.Worker && t.Blob && t.Promise && t.OffscreenCanvas && t.OffscreenCanvasRenderingContext2D && t.HTMLCanvasElement && t.HTMLCanvasElement.prototype.transferControlToOffscreen && t.URL && t.URL.createObjectURL), r = typeof Path2D == "function" && typeof DOMMatrix == "function", l = (function() {
    if (!t.OffscreenCanvas)
      return !1;
    try {
      var m = new OffscreenCanvas(1, 1), f = m.getContext("2d");
      f.fillRect(0, 0, 1, 1);
      var C = m.transferToImageBitmap();
      f.createPattern(C, "no-repeat");
    } catch {
      return !1;
    }
    return !0;
  })();
  function a() {
  }
  function d(m) {
    var f = n.exports.Promise, C = f !== void 0 ? f : t.Promise;
    return typeof C == "function" ? new C(m) : (m(a, a), null);
  }
  var u = /* @__PURE__ */ (function(m, f) {
    return {
      transform: function(C) {
        if (m)
          return C;
        if (f.has(C))
          return f.get(C);
        var V = new OffscreenCanvas(C.width, C.height), N = V.getContext("2d");
        return N.drawImage(C, 0, 0), f.set(C, V), V;
      },
      clear: function() {
        f.clear();
      }
    };
  })(l, /* @__PURE__ */ new Map()), h = (function() {
    var m = Math.floor(16.666666666666668), f, C, V = {}, N = 0;
    return typeof requestAnimationFrame == "function" && typeof cancelAnimationFrame == "function" ? (f = function(D) {
      var R = Math.random();
      return V[R] = requestAnimationFrame(function P(L) {
        N === L || N + m - 1 < L ? (N = L, delete V[R], D()) : V[R] = requestAnimationFrame(P);
      }), R;
    }, C = function(D) {
      V[D] && cancelAnimationFrame(V[D]);
    }) : (f = function(D) {
      return setTimeout(D, m);
    }, C = function(D) {
      return clearTimeout(D);
    }), { frame: f, cancel: C };
  })(), p = /* @__PURE__ */ (function() {
    var m, f, C = {};
    function V(N) {
      function D(R, P) {
        N.postMessage({ options: R || {}, callback: P });
      }
      N.init = function(P) {
        var L = P.transferControlToOffscreen();
        N.postMessage({ canvas: L }, [L]);
      }, N.fire = function(P, L, O) {
        if (f)
          return D(P, null), f;
        var H = Math.random().toString(36).slice(2);
        return f = d(function(U) {
          function K(ne) {
            ne.data.callback === H && (delete C[H], N.removeEventListener("message", K), f = null, u.clear(), O(), U());
          }
          N.addEventListener("message", K), D(P, H), C[H] = K.bind(null, { data: { callback: H } });
        }), f;
      }, N.reset = function() {
        N.postMessage({ reset: !0 });
        for (var P in C)
          C[P](), delete C[P];
      };
    }
    return function() {
      if (m)
        return m;
      if (!i && o) {
        var N = [
          "var CONFETTI, SIZE = {}, module = {};",
          "(" + e.toString() + ")(this, module, true, SIZE);",
          "onmessage = function(msg) {",
          "  if (msg.data.options) {",
          "    CONFETTI(msg.data.options).then(function () {",
          "      if (msg.data.callback) {",
          "        postMessage({ callback: msg.data.callback });",
          "      }",
          "    });",
          "  } else if (msg.data.reset) {",
          "    CONFETTI && CONFETTI.reset();",
          "  } else if (msg.data.resize) {",
          "    SIZE.width = msg.data.resize.width;",
          "    SIZE.height = msg.data.resize.height;",
          "  } else if (msg.data.canvas) {",
          "    SIZE.width = msg.data.canvas.width;",
          "    SIZE.height = msg.data.canvas.height;",
          "    CONFETTI = module.exports.create(msg.data.canvas);",
          "  }",
          "}"
        ].join(`
`);
        try {
          m = new Worker(URL.createObjectURL(new Blob([N])));
        } catch (D) {
          return typeof console < "u" && typeof console.warn == "function" && console.warn("🎊 Could not load worker", D), null;
        }
        V(m);
      }
      return m;
    };
  })(), g = {
    particleCount: 50,
    angle: 90,
    spread: 45,
    startVelocity: 45,
    decay: 0.9,
    gravity: 1,
    drift: 0,
    ticks: 200,
    x: 0.5,
    y: 0.5,
    shapes: ["square", "circle"],
    zIndex: 100,
    colors: [
      "#26ccff",
      "#a25afd",
      "#ff5e7e",
      "#88ff5a",
      "#fcff42",
      "#ffa62d",
      "#ff36ff"
    ],
    // probably should be true, but back-compat
    disableForReducedMotion: !1,
    scalar: 1
  };
  function b(m, f) {
    return f ? f(m) : m;
  }
  function w(m) {
    return m != null;
  }
  function x(m, f, C) {
    return b(
      m && w(m[f]) ? m[f] : g[f],
      C
    );
  }
  function F(m) {
    return m < 0 ? 0 : Math.floor(m);
  }
  function S(m, f) {
    return Math.floor(Math.random() * (f - m)) + m;
  }
  function T(m) {
    return parseInt(m, 16);
  }
  function E(m) {
    return m.map(k);
  }
  function k(m) {
    var f = String(m).replace(/[^0-9a-f]/gi, "");
    return f.length < 6 && (f = f[0] + f[0] + f[1] + f[1] + f[2] + f[2]), {
      r: T(f.substring(0, 2)),
      g: T(f.substring(2, 4)),
      b: T(f.substring(4, 6))
    };
  }
  function I(m) {
    var f = x(m, "origin", Object);
    return f.x = x(f, "x", Number), f.y = x(f, "y", Number), f;
  }
  function B(m) {
    m.width = document.documentElement.clientWidth, m.height = document.documentElement.clientHeight;
  }
  function A(m) {
    var f = m.getBoundingClientRect();
    m.width = f.width, m.height = f.height;
  }
  function Y(m) {
    var f = document.createElement("canvas");
    return f.style.position = "fixed", f.style.top = "0px", f.style.left = "0px", f.style.pointerEvents = "none", f.style.zIndex = m, f;
  }
  function te(m, f, C, V, N, D, R, P, L) {
    m.save(), m.translate(f, C), m.rotate(D), m.scale(V, N), m.arc(0, 0, 1, R, P, L), m.restore();
  }
  function ye(m) {
    var f = m.angle * (Math.PI / 180), C = m.spread * (Math.PI / 180);
    return {
      x: m.x,
      y: m.y,
      wobble: Math.random() * 10,
      wobbleSpeed: Math.min(0.11, Math.random() * 0.1 + 0.05),
      velocity: m.startVelocity * 0.5 + Math.random() * m.startVelocity,
      angle2D: -f + (0.5 * C - Math.random() * C),
      tiltAngle: (Math.random() * (0.75 - 0.25) + 0.25) * Math.PI,
      color: m.color,
      shape: m.shape,
      tick: 0,
      totalTicks: m.ticks,
      decay: m.decay,
      drift: m.drift,
      random: Math.random() + 2,
      tiltSin: 0,
      tiltCos: 0,
      wobbleX: 0,
      wobbleY: 0,
      gravity: m.gravity * 3,
      ovalScalar: 0.6,
      scalar: m.scalar,
      flat: m.flat
    };
  }
  function Mt(m, f) {
    f.x += Math.cos(f.angle2D) * f.velocity + f.drift, f.y += Math.sin(f.angle2D) * f.velocity + f.gravity, f.velocity *= f.decay, f.flat ? (f.wobble = 0, f.wobbleX = f.x + 10 * f.scalar, f.wobbleY = f.y + 10 * f.scalar, f.tiltSin = 0, f.tiltCos = 0, f.random = 1) : (f.wobble += f.wobbleSpeed, f.wobbleX = f.x + 10 * f.scalar * Math.cos(f.wobble), f.wobbleY = f.y + 10 * f.scalar * Math.sin(f.wobble), f.tiltAngle += 0.1, f.tiltSin = Math.sin(f.tiltAngle), f.tiltCos = Math.cos(f.tiltAngle), f.random = Math.random() + 2);
    var C = f.tick++ / f.totalTicks, V = f.x + f.random * f.tiltCos, N = f.y + f.random * f.tiltSin, D = f.wobbleX + f.random * f.tiltCos, R = f.wobbleY + f.random * f.tiltSin;
    if (m.fillStyle = "rgba(" + f.color.r + ", " + f.color.g + ", " + f.color.b + ", " + (1 - C) + ")", m.beginPath(), r && f.shape.type === "path" && typeof f.shape.path == "string" && Array.isArray(f.shape.matrix))
      m.fill(J(
        f.shape.path,
        f.shape.matrix,
        f.x,
        f.y,
        Math.abs(D - V) * 0.1,
        Math.abs(R - N) * 0.1,
        Math.PI / 10 * f.wobble
      ));
    else if (f.shape.type === "bitmap") {
      var P = Math.PI / 10 * f.wobble, L = Math.abs(D - V) * 0.1, O = Math.abs(R - N) * 0.1, H = f.shape.bitmap.width * f.scalar, U = f.shape.bitmap.height * f.scalar, K = new DOMMatrix([
        Math.cos(P) * L,
        Math.sin(P) * L,
        -Math.sin(P) * O,
        Math.cos(P) * O,
        f.x,
        f.y
      ]);
      K.multiplySelf(new DOMMatrix(f.shape.matrix));
      var ne = m.createPattern(u.transform(f.shape.bitmap), "no-repeat");
      ne.setTransform(K), m.globalAlpha = 1 - C, m.fillStyle = ne, m.fillRect(
        f.x - H / 2,
        f.y - U / 2,
        H,
        U
      ), m.globalAlpha = 1;
    } else if (f.shape === "circle")
      m.ellipse ? m.ellipse(f.x, f.y, Math.abs(D - V) * f.ovalScalar, Math.abs(R - N) * f.ovalScalar, Math.PI / 10 * f.wobble, 0, 2 * Math.PI) : te(m, f.x, f.y, Math.abs(D - V) * f.ovalScalar, Math.abs(R - N) * f.ovalScalar, Math.PI / 10 * f.wobble, 0, 2 * Math.PI);
    else if (f.shape === "star")
      for (var z = Math.PI / 2 * 3, oe = 4 * f.scalar, fe = 8 * f.scalar, pe = f.x, we = f.y, Ve = 5, ge = Math.PI / Ve; Ve--; )
        pe = f.x + Math.cos(z) * fe, we = f.y + Math.sin(z) * fe, m.lineTo(pe, we), z += ge, pe = f.x + Math.cos(z) * oe, we = f.y + Math.sin(z) * oe, m.lineTo(pe, we), z += ge;
    else
      m.moveTo(Math.floor(f.x), Math.floor(f.y)), m.lineTo(Math.floor(f.wobbleX), Math.floor(N)), m.lineTo(Math.floor(D), Math.floor(R)), m.lineTo(Math.floor(V), Math.floor(f.wobbleY));
    return m.closePath(), m.fill(), f.tick < f.totalTicks;
  }
  function Yt(m, f, C, V, N) {
    var D = f.slice(), R = m.getContext("2d"), P, L, O = d(function(H) {
      function U() {
        P = L = null, R.clearRect(0, 0, V.width, V.height), u.clear(), N(), H();
      }
      function K() {
        i && !(V.width === s.width && V.height === s.height) && (V.width = m.width = s.width, V.height = m.height = s.height), !V.width && !V.height && (C(m), V.width = m.width, V.height = m.height), R.clearRect(0, 0, V.width, V.height), D = D.filter(function(ne) {
          return Mt(R, ne);
        }), D.length ? P = h.frame(K) : U();
      }
      P = h.frame(K), L = U;
    });
    return {
      addFettis: function(H) {
        return D = D.concat(H), O;
      },
      canvas: m,
      promise: O,
      reset: function() {
        P && h.cancel(P), L && L();
      }
    };
  }
  function et(m, f) {
    var C = !m, V = !!x(f || {}, "resize"), N = !1, D = x(f, "disableForReducedMotion", Boolean), R = o && !!x(f || {}, "useWorker"), P = R ? p() : null, L = C ? B : A, O = m && P ? !!m.__confetti_initialized : !1, H = typeof matchMedia == "function" && matchMedia("(prefers-reduced-motion)").matches, U;
    function K(z, oe, fe) {
      for (var pe = x(z, "particleCount", F), we = x(z, "angle", Number), Ve = x(z, "spread", Number), ge = x(z, "startVelocity", Number), Go = x(z, "decay", Number), Ho = x(z, "gravity", Number), Ko = x(z, "drift", Number), ki = x(z, "colors", E), qo = x(z, "ticks", Number), Mi = x(z, "shapes"), Xo = x(z, "scalar"), Yo = !!x(z, "flat"), Pi = I(z), Ai = pe, Jt = [], Zo = m.width * Pi.x, Jo = m.height * Pi.y; Ai--; )
        Jt.push(
          ye({
            x: Zo,
            y: Jo,
            angle: we,
            spread: Ve,
            startVelocity: ge,
            color: ki[Ai % ki.length],
            shape: Mi[S(0, Mi.length)],
            ticks: qo,
            decay: Go,
            gravity: Ho,
            drift: Ko,
            scalar: Xo,
            flat: Yo
          })
        );
      return U ? U.addFettis(Jt) : (U = Yt(m, Jt, L, oe, fe), U.promise);
    }
    function ne(z) {
      var oe = D || x(z, "disableForReducedMotion", Boolean), fe = x(z, "zIndex", Number);
      if (oe && H)
        return d(function(ge) {
          ge();
        });
      C && U ? m = U.canvas : C && !m && (m = Y(fe), document.body.appendChild(m)), V && !O && L(m);
      var pe = {
        width: m.width,
        height: m.height
      };
      P && !O && P.init(m), O = !0, P && (m.__confetti_initialized = !0);
      function we() {
        if (P) {
          var ge = {
            getBoundingClientRect: function() {
              if (!C)
                return m.getBoundingClientRect();
            }
          };
          L(ge), P.postMessage({
            resize: {
              width: ge.width,
              height: ge.height
            }
          });
          return;
        }
        pe.width = pe.height = null;
      }
      function Ve() {
        U = null, V && (N = !1, t.removeEventListener("resize", we)), C && m && (document.body.contains(m) && document.body.removeChild(m), m = null, O = !1);
      }
      return V && !N && (N = !0, t.addEventListener("resize", we, !1)), P ? P.fire(z, pe, Ve) : K(z, pe, Ve);
    }
    return ne.reset = function() {
      P && P.reset(), U && U.reset();
    }, ne;
  }
  var We;
  function Zt() {
    return We || (We = et(null, { useWorker: !0, resize: !0 })), We;
  }
  function J(m, f, C, V, N, D, R) {
    var P = new Path2D(m), L = new Path2D();
    L.addPath(P, new DOMMatrix(f));
    var O = new Path2D();
    return O.addPath(L, new DOMMatrix([
      Math.cos(R) * N,
      Math.sin(R) * N,
      -Math.sin(R) * D,
      Math.cos(R) * D,
      C,
      V
    ])), O;
  }
  function re(m) {
    if (!r)
      throw new Error("path confetti are not supported in this browser");
    var f, C;
    typeof m == "string" ? f = m : (f = m.path, C = m.matrix);
    var V = new Path2D(f), N = document.createElement("canvas"), D = N.getContext("2d");
    if (!C) {
      for (var R = 1e3, P = R, L = R, O = 0, H = 0, U, K, ne = 0; ne < R; ne += 2)
        for (var z = 0; z < R; z += 2)
          D.isPointInPath(V, ne, z, "nonzero") && (P = Math.min(P, ne), L = Math.min(L, z), O = Math.max(O, ne), H = Math.max(H, z));
      U = O - P, K = H - L;
      var oe = 10, fe = Math.min(oe / U, oe / K);
      C = [
        fe,
        0,
        0,
        fe,
        -Math.round(U / 2 + P) * fe,
        -Math.round(K / 2 + L) * fe
      ];
    }
    return {
      type: "path",
      path: f,
      matrix: C
    };
  }
  function Fe(m) {
    var f, C = 1, V = "#000000", N = '"Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji", "EmojiOne Color", "Android Emoji", "Twemoji Mozilla", "system emoji", sans-serif';
    typeof m == "string" ? f = m : (f = m.text, C = "scalar" in m ? m.scalar : C, N = "fontFamily" in m ? m.fontFamily : N, V = "color" in m ? m.color : V);
    var D = 10 * C, R = "" + D + "px " + N, P = new OffscreenCanvas(D, D), L = P.getContext("2d");
    L.font = R;
    var O = L.measureText(f), H = Math.ceil(O.actualBoundingBoxRight + O.actualBoundingBoxLeft), U = Math.ceil(O.actualBoundingBoxAscent + O.actualBoundingBoxDescent), K = 2, ne = O.actualBoundingBoxLeft + K, z = O.actualBoundingBoxAscent + K;
    H += K + K, U += K + K, P = new OffscreenCanvas(H, U), L = P.getContext("2d"), L.font = R, L.fillStyle = V, L.fillText(f, ne, z);
    var oe = 1 / C;
    return {
      type: "bitmap",
      // TODO these probably need to be transfered for workers
      bitmap: P.transferToImageBitmap(),
      matrix: [oe, 0, 0, oe, -H * oe / 2, -U * oe / 2]
    };
  }
  n.exports = function() {
    return Zt().apply(this, arguments);
  }, n.exports.reset = function() {
    Zt().reset();
  }, n.exports.create = et, n.exports.shapeFromPath = re, n.exports.shapeFromText = Fe;
})(/* @__PURE__ */ (function() {
  return typeof window < "u" ? window : typeof self < "u" ? self : this || {};
})(), Ci, !1);
const Ln = Ci.exports;
Ci.exports.create;
const it = [
  { front: "What enzyme is deficient in Phenylketonuria (PKU)?", back: "Phenylalanine hydroxylase — converts Phe → Tyr. Autosomal recessive. Musty body odor, intellectual disability, fair skin.", topic: "Biochemistry" },
  { front: "Describe the pathogenesis of Nephrotic Syndrome.", back: "Podocyte damage → loss of charge barrier → massive proteinuria (>3.5g/day) → hypoalbuminemia → edema + hyperlipidemia.", topic: "Pathology" },
  { front: "What is the mechanism of action of Metformin?", back: "Activates AMP-kinase → decreases hepatic gluconeogenesis, increases insulin sensitivity. No hypoglycemia risk. First-line for T2DM.", topic: "Pharmacology" },
  { front: "Name the layers of the adrenal cortex (outside → in).", back: "GFR — Glomerulosa (aldosterone), Fasciculata (cortisol), Reticularis (androgens). 'Salt, Sugar, Sex — the deeper you go, the sweeter it gets.'", topic: "Anatomy" }
];
function Qh() {
  const [e, t] = W("Morning"), [n, i] = W(0), [s, o] = W(!1), [r, l] = W([]), [a, d] = W(!1), u = bi(0), h = ht(u, [-200, 200], [-15, 15]), p = ht(u, [-200, 0], [0.3, 0]), g = ht(u, [0, 200], [0, 0.3]), b = Ke((F, S) => {
    if (Math.abs(S.offset.x) > 100) {
      const T = S.offset.x > 0 ? "right" : "left";
      l((E) => [...E, n]), T === "right" && Ln({ particleCount: 30, spread: 60, origin: { y: 0.6 }, colors: ["#22C55E", "#6366F1"] }), setTimeout(() => {
        n < it.length - 1 ? (i((E) => E + 1), o(!1)) : (d(!0), Ln({ particleCount: 100, spread: 120, origin: { y: 0.5 }, colors: ["#6366F1", "#818CF8", "#22C55E", "#F59E0B"] }));
      }, 300);
    }
  }, [n]), w = r.length / it.length * 100, x = it[n];
  return /* @__PURE__ */ y("div", { className: "space-y-4", children: [
    /* @__PURE__ */ c(
      v.div,
      {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20 },
        children: /* @__PURE__ */ c("h1", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }, children: "Revision Hub" })
      }
    ),
    /* @__PURE__ */ c("div", { className: "flex gap-1 p-1 rounded-xl w-52", style: { background: "rgba(255,255,255,0.06)" }, children: ["Morning", "Evening"].map((F) => /* @__PURE__ */ y(
      v.button,
      {
        onClick: () => t(F),
        className: "flex-1 py-2 rounded-lg relative",
        whileTap: { scale: 0.95 },
        children: [
          e === F && /* @__PURE__ */ c(
            v.div,
            {
              layoutId: "mode-pill",
              className: "absolute inset-0 rounded-lg",
              style: { background: "rgba(99,102,241,0.2)", border: "1px solid rgba(99,102,241,0.3)" },
              transition: { type: "spring", stiffness: 300, damping: 25 }
            }
          ),
          /* @__PURE__ */ y("span", { className: "relative z-10", style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: e === F ? "#818CF8" : "#6B7280" }, children: [
            F === "Morning" ? "🌅 " : "🌙 ",
            F
          ] })
        ]
      },
      F
    )) }),
    /* @__PURE__ */ y(_, { delay: 1, children: [
      /* @__PURE__ */ y("div", { className: "flex justify-between mb-2", children: [
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#6B7280" }, children: "Progress" }),
        /* @__PURE__ */ y("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#818CF8" }, children: [
          r.length,
          "/",
          it.length
        ] })
      ] }),
      /* @__PURE__ */ c(je, { progress: w, color: "#6366F1", delay: 1 })
    ] }),
    /* @__PURE__ */ c(qe, { mode: "wait", children: a ? /* @__PURE__ */ y(
      v.div,
      {
        initial: { opacity: 0, scale: 0.8 },
        animate: { opacity: 1, scale: 1 },
        transition: { type: "spring", stiffness: 150, damping: 15 },
        className: "flex flex-col items-center py-12",
        children: [
          /* @__PURE__ */ c(
            v.div,
            {
              animate: { scale: [1, 1.1, 1], rotate: [0, 5, -5, 0] },
              transition: { duration: 2, repeat: 1 / 0 },
              style: { fontSize: 64 },
              children: "🌟"
            }
          ),
          /* @__PURE__ */ c("h2", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 22, color: "#F4F4FF", marginTop: 16, textAlign: "center" }, children: "Zero backlog. Clean slate." }),
          /* @__PURE__ */ c("p", { style: { fontFamily: "Inter", fontSize: 14, color: "#6B7280", marginTop: 8 }, children: "All revision cards completed!" }),
          /* @__PURE__ */ y(
            v.button,
            {
              whileTap: { scale: 0.95 },
              onClick: () => {
                i(0), l([]), d(!1), o(!1);
              },
              className: "mt-6 px-6 py-3 rounded-2xl flex items-center gap-2",
              style: { background: "rgba(99,102,241,0.2)", border: "1px solid rgba(99,102,241,0.3)" },
              children: [
                /* @__PURE__ */ c(Ti, { size: 16, color: "#818CF8" }),
                /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 14, color: "#818CF8" }, children: "Start Over" })
              ]
            }
          )
        ]
      },
      "done"
    ) : /* @__PURE__ */ y(
      v.div,
      {
        initial: { opacity: 0, scale: 0.9 },
        animate: { opacity: 1, scale: 1 },
        exit: { opacity: 0, scale: 0.9 },
        transition: { type: "spring", stiffness: 200, damping: 20 },
        className: "relative",
        style: { perspective: "1000px", minHeight: 280 },
        children: [
          /* @__PURE__ */ c(
            v.div,
            {
              className: "absolute left-0 top-0 bottom-0 w-16 rounded-l-2xl flex items-center justify-center",
              style: { background: `rgba(239,68,68,${p.get()})`, opacity: p },
              children: /* @__PURE__ */ c(Uo, { size: 24, color: "#EF4444" })
            }
          ),
          /* @__PURE__ */ c(
            v.div,
            {
              className: "absolute right-0 top-0 bottom-0 w-16 rounded-r-2xl flex items-center justify-center",
              style: { background: `rgba(34,197,94,${g.get()})`, opacity: g },
              children: /* @__PURE__ */ c(xi, { size: 24, color: "#22C55E" })
            }
          ),
          /* @__PURE__ */ c(
            v.div,
            {
              drag: "x",
              dragConstraints: { left: 0, right: 0 },
              dragElastic: 0.8,
              onDragEnd: b,
              style: { x: u, rotate: h },
              onClick: () => o(!s),
              className: "cursor-grab active:cursor-grabbing",
              children: /* @__PURE__ */ c(
                v.div,
                {
                  animate: { rotateY: s ? 180 : 0 },
                  transition: { type: "spring", stiffness: 200, damping: 20 },
                  style: { transformStyle: "preserve-3d" },
                  className: "relative",
                  children: /* @__PURE__ */ y(
                    "div",
                    {
                      className: "rounded-2xl p-6 relative overflow-hidden",
                      style: {
                        background: "rgba(255,255,255,0.08)",
                        backdropFilter: "blur(40px)",
                        border: "1px solid rgba(99,102,241,0.3)",
                        boxShadow: "0 0 30px rgba(99,102,241,0.15)",
                        minHeight: 260,
                        backfaceVisibility: "hidden"
                      },
                      children: [
                        /* @__PURE__ */ c(
                          v.div,
                          {
                            className: "absolute inset-0 pointer-events-none",
                            style: { background: "linear-gradient(105deg, transparent 40%, rgba(255,255,255,0.06) 50%, transparent 60%)", backgroundSize: "200% 100%" },
                            animate: { backgroundPosition: ["200% 0", "-200% 0"] },
                            transition: { duration: 3, repeat: 1 / 0, repeatDelay: 4, ease: "linear" }
                          }
                        ),
                        /* @__PURE__ */ c(
                          "span",
                          {
                            className: "px-2 py-0.5 rounded-full",
                            style: { fontSize: 11, fontFamily: "Inter", fontWeight: 600, background: "rgba(99,102,241,0.2)", color: "#818CF8" },
                            children: x.topic
                          }
                        ),
                        /* @__PURE__ */ y("div", { className: "mt-4", style: { display: s ? "none" : "block" }, children: [
                          /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 18, color: "#F4F4FF", lineHeight: 1.5, display: "block" }, children: x.front }),
                          /* @__PURE__ */ c("p", { style: { fontFamily: "Inter", fontSize: 12, color: "#6B7280", marginTop: 20 }, children: "Tap to flip · Swipe right ✅ · Swipe left ⏭" })
                        ] }),
                        /* @__PURE__ */ c("div", { className: "mt-4", style: { display: s ? "block" : "none", transform: "rotateY(180deg)" }, children: /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 15, color: "#F4F4FF", lineHeight: 1.6, display: "block" }, children: x.back }) })
                      ]
                    }
                  )
                }
              )
            }
          )
        ]
      },
      n
    ) }),
    !a && /* @__PURE__ */ c("div", { className: "flex justify-center gap-2", children: it.map((F, S) => /* @__PURE__ */ c(
      v.div,
      {
        className: "w-2 h-2 rounded-full",
        animate: {
          background: S === n ? "#6366F1" : r.includes(S) ? "#22C55E" : "rgba(255,255,255,0.15)",
          scale: S === n ? 1.3 : 1
        },
        transition: { type: "spring", stiffness: 300, damping: 20 },
        style: { boxShadow: S === n ? "0 0 8px rgba(99,102,241,0.5)" : void 0 }
      },
      S
    )) })
  ] });
}
const mn = `{
  "actions": [
    { "type": "mark_read", "pages": "50-59" },
    { "type": "anki_done", "pages": "46-49" },
    { "type": "add_task", "title": "Cook lunch",
      "time": "13:00-15:00" },
    { "type": "uworld", "subject": "Biochemistry",
      "questions": 10, "correct": 70 }
  ]
}`, ef = [
  { icon: kt, text: "Mark FA Pages 50–59 as Read", emoji: "📖", color: "#6366F1" },
  { icon: bt, text: "Anki done for Pages 46–49", emoji: "🧠", color: "#818CF8" },
  { icon: rh, text: "Add task: Cook lunch 13:00–15:00", emoji: "📋", color: "#F59E0B" },
  { icon: Wo, text: "UWorld: Biochemistry 10Qs — 70% correct", emoji: "📊", color: "#22C55E" }
];
function tf() {
  const [e, t] = W(""), [n, i] = W(!1), [s, o] = W(!1), [r, l] = W(!1);
  xe(() => {
    let d = 0;
    const u = setInterval(() => {
      d <= mn.length ? (t(mn.slice(0, d)), d++, d > mn.length && setTimeout(() => i(!0), 500)) : clearInterval(u);
    }, 15);
    return () => clearInterval(u);
  }, []);
  const a = () => {
    o(!0), setTimeout(() => {
      o(!1), l(!0), Ln({ particleCount: 80, spread: 100, origin: { y: 0.6 }, colors: ["#6366F1", "#818CF8", "#22C55E"] });
    }, 1500);
  };
  return /* @__PURE__ */ y("div", { className: "space-y-4", children: [
    /* @__PURE__ */ y(
      v.div,
      {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20 },
        children: [
          /* @__PURE__ */ y("div", { className: "flex items-center gap-2", children: [
            /* @__PURE__ */ c($o, { size: 22, color: "#818CF8" }),
            /* @__PURE__ */ c("h1", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }, children: "Claude Import" })
          ] }),
          /* @__PURE__ */ c("p", { style: { fontFamily: "Inter", fontSize: 13, color: "#6B7280", marginTop: 4 }, children: "Paste AI-generated JSON to auto-update your study data" })
        ]
      }
    ),
    /* @__PURE__ */ c(_, { delay: 1, hero: !0, children: /* @__PURE__ */ c(
      "div",
      {
        className: "rounded-xl p-4 overflow-auto",
        style: {
          background: "rgba(14,14,26,0.8)",
          border: "1px solid rgba(99,102,241,0.2)",
          maxHeight: 220,
          fontFamily: "'SF Mono', 'Fira Code', monospace",
          fontSize: 12,
          lineHeight: 1.6
        },
        children: /* @__PURE__ */ y("pre", { className: "whitespace-pre-wrap", children: [
          e.split("").map((d, u) => {
            let h = "#F4F4FF";
            return (d === '"' || e[u - 1] === '"' && d !== ":") && (h = "#818CF8"), (d === ":" || d === "{" || d === "}" || d === "[" || d === "]") && (h = "#6B7280"), !isNaN(Number(d)) && d !== " " && d !== `
` && (h = "#22C55E"), /* @__PURE__ */ c(
              v.span,
              {
                initial: { opacity: 0, scale: 0.5 },
                animate: { opacity: 1, scale: 1 },
                transition: { type: "spring", stiffness: 500, damping: 30 },
                style: { color: h },
                children: d
              },
              u
            );
          }),
          /* @__PURE__ */ c(
            v.span,
            {
              animate: { opacity: [1, 0] },
              transition: { duration: 0.5, repeat: 1 / 0 },
              style: { color: "#6366F1" },
              children: "█"
            }
          )
        ] })
      }
    ) }),
    /* @__PURE__ */ c(qe, { children: n && /* @__PURE__ */ y(
      v.div,
      {
        initial: { opacity: 0 },
        animate: { opacity: 1 },
        className: "space-y-3",
        children: [
          /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }, children: "PARSED ACTIONS" }),
          ef.map((d, u) => /* @__PURE__ */ y(
            v.div,
            {
              initial: { opacity: 0, x: -40, scale: 0.9 },
              animate: { opacity: 1, x: 0, scale: 1 },
              transition: { type: "spring", stiffness: 180, damping: 18, delay: u * 0.1 },
              whileTap: { scale: 0.97 },
              className: "flex items-center gap-3 px-4 py-3 rounded-xl relative overflow-hidden",
              style: {
                background: "rgba(255,255,255,0.06)",
                backdropFilter: "blur(20px)",
                border: "1px solid rgba(99,102,241,0.2)"
              },
              children: [
                /* @__PURE__ */ c(
                  "div",
                  {
                    className: "absolute left-0 top-0 bottom-0 w-1 rounded-full",
                    style: { background: d.color }
                  }
                ),
                /* @__PURE__ */ c("span", { style: { fontSize: 18 }, children: d.emoji }),
                /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#F4F4FF", flex: 1 }, children: d.text }),
                r && /* @__PURE__ */ c(
                  v.div,
                  {
                    initial: { scale: 0 },
                    animate: { scale: 1 },
                    transition: { type: "spring", stiffness: 300, damping: 15 },
                    children: /* @__PURE__ */ c(xi, { size: 16, color: "#22C55E" })
                  }
                )
              ]
            },
            d.text
          ))
        ]
      }
    ) }),
    n && !r && /* @__PURE__ */ y(
      v.button,
      {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20, delay: 0.5 },
        whileTap: { scale: 0.95 },
        onClick: a,
        className: "w-full py-4 rounded-2xl flex items-center justify-center gap-2 relative overflow-hidden",
        style: {
          background: "linear-gradient(135deg, #6366F1, #8B5CF6)",
          boxShadow: "0 0 30px rgba(99,102,241,0.3)"
        },
        children: [
          /* @__PURE__ */ c(
            v.div,
            {
              className: "absolute inset-0 rounded-2xl",
              style: { border: "2px solid rgba(99,102,241,0.4)" },
              animate: { scale: [1, 1.05, 1], opacity: [0.3, 0, 0.3] },
              transition: { duration: 2, repeat: 1 / 0 }
            }
          ),
          s ? /* @__PURE__ */ c(
            v.div,
            {
              animate: { rotate: 360 },
              transition: { duration: 1, repeat: 1 / 0, ease: "linear" },
              children: /* @__PURE__ */ c(Xs, { size: 20, color: "#fff" })
            }
          ) : /* @__PURE__ */ c(Xs, { size: 20, color: "#fff" }),
          /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 16, color: "#fff" }, children: s ? "Executing..." : "Execute All Actions" })
        ]
      }
    ),
    r && /* @__PURE__ */ c(
      v.div,
      {
        initial: { opacity: 0, scale: 0.9 },
        animate: { opacity: 1, scale: 1 },
        transition: { type: "spring", stiffness: 150, damping: 15 },
        className: "text-center py-4",
        children: /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 18, color: "#22C55E" }, children: "✅ All actions executed successfully!" })
      }
    )
  ] });
}
const nf = [
  { day: "Mon", pages: 6, target: 10 },
  { day: "Tue", pages: 9, target: 10 },
  { day: "Wed", pages: 7, target: 10 },
  { day: "Thu", pages: 11, target: 10 },
  { day: "Fri", pages: 8, target: 10 },
  { day: "Sat", pages: 10, target: 10 },
  { day: "Sun", pages: 8.3, target: 10 }
], sf = [
  { name: "Biochem", progress: 67, color: "#6366F1" },
  { name: "Immuno", progress: 45, color: "#818CF8" },
  { name: "Micro", progress: 30, color: "#8B5CF6" },
  { name: "Path", progress: 12, color: "#A78BFA" },
  { name: "Pharm", progress: 55, color: "#7C3AED" },
  { name: "Anatomy", progress: 38, color: "#6366F1" }
], rf = Array.from(
  { length: 4 },
  () => Array.from({ length: 7 }, () => Math.floor(Math.random() * 5))
);
function of() {
  const [e, t] = W(null), [n, i] = W(null);
  return /* @__PURE__ */ y("div", { className: "space-y-4", children: [
    /* @__PURE__ */ c(
      v.div,
      {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20 },
        children: /* @__PURE__ */ c("h1", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }, children: "Analytics" })
      }
    ),
    /* @__PURE__ */ y(_, { delay: 1, hero: !0, children: [
      /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }, children: "Weekly Pace" }),
      /* @__PURE__ */ c("div", { className: "mt-3", children: /* @__PURE__ */ c(af, { data: nf }) })
    ] }),
    /* @__PURE__ */ y("div", { className: "grid grid-cols-2 gap-3", children: [
      /* @__PURE__ */ y(_, { delay: 3, glowColor: "rgba(245,158,11,0.15)", children: [
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: "#6B7280" }, children: "At 8.3/day" }),
        /* @__PURE__ */ c("div", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 20, color: "#F4F4FF", marginTop: 4 }, children: "May 8" }),
        /* @__PURE__ */ c("span", { className: "px-2 py-0.5 rounded-full", style: { fontSize: 11, fontFamily: "Inter", fontWeight: 600, background: "rgba(245,158,11,0.15)", color: "#F59E0B" }, children: "⚠️ Cutting it close" }),
        /* @__PURE__ */ c("div", { className: "mt-2", children: /* @__PURE__ */ c(je, { progress: 75, color: "#F59E0B", delay: 4, height: 3 }) })
      ] }),
      /* @__PURE__ */ y(_, { delay: 4, glowColor: "rgba(34,197,94,0.15)", children: [
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: "#6B7280" }, children: "At 10/day" }),
        /* @__PURE__ */ c("div", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 20, color: "#F4F4FF", marginTop: 4 }, children: "May 1" }),
        /* @__PURE__ */ c("span", { className: "px-2 py-0.5 rounded-full", style: { fontSize: 11, fontFamily: "Inter", fontWeight: 600, background: "rgba(34,197,94,0.15)", color: "#22C55E" }, children: "✅ On track" }),
        /* @__PURE__ */ c("div", { className: "mt-2", children: /* @__PURE__ */ c(je, { progress: 92, color: "#22C55E", delay: 5, height: 3 }) })
      ] })
    ] }),
    /* @__PURE__ */ y(_, { delay: 5, children: [
      /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }, children: "Subject Progress" }),
      /* @__PURE__ */ c("div", { className: "mt-3 grid grid-cols-3 gap-4", children: sf.map((s, o) => /* @__PURE__ */ y(
        v.div,
        {
          className: "flex flex-col items-center gap-1 cursor-pointer",
          whileTap: { scale: 1.05 },
          onHoverStart: () => t(o),
          onHoverEnd: () => t(null),
          animate: { scale: e === o ? 1.05 : 1 },
          transition: { type: "spring", stiffness: 300, damping: 20 },
          children: [
            /* @__PURE__ */ c(lf, { progress: s.progress, color: s.color, delay: o }),
            /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 11, color: "#6B7280" }, children: s.name })
          ]
        },
        s.name
      )) })
    ] }),
    /* @__PURE__ */ y(_, { delay: 7, children: [
      /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }, children: "Study Heatmap" }),
      /* @__PURE__ */ c("div", { className: "mt-3 flex flex-col gap-1.5 relative", children: rf.map((s, o) => /* @__PURE__ */ c("div", { className: "flex gap-1.5", children: s.map((r, l) => /* @__PURE__ */ c(
        v.div,
        {
          className: "flex-1 rounded-md relative cursor-pointer",
          style: {
            aspectRatio: "1",
            background: r === 0 ? "rgba(255,255,255,0.04)" : `rgba(99,102,241,${0.15 + r * 0.18})`,
            border: "1px solid rgba(99,102,241,0.1)"
          },
          initial: { opacity: 0 },
          animate: { opacity: 1 },
          transition: { delay: 0.6 + o * 0.08 + l * 0.04 },
          whileTap: { scale: 0.9 },
          onClick: () => i(n?.r === o && n?.c === l ? null : { r: o, c: l }),
          children: n?.r === o && n?.c === l && /* @__PURE__ */ y(
            v.div,
            {
              initial: { opacity: 0, y: 10, scale: 0.8 },
              animate: { opacity: 1, y: -32, scale: 1 },
              transition: { type: "spring", stiffness: 300, damping: 20 },
              className: "absolute left-1/2 -translate-x-1/2 px-2 py-1 rounded-lg z-20 whitespace-nowrap",
              style: {
                background: "rgba(14,14,26,0.9)",
                border: "1px solid rgba(99,102,241,0.3)",
                fontSize: 10,
                fontFamily: "Inter",
                fontWeight: 500,
                color: "#818CF8"
              },
              children: [
                r,
                "h studied"
              ]
            }
          )
        },
        l
      )) }, o)) }),
      /* @__PURE__ */ y("div", { className: "mt-2 flex items-center justify-end gap-1", children: [
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontSize: 10, color: "#6B7280" }, children: "Less" }),
        [0, 1, 2, 3, 4].map((s) => /* @__PURE__ */ c(
          "div",
          {
            className: "w-3 h-3 rounded-sm",
            style: {
              background: s === 0 ? "rgba(255,255,255,0.04)" : `rgba(99,102,241,${0.15 + s * 0.18})`
            }
          },
          s
        )),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontSize: 10, color: "#6B7280" }, children: "More" })
      ] })
    ] })
  ] });
}
function af({ data: e }) {
  const o = (u) => 10 + u / (e.length - 1) * 260, r = (u) => 110 - u / 14 * 100, l = e.map((u, h) => `${h === 0 ? "M" : "L"} ${o(h)} ${r(u.pages)}`).join(" "), a = e.map((u, h) => `${h === 0 ? "M" : "L"} ${o(h)} ${r(u.target)}`).join(" "), d = `${l} L ${o(e.length - 1)} 110 L ${o(0)} 110 Z`;
  return /* @__PURE__ */ y("svg", { width: "100%", viewBox: "0 0 280 140", className: "overflow-visible", children: [
    /* @__PURE__ */ c("defs", { children: /* @__PURE__ */ y("linearGradient", { id: "area-grad", x1: "0", y1: "0", x2: "0", y2: "1", children: [
      /* @__PURE__ */ c("stop", { offset: "0%", stopColor: "#6366F1", stopOpacity: 0.3 }),
      /* @__PURE__ */ c("stop", { offset: "100%", stopColor: "#6366F1", stopOpacity: 0 })
    ] }) }),
    /* @__PURE__ */ c(
      v.path,
      {
        d,
        fill: "url(#area-grad)",
        initial: { opacity: 0 },
        animate: { opacity: 1 },
        transition: { delay: 1, duration: 0.8 }
      }
    ),
    /* @__PURE__ */ c(
      v.path,
      {
        d: a,
        fill: "none",
        stroke: "#F59E0B",
        strokeWidth: 1.5,
        strokeDasharray: "4 4",
        initial: { pathLength: 0 },
        animate: { pathLength: 1 },
        transition: { duration: 1, delay: 0.3, ease: "easeOut" }
      }
    ),
    /* @__PURE__ */ c(
      v.path,
      {
        d: l,
        fill: "none",
        stroke: "#6366F1",
        strokeWidth: 2.5,
        strokeLinecap: "round",
        initial: { pathLength: 0 },
        animate: { pathLength: 1 },
        transition: { duration: 1, delay: 0.3, ease: "easeOut" },
        style: { filter: "drop-shadow(0 0 6px rgba(99,102,241,0.5))" }
      }
    ),
    e.map((u, h) => /* @__PURE__ */ c(
      v.circle,
      {
        cx: o(h),
        cy: r(u.pages),
        r: 4,
        fill: "#6366F1",
        stroke: "#0E0E1A",
        strokeWidth: 2,
        initial: { scale: 0 },
        animate: { scale: 1 },
        transition: { type: "spring", stiffness: 300, damping: 15, delay: 1.2 + h * 0.08 },
        style: { filter: "drop-shadow(0 0 4px rgba(99,102,241,0.6))" }
      },
      h
    )),
    e.map((u, h) => /* @__PURE__ */ c(
      "text",
      {
        x: o(h),
        y: 134,
        textAnchor: "middle",
        style: { fontSize: 10, fontFamily: "Inter", fill: "#6B7280" },
        children: u.day
      },
      `label-${h}`
    ))
  ] });
}
function lf({ progress: e, color: t, delay: n }) {
  const s = 2 * Math.PI * 22, o = s - e / 100 * s;
  return /* @__PURE__ */ y("div", { className: "relative", children: [
    /* @__PURE__ */ y("svg", { width: 56, height: 56, viewBox: "0 0 56 56", children: [
      /* @__PURE__ */ c("circle", { cx: 28, cy: 28, r: 22, fill: "none", stroke: "rgba(255,255,255,0.06)", strokeWidth: 4 }),
      /* @__PURE__ */ c(
        v.circle,
        {
          cx: 28,
          cy: 28,
          r: 22,
          fill: "none",
          stroke: t,
          strokeWidth: 4,
          strokeLinecap: "round",
          strokeDasharray: s,
          initial: { strokeDashoffset: s },
          animate: { strokeDashoffset: o },
          transition: { type: "spring", stiffness: 40, damping: 10, delay: 0.5 + n * 0.1 },
          style: {
            filter: `drop-shadow(0 0 4px ${t}60)`,
            transform: "rotate(-90deg)",
            transformOrigin: "center"
          }
        }
      )
    ] }),
    /* @__PURE__ */ c("div", { className: "absolute inset-0 flex items-center justify-center", children: /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 11, color: "#F4F4FF" }, children: /* @__PURE__ */ c(de, { value: e, suffix: "%" }) }) })
  ] });
}
const cf = [
  { time: "07:00 – 09:30", label: "FA Reading", icon: kt, duration: "2h 30min", color: "#6366F1", auto: !0 },
  { time: "09:45 – 10:45", label: "Anki Review", icon: bt, duration: "1h 00min", color: "#818CF8", auto: !0 },
  { time: "11:00 – 12:15", label: "Sketchy Micro", icon: Si, duration: "1h 15min", color: "#14B8A6", auto: !0 },
  { time: "13:00 – 13:30", label: "Break", icon: dh, duration: "30min", color: "#6B7280", auto: !1 },
  { time: "14:00 – 14:25", label: "Anki (extra)", icon: bt, duration: "25min", color: "#818CF8", auto: !1 }
], df = ["All", "Study", "Break", "Manual", "Auto"];
function uf() {
  const [e, t] = W("All"), [n, i] = W(!1);
  return /* @__PURE__ */ y("div", { className: "space-y-4", children: [
    /* @__PURE__ */ c(
      v.div,
      {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20 },
        children: /* @__PURE__ */ c("h1", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }, children: "Time Logger" })
      }
    ),
    /* @__PURE__ */ y(_, { delay: 1, hero: !0, glowColor: "rgba(99,102,241,0.2)", children: [
      /* @__PURE__ */ y("div", { className: "flex items-center gap-3", children: [
        /* @__PURE__ */ c(
          v.div,
          {
            animate: { rotate: [0, 360] },
            transition: { duration: 8, repeat: 1 / 0, ease: "linear" },
            children: /* @__PURE__ */ c(wi, { size: 32, color: "#6366F1" })
          }
        ),
        /* @__PURE__ */ y("div", { children: [
          /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 13, color: "#6B7280" }, children: "Total today" }),
          /* @__PURE__ */ y("div", { style: { fontFamily: "Inter", fontWeight: 800, fontSize: 34, color: "#F4F4FF" }, children: [
            /* @__PURE__ */ c(de, { value: 5, suffix: "h " }),
            /* @__PURE__ */ c(de, { value: 40, suffix: "min" })
          ] })
        ] })
      ] }),
      /* @__PURE__ */ y("div", { className: "mt-3", children: [
        /* @__PURE__ */ c(je, { progress: 71, color: "#6366F1", delay: 2, height: 5 }),
        /* @__PURE__ */ y("div", { className: "flex justify-between mt-1", children: [
          /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontSize: 11, color: "#6B7280" }, children: "0h" }),
          /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontSize: 11, color: "#6B7280" }, children: "8h goal" })
        ] })
      ] })
    ] }),
    /* @__PURE__ */ c("div", { className: "flex gap-2 overflow-x-auto pb-1", style: { scrollbarWidth: "none" }, children: df.map((s) => /* @__PURE__ */ y(
      v.button,
      {
        onClick: () => t(s),
        whileTap: { scale: 0.9 },
        className: "px-3.5 py-1.5 rounded-full whitespace-nowrap relative overflow-hidden",
        style: {
          background: e === s ? "rgba(99,102,241,0.25)" : "rgba(255,255,255,0.06)",
          border: `1px solid ${e === s ? "rgba(99,102,241,0.4)" : "rgba(255,255,255,0.08)"}`
        },
        children: [
          e === s && /* @__PURE__ */ c(
            v.div,
            {
              layoutId: "cat-pill",
              className: "absolute inset-0 rounded-full",
              style: { background: "rgba(99,102,241,0.15)" },
              transition: { type: "spring", stiffness: 300, damping: 25 }
            }
          ),
          /* @__PURE__ */ c("span", { className: "relative z-10", style: { fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: e === s ? "#818CF8" : "#6B7280" }, children: s })
        ]
      },
      s
    )) }),
    /* @__PURE__ */ c("div", { className: "space-y-3", children: cf.map((s, o) => /* @__PURE__ */ c(
      v.div,
      {
        initial: { opacity: 0, x: -30 },
        animate: { opacity: 1, x: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20, delay: 0.2 + o * 0.06 },
        children: /* @__PURE__ */ c(_, { delay: 0, children: /* @__PURE__ */ y("div", { className: "flex items-center gap-3", children: [
          /* @__PURE__ */ c(
            "div",
            {
              className: "w-10 h-10 rounded-xl flex items-center justify-center",
              style: { background: `${s.color}20`, border: `1px solid ${s.color}30` },
              children: /* @__PURE__ */ c(s.icon, { size: 18, color: s.color, strokeWidth: 1.5 })
            }
          ),
          /* @__PURE__ */ y("div", { className: "flex-1", children: [
            /* @__PURE__ */ y("div", { className: "flex items-center justify-between", children: [
              /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 14, color: "#F4F4FF" }, children: s.label }),
              /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 14, color: s.color }, children: s.duration })
            ] }),
            /* @__PURE__ */ y("div", { className: "flex items-center gap-2 mt-0.5", children: [
              /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 12, color: "#6B7280" }, children: s.time }),
              s.auto && /* @__PURE__ */ c(
                "span",
                {
                  className: "px-1.5 py-0.5 rounded",
                  style: { fontSize: 9, fontFamily: "Inter", fontWeight: 600, background: "rgba(99,102,241,0.15)", color: "#818CF8" },
                  children: "AUTO"
                }
              )
            ] })
          ] })
        ] }) })
      },
      s.label + s.time
    )) }),
    /* @__PURE__ */ y(
      v.button,
      {
        className: "fixed bottom-24 right-5 w-14 h-14 rounded-full flex items-center justify-center z-40",
        style: { background: "linear-gradient(135deg, #6366F1, #8B5CF6)", boxShadow: "0 0 30px rgba(99,102,241,0.4)" },
        whileTap: { scale: 0.9 },
        onClick: () => i(!0),
        initial: { scale: 0 },
        animate: { scale: 1 },
        transition: { type: "spring", stiffness: 200, damping: 15, delay: 0.8 },
        children: [
          /* @__PURE__ */ c(
            v.div,
            {
              className: "absolute inset-0 rounded-full",
              style: { border: "2px solid rgba(99,102,241,0.5)" },
              animate: { scale: [1, 1.4, 1], opacity: [0.5, 0, 0.5] },
              transition: { duration: 2, repeat: 1 / 0 }
            }
          ),
          /* @__PURE__ */ c(Xt, { size: 24, color: "#fff" })
        ]
      }
    ),
    /* @__PURE__ */ c(qe, { children: n && /* @__PURE__ */ y(er, { children: [
      /* @__PURE__ */ c(
        v.div,
        {
          initial: { opacity: 0 },
          animate: { opacity: 1 },
          exit: { opacity: 0 },
          className: "fixed inset-0 z-50",
          style: { background: "rgba(0,0,0,0.5)", backdropFilter: "blur(8px)" },
          onClick: () => i(!1)
        }
      ),
      /* @__PURE__ */ y(
        v.div,
        {
          initial: { y: "100%" },
          animate: { y: 0 },
          exit: { y: "100%" },
          transition: { type: "spring", stiffness: 200, damping: 25 },
          className: "fixed bottom-0 left-0 right-0 z-50 rounded-t-3xl p-6",
          style: {
            background: "rgba(14,14,26,0.95)",
            backdropFilter: "blur(40px)",
            border: "1px solid rgba(99,102,241,0.2)",
            borderBottom: "none"
          },
          children: [
            /* @__PURE__ */ y("div", { className: "flex justify-between items-center mb-6", children: [
              /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 18, color: "#F4F4FF" }, children: "Add Manual Entry" }),
              /* @__PURE__ */ c(v.button, { whileTap: { scale: 0.9 }, onClick: () => i(!1), children: /* @__PURE__ */ c(Uo, { size: 20, color: "#6B7280" }) })
            ] }),
            /* @__PURE__ */ y("div", { className: "space-y-4", children: [
              /* @__PURE__ */ y("div", { children: [
                /* @__PURE__ */ c("label", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#6B7280", display: "block", marginBottom: 6 }, children: "Activity" }),
                /* @__PURE__ */ c(
                  v.input,
                  {
                    initial: { opacity: 0, y: 10 },
                    animate: { opacity: 1, y: 0 },
                    transition: { delay: 0.1 },
                    className: "w-full px-4 py-3 rounded-xl outline-none",
                    style: {
                      background: "rgba(255,255,255,0.06)",
                      border: "1px solid rgba(99,102,241,0.2)",
                      fontFamily: "Inter",
                      fontSize: 14,
                      color: "#F4F4FF"
                    },
                    placeholder: "e.g., Extra revision"
                  }
                )
              ] }),
              /* @__PURE__ */ y("div", { className: "grid grid-cols-2 gap-3", children: [
                /* @__PURE__ */ y("div", { children: [
                  /* @__PURE__ */ c("label", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#6B7280", display: "block", marginBottom: 6 }, children: "Start Time" }),
                  /* @__PURE__ */ c(
                    v.input,
                    {
                      initial: { opacity: 0, y: 10 },
                      animate: { opacity: 1, y: 0 },
                      transition: { delay: 0.15 },
                      type: "time",
                      className: "w-full px-4 py-3 rounded-xl outline-none",
                      style: { background: "rgba(255,255,255,0.06)", border: "1px solid rgba(99,102,241,0.2)", fontFamily: "Inter", fontSize: 14, color: "#F4F4FF" }
                    }
                  )
                ] }),
                /* @__PURE__ */ y("div", { children: [
                  /* @__PURE__ */ c("label", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#6B7280", display: "block", marginBottom: 6 }, children: "End Time" }),
                  /* @__PURE__ */ c(
                    v.input,
                    {
                      initial: { opacity: 0, y: 10 },
                      animate: { opacity: 1, y: 0 },
                      transition: { delay: 0.2 },
                      type: "time",
                      className: "w-full px-4 py-3 rounded-xl outline-none",
                      style: { background: "rgba(255,255,255,0.06)", border: "1px solid rgba(99,102,241,0.2)", fontFamily: "Inter", fontSize: 14, color: "#F4F4FF" }
                    }
                  )
                ] })
              ] }),
              /* @__PURE__ */ c(
                v.button,
                {
                  whileTap: { scale: 0.95 },
                  className: "w-full py-3.5 rounded-2xl",
                  style: { background: "linear-gradient(135deg, #6366F1, #8B5CF6)" },
                  children: /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 15, color: "#fff" }, children: "Save Entry" })
                }
              )
            ] })
          ]
        }
      )
    ] }) })
  ] });
}
const hf = [
  {
    title: "Exam Dates",
    icon: Ju,
    items: [
      { label: "FMGE", value: "Jun 28, 2026", type: "nav" },
      { label: "USMLE Step 1", value: "Jun 23, 2026", type: "nav" }
    ]
  },
  {
    title: "Prayer Times",
    icon: wi,
    items: [
      { label: "Fajr", value: "05:25", type: "nav" },
      { label: "Dhuhr", value: "12:38", type: "nav" },
      { label: "Asr", value: "16:08", type: "nav" },
      { label: "Maghrib", value: "18:12", type: "nav" },
      { label: "Isha", value: "19:38", type: "nav" }
    ]
  },
  {
    title: "Sleep & Wake",
    icon: Oo,
    items: [
      { label: "Wake up", value: "05:00", type: "nav" },
      { label: "Sleep", value: "23:00", type: "nav" }
    ]
  }
];
function ff() {
  const [e, t] = W(10), [n, i] = W("dark"), [s, o] = W(!1);
  return /* @__PURE__ */ y("div", { className: "space-y-4", children: [
    /* @__PURE__ */ c(
      v.div,
      {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20 },
        children: /* @__PURE__ */ c("h1", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }, children: "Settings" })
      }
    ),
    hf.map((r, l) => /* @__PURE__ */ y("div", { children: [
      /* @__PURE__ */ y(
        v.div,
        {
          initial: { opacity: 0 },
          animate: { opacity: 1 },
          transition: { delay: 0.1 + l * 0.1 },
          className: "flex items-center gap-2 mb-2",
          children: [
            /* @__PURE__ */ c(r.icon, { size: 16, color: "#818CF8" }),
            /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }, children: r.title.toUpperCase() }),
            /* @__PURE__ */ c(
              v.div,
              {
                className: "flex-1 h-px",
                initial: { scaleX: 0 },
                animate: { scaleX: 1 },
                transition: { delay: 0.3 + l * 0.1, duration: 0.5 },
                style: { transformOrigin: "left", background: "rgba(99,102,241,0.2)" }
              }
            )
          ]
        }
      ),
      /* @__PURE__ */ c(_, { delay: l + 1, children: /* @__PURE__ */ c("div", { className: "space-y-0", children: r.items.map((a, d) => /* @__PURE__ */ y(
        v.div,
        {
          initial: { opacity: 0, x: -10 },
          animate: { opacity: 1, x: 0 },
          transition: { delay: 0.2 + l * 0.1 + d * 0.04 },
          className: "flex items-center justify-between py-3",
          style: {
            borderBottom: d < r.items.length - 1 ? "1px solid rgba(255,255,255,0.05)" : void 0
          },
          children: [
            /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 14, color: "#F4F4FF" }, children: a.label }),
            /* @__PURE__ */ y("div", { className: "flex items-center gap-2", children: [
              /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#818CF8" }, children: a.value }),
              /* @__PURE__ */ c(Fi, { size: 14, color: "#6B7280" })
            ] })
          ]
        },
        a.label
      )) }) })
    ] }, r.title)),
    /* @__PURE__ */ y("div", { children: [
      /* @__PURE__ */ y(
        v.div,
        {
          className: "flex items-center gap-2 mb-2",
          initial: { opacity: 0 },
          animate: { opacity: 1 },
          transition: { delay: 0.5 },
          children: [
            /* @__PURE__ */ c(_o, { size: 16, color: "#818CF8" }),
            /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }, children: "DAILY GOALS" })
          ]
        }
      ),
      /* @__PURE__ */ c(_, { delay: 5, children: /* @__PURE__ */ y("div", { className: "flex items-center justify-between", children: [
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 14, color: "#F4F4FF" }, children: "FA Pages per day" }),
        /* @__PURE__ */ y("div", { className: "flex items-center gap-3", children: [
          /* @__PURE__ */ c(
            v.button,
            {
              whileTap: { scale: 0.8 },
              onClick: () => t(Math.max(1, e - 1)),
              className: "w-8 h-8 rounded-lg flex items-center justify-center",
              style: { background: "rgba(255,255,255,0.08)", border: "1px solid rgba(255,255,255,0.1)" },
              children: /* @__PURE__ */ c(wh, { size: 14, color: "#F4F4FF" })
            }
          ),
          /* @__PURE__ */ c(
            v.span,
            {
              initial: { y: -15, opacity: 0 },
              animate: { y: 0, opacity: 1 },
              transition: { type: "spring", stiffness: 300, damping: 20 },
              style: { fontFamily: "Inter", fontWeight: 700, fontSize: 20, color: "#F4F4FF", minWidth: 30, textAlign: "center", display: "inline-block" },
              children: e
            },
            e
          ),
          /* @__PURE__ */ c(
            v.button,
            {
              whileTap: { scale: 0.8 },
              onClick: () => t(e + 1),
              className: "w-8 h-8 rounded-lg flex items-center justify-center",
              style: { background: "rgba(99,102,241,0.2)", border: "1px solid rgba(99,102,241,0.3)" },
              children: /* @__PURE__ */ c(Xt, { size: 14, color: "#818CF8" })
            }
          )
        ] })
      ] }) })
    ] }),
    /* @__PURE__ */ y("div", { children: [
      /* @__PURE__ */ y(v.div, { className: "flex items-center gap-2 mb-2", initial: { opacity: 0 }, animate: { opacity: 1 }, transition: { delay: 0.6 }, children: [
        /* @__PURE__ */ c(qs, { size: 16, color: "#818CF8" }),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }, children: "NAVIGATION ORDER" })
      ] }),
      /* @__PURE__ */ c(_, { delay: 6, children: /* @__PURE__ */ c("div", { className: "space-y-2", children: ["Dashboard", "Today's Plan", "Tracker", "Analytics", "More"].map((r, l) => /* @__PURE__ */ y(
        v.div,
        {
          initial: { opacity: 0, x: -10 },
          animate: { opacity: 1, x: 0 },
          transition: { delay: 0.5 + l * 0.04 },
          whileTap: { scale: 0.97, backgroundColor: "rgba(99,102,241,0.1)" },
          className: "flex items-center gap-3 py-2.5 px-2 rounded-lg",
          children: [
            /* @__PURE__ */ c(qs, { size: 14, color: "#6B7280" }),
            /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 14, color: "#F4F4FF" }, children: r })
          ]
        },
        r
      )) }) })
    ] }),
    /* @__PURE__ */ y("div", { children: [
      /* @__PURE__ */ y(v.div, { className: "flex items-center gap-2 mb-2", initial: { opacity: 0 }, animate: { opacity: 1 }, transition: { delay: 0.7 }, children: [
        /* @__PURE__ */ c(lh, { size: 16, color: "#818CF8" }),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }, children: "BACKUP" })
      ] }),
      /* @__PURE__ */ c(_, { delay: 7, children: /* @__PURE__ */ y("div", { className: "flex items-center justify-between", children: [
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 14, color: "#F4F4FF" }, children: "Auto Backup" }),
        /* @__PURE__ */ c(
          v.button,
          {
            onClick: () => o(!s),
            className: "w-12 h-7 rounded-full relative",
            style: {
              background: s ? "rgba(99,102,241,0.5)" : "rgba(255,255,255,0.1)",
              border: `1px solid ${s ? "rgba(99,102,241,0.5)" : "rgba(255,255,255,0.15)"}`
            },
            whileTap: { scale: 0.95 },
            children: /* @__PURE__ */ c(
              v.div,
              {
                className: "w-5 h-5 rounded-full absolute top-0.5",
                animate: { left: s ? 24 : 2 },
                transition: { type: "spring", stiffness: 300, damping: 20 },
                style: {
                  background: s ? "#6366F1" : "#6B7280",
                  boxShadow: s ? "0 0 8px rgba(99,102,241,0.5)" : void 0
                }
              }
            )
          }
        )
      ] }) })
    ] }),
    /* @__PURE__ */ y("div", { children: [
      /* @__PURE__ */ y(v.div, { className: "flex items-center gap-2 mb-2", initial: { opacity: 0 }, animate: { opacity: 1 }, transition: { delay: 0.8 }, children: [
        /* @__PURE__ */ c(Mh, { size: 16, color: "#818CF8" }),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }, children: "APPEARANCE" })
      ] }),
      /* @__PURE__ */ c(_, { delay: 8, children: /* @__PURE__ */ c("div", { className: "flex gap-2", children: [
        { id: "light", icon: Rh, label: "Light" },
        { id: "dark", icon: Oo, label: "Dark" },
        { id: "system", icon: Th, label: "System" }
      ].map((r) => /* @__PURE__ */ y(
        v.button,
        {
          onClick: () => i(r.id),
          whileTap: { scale: 0.95 },
          className: "flex-1 py-3 rounded-xl flex flex-col items-center gap-1.5 relative",
          style: {
            background: n === r.id ? "rgba(99,102,241,0.15)" : "rgba(255,255,255,0.04)",
            border: `1px solid ${n === r.id ? "rgba(99,102,241,0.35)" : "rgba(255,255,255,0.06)"}`
          },
          children: [
            /* @__PURE__ */ c(r.icon, { size: 20, color: n === r.id ? "#818CF8" : "#6B7280" }),
            /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: n === r.id ? "#818CF8" : "#6B7280" }, children: r.label })
          ]
        },
        r.id
      )) }) })
    ] }),
    /* @__PURE__ */ c("div", { className: "h-8" })
  ] });
}
const pf = [
  { id: "revision", icon: Ti, label: "Revision Hub", desc: "SRS flashcard system", color: "#6366F1" },
  { id: "import", icon: $o, label: "Claude Import", desc: "AI-powered data import", color: "#818CF8" },
  { id: "logger", icon: wi, label: "Time Logger", desc: "Track study sessions", color: "#8B5CF6" },
  { id: "settings", icon: Nh, label: "Settings", desc: "Configure your study OS", color: "#A78BFA" }
];
function mf({ onNavigate: e }) {
  return /* @__PURE__ */ y("div", { className: "space-y-4", children: [
    /* @__PURE__ */ y(
      v.div,
      {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { type: "spring", stiffness: 150, damping: 20 },
        children: [
          /* @__PURE__ */ c("h1", { style: { fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }, children: "More" }),
          /* @__PURE__ */ c("p", { style: { fontFamily: "Inter", fontSize: 13, color: "#6B7280", marginTop: 2 }, children: "Additional tools & settings" })
        ]
      }
    ),
    /* @__PURE__ */ c("div", { className: "space-y-3", children: pf.map((t, n) => /* @__PURE__ */ c(_, { delay: n + 1, onClick: () => e(t.id), children: /* @__PURE__ */ y("div", { className: "flex items-center gap-4", children: [
      /* @__PURE__ */ c(
        v.div,
        {
          className: "w-12 h-12 rounded-2xl flex items-center justify-center",
          style: {
            background: `${t.color}15`,
            border: `1px solid ${t.color}30`
          },
          whileHover: { scale: 1.05 },
          children: /* @__PURE__ */ c(t.icon, { size: 22, color: t.color, strokeWidth: 1.5 })
        }
      ),
      /* @__PURE__ */ y("div", { className: "flex-1", children: [
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF", display: "block" }, children: t.label }),
        /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 400, fontSize: 12, color: "#6B7280" }, children: t.desc })
      ] }),
      /* @__PURE__ */ c(Fi, { size: 18, color: "#6B7280" })
    ] }) }, t.id)) })
  ] });
}
function yf() {
  const [e, t] = W("dashboard"), [n, i] = W(null), s = Ke((a) => {
    i(null), t(a);
  }, []), o = Ke((a) => {
    i(a);
  }, []), r = n || e, l = () => {
    switch (r) {
      case "dashboard":
        return /* @__PURE__ */ c(Zs, {});
      case "plan":
        return /* @__PURE__ */ c(Kh, {});
      case "tracker":
        return /* @__PURE__ */ c(Jh, {});
      case "analytics":
        return /* @__PURE__ */ c(of, {});
      case "revision":
        return /* @__PURE__ */ c(Qh, {});
      case "import":
        return /* @__PURE__ */ c(tf, {});
      case "logger":
        return /* @__PURE__ */ c(uf, {});
      case "settings":
        return /* @__PURE__ */ c(ff, {});
      case "more":
        return /* @__PURE__ */ c(mf, { onNavigate: o });
      default:
        return /* @__PURE__ */ c(Zs, {});
    }
  };
  return /* @__PURE__ */ y(
    "div",
    {
      className: "w-full h-full relative overflow-hidden",
      style: {
        fontFamily: "Inter, -apple-system, BlinkMacSystemFont, sans-serif",
        background: "#0E0E1A",
        maxWidth: 430,
        margin: "0 auto"
      },
      children: [
        /* @__PURE__ */ c(Wu, {}),
        /* @__PURE__ */ y(
          "div",
          {
            className: "relative z-10 h-full overflow-y-auto overflow-x-hidden",
            style: {
              paddingTop: 52,
              paddingBottom: 120,
              paddingLeft: 20,
              paddingRight: 20,
              scrollbarWidth: "none"
            },
            children: [
              n && /* @__PURE__ */ y(
                v.button,
                {
                  initial: { opacity: 0, x: -20 },
                  animate: { opacity: 1, x: 0 },
                  transition: { type: "spring", stiffness: 200, damping: 20 },
                  onClick: () => i(null),
                  className: "flex items-center gap-1.5 mb-4",
                  style: { color: "#818CF8" },
                  children: [
                    /* @__PURE__ */ c(Hu, { size: 18 }),
                    /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 14 }, children: "Back" })
                  ]
                }
              ),
              /* @__PURE__ */ c(qe, { mode: "wait", children: /* @__PURE__ */ c(
                v.div,
                {
                  initial: { opacity: 0, y: 20 },
                  animate: { opacity: 1, y: 0 },
                  exit: { opacity: 0, y: -20 },
                  transition: { type: "spring", stiffness: 200, damping: 25 },
                  children: l()
                },
                r
              ) })
            ]
          }
        ),
        /* @__PURE__ */ y(
          "div",
          {
            className: "absolute top-0 left-0 right-0 z-30 flex items-center justify-between px-6",
            style: { height: 48 },
            children: [
              /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 600, fontSize: 14, color: "#F4F4FF" }, children: "9:41" }),
              /* @__PURE__ */ y("div", { className: "flex items-center gap-1.5", children: [
                /* @__PURE__ */ c("div", { className: "flex gap-0.5", children: [1, 2, 3, 4].map((a) => /* @__PURE__ */ c(
                  "div",
                  {
                    className: "rounded-sm",
                    style: {
                      width: 3,
                      height: 4 + a * 2,
                      background: a <= 3 ? "#F4F4FF" : "rgba(244,244,255,0.3)"
                    }
                  },
                  a
                )) }),
                /* @__PURE__ */ c("span", { style: { fontFamily: "Inter", fontWeight: 500, fontSize: 11, color: "#F4F4FF", marginLeft: 4 }, children: "5G" }),
                /* @__PURE__ */ y("div", { className: "ml-2 flex items-center", style: { width: 25, height: 12 }, children: [
                  /* @__PURE__ */ c(
                    "div",
                    {
                      className: "rounded-sm",
                      style: {
                        width: 20,
                        height: 10,
                        border: "1.5px solid #F4F4FF",
                        borderRadius: 3,
                        position: "relative"
                      },
                      children: /* @__PURE__ */ c(
                        "div",
                        {
                          className: "rounded-sm",
                          style: {
                            position: "absolute",
                            left: 1.5,
                            top: 1.5,
                            bottom: 1.5,
                            width: "65%",
                            background: "#22C55E",
                            borderRadius: 1
                          }
                        }
                      )
                    }
                  ),
                  /* @__PURE__ */ c("div", { style: { width: 2, height: 5, background: "#F4F4FF", borderRadius: "0 1px 1px 0", marginLeft: 0.5 } })
                ] })
              ] })
            ]
          }
        ),
        /* @__PURE__ */ c($h, { active: e, onNavigate: s })
      ]
    }
  );
}
const gf = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  default: yf
}, Symbol.toStringTag, { value: "Module" }));
export {
  vf as Code0_8
};
