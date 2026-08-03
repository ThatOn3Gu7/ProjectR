import SectionHeader from "../components/SectionHeader";
import CodeBlock from "../components/CodeBlock";
import FeatureCard from "../components/FeatureCard";

const PACKAGE_MANAGERS = [
  "apt", "pacman", "dnf", "yum", "zypper", "apk", "xbps", "emerge",
  "brew", "port", "pkg", "choco", "scoop", "winget",
  "snap", "flatpak", "nix",
  "npm", "pip", "cargo", "gem", "go install", "composer", "luarocks",
];

const PRESETS = [
  {
    icon: "🪶",
    title: "Minimal",
    description: "Just the essentials: git, curl, wget, htop, and a sane text editor. Fast on any machine.",
  },
  {
    icon: "🧑‍💻",
    title: "Developer",
    description: "A full dev loadout — git tooling, language runtimes, linters, formatters, and container CLIs.",
  },
  {
    icon: "🎉",
    title: "Fun",
    description: "Every terminal toy in the registry: cowsay, cmatrix, asciiquarium, and the rest of the fun category.",
  },
];

export default function ReferencePage() {
  return (
    <>
      <section className="section" id="managers" style={{ paddingTop: 70 }}>
        <SectionHeader
          badge="24+ Supported"
          title="🖥️ Package Managers"
          description="ProjectR auto-detects whichever package managers are already on your system and uses the right one for each tool."
        />
        <div className="managers-wrap">
          {PACKAGE_MANAGERS.map((mgr) => (
            <span className="mgr-chip" key={mgr}>
              {mgr}
            </span>
          ))}
        </div>
      </section>

      <div className="divider" />

      <section className="section section-alt" id="flags">
        <SectionHeader
          badge="Scriptable"
          badgeColor="cyan"
          title="⚑ CLI Flags"
          description="Every interactive-menu action has a non-interactive flag equivalent, for scripts and CI pipelines."
        />
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
              <td><code>--install=&lt;tool&gt;</code></td>
              <td>Install one or more comma-separated tools by name.</td>
            </tr>
            <tr>
              <td><code>--uninstall=&lt;tool&gt;</code></td>
              <td>Remove a previously installed tool.</td>
            </tr>
            <tr>
              <td><code>--search=&lt;term&gt;</code></td>
              <td>Fuzzy-search the registry and detected package managers.</td>
            </tr>
            <tr>
              <td><code>--list</code></td>
              <td>Print the full tool registry to stdout.</td>
            </tr>
            <tr>
              <td><code>--preset=&lt;name&gt;</code></td>
              <td>Install a curated group: <code>minimal</code>, <code>developer</code>, or <code>fun</code>.</td>
            </tr>
            <tr>
              <td><code>--dry-run</code></td>
              <td>Simulate an install/uninstall and print what would happen, without changing anything.</td>
            </tr>
            <tr>
              <td><code>--undo</code></td>
              <td>Roll back the most recent install session.</td>
            </tr>
            <tr>
              <td><code>--export=&lt;file&gt;</code></td>
              <td>Write the currently installed tool set to a profile file.</td>
            </tr>
            <tr>
              <td><code>--import=&lt;file&gt;</code></td>
              <td>Install every tool listed in a profile file.</td>
            </tr>
            <tr>
              <td><code>--audit</code></td>
              <td>Validate the tool registry and report any malformed or duplicate entries.</td>
            </tr>
            <tr>
              <td><code>doctor</code></td>
              <td>Check that every installed tool is present and resolvable on PATH.</td>
            </tr>
            <tr>
              <td><code>--plugin-dir=&lt;path&gt;</code></td>
              <td>Load additional tool definitions from a custom plugin directory.</td>
            </tr>
          </tbody>
        </table>
        </div>
      </section>

      <div className="divider" />

      <section className="section" id="presets">
        <SectionHeader
          badge="One Click"
          badgeColor="violet"
          title="📋 Presets"
          description="Curated tool groups for common setups — install a complete environment in one command."
        />
        <div className="features-grid">
          {PRESETS.map((preset, i) => (
            <FeatureCard key={preset.title} icon={preset.icon} title={preset.title} description={preset.description} index={i} />
          ))}
        </div>
        <CodeBlock title="shell" code="project --preset=developer" >
          <span className="fl">project</span> --preset=<span className="str">developer</span>
        </CodeBlock>
      </section>

      <div className="divider" />

      <section className="section section-alt" id="profiles">
        <SectionHeader
          badge="Portable Setups"
          badgeColor="pink"
          title="📁 Profiles"
          description="Export your exact tool set from one machine and replay it on another."
        />
        <CodeBlock title="shell — export" code="project --export=my-setup.profile">
          <span className="cm"># Save everything currently installed via ProjectR</span>
          {"\n"}
          <span className="fl">project</span> --export=<span className="str">my-setup.profile</span>
        </CodeBlock>
        <CodeBlock title="shell — import" code="project --import=my-setup.profile">
          <span className="cm"># Reproduce that exact tool set on a new machine</span>
          {"\n"}
          <span className="fl">project</span> --import=<span className="str">my-setup.profile</span>
        </CodeBlock>
      </section>

      <div className="divider" />

      <section className="section" id="plugins">
        <SectionHeader
          badge="Extensible"
          title="🧩 Plugins"
          description="Add your own tools to the registry without touching ProjectR's core files."
        />
        <p style={{ color: "var(--text-dim)", fontSize: "0.86rem", marginBottom: 12 }}>
          Drop a <code style={{ color: "var(--green)" }}>.toml</code> file into{" "}
          <code style={{ color: "var(--green)" }}>~/.config/projectr/tools.d/</code> and ProjectR picks it up
          automatically on the next run:
        </p>
        <CodeBlock
          title="tools.d/my-tool.toml"
          code={`[tool]
name = "my-cli-tool"
category = "Dev"
description = "A custom internal CLI, not in the public registry."
icon = "🧰"
homepage = "https://example.com/my-cli-tool"

[install]
apt = "my-cli-tool"
brew = "my-cli-tool"
cargo = "my-cli-tool"`}
        >
          <span className="kw">[tool]</span>
          {"\n"}name = <span className="str">"my-cli-tool"</span>
          {"\n"}category = <span className="str">"Dev"</span>
          {"\n"}description = <span className="str">"A custom internal CLI, not in the public registry."</span>
          {"\n"}icon = <span className="str">"🧰"</span>
          {"\n"}homepage = <span className="str">"https://example.com/my-cli-tool"</span>
          {"\n\n"}
          <span className="kw">[install]</span>
          {"\n"}apt = <span className="str">"my-cli-tool"</span>
          {"\n"}brew = <span className="str">"my-cli-tool"</span>
          {"\n"}cargo = <span className="str">"my-cli-tool"</span>
        </CodeBlock>
      </section>
    </>
  );
}
