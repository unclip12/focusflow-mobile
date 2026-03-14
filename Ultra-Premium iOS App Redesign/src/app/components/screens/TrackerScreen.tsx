import { motion, AnimatePresence } from "motion/react";
import { LiquidGlassCard } from "../LiquidGlassCard";
import { AnimatedProgressBar } from "../AnimatedProgressBar";
import { AnimatedNumber } from "../AnimatedNumber";
import { useState } from "react";
import { ChevronRight, Check, Play, Plus } from "lucide-react";

const tabs = ["FA 2025", "Sketchy", "Pathoma", "UWorld"];

const subjects = [
  { name: "Biochemistry", pages: "1–89", progress: 67, read: 60, total: 89, color: "#6366F1" },
  { name: "Immunology", pages: "90–120", progress: 45, read: 14, total: 30, color: "#818CF8" },
  { name: "Microbiology", pages: "121–195", progress: 30, read: 22, total: 75, color: "#8B5CF6" },
  { name: "Pathology", pages: "196–400", progress: 12, read: 25, total: 205, color: "#A78BFA" },
  { name: "Pharmacology", pages: "401–490", progress: 55, read: 49, total: 90, color: "#7C3AED" },
];

const sketchyOrgs = [
  { name: "Staphylococcus", status: 2, color: "#22C55E" },
  { name: "Streptococcus", status: 1, color: "#F59E0B" },
  { name: "Enterococcus", status: 0, color: "#6B7280" },
  { name: "Neisseria", status: 2, color: "#22C55E" },
  { name: "Haemophilus", status: 1, color: "#F59E0B" },
  { name: "Clostridium", status: 0, color: "#6B7280" },
];

const pathomaChapters = [
  { name: "Ch 1: Growth Adaptations", watched: true, videos: 4 },
  { name: "Ch 2: Neoplasia", watched: true, videos: 6 },
  { name: "Ch 3: Hemodynamics", watched: false, videos: 5 },
  { name: "Ch 4: Hematopathology", watched: false, videos: 8 },
  { name: "Ch 5: RBC Disorders", watched: false, videos: 7 },
];

const uworldSubjects = [
  { name: "Biochemistry", qs: 45, correct: 78 },
  { name: "Microbiology", qs: 30, correct: 65 },
  { name: "Pharmacology", qs: 25, correct: 72 },
  { name: "Pathology", qs: 60, correct: 60 },
];

export function TrackerScreen() {
  const [activeTab, setActiveTab] = useState(0);
  const [activeFilter, setActiveFilter] = useState("All");
  const [expandedChapter, setExpandedChapter] = useState<number | null>(null);
  const [sketchyMode, setSketchyMode] = useState<"Micro" | "Pharma">("Micro");

  return (
    <div className="space-y-4">
      {/* Tab Bar */}
      <div className="flex gap-1 p-1 rounded-2xl" style={{ background: "rgba(255,255,255,0.06)" }}>
        {tabs.map((tab, i) => (
          <motion.button
            key={tab}
            onClick={() => setActiveTab(i)}
            className="flex-1 py-2 rounded-xl relative"
            whileTap={{ scale: 0.95 }}
          >
            {activeTab === i && (
              <motion.div
                layoutId="tab-bg"
                className="absolute inset-0 rounded-xl"
                style={{
                  background: "rgba(99,102,241,0.2)",
                  border: "1px solid rgba(99,102,241,0.3)",
                }}
                transition={{ type: "spring", stiffness: 300, damping: 25 }}
              />
            )}
            <span
              className="relative z-10"
              style={{
                fontFamily: "Inter",
                fontWeight: activeTab === i ? 600 : 400,
                fontSize: 13,
                color: activeTab === i ? "#818CF8" : "#6B7280",
              }}
            >
              {tab}
            </span>
          </motion.button>
        ))}
      </div>

      <AnimatePresence mode="wait">
        <motion.div
          key={activeTab}
          initial={{ opacity: 0, x: 30 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -30 }}
          transition={{ type: "spring", stiffness: 200, damping: 25 }}
        >
          {activeTab === 0 && (
            <div className="space-y-3">
              {/* Subject Filter Pills */}
              <div className="flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth: "none" }}>
                {["All", ...subjects.map((s) => s.name.slice(0, 5))].map((f) => (
                  <motion.button
                    key={f}
                    onClick={() => setActiveFilter(f)}
                    whileTap={{ scale: 0.9 }}
                    className="px-3 py-1.5 rounded-full whitespace-nowrap"
                    style={{
                      background: activeFilter === f ? "rgba(99,102,241,0.25)" : "rgba(255,255,255,0.06)",
                      border: `1px solid ${activeFilter === f ? "rgba(99,102,241,0.4)" : "rgba(255,255,255,0.08)"}`,
                    }}
                  >
                    <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: activeFilter === f ? "#818CF8" : "#6B7280" }}>
                      {f}
                    </span>
                  </motion.button>
                ))}
              </div>

              {subjects.map((s, i) => (
                <LiquidGlassCard key={s.name} delay={i + 1}>
                  <div className="flex items-center justify-between mb-2">
                    <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF" }}>
                      {s.name}
                    </span>
                    <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 14, color: s.color }}>
                      <AnimatedNumber value={s.progress} suffix="%" />
                    </span>
                  </div>
                  <AnimatedProgressBar progress={s.progress} color={s.color} delay={i + 1} />
                  <div className="mt-2 flex justify-between">
                    <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 12, color: "#6B7280" }}>
                      Pages {s.pages}
                    </span>
                    <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: "#6B7280" }}>
                      {s.read}/{s.total} read
                    </span>
                  </div>
                </LiquidGlassCard>
              ))}
            </div>
          )}

          {activeTab === 1 && (
            <div className="space-y-3">
              {/* Micro / Pharma switcher */}
              <div className="flex gap-1 p-1 rounded-xl w-48" style={{ background: "rgba(255,255,255,0.06)" }}>
                {(["Micro", "Pharma"] as const).map((m) => (
                  <motion.button
                    key={m}
                    onClick={() => setSketchyMode(m)}
                    className="flex-1 py-1.5 rounded-lg relative"
                    whileTap={{ scale: 0.95 }}
                  >
                    {sketchyMode === m && (
                      <motion.div
                        layoutId="sketchy-pill"
                        className="absolute inset-0 rounded-lg"
                        style={{ background: "rgba(99,102,241,0.2)", border: "1px solid rgba(99,102,241,0.3)" }}
                        transition={{ type: "spring", stiffness: 300, damping: 25 }}
                      />
                    )}
                    <span className="relative z-10" style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: sketchyMode === m ? "#818CF8" : "#6B7280" }}>
                      {m}
                    </span>
                  </motion.button>
                ))}
              </div>

              {sketchyOrgs.map((org, i) => (
                <LiquidGlassCard key={org.name} delay={i + 1}>
                  <div className="flex items-center justify-between">
                    <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 14, color: "#F4F4FF" }}>
                      {org.name}
                    </span>
                    <div className="flex gap-1.5">
                      {[0, 1, 2].map((dot) => (
                        <motion.div
                          key={dot}
                          className="w-3 h-3 rounded-full"
                          initial={{ scale: 0 }}
                          animate={{ scale: 1 }}
                          transition={{ type: "spring", stiffness: 300, damping: 15, delay: 0.3 + i * 0.05 + dot * 0.1 }}
                          style={{
                            background: dot <= org.status ? org.color : "rgba(255,255,255,0.1)",
                            boxShadow: dot <= org.status && org.status === 2 ? `0 0 8px ${org.color}60` : undefined,
                          }}
                        />
                      ))}
                    </div>
                  </div>
                </LiquidGlassCard>
              ))}
            </div>
          )}

          {activeTab === 2 && (
            <div className="space-y-3">
              {pathomaChapters.map((ch, i) => (
                <LiquidGlassCard key={ch.name} delay={i + 1} onClick={() => setExpandedChapter(expandedChapter === i ? null : i)}>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      {ch.watched ? (
                        <Check size={18} color="#22C55E" />
                      ) : (
                        <motion.div
                          animate={{ scale: [1, 1.15, 1] }}
                          transition={{ duration: 1.5, repeat: Infinity }}
                        >
                          <Play size={18} color="#818CF8" />
                        </motion.div>
                      )}
                      <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 14, color: "#F4F4FF" }}>
                        {ch.name}
                      </span>
                    </div>
                    <motion.div animate={{ rotate: expandedChapter === i ? 90 : 0 }} transition={{ type: "spring", stiffness: 300, damping: 20 }}>
                      <ChevronRight size={16} color="#6B7280" />
                    </motion.div>
                  </div>
                  <AnimatePresence>
                    {expandedChapter === i && (
                      <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: "auto", opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        transition={{ type: "spring", stiffness: 200, damping: 25 }}
                        className="overflow-hidden"
                      >
                        <div className="pt-3 mt-3" style={{ borderTop: "1px solid rgba(255,255,255,0.06)" }}>
                          <span style={{ fontFamily: "Inter", fontSize: 12, color: "#6B7280" }}>
                            {ch.videos} videos · {ch.watched ? "Completed" : "In Progress"}
                          </span>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </LiquidGlassCard>
              ))}
            </div>
          )}

          {activeTab === 3 && (
            <div className="space-y-3">
              {uworldSubjects.map((s, i) => (
                <LiquidGlassCard key={s.name} delay={i + 1}>
                  <div className="flex items-center justify-between mb-2">
                    <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 14, color: "#F4F4FF" }}>
                      {s.name}
                    </span>
                    <span style={{
                      fontFamily: "Inter", fontWeight: 700, fontSize: 14,
                      color: s.correct >= 70 ? "#22C55E" : s.correct >= 60 ? "#F59E0B" : "#EF4444",
                    }}>
                      <AnimatedNumber value={s.correct} suffix="%" />
                    </span>
                  </div>
                  <AnimatedProgressBar
                    progress={s.correct}
                    color={s.correct >= 70 ? "#22C55E" : s.correct >= 60 ? "#F59E0B" : "#EF4444"}
                    delay={i + 1}
                  />
                  <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 12, color: "#6B7280", marginTop: 4, display: "block" }}>
                    {s.qs} questions attempted
                  </span>
                </LiquidGlassCard>
              ))}
              <motion.button
                whileTap={{ scale: 0.95 }}
                className="w-full py-3 rounded-2xl flex items-center justify-center gap-2"
                style={{
                  background: "rgba(99,102,241,0.15)",
                  border: "1px solid rgba(99,102,241,0.3)",
                  backdropFilter: "blur(20px)",
                }}
              >
                <Plus size={18} color="#818CF8" />
                <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 14, color: "#818CF8" }}>
                  Add Session
                </span>
              </motion.button>
            </div>
          )}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}
