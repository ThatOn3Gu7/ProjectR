import { useEffect, useRef } from "react";

const CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()";
const FONT_SIZE = 14;

/**
 * Very low-opacity animated "digital rain" backdrop, purely decorative.
 * Fixed behind all page content. Skipped entirely when the user has
 * requested reduced motion.
 */
export default function MatrixRain() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (prefersReducedMotion) return;

    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let width = window.innerWidth;
    let height = window.innerHeight;
    let columns = Math.floor(width / FONT_SIZE);
    let drops = new Array(columns).fill(1);

    function resize() {
      width = window.innerWidth;
      height = window.innerHeight;
      canvas!.width = width;
      canvas!.height = height;
      columns = Math.floor(width / FONT_SIZE);
      drops = new Array(columns).fill(1);
    }
    resize();
    window.addEventListener("resize", resize);

    function draw() {
      ctx!.fillStyle = "rgba(0, 0, 0, 0.06)";
      ctx!.fillRect(0, 0, width, height);
      ctx!.fillStyle = "#00ff41";
      ctx!.font = `${FONT_SIZE}px monospace`;
      for (let i = 0; i < drops.length; i++) {
        const text = CHARS.charAt(Math.floor(Math.random() * CHARS.length));
        ctx!.fillText(text, i * FONT_SIZE, drops[i] * FONT_SIZE);
        if (drops[i] * FONT_SIZE > height && Math.random() > 0.975) drops[i] = 0;
        drops[i]++;
      }
    }

    const interval = window.setInterval(draw, 40);
    return () => {
      window.clearInterval(interval);
      window.removeEventListener("resize", resize);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      aria-hidden="true"
      style={{
        position: "fixed",
        inset: 0,
        width: "100%",
        height: "100%",
        pointerEvents: "none",
        zIndex: 0,
        opacity: 0.08,
      }}
    />
  );
}
