import { useEffect, useState } from "react";
import { useLocation } from "react-router-dom";

/** Thin green progress bar across the top of the page, tracking scroll position. */
export default function ScrollProgress() {
  const [pct, setPct] = useState(0);
  const location = useLocation();

  // New route -> reset the bar to empty until the user scrolls again.
  // (Actual scroll-to-top / scroll-to-hash behavior lives in Layout.tsx,
  // since it needs to wait for the page transition to finish.)
  useEffect(() => {
    setPct(0);
  }, [location.pathname]);

  useEffect(() => {
    function handleScroll() {
      const scrollable = document.documentElement.scrollHeight - window.innerHeight;
      const next = scrollable > 0 ? (window.scrollY / scrollable) * 100 : 0;
      setPct(next);
    }
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return <div id="scroll-bar" style={{ width: `${pct}%` }} />;
}
