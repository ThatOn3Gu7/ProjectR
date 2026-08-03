import { useEffect, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import DarkModeToggle from "./DarkModeToggle";

interface NavItem {
  /** Route path, optionally with a "#section" suffix for an in-page anchor */
  to: string;
  label: string;
  icon: string;
}

interface NavGroup {
  label: string;
  items: NavItem[];
}

// Every entry the original single-page site's sidebar had, preserved
// one-for-one. What used to be an in-page anchor on one long page now
// points at "<page-route>#<section-id>" instead — Layout.tsx scrolls to
// that section once the target page has mounted. Nothing from the
// original nav was dropped, it's just addressed differently:
//   Quick Start / One-Shot Install / Setup Launcher  -> sections of /docs
//   Features                                          -> section of /
//   Tool Registry                                      -> its own route, /tools
//   Package Managers / CLI Flags / Presets / Profiles / Plugins -> sections of /reference
//   Architecture / FAQ                                 -> their own routes, unchanged
const NAV_GROUPS: NavGroup[] = [
  {
    label: "Getting Started",
    items: [
      { to: "/", label: "Home", icon: "⌂" },
      { to: "/docs#quick-start", label: "Quick Start", icon: "⚡" },
      { to: "/docs#one-shot", label: "One-Shot Install", icon: "🚀" },
      { to: "/docs#setup", label: "Setup Launcher", icon: "⚙" },
    ],
  },
  {
    label: "Reference",
    items: [
      { to: "/#features", label: "Features", icon: "✦" },
      { to: "/tools", label: "Tool Registry", icon: "□" },
      { to: "/reference#managers", label: "Package Managers", icon: "◈" },
      { to: "/reference#flags", label: "CLI Flags", icon: "⚑" },
    ],
  },
  {
    label: "Advanced",
    items: [
      { to: "/reference#presets", label: "Presets", icon: "⊙" },
      { to: "/reference#profiles", label: "Profiles", icon: "◎" },
      { to: "/reference#plugins", label: "Plugins", icon: "♦" },
      { to: "/architecture", label: "Architecture", icon: "⋮" },
      { to: "/faq", label: "FAQ", icon: "?" },
    ],
  },
];

/** True when a nav item's target page + hash matches the current location exactly. */
function isNavItemActive(item: NavItem, pathname: string, hash: string): boolean {
  const [targetPath, targetHash] = item.to.split("#");
  const normalizedTargetPath = targetPath || "/";
  const normalizedTargetHash = targetHash ? `#${targetHash}` : "";
  return pathname === normalizedTargetPath && hash === normalizedTargetHash;
}

export default function Sidebar() {
  const [open, setOpen] = useState(false);
  const location = useLocation();

  // Close the mobile drawer on every route change (including hash-only changes).
  useEffect(() => {
    setOpen(false);
  }, [location.pathname, location.hash]);

  return (
    <>
      {/* Hamburger only renders while the drawer is closed — the sidebar's
          own close button (below) takes over once it's open, so there's
          never two overlapping toggle controls on screen at once. */}
      {!open && (
        <button
          className="hamburger"
          onClick={() => setOpen(true)}
          aria-label="Open navigation menu"
          aria-expanded={false}
          type="button"
        >
          ☰
        </button>
      )}
      <div
        className={`sidebar-overlay${open ? " open" : ""}`}
        onClick={() => setOpen(false)}
        aria-hidden="true"
      />

      <aside className={`sidebar${open ? " open" : ""}`} id="sidebar">
        <div className="sidebar-brand">
          <div className="logo-mark" aria-hidden="true">
            R
          </div>
          <div className="brand-text">
            <h2>ProjectR</h2>
            <span className="version">v1.4 — stable</span>
          </div>
          <button
            className="sidebar-close"
            onClick={() => setOpen(false)}
            aria-label="Close navigation menu"
            type="button"
          >
            ←
          </button>
        </div>

        <nav aria-label="Primary">
          {NAV_GROUPS.map((group) => (
            <div key={group.label}>
              <div className="nav-group">{group.label}</div>
              {group.items.map((item) => (
                <Link
                  key={item.to}
                  to={item.to}
                  className={isNavItemActive(item, location.pathname, location.hash) ? "active" : ""}
                >
                  <span className="nav-icon" aria-hidden="true">
                    {item.icon}
                  </span>
                  {item.label}
                </Link>
              ))}
            </div>
          ))}
        </nav>

        <div style={{ padding: "20px 24px 0" }}>
          <DarkModeToggle />
        </div>
      </aside>
    </>
  );
}
