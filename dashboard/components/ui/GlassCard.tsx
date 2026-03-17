import React from "react";
import { cn } from "@/lib/utils";
import { motion, HTMLMotionProps } from "framer-motion";

interface GlassCardProps extends HTMLMotionProps<"div"> {
  children: React.ReactNode;
  className?: string;
  glow?: "none" | "primary" | "secondary" | "success" | "danger";
  hover?: boolean;
}

export function GlassCard({ children, className, glow = "none", hover = false, ...props }: GlassCardProps) {
  const glowClasses = {
    none: "",
    primary: "shadow-glow-primary border-accent/20",
    secondary: "shadow-glow-secondary border-accent-secondary/20",
    success: "shadow-glow-success border-status-success/20",
    danger: "shadow-glow-danger border-status-danger/20",
  };

  return (
    <motion.div
      className={cn(
        "glass-panel p-6",
        glowClasses[glow],
        hover && "transition-all duration-300 hover:scale-[1.02] hover:-translate-y-1 hover:border-white/10",
        className
      )}
      {...props}
    >
      {children}
    </motion.div>
  );
}
