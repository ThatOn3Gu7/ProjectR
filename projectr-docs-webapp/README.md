# ProjectR Docs

A modern, terminal-themed documentation site for **ProjectR**, a modular Bash
terminal setup assistant. Built as a multi-page React + TypeScript app with
client-side routing, a live-searchable 255-tool registry, an interactive
terminal demo, and full dark/light theming.

## Tech stack

- **React 18** + **TypeScript**
- **Vite** — dev server & build
- **React Router v6** (`HashRouter`) — client-side, multi-page navigation
- **Tailwind CSS** — utility styling, alongside a hand-written terminal
  design system (`src/styles/index.css`) for the hacker aesthetic
- **Framer Motion** — page transitions, scroll-in animations, animated stat
  counters

## Getting started

```bash
npm install
npm run dev
```

The dev server opens at `http://localhost:5173`.

### Build for production

```bash
npm run build
```

Output is written to `dist/`. Preview the production build locally with:

```bash
npm run preview
```

## Deploying to GitHub Pages

This project uses **`HashRouter`** and a **relative Vite `base` (`./`)**, so
the build works unmodified on a GitHub Pages *project* site
(`https://<user>.github.io/<repo>/`) — no server rewrite rules needed for
client-side routes, and no need to hard-code your repo name into the config.

1. Build the site: `npm run build`
2. Push the contents of `dist/` to a `gh-pages` branch. The simplest way is
   the [`gh-pages`](https://www.npmjs.com/package/gh-pages) package:
   ```bash
   npm install -D gh-pages
   npx gh-pages -d dist
   ```
3. In your repository's **Settings → Pages**, set the source to the
   `gh-pages` branch (root).
4. Your site will be live at `https://<user>.github.io/<repo>/`.

(If you'd rather use `BrowserRouter` with real paths, set Vite's `base` to
`/<repo>/` in `vite.config.ts` and add a `404.html` that redirects to
`index.html`, since Pages has no built-in SPA fallback. `HashRouter` avoids
that extra step entirely, which is why it's the default here.)

## Project structure

```
src/
├── components/   Reusable UI: Layout, Sidebar, Footer, TerminalDemo,
│                 StatsRibbon, FeatureCard, ToolCard, CodeBlock,
│                 DarkModeToggle, SectionHeader, Badge, MatrixRain,
│                 ScrollProgress
├── pages/        One component per route (Home, Docs, Tools, Reference,
│                 Architecture, FAQ)
├── data/         tools.json — the 255-entry tool registry
├── hooks/        useDarkMode.ts — theme state + localStorage persistence
├── types/        Shared TypeScript interfaces (Tool, CategoryMeta)
├── styles/       index.css — Tailwind directives + the terminal design system
├── App.tsx       HashRouter + route table
└── main.tsx      React entry point
```

## Assumptions made while building this

The brief said to make reasonable assumptions where the source content was
ambiguous and to document them — here's what was decided and why:

- **In-page anchors → routes.** The original was a single scrolling page;
  this is now six routed pages. Anchors that used to jump to a section on
  the same page (`#quick-start`, `#one-shot`, `#flags`, etc.) now navigate to
  the page that contains that section (e.g. `/docs#one-shot`), and the
  `Layout` component scrolls to the matching element after the route
  transition finishes. Section `id`s from the original page were preserved
  so these links keep working.
- **Category count vs. stats ribbon.** The source content advertises "14
  categories" in the stats ribbon but only ever defines 10 named categories
  (Dev, Essentials, Fun, Security, OSINT, Cloud & Containers, Database, Web
  & Network, Data & Docs, AI). That mismatch is preserved as-is rather than
  invented away — it's presented as original copy, not a data integrity
  guarantee.
- **Tool registry (`tools.json`).** All tools explicitly named in the source
  material are included verbatim. Each category was then padded with
  additional **real, well-known CLI tools** (not invented ones) to comfortably
  clear both its own "N+ tools" badge and the site-wide 240+ total (255
  tools shipped). Homepage URLs are accurate for widely-known tools; a
  handful of less common entries use a best-effort URL and should be spot
  checked before this is used as a real product.
- **Docs/Reference/Architecture/FAQ content.** Flags, presets, the plugin
  TOML format, and the directory tree are original but consistent
  extrapolations of ProjectR's documented behavior (install/search/undo/
  export/import/audit/doctor, a `tools.d/` plugin directory, etc.) — written
  to read as real, coherent CLI documentation rather than placeholder text.
- **Favicon.** Delivered as `public/favicon.svg` (the "R" logomark) rather
  than a binary `.ico`, referenced from `index.html` via
  `<link rel="icon" type="image/svg+xml">`. Every modern browser accepts an
  SVG favicon; swap in a `.ico`/`.png` if you need legacy browser support.
- **Matrix rain effect.** Implemented as a low-opacity (`0.08`) canvas
  animation behind all content, and skipped entirely when the visitor has
  `prefers-reduced-motion` set, in line with "tasteful, not over-animated."

## Accessibility notes

- All interactive elements (nav links, buttons, search input, accordion
  triggers) are real `<button>`/`<a>`/`<input>` elements with visible focus
  states inherited from the browser default plus the theme's hover styling.
- The FAQ accordion uses `aria-expanded` / `aria-controls`.
- The hamburger menu uses `aria-expanded` and an `aria-label`.
- `prefers-reduced-motion` disables the matrix rain animation and shortens
  all CSS transitions/animations site-wide.
