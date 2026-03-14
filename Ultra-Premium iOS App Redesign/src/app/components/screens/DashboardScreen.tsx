import { motion } from "motion/react";
import { LiquidGlassCard } from "../LiquidGlassCard";
import { AnimatedNumber } from "../AnimatedNumber";
import { AnimatedProgressBar } from "../AnimatedProgressBar";
import { Flame, CheckCircle2, BookOpen, Brain, Microscope, RotateCcw } from "lucide-react";
import { useEffect, useState } from "react";

const quotes = [
  "\"The expert in anything was once a beginner.\"",
  "\"Medicine is not only a science; it is also an art.\"",
  "\"What we know is a drop, what we don't know is an ocean.\"",
];

export function DashboardScreen() {
  const [quoteIdx, setQuoteIdx] = useState(0);
  const [typed, setTyped] = useState("");
  const subtitle = "Day 18 of 123. Every page matters.";

  useEffect(() => {
    let i = 0;
    const interval = setInterval(() => {
      if (i <= subtitle.length) {
        setTyped(subtitle.slice(0, i));
        i++;
      } else {
        clearInterval(interval);
      }
    }, 35);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const interval = setInterval(() => {
      setQuoteIdx((p) => (p + 1) % quotes.length);
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  const goals = [
    { icon: BookOpen, label: "FA Pages", current: 6, target: 10, color: "#6366F1", done: false },
    { icon: Brain, label: "Anki", current: 1, target: 1, color: "#22C55E", done: true },
    { icon: Microscope, label: "Sketchy Micro", current: 1, target: 2, color: "#818CF8", done: false },
    { icon: RotateCcw, label: "Revision", current: 3, target: 3, color: "#F59E0B", done: true },
  ];

  return (
    <div className="space-y-4">
      {/* Greeting */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 150, damping: 20 }}
      >
        <h1
          style={{
            fontFamily: "Inter, sans-serif",
            fontWeight: 700,
            fontSize: 30,
            color: "#F4F4FF",
          }}
        >
          Good morning, Arsh 🌅
        </h1>
        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontWeight: 400,
            fontSize: 14,
            color: "#6B7280",
            minHeight: 20,
          }}
        >
          {typed}
          <motion.span
            animate={{ opacity: [1, 0] }}
            transition={{ duration: 0.5, repeat: Infinity }}
            style={{ color: "#6366F1" }}
          >
            |
          </motion.span>
        </p>
      </motion.div>

      {/* Hero Countdown Cards */}
      <div className="grid grid-cols-2 gap-3">
        <LiquidGlassCard delay={1} hero glowColor="rgba(99,102,241,0.25)">
          <div className="flex flex-col items-center gap-2">
            <CountdownRing progress={65} color="#6366F1" />
            <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 12, color: "#818CF8", letterSpacing: 1 }}>
              FMGE
            </span>
            <span style={{ fontFamily: "Inter", fontWeight: 800, fontSize: 28, color: "#F4F4FF" }}>
              <AnimatedNumber value={107} />
            </span>
            <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 11, color: "#6B7280" }}>
              days remaining
            </span>
          </div>
        </LiquidGlassCard>

        <LiquidGlassCard delay={2} hero glowColor="rgba(139,92,246,0.25)">
          <div className="flex flex-col items-center gap-2">
            <CountdownRing progress={58} color="#8B5CF6" />
            <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 12, color: "#A78BFA", letterSpacing: 1 }}>
              USMLE STEP 1
            </span>
            <span style={{ fontFamily: "Inter", fontWeight: 800, fontSize: 28, color: "#F4F4FF" }}>
              ~<AnimatedNumber value={102} />
            </span>
            <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 11, color: "#6B7280" }}>
              days remaining
            </span>
          </div>
        </LiquidGlassCard>
      </div>

      {/* Pace Insight */}
      <LiquidGlassCard delay={3}>
        <div className="flex items-start gap-3">
          <motion.div
            className="w-1 self-stretch rounded-full"
            style={{ background: "linear-gradient(to bottom, #6366F1, #8B5CF6)" }}
            animate={{ opacity: [0.6, 1, 0.6] }}
            transition={{ duration: 2, repeat: Infinity }}
          />
          <div className="flex-1 space-y-2">
            <div className="flex items-center justify-between">
              <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }}>
                Your Pace
              </span>
              <MiniSparkline />
            </div>
            <div style={{ fontFamily: "Inter", fontWeight: 800, fontSize: 32, color: "#F4F4FF" }}>
              <AnimatedNumber value={8.3} decimals={1} suffix=" pages/day" />
            </div>
            <div className="flex flex-wrap gap-2">
              <span
                className="px-2 py-0.5 rounded-full"
                style={{ fontSize: 11, fontFamily: "Inter", fontWeight: 500, background: "rgba(34,197,94,0.15)", color: "#22C55E" }}
              >
                ✅ On track for FMGE
              </span>
              <span
                className="px-2 py-0.5 rounded-full"
                style={{ fontSize: 11, fontFamily: "Inter", fontWeight: 500, background: "rgba(245,158,11,0.15)", color: "#F59E0B" }}
              >
                ⚠️ Push harder for Step 1
              </span>
            </div>
            <span style={{ fontSize: 12, color: "#6B7280", fontFamily: "Inter" }}>
              FA done: May 1
            </span>
          </div>
        </div>
      </LiquidGlassCard>

      {/* Time Budget */}
      <LiquidGlassCard delay={4}>
        <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }}>
          Today's Time Budget
        </span>
        <div className="mt-3 flex rounded-xl overflow-hidden h-5">
          <TimeBudgetSegment width={33} color="#1E1E2E" label="Sleep" delay={0} />
          <TimeBudgetSegment width={10} color="rgba(99,102,241,0.4)" label="Prayer" delay={0.15} />
          <TimeBudgetSegment width={27} color="#6366F1" label="Study" delay={0.3} />
          <TimeBudgetSegment width={30} color="rgba(99,102,241,0.15)" label="Free" delay={0.45} />
        </div>
        <div className="mt-2 flex items-baseline gap-2">
          <span style={{ fontFamily: "Inter", fontWeight: 800, fontSize: 26, color: "#F4F4FF" }}>
            <AnimatedNumber value={7} suffix="h " /><AnimatedNumber value={20} suffix="min" />
          </span>
          <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 13, color: "#6B7280" }}>FREE</span>
        </div>
      </LiquidGlassCard>

      {/* Today's Goals */}
      <LiquidGlassCard delay={5}>
        <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }}>
          Today's Goals
        </span>
        <div className="mt-3 space-y-3">
          {goals.map((g, i) => (
            <motion.div
              key={g.label}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ type: "spring", stiffness: 150, damping: 20, delay: 0.4 + i * 0.06 }}
              className="flex items-center gap-3"
            >
              <motion.div
                animate={g.done ? { scale: [1, 1.2, 1] } : {}}
                transition={{ type: "spring", stiffness: 300, damping: 15, delay: 0.8 + i * 0.06 }}
                style={{
                  color: g.done ? "#22C55E" : g.color,
                  filter: g.done ? "drop-shadow(0 0 6px rgba(34,197,94,0.5))" : undefined,
                }}
              >
                {g.done ? <CheckCircle2 size={20} strokeWidth={1.5} /> : <g.icon size={20} strokeWidth={1.5} />}
              </motion.div>
              <div className="flex-1">
                <div className="flex justify-between">
                  <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#F4F4FF" }}>
                    {g.label}
                  </span>
                  <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 12, color: g.done ? "#22C55E" : "#6B7280" }}>
                    {g.done ? "Done ✓" : `${g.current}/${g.target}`}
                  </span>
                </div>
                <AnimatedProgressBar
                  progress={(g.current / g.target) * 100}
                  color={g.done ? "#22C55E" : g.color}
                  delay={i + 6}
                  height={4}
                />
              </div>
            </motion.div>
          ))}
        </div>
      </LiquidGlassCard>

      {/* Streak */}
      <LiquidGlassCard delay={7}>
        <div className="flex items-center gap-3">
          <motion.div
            animate={{ scale: [1, 1.15, 1], filter: ["drop-shadow(0 0 6px rgba(245,158,11,0.4))", "drop-shadow(0 0 12px rgba(245,158,11,0.7))", "drop-shadow(0 0 6px rgba(245,158,11,0.4))"] }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            <Flame size={28} color="#F59E0B" />
          </motion.div>
          <div>
            <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 18, color: "#F4F4FF" }}>
              Day 4 streak
            </span>
          </div>
        </div>
        <motion.div
          className="mt-3 px-3 py-2 rounded-xl"
          style={{ background: "rgba(99,102,241,0.1)", border: "1px solid rgba(99,102,241,0.15)" }}
          key={quoteIdx}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
          transition={{ duration: 0.5 }}
        >
          <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 13, color: "#818CF8", fontStyle: "italic" }}>
            {quotes[quoteIdx]}
          </span>
        </motion.div>
      </LiquidGlassCard>
    </div>
  );
}

function CountdownRing({ progress, color }: { progress: number; color: string }) {
  const r = 32;
  const circ = 2 * Math.PI * r;
  const offset = circ - (progress / 100) * circ;

  return (
    <svg width={76} height={76} viewBox="0 0 76 76">
      <circle cx={38} cy={38} r={r} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth={4} />
      <motion.circle
        cx={38}
        cy={38}
        r={r}
        fill="none"
        stroke={color}
        strokeWidth={4}
        strokeLinecap="round"
        strokeDasharray={circ}
        initial={{ strokeDashoffset: circ }}
        animate={{ strokeDashoffset: offset }}
        transition={{ type: "spring", stiffness: 40, damping: 12, delay: 0.5 }}
        style={{
          filter: `drop-shadow(0 0 6px ${color}80)`,
          transform: "rotate(-90deg)",
          transformOrigin: "center",
        }}
      />
    </svg>
  );
}

function MiniSparkline() {
  const points = [4, 7, 5, 9, 8, 10, 8.3];
  const max = 12;
  const w = 80;
  const h = 28;
  const pathData = points
    .map((v, i) => `${i === 0 ? "M" : "L"} ${(i / (points.length - 1)) * w} ${h - (v / max) * h}`)
    .join(" ");

  return (
    <svg width={w} height={h} className="overflow-visible">
      <defs>
        <linearGradient id="spark-grad" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#6366F1" />
          <stop offset="100%" stopColor="#818CF8" />
        </linearGradient>
      </defs>
      <motion.path
        d={pathData}
        fill="none"
        stroke="url(#spark-grad)"
        strokeWidth={2}
        strokeLinecap="round"
        initial={{ pathLength: 0 }}
        animate={{ pathLength: 1 }}
        transition={{ duration: 1.2, delay: 0.5, ease: "easeOut" }}
      />
    </svg>
  );
}

function TimeBudgetSegment({ width, color, label, delay }: { width: number; color: string; label: string; delay: number }) {
  return (
    <motion.div
      initial={{ width: "0%" }}
      animate={{ width: `${width}%` }}
      transition={{ type: "spring", stiffness: 60, damping: 15, delay: 0.4 + delay }}
      className="h-full flex items-center justify-center overflow-hidden"
      style={{ background: color }}
    >
      {width > 12 && (
        <span style={{ fontSize: 8, fontFamily: "Inter", fontWeight: 600, color: "#F4F4FF", whiteSpace: "nowrap" }}>
          {label}
        </span>
      )}
    </motion.div>
  );
}
