import { motion, useInView, useMotionValue, useTransform, animate } from "framer-motion";
import { useEffect, useRef } from "react";

interface Stat {
  target: number | null;
  suffix: string;
  label: string;
}

const STATS: Stat[] = [
  { target: 240, suffix: "+", label: "Tools Available" },
  { target: 24, suffix: "", label: "Package Managers" },
  { target: 14, suffix: "", label: "Tool Categories" },
  { target: null, suffix: "", label: "Extensible via Plugins" },
];

function Counter({ target }: { target: number }) {
  const ref = useRef<HTMLSpanElement>(null);
  const isInView = useInView(ref, { once: true, margin: "-20px" });
  const count = useMotionValue(0);
  const rounded = useTransform(count, (v) => Math.round(v).toString());

  useEffect(() => {
    if (isInView) {
      const controls = animate(count, target, { duration: 1.4, ease: [0.16, 1, 0.3, 1] });
      return controls.stop;
    }
  }, [isInView, target, count]);

  return <motion.span ref={ref}>{rounded}</motion.span>;
}

/** Four stat cards below the hero: tool count, package manager count, etc. */
export default function StatsRibbon() {
  return (
    <div className="stats-ribbon">
      {STATS.map((stat, i) => (
        <motion.div
          className="stat-card"
          key={stat.label}
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-20px" }}
          transition={{ duration: 0.4, delay: i * 0.05 }}
        >
          <span className="stat-number">
            {stat.target !== null ? <Counter target={stat.target} /> : "∞"}
            {stat.suffix}
          </span>
          <div className="stat-label">{stat.label}</div>
        </motion.div>
      ))}
    </div>
  );
}
