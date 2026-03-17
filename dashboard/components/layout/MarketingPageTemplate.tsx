"use client";

import React from "react";
import { MarketingNav } from "@/components/layout/MarketingNav";
import { motion } from "framer-motion";

export const MarketingPageTemplate = ({
  title,
  subtitle,
  description,
  icon: Icon,
  children
}: {
  title: string;
  subtitle?: string;
  description: string;
  icon?: React.ElementType;
  children?: React.ReactNode;
}) => {
  return (
    <div className="w-full min-h-screen bg-background relative overflow-hidden text-text flex flex-col justify-between">
      <MarketingNav />

      <div className="flex-1 w-full max-w-[1400px] border-x border-border mx-auto flex flex-col py-12 sm:py-20 px-4 sm:px-6 md:px-12 relative min-h-[calc(100vh-80px)]">
        {/* Architect grid overlay */}
        <div className="absolute top-0 right-0 w-1/2 h-full opacity-[0.03] pointer-events-none crosshair grid-pattern"></div>
        
        <motion.div 
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.8 }}
          className="relative z-10 w-full mb-12 sm:mb-16"
        >
          {Icon && (
             <div className="w-12 h-12 sm:w-16 sm:h-16 border border-border flex items-center justify-center bg-[#FAFAFA] rounded-xl mb-6 sm:mb-8 shadow-sm">
                <Icon size={24} className="text-accent sm:hidden" />
                <Icon size={28} className="text-accent hidden sm:block" />
             </div>
          )}

          {subtitle && (
            <div className="text-xs sm:text-sm font-mono text-text-muted mb-3 sm:mb-4 uppercase tracking-widest tracking-[0.2em] flex items-center gap-2">
              {subtitle} <span className="text-accent">_</span>
            </div>
          )}
          
          <h1 className="text-[2.25rem] sm:text-[3.5rem] md:text-[5rem] font-bold tracking-tighter text-text leading-[1] mb-6 sm:mb-8">
            {title}
          </h1>

          <p className="text-base sm:text-xl text-text-muted max-w-2xl leading-relaxed">
            {description}
          </p>
        </motion.div>

        {children ? (
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="w-full z-10"
          >
            {children}
          </motion.div>
        ) : (
          <div className="mt-12 w-full max-w-lg p-6 border border-border border-dashed bg-surface/50 rounded-sm">
            <span className="font-mono text-xs uppercase tracking-widest text-text-muted">Status: Build Phase</span>
            <div className="mt-3 flex items-center gap-2">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-accent opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-accent"></span>
              </span>
              <span className="text-sm">Active Development</span>
            </div>
          </div>
        )}
      </div>
      
      {/* Small footer */}
      <footer className="w-full border-t border-border bg-body py-6">
        <div className="max-w-[1400px] w-full mx-auto px-4 sm:px-6 flex flex-col sm:flex-row gap-2 justify-between items-center text-xs font-mono text-text-muted">
           <span>[SYS] BOUCLIER.ETH </span>
           <span>v0.1.0-alpha</span>
        </div>
      </footer>
    </div>
  );
};
