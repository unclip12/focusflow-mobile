import { motion, useMotionValue, useTransform, AnimatePresence } from "motion/react";
import { LiquidGlassCard } from "../LiquidGlassCard";
import { AnimatedProgressBar } from "../AnimatedProgressBar";
import { useState, useCallback } from "react";
import { Check, X, RotateCcw } from "lucide-react";
import confetti from "canvas-confetti";

const revisionCards = [
  { front: "What enzyme is deficient in Phenylketonuria (PKU)?", back: "Phenylalanine hydroxylase — converts Phe → Tyr. Autosomal recessive. Musty body odor, intellectual disability, fair skin.", topic: "Biochemistry" },
  { front: "Describe the pathogenesis of Nephrotic Syndrome.", back: "Podocyte damage → loss of charge barrier → massive proteinuria (>3.5g/day) → hypoalbuminemia → edema + hyperlipidemia.", topic: "Pathology" },
  { front: "What is the mechanism of action of Metformin?", back: "Activates AMP-kinase → decreases hepatic gluconeogenesis, increases insulin sensitivity. No hypoglycemia risk. First-line for T2DM.", topic: "Pharmacology" },
  { front: "Name the layers of the adrenal cortex (outside → in).", back: "GFR — Glomerulosa (aldosterone), Fasciculata (cortisol), Reticularis (androgens). 'Salt, Sugar, Sex — the deeper you go, the sweeter it gets.'", topic: "Anatomy" },
];

export function RevisionScreen() {
  const [mode, setMode] = useState<"Morning" | "Evening">("Morning");
  const [currentIdx, setCurrentIdx] = useState(0);
  const [isFlipped, setIsFlipped] = useState(false);
  const [completed, setCompleted] = useState<number[]>([]);
  const [allDone, setAllDone] = useState(false);
  const x = useMotionValue(0);
  const rotate = useTransform(x, [-200, 200], [-15, 15]);
  const bgLeft = useTransform(x, [-200, 0], [0.3, 0]);
  const bgRight = useTransform(x, [0, 200], [0, 0.3]);

  const handleDragEnd = useCallback((_: any, info: { offset: { x: number } }) => {
    if (Math.abs(info.offset.x) > 100) {
      const direction = info.offset.x > 0 ? "right" : "left";
      setCompleted((prev) => [...prev, currentIdx]);
      if (direction === "right") {
        confetti({ particleCount: 30, spread: 60, origin: { y: 0.6 }, colors: ["#22C55E", "#6366F1"] });
      }
      setTimeout(() => {
        if (currentIdx < revisionCards.length - 1) {
          setCurrentIdx((p) => p + 1);
          setIsFlipped(false);
        } else {
          setAllDone(true);
          confetti({ particleCount: 100, spread: 120, origin: { y: 0.5 }, colors: ["#6366F1", "#818CF8", "#22C55E", "#F59E0B"] });
        }
      }, 300);
    }
  }, [currentIdx]);

  const progress = ((completed.length) / revisionCards.length) * 100;
  const card = revisionCards[currentIdx];

  return (
    <div className="space-y-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 150, damping: 20 }}
      >
        <h1 style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }}>
          Revision Hub
        </h1>
      </motion.div>

      {/* Mode Toggle */}
      <div className="flex gap-1 p-1 rounded-xl w-52" style={{ background: "rgba(255,255,255,0.06)" }}>
        {(["Morning", "Evening"] as const).map((m) => (
          <motion.button
            key={m}
            onClick={() => setMode(m)}
            className="flex-1 py-2 rounded-lg relative"
            whileTap={{ scale: 0.95 }}
          >
            {mode === m && (
              <motion.div
                layoutId="mode-pill"
                className="absolute inset-0 rounded-lg"
                style={{ background: "rgba(99,102,241,0.2)", border: "1px solid rgba(99,102,241,0.3)" }}
                transition={{ type: "spring", stiffness: 300, damping: 25 }}
              />
            )}
            <span className="relative z-10" style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: mode === m ? "#818CF8" : "#6B7280" }}>
              {m === "Morning" ? "🌅 " : "🌙 "}{m}
            </span>
          </motion.button>
        ))}
      </div>

      {/* Progress */}
      <LiquidGlassCard delay={1}>
        <div className="flex justify-between mb-2">
          <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#6B7280" }}>Progress</span>
          <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#818CF8" }}>
            {completed.length}/{revisionCards.length}
          </span>
        </div>
        <AnimatedProgressBar progress={progress} color="#6366F1" delay={1} />
      </LiquidGlassCard>

      {/* Card Area */}
      <AnimatePresence mode="wait">
        {allDone ? (
          <motion.div
            key="done"
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ type: "spring", stiffness: 150, damping: 15 }}
            className="flex flex-col items-center py-12"
          >
            <motion.div
              animate={{ scale: [1, 1.1, 1], rotate: [0, 5, -5, 0] }}
              transition={{ duration: 2, repeat: Infinity }}
              style={{ fontSize: 64 }}
            >
              🌟
            </motion.div>
            <h2 style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 22, color: "#F4F4FF", marginTop: 16, textAlign: "center" }}>
              Zero backlog. Clean slate.
            </h2>
            <p style={{ fontFamily: "Inter", fontSize: 14, color: "#6B7280", marginTop: 8 }}>
              All revision cards completed!
            </p>
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={() => { setCurrentIdx(0); setCompleted([]); setAllDone(false); setIsFlipped(false); }}
              className="mt-6 px-6 py-3 rounded-2xl flex items-center gap-2"
              style={{ background: "rgba(99,102,241,0.2)", border: "1px solid rgba(99,102,241,0.3)" }}
            >
              <RotateCcw size={16} color="#818CF8" />
              <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 14, color: "#818CF8" }}>Start Over</span>
            </motion.button>
          </motion.div>
        ) : (
          <motion.div
            key={currentIdx}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            transition={{ type: "spring", stiffness: 200, damping: 20 }}
            className="relative"
            style={{ perspective: "1000px", minHeight: 280 }}
          >
            {/* Swipe indicators */}
            <motion.div
              className="absolute left-0 top-0 bottom-0 w-16 rounded-l-2xl flex items-center justify-center"
              style={{ background: `rgba(239,68,68,${bgLeft.get()})`, opacity: bgLeft }}
            >
              <X size={24} color="#EF4444" />
            </motion.div>
            <motion.div
              className="absolute right-0 top-0 bottom-0 w-16 rounded-r-2xl flex items-center justify-center"
              style={{ background: `rgba(34,197,94,${bgRight.get()})`, opacity: bgRight }}
            >
              <Check size={24} color="#22C55E" />
            </motion.div>

            <motion.div
              drag="x"
              dragConstraints={{ left: 0, right: 0 }}
              dragElastic={0.8}
              onDragEnd={handleDragEnd}
              style={{ x, rotate }}
              onClick={() => setIsFlipped(!isFlipped)}
              className="cursor-grab active:cursor-grabbing"
            >
              <motion.div
                animate={{ rotateY: isFlipped ? 180 : 0 }}
                transition={{ type: "spring", stiffness: 200, damping: 20 }}
                style={{ transformStyle: "preserve-3d" }}
                className="relative"
              >
                {/* Front */}
                <div
                  className="rounded-2xl p-6 relative overflow-hidden"
                  style={{
                    background: "rgba(255,255,255,0.08)",
                    backdropFilter: "blur(40px)",
                    border: "1px solid rgba(99,102,241,0.3)",
                    boxShadow: "0 0 30px rgba(99,102,241,0.15)",
                    minHeight: 260,
                    backfaceVisibility: "hidden",
                  }}
                >
                  <motion.div
                    className="absolute inset-0 pointer-events-none"
                    style={{ background: "linear-gradient(105deg, transparent 40%, rgba(255,255,255,0.06) 50%, transparent 60%)", backgroundSize: "200% 100%" }}
                    animate={{ backgroundPosition: ["200% 0", "-200% 0"] }}
                    transition={{ duration: 3, repeat: Infinity, repeatDelay: 4, ease: "linear" }}
                  />
                  <span
                    className="px-2 py-0.5 rounded-full"
                    style={{ fontSize: 11, fontFamily: "Inter", fontWeight: 600, background: "rgba(99,102,241,0.2)", color: "#818CF8" }}
                  >
                    {card.topic}
                  </span>
                  <div className="mt-4" style={{ display: isFlipped ? "none" : "block" }}>
                    <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 18, color: "#F4F4FF", lineHeight: 1.5, display: "block" }}>
                      {card.front}
                    </span>
                    <p style={{ fontFamily: "Inter", fontSize: 12, color: "#6B7280", marginTop: 20 }}>
                      Tap to flip · Swipe right ✅ · Swipe left ⏭
                    </p>
                  </div>
                  <div className="mt-4" style={{ display: isFlipped ? "block" : "none", transform: "rotateY(180deg)" }}>
                    <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 15, color: "#F4F4FF", lineHeight: 1.6, display: "block" }}>
                      {card.back}
                    </span>
                  </div>
                </div>
              </motion.div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Card counter */}
      {!allDone && (
        <div className="flex justify-center gap-2">
          {revisionCards.map((_, i) => (
            <motion.div
              key={i}
              className="w-2 h-2 rounded-full"
              animate={{
                background: i === currentIdx ? "#6366F1" : completed.includes(i) ? "#22C55E" : "rgba(255,255,255,0.15)",
                scale: i === currentIdx ? 1.3 : 1,
              }}
              transition={{ type: "spring", stiffness: 300, damping: 20 }}
              style={{ boxShadow: i === currentIdx ? "0 0 8px rgba(99,102,241,0.5)" : undefined }}
            />
          ))}
        </div>
      )}
    </div>
  );
}
