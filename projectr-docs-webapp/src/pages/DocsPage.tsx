import { Link } from "react-router-dom";
import SectionHeader from "../components/SectionHeader";
import CodeBlock from "../components/CodeBlock";

const QUICK_START_STEPS = [
  {
    title: "Clone the repository",
    body: "Grab the source anywhere you like — your home directory, ~/dev, or a dotfiles checkout.",
    code: "git clone https://github.com/Thaton3gu7/ProjectR.git\ncd ProjectR",
  },
  {
    title: "Run the setup script",
    body: "setup.sh copies ProjectR into ~/.local/share/projectr and drops a launcher on your PATH.",
    code: "chmod +x setup.sh\n./setup.sh",
  },
  {
    title: "Launch ProjectR",
    body: "Open a new shell (or source your rc file) and start the interactive menu.",
    code: "project",
  },
];

export default function DocsPage() {
  return (
    <>
      <section className="section" id="quick-start" style={{ paddingTop: 70 }}>
        <SectionHeader
          badge="Getting Started"
          title="⚡ Quick Start"
          description="Three steps between a fresh shell and a fully-loaded terminal."
        />
        <div className="steps">
          {QUICK_START_STEPS.map((step, i) => (
            <div className="step" key={step.title}>
              <div className="step-num">{i + 1}</div>
              <h3>{step.title}</h3>
              <p style={{ marginBottom: 12 }}>{step.body}</p>
              <CodeBlock title="shell" code={step.code}>
                {step.code}
              </CodeBlock>
            </div>
          ))}
        </div>
      </section>

      <div className="divider" />

      <section className="section section-alt" id="one-shot">
        <SectionHeader
          badge="No Clone Required"
          badgeColor="cyan"
          title="🚀 One-Shot Remote Install"
          description="Bootstrap ProjectR on a brand-new machine with a single piped command — no manual clone step."
        />
        <CodeBlock
          title="shell — one-shot install"
          code="curl -fsSL https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh | sh"
        >
          <span className="fl">curl</span> -fsSL{" "}
          <span className="str">https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh</span> | sh
        </CodeBlock>
        <p style={{ color: "var(--text-dim)", fontSize: "0.85rem", marginTop: 8 }}>
          This downloads <code style={{ color: "var(--green)" }}>setup.sh</code> and pipes it straight into your
          shell. It performs the same install as the cloned version — detects your platform, installs the
          launcher, and leaves ProjectR ready to run as <code style={{ color: "var(--green)" }}>project</code>.
          Review any script before piping it into a shell on a machine you care about.
        </p>
      </section>

      <div className="divider" />

      <section className="section" id="setup">
        <SectionHeader
          badge="Configuration"
          badgeColor="violet"
          title="🔧 Setup & Launcher Flags"
          description="Flags accepted by setup.sh at install time, plus the top-level flags of the project launcher itself."
        />

        <h3 style={{ color: "var(--text-bright)", fontSize: "1rem", marginBottom: 12 }}>setup.sh</h3>
        <div className="table-scroll" style={{ marginBottom: 40 }}>
          <table className="flags-table">
            <thead>
              <tr>
                <th>Flag</th>
                <th>Description</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>
                  <code>--silent</code>
                </td>
                <td>Install with no prompts, accepting all defaults.</td>
              </tr>
              <tr>
                <td>
                  <code>--prefix=&lt;path&gt;</code>
                </td>
                <td>
                  Install ProjectR under a custom directory instead of{" "}
                  <code>~/.local/share/projectr</code>.
                </td>
              </tr>
              <tr>
                <td>
                  <code>--no-launcher</code>
                </td>
                <td>Copy the app files but skip creating the <code>project</code> launcher on PATH.</td>
              </tr>
              <tr>
                <td>
                  <code>--uninstall</code>
                </td>
                <td>Remove ProjectR's app files and launcher from this machine.</td>
              </tr>
            </tbody>
          </table>
        </div>

        <h3 style={{ color: "var(--text-bright)", fontSize: "1rem", marginBottom: 12 }}>project launcher</h3>
        <div className="table-scroll">
          <table className="flags-table">
            <thead>
              <tr>
                <th>Flag</th>
                <th>Description</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>
                  <code>--help</code>, <code>-h</code>
                </td>
                <td>Print available commands and exit.</td>
              </tr>
              <tr>
                <td>
                  <code>--version</code>, <code>-v</code>
                </td>
                <td>Print the installed ProjectR version and exit.</td>
              </tr>
              <tr>
                <td>
                  <code>--menu</code>
                </td>
                <td>Force the interactive TUI menu, even when other flags are present.</td>
              </tr>
              <tr>
                <td>(no flags)</td>
                <td>Opens the interactive menu — the default behavior.</td>
              </tr>
            </tbody>
          </table>
        </div>
        <p style={{ color: "var(--text-dim)", fontSize: "0.82rem", marginTop: 16 }}>
          For install, search, preset, and profile flags used day-to-day, see the full{" "}
          <Link to="/reference#flags">CLI Flags reference</Link>.
        </p>
      </section>
    </>
  );
}
