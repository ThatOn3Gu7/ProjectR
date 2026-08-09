import { useMemo } from "react";
import { motion, useReducedMotion } from "framer-motion";
import { Link } from "react-router-dom";
import TerminalDemo from "../components/TerminalDemo";
import StatsRibbon from "../components/StatsRibbon";
import SectionHeader from "../components/SectionHeader";
import FeatureCard from "../components/FeatureCard";

interface Feature {
  id: string;
  icon: string;
  title: string;
  description: string;
}

const FEATURES: readonly Feature[] = [
  {
    id: "interactive-menu",
    icon: "🎛️",
    title: "Interactive Menu",
    description:
      "Beautiful TUI with numbered tools, multi-select install, presets, search, and uninstall — all from one screen.",
  },
  {
    id: "cli-flags",
    icon: "⚑",
    title: "CLI Flags & Subcommands",
    description:
      "Full non-interactive mode for scripting and automation. Install, search, audit, export, and more via flags.",
  },
  {
    id: "smart-search",
    icon: "🔍",
    title: "Smart Search",
    description:
      "Checks the built-in registry first, then queries all supported package managers with fuzzy matching via fzf.",
  },
  {
    id: "tool-registry",
    icon: "📦",
    title: "240+ Tool Registry",
    description:
      "Curated collection: dev tools, terminal fun, OSINT, databases, cloud CLIs, security tools, and more.",
  },
  {
    id: "package-managers",
    icon: "🖥️",
    title: "24+ Package Managers",
    description:
      "Auto-detects apt, pacman, dnf, brew, pkg, apk, zypper, xbps, nix, snap, flatpak, and language managers.",
  },
  {
    id: "curated-presets",
    icon: "📋",
    title: "Curated Presets",
    description: "One-click preset groups: Minimal, Developer, Fun. Build a complete workspace in seconds.",
  },
  {
    id: "dry-run",
    icon: "🧪",
    title: "Dry-Run Simulation",
    description: "Preview exactly what would happen without installing anything. JSON output for CI pipelines.",
  },
  {
    id: "undo-rollback",
    icon: "⏪",
    title: "Undo & Rollback",
    description: "Every install session is recorded. Use --undo to roll back the last batch.",
  },
  {
    id: "profile-export",
    icon: "📁",
    title: "Profile Export/Import",
    description: "Export your installed tools as a profile and replay the exact setup on any other machine.",
  },
  {
    id: "plugin-system",
    icon: "🧩",
    title: "Plugin System",
    description: "Drop TOML files into tools.d/ to add custom tools without touching the core registry.",
  },
  {
    id: "doctor-audit",
    icon: "🩺",
    title: "Doctor & Audit",
    description: "project doctor checks your environment. project audit validates the tool database.",
  },
  {
    id: "structured-logging",
    icon: "📊",
    title: "Structured Logging",
    description:
      "Every action logged with timestamps, exit codes, durations, and failure diagnostics. Auto-rotating logs.",
  },
] as const;

const JSON_LD = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "ProjectR",
  applicationCategory: "DeveloperApplication",
  operatingSystem: "Linux, macOS, Termux",
  offers: { "@type": "Offer", price: "0" },
  url: "https://github.com/Thaton3gu7/ProjectR",
};

function useFadeUp(delay = 0) {
  const shouldReduceMotion = useReducedMotion();
  return {
    initial: { opacity: 0, y: shouldReduceMotion ? 0 : 16 },
    animate: { opacity: 1, y: 0 },
    transition: {
      duration: shouldReduceMotion ? 0 : 0.6,
      delay,
      ease: [0.16, 1, 0.3, 1] as const,
    },
  };
}

export default function HomePage() {
  const heroEyebrow = useFadeUp(0);
  const heroTitle = useFadeUp(0.05);
  const heroSub = useFadeUp(0.1);
  const heroCta = useFadeUp(0.15);
  const heroDemo = useFadeUp(0.2);

  const featureCards = useMemo(
    () =>
      FEATURES.map((feature, i) => (
        <motion.div
          key={feature.id}
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-50px" }}
          transition={{
            duration: 0.5,
            delay: i * 0.05,
            ease: [0.16, 1, 0.3, 1],
          }}
        >
          <FeatureCard
            icon={feature.icon}
            title={feature.title}
            description={feature.description}
            index={i}
          />
        </motion.div>
      )),
    []
  );

  return (
    <main>
      <script type="application/ld+json">{JSON.stringify(JSON_LD)}</script>

      <section className="hero" id="hero">
        <motion.div className="hero-eyebrow" {...heroEyebrow}>
          <span className="dot" aria-hidden="true" />
          Open Source Terminal Toolkit
        </motion.div>

        <motion.h1 {...heroTitle} aria-label="ProjectR Terminal Setup">
          <span className="line1">ProjectR</span>
          <span className="line2">Terminal Setup</span>
        </motion.h1>

        <motion.p className="hero-sub" {...heroSub}>
          A modular Bash assistant that turns a fresh shell into a powerful
          workspace — interactively or fully automated, across any Linux, macOS,
          or Termux environment.
        </motion.p>

        <motion.div className="hero-cta" {...heroCta}>
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
            aria-label="View ProjectR on GitHub"
          >
            <span aria-hidden="true">★</span> GitHub
          </a>
        </motion.div>

        <motion.div className="hero-demo-wrapper" {...heroDemo}>
          <TerminalDemo />
        </motion.div>
      </section>

      <div className="stats-wrapper">
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
        <div className="features-grid">{featureCards}</div>
      </section>
    </main>
  );
}
