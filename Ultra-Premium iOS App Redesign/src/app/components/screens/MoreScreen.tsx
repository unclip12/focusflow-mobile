import { motion } from "motion/react";
import { LiquidGlassCard } from "../LiquidGlassCard";
import { RotateCcw, Terminal, Clock, Settings, ChevronRight } from "lucide-react";

const menuItems = [
  { id: "revision", icon: RotateCcw, label: "Revision Hub", desc: "SRS flashcard system", color: "#6366F1" },
  { id: "import", icon: Terminal, label: "Claude Import", desc: "AI-powered data import", color: "#818CF8" },
  { id: "logger", icon: Clock, label: "Time Logger", desc: "Track study sessions", color: "#8B5CF6" },
  { id: "settings", icon: Settings, label: "Settings", desc: "Configure your study OS", color: "#A78BFA" },
];

interface MoreScreenProps {
  onNavigate: (screen: string) => void;
}

export function MoreScreen({ onNavigate }: MoreScreenProps) {
  return (
    <div className="space-y-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 150, damping: 20 }}
      >
        <h1 style={{ fontFamily: "Inter", fontWeight: 700, fontSize: 26, color: "#F4F4FF" }}>
          More
        </h1>
        <p style={{ fontFamily: "Inter", fontSize: 13, color: "#6B7280", marginTop: 2 }}>
          Additional tools & settings
        </p>
      </motion.div>

      <div className="space-y-3">
        {menuItems.map((item, i) => (
          <LiquidGlassCard key={item.id} delay={i + 1} onClick={() => onNavigate(item.id)}>
            <div className="flex items-center gap-4">
              <motion.div
                className="w-12 h-12 rounded-2xl flex items-center justify-center"
                style={{
                  background: `${item.color}15`,
                  border: `1px solid ${item.color}30`,
                }}
                whileHover={{ scale: 1.05 }}
              >
                <item.icon size={22} color={item.color} strokeWidth={1.5} />
              </motion.div>
              <div className="flex-1">
                <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 15, color: "#F4F4FF", display: "block" }}>
                  {item.label}
                </span>
                <span style={{ fontFamily: "Inter", fontWeight: 400, fontSize: 12, color: "#6B7280" }}>
                  {item.desc}
                </span>
              </div>
              <ChevronRight size={18} color="#6B7280" />
            </div>
          </LiquidGlassCard>
        ))}
      </div>
    </div>
  );
}
