import { motion } from "framer-motion";
import type { ReactNode } from "react";
import Badge from "./Badge";

type BadgeColor = "green" | "cyan" | "violet" | "pink";

interface SectionHeaderProps {
  badge: string;
  badgeColor?: BadgeColor;
  title: ReactNode;
  description?: ReactNode;
}

/**
 * Standard "badge / heading / description" header used at the top of
 * every documentation section. Fades and slides into view once, the
 * first time it scrolls into the viewport.
 */
export default function SectionHeader({
  badge,
  badgeColor = "green",
  title,
  description,
}: SectionHeaderProps) {
  return (
    <motion.div
      className="section-header"
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-30px" }}
      transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
    >
      <Badge color={badgeColor}>{badge}</Badge>
      <h2>{title}</h2>
      {description && <p>{description}</p>}
    </motion.div>
  );
}
