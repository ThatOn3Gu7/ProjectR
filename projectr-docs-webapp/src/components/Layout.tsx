import { AnimatePresence, motion } from "framer-motion";
import { useEffect } from "react";
import { useLocation, useOutlet } from "react-router-dom";
import Sidebar from "./Sidebar";
import Footer from "./Footer";
import ScrollProgress from "./ScrollProgress";
import MatrixRain from "./MatrixRain";

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -8 },
};

/**
 * Shared shell for every route: sidebar navigation, the routed page
 * (wrapped in a Framer Motion fade/slide transition keyed by pathname),
 * and the footer. Mounted once by App.tsx around <Routes>.
 */
export default function Layout() {
  const location = useLocation();
  const outlet = useOutlet();

  // After each route change, either scroll to the top of the new page,
  // or — if the link included a hash (e.g. "/docs#one-shot") — scroll to
  // that section once it has mounted and the page transition has settled.
  useEffect(() => {
    const id = location.hash?.replace(/^#/, "");
    const timer = window.setTimeout(() => {
      if (id) {
        const el = document.getElementById(id);
        if (el) {
          el.scrollIntoView({ behavior: "smooth", block: "start" });
          return;
        }
      }
      window.scrollTo({ top: 0 });
    }, 320);
    return () => window.clearTimeout(timer);
  }, [location.pathname, location.hash]);

  return (
    <>
      <MatrixRain />
      <div className="scanline-overlay" aria-hidden="true" />
      <ScrollProgress />
      <Sidebar />

      <main className="app-main">
        <AnimatePresence mode="wait" initial={false}>
          <motion.div
            key={location.pathname}
            variants={pageVariants}
            initial="initial"
            animate="animate"
            exit="exit"
            transition={{ duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
          >
            {outlet}
          </motion.div>
        </AnimatePresence>
        <Footer />
      </main>
    </>
  );
}
