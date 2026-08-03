import { Link } from "react-router-dom";

const GITHUB_URL = "https://github.com/Thaton3gu7/ProjectR";

/**
 * Footer, preserved from the original single-page site. The original
 * in-page anchors (#quick-start, #features, #flags, #faq) now point at
 * their new home in the multi-page site (/docs, /, /reference, /faq).
 */
export default function Footer() {
  return (
    <footer className="site-footer">
      <div className="footer-logo">ProjectR</div>
      <div className="footer-links">
        <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer">
          GitHub
        </a>
        <Link to="/docs">Quick Start</Link>
        <Link to="/">Features</Link>
        <Link to="/reference">CLI Reference</Link>
        <Link to="/faq">FAQ</Link>
      </div>
      <p>
        Built with ❤️ by{" "}
        <a
          href="https://github.com/Thaton3gu7"
          target="_blank"
          rel="noopener noreferrer"
          style={{ color: "var(--green)" }}
        >
          ThatOn3Gu7
        </a>
      </p>
      <p style={{ marginTop: 8, fontSize: "0.75rem", color: "var(--text-dim)" }}>
        ProjectR — Modular Bash Terminal Setup Assistant
      </p>
      <p style={{ marginTop: 16, fontSize: "0.7rem", color: "var(--text-dim)" }}>
        Found a bug or have a suggestion? Open an issue on{" "}
        <a href={`${GITHUB_URL}/issues`} target="_blank" rel="noopener noreferrer">
          GitHub Issues
        </a>
        .
      </p>
    </footer>
  );
}
