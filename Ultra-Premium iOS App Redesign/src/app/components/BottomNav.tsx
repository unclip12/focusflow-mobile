import { motion } from "motion/react";
import {
  Home,
  CalendarDays,
  BookOpen,
  BarChart3,
  Menu,
} from "lucide-react";

const tabs = [
  { id: "dashboard", icon: Home, label: "Home" },
  { id: "plan", icon: CalendarDays, label: "Plan" },
  { id: "tracker", icon: BookOpen, label: "Tracker" },
  { id: "analytics", icon: BarChart3, label: "Stats" },
  { id: "more", icon: Menu, label: "More" },
];

interface BottomNavProps {
  active: string;
  onNavigate: (id: string) => void;
}

export function BottomNav({ active, onNavigate }: BottomNavProps) {
  return (
    <motion.div
      initial={{ y: 100 }}
      animate={{ y: 0 }}
      transition={{ type: "spring", stiffness: 200, damping: 25 }}
      className="fixed bottom-0 left-0 right-0 z-50 flex justify-center pb-6 px-4"
    >
      <div
        className="flex items-center justify-around w-full max-w-md rounded-3xl px-2"
        style={{
          height: 72,
          background: "rgba(14,14,26,0.75)",
          backdropFilter: "blur(40px)",
          WebkitBackdropFilter: "blur(40px)",
          border: "1px solid rgba(99,102,241,0.25)",
          boxShadow:
            "0 -4px 30px rgba(99,102,241,0.15), inset 0 1px 0 rgba(255,255,255,0.08)",
        }}
      >
        {tabs.map((tab) => {
          const isActive = active === tab.id;
          const Icon = tab.icon;
          return (
            <motion.button
              key={tab.id}
              onClick={() => onNavigate(tab.id)}
              whileTap={{ scale: 0.85 }}
              className="flex flex-col items-center justify-center gap-1 relative"
              style={{ minWidth: 56, minHeight: 44 }}
            >
              <motion.div
                animate={{
                  scale: isActive ? 1.15 : 1,
                  color: isActive ? "#818CF8" : "#6B7280",
                }}
                transition={{ type: "spring", stiffness: 300, damping: 20 }}
              >
                <Icon size={22} strokeWidth={1.5} />
              </motion.div>
              <span
                className="transition-colors"
                style={{
                  fontSize: 10,
                  fontFamily: "Inter, sans-serif",
                  fontWeight: 500,
                  color: isActive ? "#818CF8" : "#6B7280",
                }}
              >
                {tab.label}
              </span>
              {isActive && (
                <motion.div
                  layoutId="nav-glow"
                  className="absolute -bottom-1 w-5 h-1 rounded-full"
                  style={{
                    background: "#6366F1",
                    boxShadow: "0 0 12px rgba(99,102,241,0.6)",
                  }}
                  transition={{ type: "spring", stiffness: 300, damping: 25 }}
                />
              )}
            </motion.button>
          );
        })}
      </div>
    </motion.div>
  );
}
