import { motion } from "motion/react";
import { LiquidGlassCard } from "../LiquidGlassCard";
import { useState } from "react";
import {
  Calendar,
  Clock,
  Moon,
  Target,
  GripVertical,
  CloudUpload,
  Palette,
  ChevronRight,
  Minus,
  Plus,
  Sun,
  Monitor,
} from "lucide-react";

interface SettingSection {
  title: string;
  icon: any;
  items: SettingItem[];
}

interface SettingItem {
  label: string;
  value: string;
  type: "nav" | "toggle" | "stepper";
}

const sections: SettingSection[] = [
  {
    title: "Exam Dates",
    icon: Calendar,
    items: [
      { label: "FMGE", value: "Jun 28, 2026", type: "nav" },
      { label: "USMLE Step 1", value: "Jun 23, 2026", type: "nav" },
    ],
  },
  {
    title: "Prayer Times",
    icon: Clock,
    items: [
      { label: "Fajr", value: "05:25", type: "nav" },
      { label: "Dhuhr", value: "12:38", type: "nav" },
      { label: "Asr", value: "16:08", type: "nav" },
      { label: "Maghrib", value: "18:12", type: "nav" },
      { label: "Isha", value: "19:38", type: "nav" },
    ],
  },
  {
    title: "Sleep & Wake",
    icon: Moon,
    items: [
      { label: "Wake up", value: "05:00", type: "nav" },
      { label: "Sleep", value: "23:00", type: "nav" },
    ],
  },
];

export function SettingsScreen() {
  const [dailyGoal, setDailyGoal] = useState(10);
  const [theme, setTheme] = useState<"dark" | "light" | "system">("dark");
  const [backupEnabled, setBackupEnabled] = useState(false);

  return (
    <div className="space-y-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 150, damping: 20 }}
      >
        <h1 style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }}>
          Settings
        </h1>
      </motion.div>

      {sections.map((section, si) => (
        <div key={section.title}>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.1 + si * 0.1 }}
            className="flex items-center gap-2 mb-2"
          >
            <section.icon size={16} color="#818CF8" />
            <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }}>
              {section.title.toUpperCase()}
            </span>
            <motion.div
              className="flex-1 h-px"
              initial={{ scaleX: 0 }}
              animate={{ scaleX: 1 }}
              transition={{ delay: 0.3 + si * 0.1, duration: 0.5 }}
              style={{ transformOrigin: "left", background: "rgba(99,102,241,0.2)" }}
            />
          </motion.div>
          <LiquidGlassCard delay={si + 1}>
            <div className="space-y-0">
              {section.items.map((item, ii) => (
                <motion.div
                  key={item.label}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.2 + si * 0.1 + ii * 0.04 }}
                  className="flex items-center justify-between py-3"
                  style={{
                    borderBottom: ii < section.items.length - 1 ? "1px solid rgba(255,255,255,0.05)" : undefined,
                  }}
                >
                  <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 14, color: "#F4F4FF" }}>
                    {item.label}
                  </span>
                  <div className="flex items-center gap-2">
                    <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 13, color: "#818CF8" }}>
                      {item.value}
                    </span>
                    <ChevronRight size={14} color="#6B7280" />
                  </div>
                </motion.div>
              ))}
            </div>
          </LiquidGlassCard>
        </div>
      ))}

      {/* Daily Goals Stepper */}
      <div>
        <motion.div
          className="flex items-center gap-2 mb-2"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
        >
          <Target size={16} color="#818CF8" />
          <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }}>
            DAILY GOALS
          </span>
        </motion.div>
        <LiquidGlassCard delay={5}>
          <div className="flex items-center justify-between">
            <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 14, color: "#F4F4FF" }}>
              FA Pages per day
            </span>
            <div className="flex items-center gap-3">
              <motion.button
                whileTap={{ scale: 0.8 }}
                onClick={() => setDailyGoal(Math.max(1, dailyGoal - 1))}
                className="w-8 h-8 rounded-lg flex items-center justify-center"
                style={{ background: "rgba(255,255,255,0.08)", border: "1px solid rgba(255,255,255,0.1)" }}
              >
                <Minus size={14} color="#F4F4FF" />
              </motion.button>
              <motion.span
                key={dailyGoal}
                initial={{ y: -15, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                transition={{ type: "spring", stiffness: 300, damping: 20 }}
                style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 20, color: "#F4F4FF", minWidth: 30, textAlign: "center", display: "inline-block" }}
              >
                {dailyGoal}
              </motion.span>
              <motion.button
                whileTap={{ scale: 0.8 }}
                onClick={() => setDailyGoal(dailyGoal + 1)}
                className="w-8 h-8 rounded-lg flex items-center justify-center"
                style={{ background: "rgba(99,102,241,0.2)", border: "1px solid rgba(99,102,241,0.3)" }}
              >
                <Plus size={14} color="#818CF8" />
              </motion.button>
            </div>
          </div>
        </LiquidGlassCard>
      </div>

      {/* Navigation (Drag to reorder placeholder) */}
      <div>
        <motion.div className="flex items-center gap-2 mb-2" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.6 }}>
          <GripVertical size={16} color="#818CF8" />
          <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }}>
            NAVIGATION ORDER
          </span>
        </motion.div>
        <LiquidGlassCard delay={6}>
          <div className="space-y-2">
            {["Dashboard", "Today's Plan", "Tracker", "Analytics", "More"].map((item, i) => (
              <motion.div
                key={item}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.5 + i * 0.04 }}
                whileTap={{ scale: 0.97, backgroundColor: "rgba(99,102,241,0.1)" }}
                className="flex items-center gap-3 py-2.5 px-2 rounded-lg"
              >
                <GripVertical size={14} color="#6B7280" />
                <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 14, color: "#F4F4FF" }}>
                  {item}
                </span>
              </motion.div>
            ))}
          </div>
        </LiquidGlassCard>
      </div>

      {/* Backup */}
      <div>
        <motion.div className="flex items-center gap-2 mb-2" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.7 }}>
          <CloudUpload size={16} color="#818CF8" />
          <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }}>
            BACKUP
          </span>
        </motion.div>
        <LiquidGlassCard delay={7}>
          <div className="flex items-center justify-between">
            <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 14, color: "#F4F4FF" }}>
              Auto Backup
            </span>
            <motion.button
              onClick={() => setBackupEnabled(!backupEnabled)}
              className="w-12 h-7 rounded-full relative"
              style={{
                background: backupEnabled ? "rgba(99,102,241,0.5)" : "rgba(255,255,255,0.1)",
                border: `1px solid ${backupEnabled ? "rgba(99,102,241,0.5)" : "rgba(255,255,255,0.15)"}`,
              }}
              whileTap={{ scale: 0.95 }}
            >
              <motion.div
                className="w-5 h-5 rounded-full absolute top-0.5"
                animate={{ left: backupEnabled ? 24 : 2 }}
                transition={{ type: "spring", stiffness: 300, damping: 20 }}
                style={{
                  background: backupEnabled ? "#6366F1" : "#6B7280",
                  boxShadow: backupEnabled ? "0 0 8px rgba(99,102,241,0.5)" : undefined,
                }}
              />
            </motion.button>
          </div>
        </LiquidGlassCard>
      </div>

      {/* Appearance */}
      <div>
        <motion.div className="flex items-center gap-2 mb-2" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.8 }}>
          <Palette size={16} color="#818CF8" />
          <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 13, color: "#6B7280", letterSpacing: 0.5 }}>
            APPEARANCE
          </span>
        </motion.div>
        <LiquidGlassCard delay={8}>
          <div className="flex gap-2">
            {([
              { id: "light", icon: Sun, label: "Light" },
              { id: "dark", icon: Moon, label: "Dark" },
              { id: "system", icon: Monitor, label: "System" },
            ] as const).map((t) => (
              <motion.button
                key={t.id}
                onClick={() => setTheme(t.id)}
                whileTap={{ scale: 0.95 }}
                className="flex-1 py-3 rounded-xl flex flex-col items-center gap-1.5 relative"
                style={{
                  background: theme === t.id ? "rgba(99,102,241,0.15)" : "rgba(255,255,255,0.04)",
                  border: `1px solid ${theme === t.id ? "rgba(99,102,241,0.35)" : "rgba(255,255,255,0.06)"}`,
                }}
              >
                <t.icon size={20} color={theme === t.id ? "#818CF8" : "#6B7280"} />
                <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 12, color: theme === t.id ? "#818CF8" : "#6B7280" }}>
                  {t.label}
                </span>
              </motion.button>
            ))}
          </div>
        </LiquidGlassCard>
      </div>

      {/* Bottom spacer */}
      <div className="h-8" />
    </div>
  );
}