import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// ProjectR docs — Vite configuration.
//
// `base` is set relative ("./") rather than to a fixed repo name so the
// build works out of the box both locally (vite preview) and when hosted
// from a GitHub Pages project site (https://<user>.github.io/<repo>/).
// Because the app uses HashRouter (see src/App.tsx), no server-side
// rewrite rules are required for client-side routes to work on Pages.
export default defineConfig({
  plugins: [react()],
  base: "./",
  server: {
    port: 5173,
    open: true,
  },
  build: {
    outDir: "dist",
    sourcemap: false,
  },
});
