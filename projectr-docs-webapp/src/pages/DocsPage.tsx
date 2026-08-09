import { useMemo } from "react";
import { Link } from "react-router-dom";
import SectionHeader from "../components/SectionHeader";
import CodeBlock from "../components/CodeBlock";

interface QuickStartStep {
  id: string;
  title: string;
  body: string;
  code: string;
}

const QUICK_START_STEPS: readonly QuickStartStep[] = [
  {
    id: "clone",
    title: "Clone the repository",
    body: "Grab the source anywhere you like — your home directory, ~/dev, or a dotfiles checkout.",
    code: "git clone https://github.com/Thaton3gu7/ProjectR.git\ncd ProjectR",
  },
  {
    id: "run-setup",
    title: "Run the setup script",
    body: "setup.sh copies ProjectR into ~/.local/share/projectr and drops a launcher on your PATH.",
    code: "chmod +x setup.sh\n./setup.sh",
  },
  {
    id: "launch",
    title: "Launch ProjectR",
    body: "Open a new shell (or source your rc file) and start the interactive menu.",
    code: "project",
  },
] as const;

export default function DocsPage() {
  const quickStartSteps = useMemo(
    () =>
      QUICK_START_STEPS.map((step, i) => (
        <div className="step" key={step.id} id={`step-${step.id}`}>
          <div className="step-num" aria-label={`Step ${i + 1}`}>
            {i + 1}
          </div>
          <h3>{step.title}</h3>
          <p className="step-body">{step.body}</p>
          <div className="step-code-wrapper">
            <CodeBlock title="shell" code={step.code}>
              {step.code}
            </CodeBlock>
          </div>
        </div>
      )),
    [],
  );

  return (
    <main className="docs-page">
      <section className="section" id="quick-start" style={{ paddingTop: 70 }}>
        <SectionHeader
          badge="Getting Started"
          title="⚡ Quick Start"
          description="Three steps between a fresh shell and a fully-loaded terminal."
        />
        <div className="steps">{quickStartSteps}</div>
      </section>

      <div className="divider" />

      <section className="step-code-wrapper section section-alt" id="one-shot">
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
          <span className="str">
            https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh
          </span>{" "}
          | sh
        </CodeBlock>
        <p className="disclaimer">
          This downloads <code>setup.sh</code> and pipes it straight into your
          shell. It performs the same install as the cloned version — detects
          your platform, installs the launcher, and leaves ProjectR ready to run
          as <code>project</code>. Review any script before piping it into a
          shell on a machine you care about.
        </p>
      </section>

      <div className="divider" />

      <section className="step-code-wrapper section" id="setup">
        <SectionHeader
          badge="Configuration"
          badgeColor="violet"
          title="🔧 Setup & Launcher Flags"
          description="Flags accepted by setup.sh at install time, plus the top-level flags of the project launcher itself."
        />

        <CodeBlock
          title="shell — setup launcher"
          code="bash setup.sh --no-menu"
        >
          <span className="fl">bash </span>
          <span className="str">setup.sh</span> --no-menu
        </CodeBlock>

        <h3 className="flags-heading">setup.sh</h3>
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
                  <code>--command=&lt;name&gt;</code>
                </td>
                <td>
                  Launcher command name (default: <code>project</code>).
                </td>
              </tr>
              <tr>
                <td>
                  <code>--install-dir=&lt;path&gt;</code>
                </td>
                <td>
                  Hidden install location (default:{" "}
                  <code>~/.local/share/projectr</code>).
                </td>
              </tr>
              <tr>
                <td>
                  <code>--bin-dir=&lt;path&gt;</code>
                </td>
                <td>
                  Directory for launcher (default: <code>~/.local/bin</code>).
                </td>
              </tr>
              <tr>
                <td>
                  <code>--add-path</code>
                </td>
                <td>Add the bin dir to common shell rc files when missing.</td>
              </tr>
              <tr>
                <td>
                  <code>--no-menu</code>
                </td>
                <td>Skip interactive menu, use defaults/flags directly.</td>
              </tr>
              <tr>
                <td>
                  <code>--self-update-mode</code>
                </td>
                <td>Internal: refresh installed copy without any setup UI.</td>
              </tr>
              <tr>
                <td>
                  <code>--force-remote</code>
                </td>
                <td>
                  Internal: refresh installed copy directly from{" "}
                  <code>PROJECTR_REPO_URL</code>.
                </td>
              </tr>
              <tr>
                <td>
                  <code>-h</code>, <code>--help</code>
                </td>
                <td>Show help and exit.</td>
              </tr>
            </tbody>
          </table>
        </div>

        <h3 className="flags-heading">Environment overrides</h3>
        <div className="table-scroll" style={{ marginBottom: 40 }}>
          <table className="flags-table">
            <thead>
              <tr>
                <th>Variable</th>
                <th>Maps to</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>
                  <code>PROJECTR_COMMAND_NAME</code>
                </td>
                <td>
                  Same as <code>--command</code>
                </td>
              </tr>
              <tr>
                <td>
                  <code>PROJECTR_INSTALL_DIR</code>
                </td>
                <td>
                  Same as <code>--install-dir</code>
                </td>
              </tr>
              <tr>
                <td>
                  <code>PROJECTR_BIN_DIR</code>
                </td>
                <td>
                  Same as <code>--bin-dir</code>
                </td>
              </tr>
              <tr>
                <td>
                  <code>PROJECTR_REPO_URL</code>
                </td>
                <td>
                  Git remote to clone (default:{" "}
                  <code>https://github.com/Thaton3gu7/ProjectR.git</code>)
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <h3 className="flags-heading">project launcher</h3>
        <div className="table-scroll">
          <table className="flags-table">
            <thead>
              <tr>
                <th>Command / Flag</th>
                <th>Description</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>
                  <code>project</code>
                </td>
                <td>Run interactive mode via launcher name (default).</td>
              </tr>
              <tr>
                <td>
                  <code>project --help</code>
                </td>
                <td>Show the help menu.</td>
              </tr>
              <tr>
                <td>
                  <code>project --install=&lt;tool&gt;</code>
                </td>
                <td>Install a tool non-interactively.</td>
              </tr>
              <tr>
                <td>
                  <code>project --self-update</code>
                </td>
                <td>Updates ProjectR via GitHub.</td>
              </tr>
            </tbody>
          </table>
        </div>

        <h3 className="flags-heading" style={{ marginTop: 40 }}>
          Examples
        </h3>
        <CodeBlock title="shell" code="bash setup.sh">
          <span className="fl">bash</span> setup.sh{" "}
          <span className="cm"># Launch interactive setup menu</span>
        </CodeBlock>
        <CodeBlock title="shell" code="bash setup.sh --no-menu">
          <span className="fl">bash</span> setup.sh --no-menu{" "}
          <span className="cm"># Install with defaults (no menu)</span>
        </CodeBlock>
        <CodeBlock title="shell" code="project --install=git">
          <span className="fl">project</span> --install=git{" "}
          <span className="cm"># Installs git non-interactively</span>
        </CodeBlock>

        <p className="flags-linkout">
          For install, search, preset, and profile flags used day-to-day, see
          the full <Link to="/reference#flags">CLI Flags reference</Link>.
        </p>
      </section>
    </main>
  );
}
