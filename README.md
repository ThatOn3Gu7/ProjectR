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

Clone the repository and run the script:

```bash
git clone https://github.com/ThatOn3Gu7/ProjectR.git

cd ProjectR

```bash
bash main.sh


