import { motion } from "motion/react";
import { LiquidGlassCard } from "../LiquidGlassCard";
import { AnimatedNumber } from "../AnimatedNumber";
import { AnimatedProgressBar } from "../AnimatedProgressBar";
import { useState } from "react";

const paceData = [
  { day: "Mon", pages: 6, target: 10 },
  { day: "Tue", pages: 9, target: 10 },
  { day: "Wed", pages: 7, target: 10 },
  { day: "Thu", pages: 11, target: 10 },
  { day: "Fri", pages: 8, target: 10 },
  { day: "Sat", pages: 10, target: 10 },
  { day: "Sun", pages: 8.3, target: 10 },
];

const subjectRadials = [
  { name: "Biochem", progress: 67, color: "#6366F1" },
  { name: "Immuno", progress: 45, color: "#818CF8" },
  { name: "Micro", progress: 30, color: "#8B5CF6" },
  { name: "Path", progress: 12, color: "#A78BFA" },
  { name: "Pharm", progress: 55, color: "#7C3AED" },
  { name: "Anatomy", progress: 38, color: "#6366F1" },
];

const heatmapData: number[][] = Array.from({ length: 4 }, () =>
  Array.from({ length: 7 }, () => Math.floor(Math.random() * 5))
);

export function AnalyticsScreen() {
  const [hoveredRadial, setHoveredRadial] = useState<number | null>(null);
  const [hoveredCell, setHoveredCell] = useState<{ r: number; c: number } | null>(null);

  return (
    <div className="space-y-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 150, damping: 20 }}
      >
        <h1 style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }}>
          Analytics
        </h1>
      </motion.div>

      {/* Pace Line Chart */}
      <LiquidGlassCard delay={1} hero>
        <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }}>
          Weekly Pace
        </span>
        <div className="mt-3">
          <PaceChart data={paceData} />
        </div>
      </LiquidGlassCard>

      {/* Exam Projection Cards */}
      <div className="grid grid-cols-2 gap-3">
        <LiquidGlassCard delay={3} glowColor="rgba(245,158,11,0.15)">
          <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: "#6B7280" }}>
            At 8.3/day
          </span>
          <div style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 20, color: "#F4F4FF", marginTop: 4 }}>
            May 8
          </div>
          <span className="px-2 py-0.5 rounded-full" style={{ fontSize: 11, fontFamily: "Inter", fontWeight: 600, background: "rgba(245,158,11,0.15)", color: "#F59E0B" }}>
            ⚠️ Cutting it close
          </span>
          <div className="mt-2">
            <AnimatedProgressBar progress={75} color="#F59E0B" delay={4} height={3} />
          </div>
        </LiquidGlassCard>

        <LiquidGlassCard delay={4} glowColor="rgba(34,197,94,0.15)">
          <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: "#6B7280" }}>
            At 10/day
          </span>
          <div style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 20, color: "#F4F4FF", marginTop: 4 }}>
            May 1
          </div>
          <span className="px-2 py-0.5 rounded-full" style={{ fontSize: 11, fontFamily: "Inter", fontWeight: 600, background: "rgba(34,197,94,0.15)", color: "#22C55E" }}>
            ✅ On track
          </span>
          <div className="mt-2">
            <AnimatedProgressBar progress={92} color="#22C55E" delay={5} height={3} />
          </div>
        </LiquidGlassCard>
      </div>

      {/* Subject Radial Mini Charts */}
      <LiquidGlassCard delay={5}>
        <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }}>
          Subject Progress
        </span>
        <div className="mt-3 grid grid-cols-3 gap-4">
          {subjectRadials.map((s, i) => (
            <motion.div
              key={s.name}
              className="flex flex-col items-center gap-1 cursor-pointer"
              whileTap={{ scale: 1.05 }}
              onHoverStart={() => setHoveredRadial(i)}
              onHoverEnd={() => setHoveredRadial(null)}
              animate={{ scale: hoveredRadial === i ? 1.05 : 1 }}
              transition={{ type: "spring", stiffness: 300, damping: 20 }}
            >
              <MiniDonut progress={s.progress} color={s.color} delay={i} />
              <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 11, color: "#6B7280" }}>
                {s.name}
              </span>
            </motion.div>
          ))}
        </div>
      </LiquidGlassCard>

      {/* Heatmap */}
      <LiquidGlassCard delay={7}>
        <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }}>
          Study Heatmap
        </span>
        <div className="mt-3 flex flex-col gap-1.5 relative">
          {heatmapData.map((row, ri) => (
            <div key={ri} className="flex gap-1.5">
              {row.map((val, ci) => (
                <motion.div
                  key={ci}
                  className="flex-1 rounded-md relative cursor-pointer"
                  style={{
                    aspectRatio: "1",
                    background: val === 0
                      ? "rgba(255,255,255,0.04)"
                      : `rgba(99,102,241,${0.15 + val * 0.18})`,
                    border: "1px solid rgba(99,102,241,0.1)",
                  }}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.6 + ri * 0.08 + ci * 0.04 }}
                  whileTap={{ scale: 0.9 }}
                  onClick={() => setHoveredCell(hoveredCell?.r === ri && hoveredCell?.c === ci ? null : { r: ri, c: ci })}
                >
                  {hoveredCell?.r === ri && hoveredCell?.c === ci && (
                    <motion.div
                      initial={{ opacity: 0, y: 10, scale: 0.8 }}
                      animate={{ opacity: 1, y: -32, scale: 1 }}
                      transition={{ type: "spring", stiffness: 300, damping: 20 }}
                      className="absolute left-1/2 -translate-x-1/2 px-2 py-1 rounded-lg z-20 whitespace-nowrap"
                      style={{
                        background: "rgba(14,14,26,0.9)",
                        border: "1px solid rgba(99,102,241,0.3)",
                        fontSize: 10,
                        fontFamily: "Inter",
                        fontWeight: 500,
                        color: "#818CF8",
                      }}
                    >
                      {val}h studied
                    </motion.div>
                  )}
                </motion.div>
              ))}
            </div>
          ))}
        </div>
        <div className="mt-2 flex items-center justify-end gap-1">
          <span style={{ fontFamily: "Inter", fontSize: 10, color: "#6B7280" }}>Less</span>
          {[0, 1, 2, 3, 4].map((v) => (
            <div
              key={v}
              className="w-3 h-3 rounded-sm"
              style={{
                background: v === 0 ? "rgba(255,255,255,0.04)" : `rgba(99,102,241,${0.15 + v * 0.18})`,
              }}
            />
          ))}
          <span style={{ fontFamily: "Inter", fontSize: 10, color: "#6B7280" }}>More</span>
        </div>
      </LiquidGlassCard>
    </div>
  );
}

function PaceChart({ data }: { data: typeof paceData }) {
  const maxVal = 14;
  const w = 280;
  const h = 120;
  const padding = 10;

  const getX = (i: number) => padding + (i / (data.length - 1)) * (w - padding * 2);
  const getY = (v: number) => h - padding - ((v / maxVal) * (h - padding * 2));

  const linePath = data.map((d, i) => `${i === 0 ? "M" : "L"} ${getX(i)} ${getY(d.pages)}`).join(" ");
  const targetPath = data.map((d, i) => `${i === 0 ? "M" : "L"} ${getX(i)} ${getY(d.target)}`).join(" ");
  const areaPath = `${linePath} L ${getX(data.length - 1)} ${h - padding} L ${getX(0)} ${h - padding} Z`;

  return (
    <svg width="100%" viewBox={`0 0 ${w} ${h + 20}`} className="overflow-visible">
      <defs>
        <linearGradient id="area-grad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#6366F1" stopOpacity={0.3} />
          <stop offset="100%" stopColor="#6366F1" stopOpacity={0} />
        </linearGradient>
      </defs>

      {/* Area fill */}
      <motion.path
        d={areaPath}
        fill="url(#area-grad)"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1, duration: 0.8 }}
      />

      {/* Target line */}
      <motion.path
        d={targetPath}
        fill="none"
        stroke="#F59E0B"
        strokeWidth={1.5}
        strokeDasharray="4 4"
        initial={{ pathLength: 0 }}
        animate={{ pathLength: 1 }}
        transition={{ duration: 1, delay: 0.3, ease: "easeOut" }}
      />

      {/* Main line */}
      <motion.path
        d={linePath}
        fill="none"
        stroke="#6366F1"
        strokeWidth={2.5}
        strokeLinecap="round"
        initial={{ pathLength: 0 }}
        animate={{ pathLength: 1 }}
        transition={{ duration: 1, delay: 0.3, ease: "easeOut" }}
        style={{ filter: "drop-shadow(0 0 6px rgba(99,102,241,0.5))" }}
      />

      {/* Data dots */}
      {data.map((d, i) => (
        <motion.circle
          key={i}
          cx={getX(i)}
          cy={getY(d.pages)}
          r={4}
          fill="#6366F1"
          stroke="#0E0E1A"
          strokeWidth={2}
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: "spring", stiffness: 300, damping: 15, delay: 1.2 + i * 0.08 }}
          style={{ filter: "drop-shadow(0 0 4px rgba(99,102,241,0.6))" }}
        />
      ))}

      {/* Day labels */}
      {data.map((d, i) => (
        <text
          key={`label-${i}`}
          x={getX(i)}
          y={h + 14}
          textAnchor="middle"
          style={{ fontSize: 10, fontFamily: "Inter", fill: "#6B7280" }}
        >
          {d.day}
        </text>
      ))}
    </svg>
  );
}

function MiniDonut({ progress, color, delay }: { progress: number; color: string; delay: number }) {
  const r = 22;
  const circ = 2 * Math.PI * r;
  const offset = circ - (progress / 100) * circ;

  return (
    <div className="relative">
      <svg width={56} height={56} viewBox="0 0 56 56">
        <circle cx={28} cy={28} r={r} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth={4} />
        <motion.circle
          cx={28}
          cy={28}
          r={r}
          fill="none"
          stroke={color}
          strokeWidth={4}
          strokeLinecap="round"
          strokeDasharray={circ}
          initial={{ strokeDashoffset: circ }}
          animate={{ strokeDashoffset: offset }}
          transition={{ type: "spring", stiffness: 40, damping: 10, delay: 0.5 + delay * 0.1 }}
          style={{
            filter: `drop-shadow(0 0 4px ${color}60)`,
            transform: "rotate(-90deg)",
            transformOrigin: "center",
          }}
        />
      </svg>
      <div className="absolute inset-0 flex items-center justify-center">
        <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 11, color: "#F4F4FF" }}>
          <AnimatedNumber value={progress} suffix="%" />
        </span>
      </div>
    </div>
  );
}
