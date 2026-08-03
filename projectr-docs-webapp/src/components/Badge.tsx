import type { ReactNode } from "react";

type BadgeColor = "green" | "cyan" | "violet" | "pink";

interface BadgeProps {
  color?: BadgeColor;
  children: ReactNode;
}

const COLOR_CLASS: Record<BadgeColor, string> = {
  green: "badge",
  cyan: "badge badge-cyan",
  violet: "badge badge-violet",
  pink: "badge badge-pink",
};

/** Small uppercase pill label, e.g. "Beginner Friendly" above a section heading. */
export default function Badge({ color = "green", children }: BadgeProps) {
  return <span className={COLOR_CLASS[color]}>{children}</span>;
}
