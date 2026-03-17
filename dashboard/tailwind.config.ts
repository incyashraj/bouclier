import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: {
          DEFAULT: "#F4F4F5", // Light mode canvas
          dark: "#0F0F10",    // Dark mode canvas
        },
        surface: {
          DEFAULT: "#FFFFFF",
          dark: "#1A1A1C",
          darker: "#121213",
        },
        accent: {
          DEFAULT: "#FF451A",
          hover: "#E03A12",
        },
        text: {
          DEFAULT: "#111111",
          muted: "#737373",
          dark: "#FFFFFF",
          darkMuted: "#A1A1AA",
        },
        border: {
          DEFAULT: "#E5E5E5",
          dark: "#2A2A2A",
          darker: "#1D1D1E"
        }
      },
      fontFamily: {
        sans: ["var(--font-geist-sans)", "sans-serif"],
        mono: ["var(--font-geist-mono)", "monospace"],
      },
    },
  },
  plugins: [],
};

export default config;
