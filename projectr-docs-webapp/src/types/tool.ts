/**
 * A single entry in the ProjectR tool registry (src/data/tools.json).
 * Mirrors the pipe-delimited records ProjectR's Bash core keeps in
 * lib/data/tools.sh, expressed here as structured JSON for the site.
 */
export interface Tool {
  /** Human-readable display name, e.g. "Neovim" */
  name: string;
  /** One of the fixed registry categories, e.g. "Dev" */
  category: string;
  /** Short, one-line description of what the tool does */
  description: string;
  /** The `project install <slug>` command used to install this tool */
  installCmd: string;
  /** Emoji icon shown on tool cards */
  icon: string;
  /** Link to the tool's official homepage or repository */
  homepage: string;
}

/** Metadata describing a category shown on the Tools page. */
export interface CategoryMeta {
  name: string;
  icon: string;
  /** Text shown on the category badge, e.g. "60+ tools" */
  countLabel: string;
}
