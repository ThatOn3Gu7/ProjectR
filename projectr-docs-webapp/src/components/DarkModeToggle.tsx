import { useDarkMode } from "../hooks/useDarkMode";

/** Icon button that flips the site between the dark terminal theme and light theme. */
export default function DarkModeToggle() {
  const { theme, toggleTheme } = useDarkMode();

  return (
    <button
      type="button"
      className="dark-toggle"
      onClick={toggleTheme}
      aria-label={theme === "dark" ? "Switch to light theme" : "Switch to dark theme"}
      title={theme === "dark" ? "Switch to light theme" : "Switch to dark theme"}
    >
      {theme === "dark" ? "☀" : "☾"}
    </button>
  );
}
