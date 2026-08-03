import { useEffect, useRef, useState, useCallback, type FormEvent, type KeyboardEvent } from "react";

type ScriptLineType = "comment" | "cmd" | "out" | "out-s";

interface ScriptLine {
  type: ScriptLineType;
  text: string;
}

interface RenderedLine {
  type: ScriptLineType;
  text: string;
  typing?: boolean;
}

interface ActiveEntry {
  cmd: string;
  outputs: { text: string; success?: boolean }[];
}

// ─── Pure helpers (outside component) ────────────────────────────────────────

// ─── Constants ───────────────────────────────────────────────────────────────

const SCRIPTS: ScriptLine[][] = [
  // Demo 1: One-shot setup
  [
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
  ],

  // Demo 2: Search & install
  [
    { type: "comment", text: "# Search 240+ tools across registries" },
    { type: "cmd", text: "project search lazygit" },
    { type: "out", text: '[i] Searching registry + package managers for "lazygit"...' },
    { type: "out-s", text: "[✓] 1 match found in built-in registry." },
    { type: "out", text: "" },
    { type: "cmd", text: "project --install=lazygit" },
    { type: "out-s", text: "[✓] lazygit installed successfully (via apt)." },
  ],

  // Demo 3: Environment health
  [
    { type: "comment", text: "# Verify your environment" },
    { type: "cmd", text: "project doctor" },
    { type: "out-s", text: "[✓] Environment healthy. All managed tools present on PATH." },
  ],

  // Demo 4: Browse registry
  [
    { type: "comment", text: "# Browse the full tool catalogue" },
    { type: "cmd", text: "project list tools" },
    { type: "out", text: "[001] Git        - Distributed version control system (Dev)" },
    { type: "out", text: "[002] Curl       - Transfer data via URLs (Min)" },
    { type: "out", text: "[003] Wget       - Non-interactive file downloader (Min)" },
    { type: "out", text: "[004] Bat        - A cat clone with syntax highlighting (Min)" },
    { type: "out", text: "[005] Htop       - Interactive process viewer and manager (Min)" },
    { type: "out", text: "" },
    { type: "out-s", text: "◇ Showing 50/240 tools — type 'l' to load more tools" },
  ],

  // Demo 5: Inspect installed tools
  [
    { type: "comment", text: "# Inspect what's already on your system" },
    { type: "cmd", text: "project inspect" },
    { type: "out", text: "[*] Verification of installed tools in progress:" },
    { type: "out-s", text: '[✓] "Git"     is installed (v2.55.0)' },
    { type: "out-s", text: '[✓] "Curl"    is installed (v8.21.0)' },
    { type: "out", text: '[x] "Fish"    is not installed' },
    { type: "out-s", text: '[✓] "Neovim"  is installed (v0.12.4)' },
    { type: "out", text: '[x] "Ranger"  is not installed' },
    { type: "out", text: "" },
    { type: "out", text: "[ Analysis Results ]" },
    { type: "out", text: "● Total checked:  240" },
    { type: "out-s", text: "● Installed:      52" },
    { type: "out", text: "● Not found:      188" },
    { type: "out", text: "" },
    { type: "out-s", text: "[✓] Verification process completed." },
  ],
];

const TYPE_SPEED_MIN = 14;
const TYPE_SPEED_MAX = 32;
const CMD_PAUSE_MS = 250;
const LOOP_PAUSE_MS = 3500;
const EMPTY_LINE_PAUSE_MS = 80;
const NORMAL_LINE_PAUSE_MS = 160;

// ─── Pure helpers (outside component) ────────────────────────────────────────

function sleep(ms: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}

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
    return [
      { text: `[i] Searching registry + package managers for "${searchMatch[1]}"...` },
      { text: "[✓] 1 match found in built-in registry.", success: true },
    ];
  }

  if (/^project\s+list\s+tools/.test(cmd)) {
    return [
      { text: "[001] Git        - Distributed version control system (Dev)" },
      { text: "[002] Curl       - Transfer data via URLs (Min)" },
      { text: "[003] Wget       - Non-interactive file downloader (Min)" },
      { text: "[004] Bat        - A cat clone with syntax highlighting (Min)" },
      { text: "[005] Htop       - Interactive process viewer and manager (Min)" },
      { text: "" },
      { text: "◇ Showing 50/240 tools — type 'l' to load more tools" },
    ];
  }

  if (/^project\s+inspect/.test(cmd)) {
    return [
      { text: "[*] Verification of installed tools in progress:" },
      { text: '[✓] "Git"     is installed (v2.55.0)', success: true },
      { text: '[✓] "Curl"    is installed (v8.21.0)', success: true },
      { text: '[x] "Fish"    is not installed' },
      { text: '[✓] "Neovim"  is installed (v0.12.4)', success: true },
      { text: '[x] "Ranger"  is not installed' },
      { text: "" },
      { text: "[ Analysis Results ]" },
      { text: "● Total checked:  240" },
      { text: "● Installed:      52", success: true },
      { text: "● Not found:      188" },
      { text: "" },
      { text: "[✓] Verification process completed.", success: true },
    ];
  }

  if (/^project\s+--help/.test(cmd) || cmd === "project -h") {
    return [
      { text: "Usage: project [command] [flags]" },
      { text: "  install <name>     Install a tool" },
      { text: "  list tools         Show the full registry" },
      { text: "  doctor             Check environment health" },
      { text: "  inspect            Verify installed tools" },
      { text: "  --help             Show this message" },
    ];
  }

  if (/^project\s+doctor/.test(cmd)) {
    return [
      { text: "[✓] Environment healthy. All managed tools present on PATH.", success: true },
    ];
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

  return [
    { text: `bash: ${cmd.split(" ")[0]}: try "project --help" for available commands` },
  ];
}

// ─── Component ───────────────────────────────────────────────────────────────

export default function TerminalDemo() {
  const [mode, setMode] = useState<"auto" | "active">("auto");
  const [autoLines, setAutoLines] = useState<RenderedLine[]>([]);
  const [history, setHistory] = useState<ActiveEntry[]>([]);
  const [input, setInput] = useState("");

  const containerRef = useRef<HTMLDivElement>(null);
  const bodyRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const runIdRef = useRef(0);
  const historyIndexRef = useRef(-1); // for Up/Down arrow nav

  // ── Auto-scroll ───────────────────────────────────────────────────────────
  useEffect(() => {
    if (bodyRef.current) {
      bodyRef.current.scrollTo({
        top: bodyRef.current.scrollHeight,
        behavior: "smooth",
      });
    }
  }, [autoLines, history, input]);

  // ── Auto-play typewriter loop (cycles through all scripts) ────────────────
  useEffect(() => {
    if (mode !== "auto") return;

    const runId = ++runIdRef.current;
    let cancelled = false;

    async function typeLine(line: ScriptLine): Promise<void> {
      if (line.type === "cmd") {
        let typed = "";
        setAutoLines((prev) => [...prev, { type: "cmd", text: "", typing: true }]);

        for (const ch of line.text) {
          if (cancelled || runIdRef.current !== runId) return;
          typed += ch;
          setAutoLines((prev) => {
            const next = [...prev];
            next[next.length - 1] = { type: "cmd", text: typed, typing: true };
            return next;
          });
          await sleep(TYPE_SPEED_MIN + Math.random() * (TYPE_SPEED_MAX - TYPE_SPEED_MIN));
        }

        setAutoLines((prev) => {
          const next = [...prev];
          next[next.length - 1] = { type: "cmd", text: typed };
          return next;
        });
        await sleep(CMD_PAUSE_MS);
      } else {
        setAutoLines((prev) => [...prev, { type: line.type, text: line.text }]);
        await sleep(line.type === "out" && !line.text ? EMPTY_LINE_PAUSE_MS : NORMAL_LINE_PAUSE_MS);
      }
    }

    async function playScript(script: ScriptLine[]) {
      setAutoLines([]);
      await sleep(600);
      for (const line of script) {
        if (cancelled || runIdRef.current !== runId) return;
        await typeLine(line);
      }
    }

    async function playLoop() {
      let scriptIdx = 0;
      while (!cancelled && runIdRef.current === runId) {
        await playScript(SCRIPTS[scriptIdx]);
        scriptIdx = (scriptIdx + 1) % SCRIPTS.length;
        await sleep(LOOP_PAUSE_MS);
      }
    }

    playLoop();

    return () => {
      cancelled = true;
    };
  }, [mode]);

  // ── Click outside to return to auto ───────────────────────────────────────
  useEffect(() => {
    if (mode !== "active") return;

    function handleClickOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setMode("auto");
      }
    }

    document.addEventListener("click", handleClickOutside);
    return () => document.removeEventListener("click", handleClickOutside);
  }, [mode]);

  // ── Focus input when entering active mode ─────────────────────────────────
  useEffect(() => {
    if (mode === "active") {
      inputRef.current?.focus();
    }
  }, [mode]);

  // ── Handlers ──────────────────────────────────────────────────────────────

  const handleActivate = useCallback(() => {
    if (mode === "auto") {
      setMode("active");
      historyIndexRef.current = -1;
    }
  }, [mode]);

  const handleSubmit = useCallback(
    (e: FormEvent) => {
      e.preventDefault();
      const cmd = input.trim();
      setInput("");
      historyIndexRef.current = -1;

      if (cmd === "clear") {
        setHistory([]);
        return;
      }

      const outputs = respondTo(cmd);
      setHistory((prev) => [...prev, { cmd, outputs }]);
    },
    [input]
  );

  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLInputElement>) => {
      if (e.key === "Escape") {
        setMode("auto");
        return;
      }

      if (e.key === "ArrowUp") {
        e.preventDefault();
        const next = historyIndexRef.current + 1;
        const max = history.length - 1;
        if (next > max) return;
        historyIndexRef.current = next;
        setInput(history[history.length - 1 - next].cmd);
        return;
      }

      if (e.key === "ArrowDown") {
        e.preventDefault();
        const next = historyIndexRef.current - 1;
        if (next < -1) return;
        historyIndexRef.current = next;
        if (next === -1) {
          setInput("");
          return;
        }
        setInput(history[history.length - 1 - next].cmd);
        return;
      }
    },
    [history]
  );

  // ── Render helpers ────────────────────────────────────────────────────────

  const renderAutoBody = () => (
    <>
      {autoLines.map((line, i) => (
        <span className="term-line" key={`auto-${i}`}>
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
    </>
  );

  const renderActiveBody = () => (
    <>
      <span className="term-line">
        <span className="term-comment">
          # Try: project --install=git, project list tools, project inspect, project doctor
        </span>
      </span>
      {history.map((entry, i) => (
        <div key={`entry-${entry.cmd}-${i}`}>
          <span className="term-line">
            <span className="term-prompt">$ </span>
            <span className="term-cmd">{entry.cmd}</span>
          </span>
          {entry.outputs.map((o, j) => (
            <span className="term-line" key={`out-${i}-${j}`}>
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
          onChange={(e) => {
            setInput(e.target.value);
            historyIndexRef.current = -1;
          }}
          onKeyDown={handleKeyDown}
          spellCheck={false}
          autoComplete="off"
          aria-label="Terminal command input"
        />
        <span className="term-cursor" />
      </form>
    </>
  );

  // ── JSX ───────────────────────────────────────────────────────────────────

  return (
    <div
      className="hero-terminal"
      ref={containerRef}
      onClick={handleActivate}
      role="button"
      tabIndex={0}
      aria-label="Interactive terminal demo. Click to type commands."
      onKeyDown={(e) => {
        if (e.key === "Enter") handleActivate();
      }}
    >
      <div className="term-bar">
        <span className="term-dot r" />
        <span className="term-dot y" />
        <span className="term-dot g" />
        <span className="term-title">bash — ProjectR v1.4</span>
      </div>

      <div className="term-body" ref={bodyRef}>
        {mode === "auto" ? renderAutoBody() : renderActiveBody()}
      </div>

      <div className="term-hint">
        {mode === "auto"
          ? "Click to type your own commands"
          : "Click outside to return to auto-play · Esc to exit"}
      </div>
    </div>
  );
}
