import { motion } from "motion/react";
import { LiquidGlassCard } from "../LiquidGlassCard";
import { AnimatedNumber } from "../AnimatedNumber";
import { Plus, Lock, BookOpen, Brain, Microscope, Target, AlertTriangle } from "lucide-react";
import { useState } from "react";

const prayerBlocks = [
  { name: "Fajr", time: "05:25" },
  { name: "Dhuhr", time: "12:38" },
  { name: "Asr", time: "16:08" },
  { name: "Maghrib", time: "18:12" },
  { name: "Isha", time: "19:38" },
];

const studyBlocks = [
  {
    title: "FA Reading",
    subtitle: "FA Pages 50–59 | Biochemistry",
    time: "07:00 – 09:30",
    icon: BookOpen,
    gradient: "linear-gradient(135deg, rgba(99,102,241,0.2), rgba(139,92,246,0.2))",
    border: "rgba(139,92,246,0.35)",
    iconColor: "#8B5CF6",
  },
  {
    title: "Anki Review",
    subtitle: "Flashcards for Pages 46–49",
    time: "09:45 – 10:45",
    icon: Brain,
    gradient: "linear-gradient(135deg, rgba(245,158,11,0.15), rgba(245,158,11,0.08))",
    border: "rgba(245,158,11,0.35)",
    iconColor: "#F59E0B",
  },
  {
    title: "Sketchy Micro",
    subtitle: "Staphylococcus + Streptococcus",
    time: "11:00 – 12:30",
    icon: Microscope,
    gradient: "linear-gradient(135deg, rgba(20,184,166,0.15), rgba(20,184,166,0.08))",
    border: "rgba(20,184,166,0.35)",
    iconColor: "#14B8A6",
  },
  {
    title: "UWorld Practice",
    subtitle: "Biochemistry Block — 20 Qs",
    time: "15:00 – 16:00",
    icon: Target,
    gradient: "linear-gradient(135deg, rgba(34,197,94,0.15), rgba(34,197,94,0.08))",
    border: "rgba(34,197,94,0.35)",
    iconColor: "#22C55E",
  },
];

export function PlanScreen() {
  const [showFab, setShowFab] = useState(true);

  return (
    <div className="space-y-4">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 150, damping: 20 }}
      >
        <h1 style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }}>
          Friday, March 13
        </h1>
        <div className="flex items-center gap-2 mt-1">
          <motion.span
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: "spring", stiffness: 200, damping: 15, delay: 0.2 }}
            className="px-3 py-1 rounded-full"
            style={{ background: "rgba(99,102,241,0.2)", border: "1px solid rgba(99,102,241,0.3)" }}
          >
            <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 12, color: "#818CF8" }}>
              Available: 7h 20min
            </span>
          </motion.span>
        </div>
      </motion.div>

      {/* Over-budget warning */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 150, damping: 20, delay: 0.3 }}
        className="flex items-center gap-2 px-4 py-2.5 rounded-2xl"
        style={{
          background: "rgba(245,158,11,0.12)",
          border: "1px solid rgba(245,158,11,0.3)",
          backdropFilter: "blur(20px)",
        }}
      >
        <motion.div
          animate={{ scale: [1, 1.1, 1] }}
          transition={{ duration: 1.5, repeat: Infinity }}
        >
          <AlertTriangle size={16} color="#F59E0B" />
        </motion.div>
        <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#F59E0B" }}>
          40 min over budget — consider trimming a block
        </span>
      </motion.div>

      {/* Prayer Blocks */}
      <div>
        <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }}>
          PRAYERS
        </span>
        <div className="mt-2 space-y-2">
          {prayerBlocks.map((p, i) => (
            <motion.div
              key={p.name}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ type: "spring", stiffness: 150, damping: 20, delay: 0.2 + i * 0.05 }}
              className="flex items-center gap-3 px-4 py-3 rounded-xl"
              style={{
                background: "rgba(99,102,241,0.06)",
                border: "1px solid rgba(99,102,241,0.15)",
                borderLeft: "2px dashed rgba(99,102,241,0.4)",
                backdropFilter: "blur(16px)",
              }}
            >
              <span style={{ fontSize: 14 }}>🕌</span>
              <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 14, color: "#F4F4FF", flex: 1 }}>
                {p.name}
              </span>
              <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#818CF8" }}>
                {p.time}
              </span>
              <Lock size={12} color="#6B7280" />
            </motion.div>
          ))}
        </div>
      </div>

      {/* Study Blocks */}
      <div>
        <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }}>
          STUDY BLOCKS
        </span>
        <div className="mt-2 space-y-3">
          {studyBlocks.map((block, i) => (
            <motion.div
              key={block.title}
              initial={{ opacity: 0, y: 30, scale: 0.92 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ type: "spring", stiffness: 180, damping: 20, delay: 0.4 + i * 0.08 }}
              whileTap={{ scale: 0.97 }}
              className="rounded-2xl p-4 relative overflow-hidden"
              style={{
                background: block.gradient,
                backdropFilter: "blur(24px)",
                border: `1px solid ${block.border}`,
                boxShadow: `0 0 20px ${block.border}40`,
              }}
            >
              <div className="flex items-start gap-3">
                <motion.div
                  animate={{ rotate: block.title === "Anki Review" ? [0, 180, 360] : 0 }}
                  transition={{ duration: 2, repeat: block.title === "Anki Review" ? Infinity : 0, repeatDelay: 3 }}
                  style={{ color: block.iconColor }}
                >
                  <block.icon size={22} strokeWidth={1.5} />
                </motion.div>
                <div className="flex-1">
                  <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF", display: "block" }}>
                    {block.title}
                  </span>
                  <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 12, color: "#6B7280", display: "block", marginTop: 2 }}>
                    {block.subtitle}
                  </span>
                </div>
                <span
                  className="px-2 py-1 rounded-lg"
                  style={{
                    fontFamily: "Inter",
                    fontWeight: 600,
                    fontSize: 11,
                    color: block.iconColor,
                    background: `${block.iconColor}15`,
                  }}
                >
                  {block.time}
                </span>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Time Calculator Strip */}
      <LiquidGlassCard delay={8}>
        <div className="flex items-center justify-between">
          <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#6B7280" }}>
            Total Scheduled
          </span>
          <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 18, color: "#F4F4FF" }}>
            <AnimatedNumber value={8} suffix="h " /><AnimatedNumber value={0} suffix="min" />
          </span>
        </div>
      </LiquidGlassCard>

      {/* FAB */}
      <motion.button
        className="fixed bottom-24 right-5 w-14 h-14 rounded-full flex items-center justify-center z-40"
        style={{
          background: "linear-gradient(135deg, #6366F1, #8B5CF6)",
          boxShadow: "0 0 30px rgba(99,102,241,0.4)",
        }}
        whileTap={{ scale: 0.9 }}
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ type: "spring", stiffness: 200, damping: 15, delay: 0.8 }}
      >
        <motion.div
          className="absolute inset-0 rounded-full"
          style={{ border: "2px solid rgba(99,102,241,0.5)" }}
          animate={{ scale: [1, 1.4, 1], opacity: [0.5, 0, 0.5] }}
          transition={{ duration: 2, repeat: Infinity }}
        />
        <Plus size={24} color="#fff" />
      </motion.button>
    </div>
  );
}
