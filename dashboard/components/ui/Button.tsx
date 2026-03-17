import React from "react";
import { cn } from "@/lib/utils";
import { motion, HTMLMotionProps } from "framer-motion";

interface ButtonProps extends HTMLMotionProps<"button"> {
  variant?: "primary" | "secondary" | "outline" | "ghost" | "dark-outline";
  size?: "sm" | "md" | "lg";
  children: React.ReactNode;
}

export function Button({ variant = "primary", size = "md", className, children, ...props }: ButtonProps) {
  const baseStyles = "relative inline-flex items-center justify-center font-bold transition-all duration-200 rounded-full focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:opacity-50 disabled:cursor-not-allowed";
  
  const variants = {
    primary: "bg-accent text-white hover:bg-accent-hover",
    secondary: "bg-[#222222] text-white hover:bg-black",
    outline: "bg-[#EAEAEA] border border-transparent text-text hover:bg-[#D5D5D5]",
    "dark-outline": "bg-transparent border border-border-dark text-text-dark hover:bg-border-dark",
    ghost: "text-text-muted hover:text-text",
  };

  const sizes = {
    sm: "text-xs px-4 py-2",
    md: "text-sm px-5 py-2.5",
    lg: "text-sm px-6 py-3.5",
  };

  return (
    <motion.button
      whileHover={{ y: -1 }}
      whileTap={{ scale: 0.98 }}
      className={cn(baseStyles, variants[variant], sizes[size], className)}
      {...props}
    >
      {children}
    </motion.button>
  );
}
