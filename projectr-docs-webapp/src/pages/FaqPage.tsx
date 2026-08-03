import { useState } from "react";
import SectionHeader from "../components/SectionHeader";

interface FaqEntry {
  q: string;
  a: string;
}

const FAQS: FaqEntry[] = [
  {
    q: "What platforms does ProjectR support?",
    a: "Any system with Bash 4+: Linux (all major distros), macOS, WSL, and Termux on Android. setup.sh detects your platform and available package managers automatically.",
  },
  {
    q: "Do I need root or sudo?",
    a: "Only for installs that require it, and only if the underlying package manager itself needs elevated privileges. Language-level managers like pip, cargo, and npm typically don't.",
  },
  {
    q: "How does the search feature decide where to install from?",
    a: "It checks the built-in registry (project.registry) first for a curated, tested install command. If a tool isn't registered, it queries every detected package manager and lets you pick a match via fzf.",
  },
  {
    q: "What happens if a tool isn't in the registry?",
    a: "You can still search for and install it — ProjectR falls back to your package managers directly. You can also add it permanently via a plugin file in tools.d/.",
  },
  {
    q: "Can I run ProjectR non-interactively, e.g. in a Dockerfile or CI pipeline?",
    a: "Yes. Every menu action has a CLI flag equivalent — see the CLI Flags reference. --preset=minimal --dry-run is a common way to validate a setup before running it for real.",
  },
  {
    q: "What's the difference between --undo and --uninstall?",
    a: "--undo rolls back the most recent install session as a batch (everything installed together, together). --uninstall=<tool> removes one specific tool at any time, regardless of when it was installed.",
  },
  {
    q: "Does ProjectR modify my shell rc files?",
    a: "Only to add its own launcher directory to PATH, and only with your confirmation during setup. It never rewrites existing aliases, functions, or prompt configuration.",
  },
  {
    q: "How do I update ProjectR itself?",
    a: "Re-run setup.sh, or use git pull if you cloned the repository — the installer detects an existing installation and updates in place rather than duplicating it.",
  },
  {
    q: "Is any usage data collected or sent anywhere?",
    a: "No. ProjectR runs entirely locally. Its structured logs are written to ~/.local/share/projectr/logs and never leave your machine.",
  },
  {
    q: "How do profiles differ from presets?",
    a: "Presets (Minimal, Developer, Fun) are built-in, curated groups. Profiles are personal — you export your own current tool set with --export and can import it on any other machine.",
  },
];

export default function FaqPage() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  return (
    <section className="section" style={{ paddingTop: 70 }} id="faq">
      <SectionHeader badge="Common Questions" title="? FAQ" description="Answers to what people ask most often before and after installing ProjectR." />

      <div style={{ display: "flex", flexDirection: "column", gap: 10, maxWidth: 780, margin: "0 auto" }}>
        {FAQS.map((entry, i) => {
          const isOpen = openIndex === i;
          return (
            <div className={`faq-item${isOpen ? " open" : ""}`} key={entry.q}>
              <button
                type="button"
                className="faq-q"
                onClick={() => setOpenIndex(isOpen ? null : i)}
                aria-expanded={isOpen}
                aria-controls={`faq-answer-${i}`}
              >
                {entry.q}
                <span className="faq-arrow" aria-hidden="true">
                  ▾
                </span>
              </button>
              {isOpen && (
                <div className="faq-a" id={`faq-answer-${i}`}>
                  {entry.a}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}
