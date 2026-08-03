import { HashRouter, Route, Routes } from "react-router-dom";
import Layout from "./components/Layout";
import HomePage from "./pages/HomePage";
import DocsPage from "./pages/DocsPage";
import ToolsPage from "./pages/ToolsPage";
import ReferencePage from "./pages/ReferencePage";
import ArchitecturePage from "./pages/ArchitecturePage";
import FaqPage from "./pages/FaqPage";

// HashRouter is used (rather than BrowserRouter) so the built site works
// on GitHub Pages — and any other static host — without server-side
// rewrite rules for client-side routes. See vite.config.ts for the
// matching relative `base` setting.
export default function App() {
  return (
    <HashRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<HomePage />} />
          <Route path="/docs" element={<DocsPage />} />
          <Route path="/tools" element={<ToolsPage />} />
          <Route path="/reference" element={<ReferencePage />} />
          <Route path="/architecture" element={<ArchitecturePage />} />
          <Route path="/faq" element={<FaqPage />} />
          <Route path="*" element={<HomePage />} />
        </Route>
      </Routes>
    </HashRouter>
  );
}
