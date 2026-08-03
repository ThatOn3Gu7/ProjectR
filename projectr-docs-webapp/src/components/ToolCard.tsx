import { motion } from "framer-motion";
import type { Tool } from "../types/tool";

interface ToolCardProps {
  tool: Tool;
  index?: number;
}

/** A single tool's card in the registry grid: icon, name, category, description, homepage link. */
export default function ToolCard({ tool, index = 0 }: ToolCardProps) {
  return (
    <motion.div
      className="tool-registry-card"
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay: Math.min(index, 12) * 0.02 }}
      layout
    >
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <span style={{ fontSize: "1.2rem" }} aria-hidden="true">
          {tool.icon}
        </span>
        <div>
          <div style={{ fontWeight: 700, color: "var(--text-bright)", fontSize: "0.92rem" }}>
            {tool.name}
          </div>
          <span className="tool-tag" style={{ fontSize: "0.62rem" }}>
            {tool.category}
          </span>
        </div>
      </div>
      <p style={{ fontSize: "0.82rem", color: "var(--text-dim)", lineHeight: 1.6 }}>
        {tool.description}
      </p>
      <div style={{ display: "flex", gap: 10, alignItems: "center", marginTop: 4 }}>
        <code
          style={{
            fontSize: "0.72rem",
            color: "var(--green)",
            background: "rgba(0,255,65,0.07)",
            border: "1px solid var(--green-dim)",
            padding: "2px 6px",
          }}
        >
          {tool.installCmd}
        </code>
      </div>
      <a
        href={tool.homepage}
        target="_blank"
        rel="noopener noreferrer"
        style={{ fontSize: "0.74rem", marginTop: 2 }}
      >
        Homepage ↗
      </a>
    </motion.div>
  );
}
