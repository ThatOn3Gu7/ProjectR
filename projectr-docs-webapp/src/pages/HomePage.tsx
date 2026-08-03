import { motion } from "framer-motion";
import { Link } from "react-router-dom";
import TerminalDemo from "../components/TerminalDemo";
import StatsRibbon from "../components/StatsRibbon";
import SectionHeader from "../components/SectionHeader";
import FeatureCard from "../components/FeatureCard";

interface Feature {
  icon: string;
  title: string;
  description: string;
}

// The original site's 12 feature cards, text preserved verbatim.
const FEATURES: Feature[] = [
  {
    icon: "🎛️",
    title: "Interactive Menu",
    description:
      "Beautiful TUI with numbered tools, multi-select install, presets, search, and uninstall — all from one screen.",
  },
  {
    icon: "⚑",
    title: "CLI Flags & Subcommands",
    description:
      "Full non-interactive mode for scripting and automation. Install, search, audit, export, and more via flags.",
  },
  {
    icon: "🔍",
    title: "Smart Search",
    description:
      "Checks the built-in registry first, then queries all supported package managers with fuzzy matching via fzf.",
  },
  {
    icon: "📦",
    title: "240+ Tool Registry",
    description:
      "Curated collection: dev tools, terminal fun, OSINT, databases, cloud CLIs, security tools, and more.",
  },
  {
    icon: "🖥️",
    title: "24+ Package Managers",
    description:
      "Auto-detects apt, pacman, dnf, brew, pkg, apk, zypper, xbps, nix, snap, flatpak, and language managers.",
  },
  {
    icon: "📋",
    title: "Curated Presets",
    description: "One-click preset groups: Minimal, Developer, Fun. Build a complete workspace in seconds.",
  },
  {
    icon: "🧪",
    title: "Dry-Run Simulation",
    description: "Preview exactly what would happen without installing anything. JSON output for CI pipelines.",
  },
  {
    icon: "⏪",
    title: "Undo & Rollback",
    description: "Every install session is recorded. Use --undo to roll back the last batch.",
  },
  {
    icon: "📁",
    title: "Profile Export/Import",
    description: "Export your installed tools as a profile and replay the exact setup on any other machine.",
  },
  {
    icon: "🧩",
    title: "Plugin System",
    description: "Drop TOML files into tools.d/ to add custom tools without touching the core registry.",
  },
  {
    icon: "🩺",
    title: "Doctor & Audit",
    description: "project doctor checks your environment. project audit validates the tool database.",
  },
  {
    icon: "📊",
    title: "Structured Logging",
    description: "Every action logged with timestamps, exit codes, durations, and failure diagnostics. Auto-rotating logs.",
  },
];

export default function HomePage() {
  return (
    <>
      <section className="hero" id="hero">
        <motion.div
          className="hero-eyebrow"
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <span className="dot" />
          Open Source Terminal Toolkit
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.05, ease: [0.16, 1, 0.3, 1] }}
        >
          <span className="line1">ProjectR</span>
          <span className="line2">Terminal Setup</span>
        </motion.h1>

        <motion.p
          className="hero-sub"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
        >
          A modular Bash assistant that turns a fresh shell into a powerful workspace — interactively or
          fully automated, across any Linux, macOS, or Termux environment.
        </motion.p>

        <motion.div
          className="hero-cta"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.15, ease: [0.16, 1, 0.3, 1] }}
        >
          <Link to="/docs#one-shot" className="btn btn-primary">
            ⚡ One-Shot Install
          </Link>
          <Link to="/docs#quick-start" className="btn btn-ghost">
            📖 Read the Docs
          </Link>
          <a
            href="https://github.com/Thaton3gu7/ProjectR"
            className="btn btn-ghost"
            target="_blank"
            rel="noopener noreferrer"
          >
            ★ GitHub
          </a>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
          style={{ width: "100%" }}
        >
          <TerminalDemo />
        </motion.div>
      </section>

      <div style={{ padding: "0 48px", maxWidth: 1180, margin: "-20px auto 0", position: "relative", zIndex: 3 }}>
        <StatsRibbon />
      </div>

      <div className="divider" style={{ marginTop: 70 }} />

      <section className="section" id="features">
        <SectionHeader
          badge="Power Features"
          badgeColor="pink"
          title="✦ Everything ProjectR Can Do"
          description="A comprehensive toolkit for beginners and power users alike."
        />
        <div className="features-grid">
          {FEATURES.map((feature, i) => (
            <FeatureCard key={feature.title} icon={feature.icon} title={feature.title} description={feature.description} index={i} />
          ))}
        </div>
      </section>
    </>
  );
}
