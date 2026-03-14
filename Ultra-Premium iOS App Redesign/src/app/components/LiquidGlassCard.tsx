import { motion } from "motion/react";
import { ReactNode, useState } from "react";

interface LiquidGlassCardProps {
  children: ReactNode;
  className?: string;
  delay?: number;
  glowColor?: string;
  onClick?: () => void;
  hero?: boolean;
}

export function LiquidGlassCard({
  children,
  className = "",
  delay = 0,
  glowColor,
  onClick,
  hero = false,
}: LiquidGlassCardProps) {
  const [tapped, setTapped] = useState(false);

  return (
    <motion.div
      initial={{ opacity: 0, y: 30, scale: 0.92 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{
        type: "spring",
        stiffness: 180,
        damping: 20,
        delay: delay * 0.06,
      }}
      whileTap={{ scale: 0.97 }}
      onClick={() => {
        setTapped(true);
        setTimeout(() => setTapped(false), 600);
        onClick?.();
      }}
      className={`relative overflow-hidden rounded-2xl p-5 ${className}`}
      style={{
        background: "rgba(255,255,255,0.08)",
        backdropFilter: hero ? "blur(40px)" : "blur(24px)",
        WebkitBackdropFilter: hero ? "blur(40px)" : "blur(24px)",
        border: "1px solid rgba(99,102,241,0.3)",
        boxShadow: glowColor
          ? `0 0 30px ${glowColor}, inset 0 1px 0 rgba(255,255,255,0.1)`
          : "0 0 20px rgba(99,102,241,0.15), inset 0 1px 0 rgba(255,255,255,0.1)",
      }}
    >
      {/* Shimmer sweep */}
      <motion.div
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            "linear-gradient(105deg, transparent 40%, rgba(255,255,255,0.08) 45%, rgba(255,255,255,0.15) 50%, rgba(255,255,255,0.08) 55%, transparent 60%)",
          backgroundSize: "200% 100%",
        }}
        animate={{ backgroundPosition: ["200% 0", "-200% 0"] }}
        transition={{ duration: 4, repeat: Infinity, repeatDelay: 3, ease: "linear" }}
      />
      {/* Tap ripple */}
      {tapped && (
        <motion.div
          className="absolute inset-0 pointer-events-none"
          initial={{ opacity: 0.3 }}
          animate={{ opacity: 0 }}
          transition={{ duration: 0.6 }}
          style={{
            background: "radial-gradient(circle at center, rgba(99,102,241,0.3), transparent 70%)",
          }}
        />
      )}
      <div className="relative z-10">{children}</div>
    </motion.div>
  );
}
