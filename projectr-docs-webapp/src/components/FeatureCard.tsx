import { motion } from "framer-motion";
import type { ReactNode } from "react";

interface FeatureCardProps {
  icon: string;
  title: string;
  description: ReactNode;
  /** Stagger index — used to slightly delay each card's entrance animation */
  index?: number;
}

/** A single feature/preset card used on the Home and Reference pages. */
export default function FeatureCard({ icon, title, description, index = 0 }: FeatureCardProps) {
  return (
    <motion.div
      className="feature-card"
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-30px" }}
      transition={{ duration: 0.4, delay: Math.min(index, 8) * 0.04, ease: [0.16, 1, 0.3, 1] }}
    >
      <div className="feature-icon-wrap" aria-hidden="true">
        {icon}
      </div>
      <h3>{title}</h3>
      <p>{description}</p>
    </motion.div>
  );
}
