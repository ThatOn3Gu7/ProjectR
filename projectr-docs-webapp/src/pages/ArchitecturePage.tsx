import SectionHeader from "../components/SectionHeader";

export default function ArchitecturePage() {
  return (
    <section className="section" style={{ paddingTop: 70 }} id="architecture">
      <SectionHeader
        badge="Under the Hood"
        badgeColor="violet"
        title="⋮ Architecture"
        description="ProjectR is a modular collection of Bash scripts — no single monolithic file to untangle."
      />
      <div className="arch-tree" role="img" aria-label="ProjectR directory structure">
        <span className="dir">ProjectR/</span>
        {"\n"}├── <span className="file">setup.sh</span>              <span className="desc"># One-shot / local installer, drops the launcher on PATH</span>
        {"\n"}├── <span className="file">project</span>                <span className="desc"># Thin entry-point launcher script</span>
        {"\n"}├── <span className="dir">bin/</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;└── <span className="file">project</span>            <span className="desc"># Installed copy of the launcher (symlinked onto PATH)</span>
        {"\n"}├── <span className="dir">lib/</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="dir">core/</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="file">dispatch.sh</span>      <span className="desc"># Parses flags/subcommands, routes to handlers</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="file">detect.sh</span>        <span className="desc"># Detects OS, distro, and available package managers</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="file">install.sh</span>       <span className="desc"># Resolves a tool + manager pair and runs the install</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="file">undo.sh</span>          <span className="desc"># Session-based rollback</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="file">doctor.sh</span>        <span className="desc"># Environment health checks</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;└── <span className="file">audit.sh</span>         <span className="desc"># Validates the tool registry for errors</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="dir">ui/</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="file">menu.sh</span>          <span className="desc"># Interactive TUI menu (search, multi-select, presets)</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;└── <span className="file">theme.sh</span>         <span className="desc"># Terminal colours, banners, and prompts</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="dir">data/</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="file">tools.sh</span>         <span className="desc"># Loads and merges the core registry + plugins</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;└── <span className="file">presets.sh</span>       <span className="desc"># Minimal / Developer / Fun preset definitions</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;└── <span className="dir">profile/</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── <span className="file">export.sh</span>       <span className="desc"># Writes the current tool set to a .profile file</span>
        {"\n"}│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── <span className="file">import.sh</span>       <span className="desc"># Replays a .profile file's tool set</span>
        {"\n"}├── <span className="dir">tools.d/</span>                <span className="desc"># User plugin directory (drop-in .toml tool definitions)</span>
        {"\n"}├── <span className="dir">logs/</span>                   <span className="desc"># Auto-rotating structured session logs</span>
        {"\n"}├── <span className="file">VERSION</span>
        {"\n"}├── <span className="file">LICENSE</span>
        {"\n"}└── <span className="file">README.md</span>
      </div>
      <p style={{ color: "var(--text-dim)", fontSize: "0.85rem", marginTop: 20 }}>
        Every command flows through <code style={{ color: "var(--green)" }}>lib/core/dispatch.sh</code>, whether
        it was triggered from the interactive menu or a CLI flag — so the two interfaces never drift out of
        sync.
      </p>
    </section>
  );
}
