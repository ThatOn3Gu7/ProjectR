import { useEffect, useRef, useState, type FormEvent } from "react";

type ScriptLineType = "comment" | "cmd" | "out" | "out-s";

interface ScriptLine {
  type: ScriptLineType;
  text: string;
}

// The same scripted auto-play sequence from the original site's hero terminal.
const SCRIPT: ScriptLine[] = [
  { type: "comment", text: "# One command. Full setup." },
  {
    type: "cmd",
    text: "curl -fsSL https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh | sh",
  },
  { type: "out", text: "" },
  { type: "out-s", text: "[✓] ProjectR installed via remote one-shot setup." },
  { type: "out", text: "    App files : ~/.local/share/projectr" },
  { type: "out", text: "    Launcher  : ~/.local/bin/project" },
  { type: "out", text: "" },
  { type: "cmd", text: "project --install=neovim" },
  { type: "out-s", text: "[✓] Neovim installed successfully (via apt)." },
];

interface RenderedLine {
  type: ScriptLineType;
  text: string;
  /** Only used for "cmd" lines while the typewriter is still typing */
  typing?: boolean;
}

interface ActiveEntry {
  cmd: string;
  outputs: { text: string; success?: boolean }[];
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/** Produces a plausible simulated response for a command typed into active mode. */
function respondTo(rawCmd: string): { text: string; success?: boolean }[] {
  const cmd = rawCmd.trim();

  if (!cmd) return [];

  const installMatch = cmd.match(/^project\s+(?:--install=|install\s+)(\S+)/);
  if (installMatch) {
    const tool = installMatch[1];
    return [{ text: `[✓] ${tool} installed successfully (via apt).`, success: true }];
  }

  const searchMatch = cmd.match(/^project\s+(?:--search=|search\s+)(\S+)/);
  if (searchMatch) {
    return [{ text: `[i] Searching registry + package managers for "${searchMatch[1]}"...` }, { text: "[✓] 1 match found in built-in registry.", success: true }];
  }

  if (/^project\s+--help/.test(cmd) || cmd === "project -h") {
    return [
      { text: "Usage: project [command] [flags]" },
      { text: "  install <name>     Install a tool" },
      { text: "  list tools         Show the full registry" },
      { text: "  doctor             Check environment health" },
      { text: "  --help             Show this message" },
    ];
  }

  if (/^project\s+doctor/.test(cmd)) {
    return [{ text: "[✓] Environment healthy. All managed tools present on PATH.", success: true }];
  }

  if (/^project\s+--setup-info/.test(cmd)) {
    return [
      { text: "App files : ~/.local/share/projectr" },
      { text: "Launcher  : ~/.local/bin/project" },
    ];
  }

  if (cmd === "clear") {
    return [];
  }

  return [{ text: `bash: ${cmd.split(" ")[0]}: try "project --help" for available commands` }];
}

/**
 * Hero terminal. In "auto" mode it types out a scripted install sequence
 * on a loop. Clicking it switches to "active" mode, where the visitor can
 * type real ProjectR-style commands and get a simulated response.
 * Clicking outside the terminal returns it to auto-play.
 */
export default function TerminalDemo() {
  const [mode, setMode] = useState<"auto" | "active">("auto");
  const [autoLines, setAutoLines] = useState<RenderedLine[]>([]);
  const [history, setHistory] = useState<ActiveEntry[]>([]);
  const [input, setInput] = useState("");

  const containerRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const runIdRef = useRef(0);

  // Auto-play the scripted sequence, looping with a pause, while in "auto" mode.
  useEffect(() => {
    if (mode !== "auto") return;

    const runId = ++runIdRef.current;
    let cancelled = false;

    async function play() {
      while (!cancelled && runIdRef.current === runId) {
        setAutoLines([]);
        await sleep(600);
        for (const line of SCRIPT) {
          if (cancelled || runIdRef.current !== runId) return;
          if (line.type === "cmd") {
            let typed = "";
            setAutoLines((prev) => [...prev, { type: "cmd", text: "", typing: true }]);
            for (const ch of line.text) {
              if (cancelled || runIdRef.current !== runId) return;
              typed += ch;
              const snapshot = typed;
              setAutoLines((prev) => {
                const next = [...prev];
                next[next.length - 1] = { type: "cmd", text: snapshot, typing: true };
                return next;
              });
              await sleep(14 + Math.random() * 18);
            }
            setAutoLines((prev) => {
              const next = [...prev];
              next[next.length - 1] = { type: "cmd", text: typed };
              return next;
            });
            await sleep(250);
          } else {
            setAutoLines((prev) => [...prev, { type: line.type, text: line.text }]);
            await sleep(line.type === "out" && !line.text ? 80 : 160);
          }
        }
        await sleep(3200);
      }
    }
    play();

    return () => {
      cancelled = true;
    };
  }, [mode]);

  // Return to auto-play when the user clicks anywhere outside the terminal.
  useEffect(() => {
    if (mode !== "active") return;
    function handleClickOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setMode("auto");
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [mode]);

  useEffect(() => {
    if (mode === "active") inputRef.current?.focus();
  }, [mode]);

  function handleActivate() {
    if (mode === "auto") {
      setMode("active");
      setHistory([]);
    }
  }

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const cmd = input;
    setInput("");
    if (cmd.trim() === "clear") {
      setHistory([]);
      return;
    }
    const outputs = respondTo(cmd);
    setHistory((prev) => [...prev, { cmd, outputs }]);
  }

  return (
    <div className="hero-terminal" ref={containerRef} onClick={handleActivate}>
      <div className="term-bar">
        <span className="term-dot r" />
        <span className="term-dot y" />
        <span className="term-dot g" />
        <span className="term-title">bash — ProjectR v1.4</span>
      </div>

      {mode === "auto" ? (
        <div className="term-body">
          {autoLines.map((line, i) => (
            <span className="term-line" key={i}>
              {line.type === "comment" && <span className="term-comment">{line.text}</span>}
              {line.type === "cmd" && (
                <>
                  <span className="term-prompt">$ </span>
                  <span className="term-cmd">{line.text}</span>
                </>
              )}
              {line.type === "out" && <span className="term-out">{line.text}</span>}
              {line.type === "out-s" && <span className="term-out success">{line.text}</span>}
            </span>
          ))}
          <span className="term-cursor" />
        </div>
      ) : (
        <div className="term-body">
          <span className="term-line">
            <span className="term-comment"># Try: project --install=git, project --help, project doctor</span>
          </span>
          {history.map((entry, i) => (
            <div key={i}>
              <span className="term-line">
                <span className="term-prompt">$ </span>
                <span className="term-cmd">{entry.cmd}</span>
              </span>
              {entry.outputs.map((o, j) => (
                <span className="term-line" key={j}>
                  <span className={o.success ? "term-out success" : "term-out"}>{o.text}</span>
                </span>
              ))}
            </div>
          ))}
          <form onSubmit={handleSubmit} className="term-input-row">
            <span className="term-prompt">$</span>
            <input
              ref={inputRef}
              className="term-input"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              spellCheck={false}
              autoComplete="off"
              aria-label="Terminal command input"
            />
            <span className="term-cursor" />
          </form>
        </div>
      )}

      <div className="term-hint">
        {mode === "auto" ? "Click to type your own commands" : "Click outside to return to auto-play"}
      </div>
    </div>
  );
}
