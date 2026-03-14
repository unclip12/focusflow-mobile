import { motion, AnimatePresence } from "motion/react";
import { LiquidGlassCard } from "../LiquidGlassCard";
import { AnimatedNumber } from "../AnimatedNumber";
import { AnimatedProgressBar } from "../AnimatedProgressBar";
import { Plus, Clock, BookOpen, Brain, Microscope, Coffee, X } from "lucide-react";
import { useState } from "react";

const entries = [
  { time: "07:00 – 09:30", label: "FA Reading", icon: BookOpen, duration: "2h 30min", color: "#6366F1", auto: true },
  { time: "09:45 – 10:45", label: "Anki Review", icon: Brain, duration: "1h 00min", color: "#818CF8", auto: true },
  { time: "11:00 – 12:15", label: "Sketchy Micro", icon: Microscope, duration: "1h 15min", color: "#14B8A6", auto: true },
  { time: "13:00 – 13:30", label: "Break", icon: Coffee, duration: "30min", color: "#6B7280", auto: false },
  { time: "14:00 – 14:25", label: "Anki (extra)", icon: Brain, duration: "25min", color: "#818CF8", auto: false },
];

const categories = ["All", "Study", "Break", "Manual", "Auto"];

export function TimeLoggerScreen() {
  const [activeCategory, setActiveCategory] = useState("All");
  const [showSheet, setShowSheet] = useState(false);

  return (
    <div className="space-y-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 150, damping: 20 }}
      >
        <h1 style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }}>
          Time Logger
        </h1>
      </motion.div>

      {/* Top Stat */}
      <LiquidGlassCard delay={1} hero glowColor="rgba(99,102,241,0.2)">
        <div className="flex items-center gap-3">
          <motion.div
            animate={{ rotate: [0, 360] }}
            transition={{ duration: 8, repeat: Infinity, ease: "linear" }}
          >
            <Clock size={32} color="#6366F1" />
          </motion.div>
          <div>
            <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 13, color: "#6B7280" }}>
              Total today
            </span>
            <div style={{ fontFamily: "Inter", fontWeight: 800, fontSize: 34, color: "#F4F4FF" }}>
              <AnimatedNumber value={5} suffix="h " /><AnimatedNumber value={40} suffix="min" />
            </div>
          </div>
        </div>
        <div className="mt-3">
          <AnimatedProgressBar progress={71} color="#6366F1" delay={2} height={5} />
          <div className="flex justify-between mt-1">
            <span style={{ fontFamily: "Inter", fontSize: 11, color: "#6B7280" }}>0h</span>
            <span style={{ fontFamily: "Inter", fontSize: 11, color: "#6B7280" }}>8h goal</span>
          </div>
        </div>
      </LiquidGlassCard>

      {/* Category chips */}
      <div className="flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth: "none" }}>
        {categories.map((c) => (
          <motion.button
            key={c}
            onClick={() => setActiveCategory(c)}
            whileTap={{ scale: 0.9 }}
            className="px-3.5 py-1.5 rounded-full whitespace-nowrap relative overflow-hidden"
            style={{
              background: activeCategory === c ? "rgba(99,102,241,0.25)" : "rgba(255,255,255,0.06)",
              border: `1px solid ${activeCategory === c ? "rgba(99,102,241,0.4)" : "rgba(255,255,255,0.08)"}`,
            }}
          >
            {activeCategory === c && (
              <motion.div
                layoutId="cat-pill"
                className="absolute inset-0 rounded-full"
                style={{ background: "rgba(99,102,241,0.15)" }}
                transition={{ type: "spring", stiffness: 300, damping: 25 }}
              />
            )}
            <span className="relative z-10" style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: activeCategory === c ? "#818CF8" : "#6B7280" }}>
              {c}
            </span>
          </motion.button>
        ))}
      </div>

      {/* Entry List */}
      <div className="space-y-3">
        {entries.map((entry, i) => (
          <motion.div
            key={entry.label + entry.time}
            initial={{ opacity: 0, x: -30 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ type: "spring", stiffness: 150, damping: 20, delay: 0.2 + i * 0.06 }}
          >
            <LiquidGlassCard delay={0}>
              <div className="flex items-center gap-3">
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center"
                  style={{ background: `${entry.color}20`, border: `1px solid ${entry.color}30` }}
                >
                  <entry.icon size={18} color={entry.color} strokeWidth={1.5} />
                </div>
                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 14, color: "#F4F4FF" }}>
                      {entry.label}
                    </span>
                    <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 14, color: entry.color }}>
                      {entry.duration}
                    </span>
                  </div>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 12, color: "#6B7280" }}>
                      {entry.time}
                    </span>
                    {entry.auto && (
                      <span
                        className="px-1.5 py-0.5 rounded"
                        style={{ fontSize: 9, fontFamily: "Inter", fontWeight: 600, background: "rgba(99,102,241,0.15)", color: "#818CF8" }}
                      >
                        AUTO
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </LiquidGlassCard>
          </motion.div>
        ))}
      </div>

      {/* FAB */}
      <motion.button
        className="fixed bottom-24 right-5 w-14 h-14 rounded-full flex items-center justify-center z-40"
        style={{ background: "linear-gradient(135deg, #6366F1, #8B5CF6)", boxShadow: "0 0 30px rgba(99,102,241,0.4)" }}
        whileTap={{ scale: 0.9 }}
        onClick={() => setShowSheet(true)}
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

      {/* Bottom Sheet */}
      <AnimatePresence>
        {showSheet && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 z-50"
              style={{ background: "rgba(0,0,0,0.5)", backdropFilter: "blur(8px)" }}
              onClick={() => setShowSheet(false)}
            />
            <motion.div
              initial={{ y: "100%" }}
              animate={{ y: 0 }}
              exit={{ y: "100%" }}
              transition={{ type: "spring", stiffness: 200, damping: 25 }}
              className="fixed bottom-0 left-0 right-0 z-50 rounded-t-3xl p-6"
              style={{
                background: "rgba(14,14,26,0.95)",
                backdropFilter: "blur(40px)",
                border: "1px solid rgba(99,102,241,0.2)",
                borderBottom: "none",
              }}
            >
              <div className="flex justify-between items-center mb-6">
                <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 18, color: "#F4F4FF" }}>
                  Add Manual Entry
                </span>
                <motion.button whileTap={{ scale: 0.9 }} onClick={() => setShowSheet(false)}>
                  <X size={20} color="#6B7280" />
                </motion.button>
              </div>

              <div className="space-y-4">
                <div>
                  <label style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#6B7280", display: "block", marginBottom: 6 }}>
                    Activity
                  </label>
                  <motion.input
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.1 }}
                    className="w-full px-4 py-3 rounded-xl outline-none"
                    style={{
                      background: "rgba(255,255,255,0.06)",
                      border: "1px solid rgba(99,102,241,0.2)",
                      fontFamily: "Inter",
                      fontSize: 14,
                      color: "#F4F4FF",
                    }}
                    placeholder="e.g., Extra revision"
                  />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#6B7280", display: "block", marginBottom: 6 }}>
                      Start Time
                    </label>
                    <motion.input
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.15 }}
                      type="time"
                      className="w-full px-4 py-3 rounded-xl outline-none"
                      style={{ background: "rgba(255,255,255,0.06)", border: "1px solid rgba(99,102,241,0.2)", fontFamily: "Inter", fontSize: 14, color: "#F4F4FF" }}
                    />
                  </div>
                  <div>
                    <label style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#6B7280", display: "block", marginBottom: 6 }}>
                      End Time
                    </label>
                    <motion.input
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.2 }}
                      type="time"
                      className="w-full px-4 py-3 rounded-xl outline-none"
                      style={{ background: "rgba(255,255,255,0.06)", border: "1px solid rgba(99,102,241,0.2)", fontFamily: "Inter", fontSize: 14, color: "#F4F4FF" }}
                    />
                  </div>
                </div>
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  className="w-full py-3.5 rounded-2xl"
                  style={{ background: "linear-gradient(135deg, #6366F1, #8B5CF6)" }}
                >
                  <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 15, color: "#fff" }}>
                    Save Entry
                  </span>
                </motion.button>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}
