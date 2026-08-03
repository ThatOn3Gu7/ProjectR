/** @type {import('tailwindcss').Config} */
export default {
  // Dark mode is toggled by adding/removing the `dark` class on <html>,
  // driven by useDarkMode.ts (persisted to localStorage).
  darkMode: "class",
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Terminal / hacker palette (dark theme, the site's default)
        term: {
          bg: "#000000",
          bg2: "#050505",
          bg3: "#0a0a0a",
          bg4: "#111111",
          bg5: "#1a1a1a",
          text: "#c8f8d8",
          dim: "#507a50",
          mid: "#8acc8a",
          bright: "#ffffff",
          green: "#00ff41",
          greenDim: "#008f11",
          cyan: "#00e5ff",
          violet: "#b06aff",
          pink: "#ff5caa",
          gold: "#ffc94d",
        },
        // Light theme palette, used when `dark` class is absent
        paper: {
          bg: "#f5f7f5",
          bg2: "#ffffff",
          bg3: "#eef2ee",
          bg4: "#e4e9e4",
          text: "#132313",
          dim: "#5c6b5c",
          mid: "#33472f",
          bright: "#04140a",
          green: "#0b8f2e",
          greenDim: "#0b8f2e33",
          cyan: "#0088a8",
          violet: "#7a3fd1",
          pink: "#c22b73",
        },
      },
      fontFamily: {
        mono: ["'JetBrains Mono'", "monospace"],
      },
      boxShadow: {
        glow: "0 0 20px rgba(0,255,65,0.25)",
        "glow-lg": "0 0 40px rgba(0,255,65,0.15), 0 0 80px rgba(0,255,65,0.05)",
      },
      keyframes: {
        blink: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.2" },
        },
        cursorBlink: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0" },
        },
        flicker: {
          "0%": { opacity: "0.96" },
          "5%": { opacity: "0.9" },
          "10%": { opacity: "0.98" },
          "15%": { opacity: "1" },
          "100%": { opacity: "0.95" },
        },
      },
      animation: {
        blink: "blink 1.5s ease-in-out infinite",
        cursorBlink: "cursorBlink 1s step-end infinite",
        flicker: "flicker 4s infinite alternate",
      },
    },
  },
  plugins: [],
};
