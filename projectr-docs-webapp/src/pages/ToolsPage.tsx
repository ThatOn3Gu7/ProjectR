import { useMemo, useState } from "react";
import SectionHeader from "../components/SectionHeader";
import ToolCard from "../components/ToolCard";
import toolsData from "../data/tools.json";
import type { Tool } from "../types/tool";

const tools = toolsData as Tool[];

const CATEGORY_ICONS: Record<string, string> = {
  Dev: "🛠️",
  Essentials: "📦",
  Fun: "🎉",
  Security: "🔐",
  OSINT: "🕵️",
  "Cloud & Containers": "☁️",
  Database: "🗄️",
  "Web & Network": "🌐",
  "Data & Docs": "📊",
  AI: "🤖",
};

const CATEGORIES = ["All", ...Array.from(new Set(tools.map((t) => t.category)))];

/** Deterministic "random" pick based on today's date, so Tool of the Day is stable through the day. */
function pickToolOfTheDay(): Tool {
  const seed = new Date().toDateString();
  let hash = 0;
  for (let i = 0; i < seed.length; i++) {
    hash = (hash * 31 + seed.charCodeAt(i)) >>> 0;
  }
  return tools[hash % tools.length];
}

export default function ToolsPage() {
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("All");
  const [copied, setCopied] = useState(false);
  const [totd] = useState<Tool>(pickToolOfTheDay);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return tools.filter((tool) => {
      const matchesCategory = category === "All" || tool.category === category;
      if (!matchesCategory) return false;
      if (!q) return true;
      return (
        tool.name.toLowerCase().includes(q) ||
        tool.category.toLowerCase().includes(q) ||
        tool.description.toLowerCase().includes(q)
      );
    });
  }, [query, category]);

  async function copyInstall() {
    try {
      await navigator.clipboard.writeText(totd.installCmd);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    } catch {
      // ignore — clipboard can be unavailable in some contexts
    }
  }

  return (
    <section className="section" style={{ paddingTop: 70 }} id="tools">
      <SectionHeader
        badge={`${tools.length}+ Tools`}
        badgeColor="green"
        title="□ Tool Registry"
        description="Search the full ProjectR registry, or browse tool-of-the-day picks by category."
      />

      <div className="tool-of-day" style={{ marginBottom: 44 }}>
        <div className="badge badge-cyan" style={{ marginBottom: 14 }}>
          ✦ Tool of the Day
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
          <span style={{ fontSize: "2rem" }} aria-hidden="true">
            {totd.icon}
          </span>
          <div style={{ flex: 1, minWidth: 200 }}>
            <h3 style={{ fontSize: "1.15rem", color: "var(--text-bright)", fontWeight: 700 }}>{totd.name}</h3>
            <p style={{ color: "var(--text-dim)", fontSize: "0.86rem", marginTop: 4 }}>{totd.description}</p>
          </div>
          <button type="button" className="btn btn-primary" onClick={copyInstall}>
            {copied ? "Copied!" : "📋 Copy Install Command"}
          </button>
        </div>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 20, marginBottom: 32 }}>
        <div className="search-input-wrap">
          <span aria-hidden="true">🔎</span>
          <input
            className="search-input"
            type="text"
            placeholder="Search by name, category, or description…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            aria-label="Search tools"
          />
          {query && (
            <button type="button" className="copy-btn" onClick={() => setQuery("")}>
              Clear
            </button>
          )}
        </div>

        <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {CATEGORIES.map((cat) => (
            <button
              key={cat}
              type="button"
              onClick={() => setCategory(cat)}
              className="mgr-chip"
              style={
                category === cat
                  ? { borderColor: "var(--green)", color: "var(--green)", background: "rgba(0,255,65,0.08)" }
                  : undefined
              }
            >
              {cat !== "All" && CATEGORY_ICONS[cat] ? `${CATEGORY_ICONS[cat]} ` : ""}
              {cat}
            </button>
          ))}
        </div>

        <p style={{ color: "var(--text-dim)", fontSize: "0.8rem" }}>
          Showing {filtered.length} of {tools.length} tools
        </p>
      </div>

      {filtered.length === 0 ? (
        <p style={{ color: "var(--text-dim)", textAlign: "center", padding: "40px 0" }}>
          No tools match "{query}". Try a different search term or category.
        </p>
      ) : (
        <div className="features-grid">
          {filtered.map((tool, i) => (
            <ToolCard tool={tool} key={`${tool.category}-${tool.name}`} index={i} />
          ))}
        </div>
      )}
    </section>
  );
}
