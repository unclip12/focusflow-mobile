import { motion } from "motion/react";

interface AnimatedProgressBarProps {
  progress: number; // 0-100
  color?: string;
  delay?: number;
  height?: number;
}

export function AnimatedProgressBar({
  progress,
  color = "#6366F1",
  delay = 0,
  height = 6,
}: AnimatedProgressBarProps) {
  return (
    <div
      className="w-full rounded-full overflow-hidden"
      style={{ height, background: "rgba(255,255,255,0.1)" }}
    >
      <motion.div
        className="h-full rounded-full"
        initial={{ width: "0%" }}
        animate={{ width: `${progress}%` }}
        transition={{
          type: "spring",
          stiffness: 60,
          damping: 15,
          delay: delay * 0.06 + 0.3,
        }}
        style={{
          background: `linear-gradient(90deg, ${color}, ${color}cc)`,
          boxShadow: `0 0 12px ${color}60`,
        }}
      />
    </div>
  );
}
