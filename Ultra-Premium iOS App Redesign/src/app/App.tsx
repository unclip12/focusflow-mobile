import { useState, useCallback } from "react";
import { motion, AnimatePresence } from "motion/react";
import { AuroraBackground } from "./components/AuroraBackground";
import { BottomNav } from "./components/BottomNav";
import { DashboardScreen } from "./components/screens/DashboardScreen";
import { PlanScreen } from "./components/screens/PlanScreen";
import { TrackerScreen } from "./components/screens/TrackerScreen";
import { RevisionScreen } from "./components/screens/RevisionScreen";
import { ClaudeImportScreen } from "./components/screens/ClaudeImportScreen";
import { AnalyticsScreen } from "./components/screens/AnalyticsScreen";
import { TimeLoggerScreen } from "./components/screens/TimeLoggerScreen";
import { SettingsScreen } from "./components/screens/SettingsScreen";
import { MoreScreen } from "./components/screens/MoreScreen";
import { ArrowLeft } from "lucide-react";

export default function App() {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [subScreen, setSubScreen] = useState<string | null>(null);

  const handleNavigate = useCallback((id: string) => {
    setSubScreen(null);
    setActiveTab(id);
  }, []);

  const handleMoreNavigate = useCallback((screen: string) => {
    setSubScreen(screen);
  }, []);

  const currentScreen = subScreen || activeTab;

  const renderScreen = () => {
    switch (currentScreen) {
      case "dashboard": return <DashboardScreen />;
      case "plan": return <PlanScreen />;
      case "tracker": return <TrackerScreen />;
      case "analytics": return <AnalyticsScreen />;
      case "revision": return <RevisionScreen />;
      case "import": return <ClaudeImportScreen />;
      case "logger": return <TimeLoggerScreen />;
      case "settings": return <SettingsScreen />;
      case "more": return <MoreScreen onNavigate={handleMoreNavigate} />;
      default: return <DashboardScreen />;
    }
  };

  return (
    <div
      className="w-full h-full relative overflow-hidden"
      style={{
        fontFamily: "Inter, -apple-system, BlinkMacSystemFont, sans-serif",
        background: "#0E0E1A",
        maxWidth: 430,
        margin: "0 auto",
      }}
    >
      <AuroraBackground />

      {/* Scrollable content */}
      <div
        className="relative z-10 h-full overflow-y-auto overflow-x-hidden"
        style={{
          paddingTop: 52,
          paddingBottom: 120,
          paddingLeft: 20,
          paddingRight: 20,
          scrollbarWidth: "none",
        }}
      >
        {/* Back button for sub-screens */}
        {subScreen && (
          <motion.button
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ type: "spring", stiffness: 200, damping: 20 }}
            onClick={() => setSubScreen(null)}
            className="flex items-center gap-1.5 mb-4"
            style={{ color: "#818CF8" }}
          >
            <ArrowLeft size={18} />
            <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 14 }}>Back</span>
          </motion.button>
        )}

        <AnimatePresence mode="wait">
          <motion.div
            key={currentScreen}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ type: "spring", stiffness: 200, damping: 25 }}
          >
            {renderScreen()}
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Status bar overlay */}
      <div
        className="absolute top-0 left-0 right-0 z-30 flex items-center justify-between px-6"
        style={{ height: 48 }}
      >
        <span style={{ fontFamily: "Inter", fontWeight: 600, fontSize: 14, color: "#F4F4FF" }}>
          9:41
        </span>
        <div className="flex items-center gap-1.5">
          <div className="flex gap-0.5">
            {[1, 2, 3, 4].map((i) => (
              <div
                key={i}
                className="rounded-sm"
                style={{
                  width: 3,
                  height: 4 + i * 2,
                  background: i <= 3 ? "#F4F4FF" : "rgba(244,244,255,0.3)",
                }}
              />
            ))}
          </div>
          <span style={{ fontFamily: "Inter", fontWeight: 500, fontSize: 11, color: "#F4F4FF", marginLeft: 4 }}>
            5G
          </span>
          <div className="ml-2 flex items-center" style={{ width: 25, height: 12 }}>
            <div
              className="rounded-sm"
              style={{
                width: 20,
                height: 10,
                border: "1.5px solid #F4F4FF",
                borderRadius: 3,
                position: "relative",
              }}
            >
              <div
                className="rounded-sm"
                style={{
                  position: "absolute",
                  left: 1.5,
                  top: 1.5,
                  bottom: 1.5,
                  width: "65%",
                  background: "#22C55E",
                  borderRadius: 1,
                }}
              />
            </div>
            <div style={{ width: 2, height: 5, background: "#F4F4FF", borderRadius: "0 1px 1px 0", marginLeft: 0.5 }} />
          </div>
        </div>
      </div>

      <BottomNav active={activeTab} onNavigate={handleNavigate} />
    </div>
  );
}
