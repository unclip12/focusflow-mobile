import { motion, AnimatePresence } from "motion/react";
import { LiquidGlassCard } from "../LiquidGlassCard";
import { useState, useEffect } from "react";
import { Terminal, Check, Sparkles, BookOpen, Brain, ClipboardList, BarChart3 } from "lucide-react";
import confetti from "canvas-confetti";

const sampleJSON = `{
  "actions": [
    { "type": "mark_read", "pages": "50-59" },
    { "type": "anki_done", "pages": "46-49" },
    { "type": "add_task", "title": "Cook lunch",
      "time": "13:00-15:00" },
    { "type": "uworld", "subject": "Biochemistry",
      "questions": 10, "correct": 70 }
  ]
}`;

const previewActions = [
  { icon: BookOpen, text: "Mark FA Pages 50–59 as Read", emoji: "📖", color: "#6366F1" },
  { icon: Brain, text: "Anki done for Pages 46–49", emoji: "🧠", color: "#818CF8" },
  { icon: ClipboardList, text: "Add task: Cook lunch 13:00–15:00", emoji: "📋", color: "#F59E0B" },
  { icon: BarChart3, text: "UWorld: Biochemistry 10Qs — 70% correct", emoji: "📊", color: "#22C55E" },
];

export function ClaudeImportScreen() {
  const [typedCode, setTypedCode] = useState("");
  const [showPreview, setShowPreview] = useState(false);
  const [executing, setExecuting] = useState(false);
  const [done, setDone] = useState(false);

  useEffect(() => {
    let i = 0;
    const interval = setInterval(() => {
      if (i <= sampleJSON.length) {
        setTypedCode(sampleJSON.slice(0, i));
        i++;
        if (i > sampleJSON.length) {
          setTimeout(() => setShowPreview(true), 500);
        }
      } else {
        clearInterval(interval);
      }
    }, 15);
    return () => clearInterval(interval);
  }, []);

  const handleExecute = () => {
    setExecuting(true);
    setTimeout(() => {
      setExecuting(false);
      setDone(true);
      confetti({ particleCount: 80, spread: 100, origin: { y: 0.6 }, colors: ["#6366F1", "#818CF8", "#22C55E"] });
    }, 1500);
  };

  return (
    <div className="space-y-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 150, damping: 20 }}
      >
        <div className="flex items-center gap-2">
          <Terminal size={22} color="#818CF8" />
          <h1 style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }}>
            Claude Import
          </h1>
        </div>
        <p style={{ fontFamily: "Inter", fontSize: 13, color: "#6B7280", marginTop: 4 }}>
          Paste AI-generated JSON to auto-update your study data
        </p>
      </motion.div>

      {/* Code Editor */}
      <LiquidGlassCard delay={1} hero>
        <div
          className="rounded-xl p-4 overflow-auto"
          style={{
            background: "rgba(14,14,26,0.8)",
            border: "1px solid rgba(99,102,241,0.2)",
            maxHeight: 220,
            fontFamily: "'SF Mono', 'Fira Code', monospace",
            fontSize: 12,
            lineHeight: 1.6,
          }}
        >
          <pre className="whitespace-pre-wrap">
            {typedCode.split("").map((char, i) => {
              let color = "#F4F4FF";
              if (char === '"' || (typedCode[i - 1] === '"' && char !== ":")) color = "#818CF8";
              if (char === ":" || char === "{" || char === "}" || char === "[" || char === "]") color = "#6B7280";
              if (!isNaN(Number(char)) && char !== " " && char !== "\n") color = "#22C55E";
              return (
                <motion.span
                  key={i}
                  initial={{ opacity: 0, scale: 0.5 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ type: "spring", stiffness: 500, damping: 30 }}
                  style={{ color }}
                >
                  {char}
                </motion.span>
              );
            })}
            <motion.span
              animate={{ opacity: [1, 0] }}
              transition={{ duration: 0.5, repeat: Infinity }}
              style={{ color: "#6366F1" }}
            >
              █
            </motion.span>
          </pre>
        </div>
      </LiquidGlassCard>

      {/* Preview Cards */}
      <AnimatePresence>
        {showPreview && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="space-y-3"
          >
            <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }}>
              PARSED ACTIONS
            </span>
            {previewActions.map((action, i) => (
              <motion.div
                key={action.text}
                initial={{ opacity: 0, x: -40, scale: 0.9 }}
                animate={{ opacity: 1, x: 0, scale: 1 }}
                transition={{ type: "spring", stiffness: 180, damping: 18, delay: i * 0.1 }}
                whileTap={{ scale: 0.97 }}
                className="flex items-center gap-3 px-4 py-3 rounded-xl relative overflow-hidden"
                style={{
                  background: "rgba(255,255,255,0.06)",
                  backdropFilter: "blur(20px)",
                  border: "1px solid rgba(99,102,241,0.2)",
                }}
              >
                <div
                  className="absolute left-0 top-0 bottom-0 w-1 rounded-full"
                  style={{ background: action.color }}
                />
                <span style={{ fontSize: 18 }}>{action.emoji}</span>
                <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#F4F4FF", flex: 1 }}>
                  {action.text}
                </span>
                {done && (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ type: "spring", stiffness: 300, damping: 15 }}
                  >
                    <Check size={16} color="#22C55E" />
                  </motion.div>
                )}
              </motion.div>
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Execute Button */}
      {showPreview && !done && (
        <motion.button
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ type: "spring", stiffness: 150, damping: 20, delay: 0.5 }}
          whileTap={{ scale: 0.95 }}
          onClick={handleExecute}
          className="w-full py-4 rounded-2xl flex items-center justify-center gap-2 relative overflow-hidden"
          style={{
            background: "linear-gradient(135deg, #6366F1, #8B5CF6)",
            boxShadow: "0 0 30px rgba(99,102,241,0.3)",
          }}
        >
          <motion.div
            className="absolute inset-0 rounded-2xl"
            style={{ border: "2px solid rgba(99,102,241,0.4)" }}
            animate={{ scale: [1, 1.05, 1], opacity: [0.3, 0, 0.3] }}
            transition={{ duration: 2, repeat: Infinity }}
          />
          {executing ? (
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
            >
              <Sparkles size={20} color="#fff" />
            </motion.div>
          ) : (
            <Sparkles size={20} color="#fff" />
          )}
          <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 16, color: "#fff" }}>
            {executing ? "Executing..." : "Execute All Actions"}
          </span>
        </motion.button>
      )}

      {done && (
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ type: "spring", stiffness: 150, damping: 15 }}
          className="text-center py-4"
        >
          <span style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 18, color: "#22C55E" }}>
            ✅ All actions executed successfully!
          </span>
        </motion.div>
      )}
    </div>
  );
}
