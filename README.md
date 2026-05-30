# Terminal Setup Script (Bash)

A clean, modular **Bash-based terminal setup / installer script** designed to run smoothly even on limited environments (like mobile terminals).  
Built with readability, user experience, and future extensibility in mind.

---

## ✨ Features

- 🎨 **Colored, clean UI**
  - Custom boxed text UI
  - Sectioned menus
  - Graceful exit screen (zoom-safe)

- 🌐 **Internet connectivity checks**
  - Checked at script startup
  - Checked before bulk installs

- 📦 **Package installation system**
  - Install tools one-by-one
  - Multi install (separated by space)
  - Install everything at once
  - Safe handling when offline

- 🧩 **Profile Presets**
  - Predefined install profiles
  - Nested submenus
  - Easy to extend with new presets

- 📝 **Post-install summary**
  - Shows what was installed/skiped/failed
  - Helps verify successful setup

- 🪵 **Logging system**
  - Logs important actions and states
  - Useful for debugging and future expansion

---

## 🛠 Requirements

- Bash (v4+ recommended)
- Standard Linux utilities:
  - `curl` or `wget`
  - `ping`
- Internet connection (for installs)

> Designed to work well in minimal environments (including mobile terminals).

---

## 🚀 Usage

Clone the repository and run the script directly:

```bash
git clone https://github.com/ThatOn3Gu7/ProjectR.git
cd ProjectR
bash main.sh
```

### Optional: install the `project` command

If you want ProjectR to behave like a regular terminal command, run the setup script once:

```bash
git clone https://github.com/ThatOn3Gu7/ProjectR.git
cd ProjectR
bash setup.sh
```

The setup script copies ProjectR into a hidden user app directory (`~/.local/share/projectr` by default) and creates a launcher at `~/.local/bin/project`. After that, you can run ProjectR from any directory:

```bash
project
project --help
project --install=git
project --list=tools
```

If `~/.local/bin` is not already in your `PATH`, either run:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

or rerun setup with:

```bash
bash setup.sh --add-path
```

Useful setup overrides:

```bash
bash setup.sh --command=projectr
bash setup.sh --install-dir="$HOME/.projectr"
bash setup.sh --bin-dir="$HOME/bin"
```


