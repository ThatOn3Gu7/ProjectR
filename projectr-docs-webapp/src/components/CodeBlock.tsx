import { useState, type ReactNode } from "react";

interface CodeBlockProps {
  /** Label shown in the header bar, e.g. "shell" or "projectr.yml" */
  title: string;
  /** Plain-text version of the code — this is what gets copied to the clipboard */
  code: string;
  /**
   * Optional richly-formatted version of the code (with <span class="kw">,
   * .str, .cm, .fl highlighting) to display instead of the plain string.
   * If omitted, `code` is rendered as-is.
   */
  children?: ReactNode;
}

/**
 * A terminal-styled code block with a header bar and a "Copy" button.
 * Used throughout the docs/reference pages for every shell snippet,
 * YAML/TOML config sample, and CLI example.
 */
export default function CodeBlock({ title, code, children }: CodeBlockProps) {
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    } catch {
      // Clipboard API can fail (e.g. insecure context) — fail silently,
      // the button simply won't flip to "Copied!".
    }
  }

  return (
    <div className="code-block">
      <div className="code-header">
        <span>{title}</span>
        <button className="copy-btn" onClick={handleCopy} type="button">
          {copied ? "Copied!" : "Copy"}
        </button>
      </div>
      <div className="code-content">{children ?? code}</div>
    </div>
  );
}
