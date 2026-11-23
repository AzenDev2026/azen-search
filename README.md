# Azen Search

A KDE Plasma 6 widget (Plasmoid): a Windows 11 style search box that can be pinned to a panel (taskbar).

- Click the capsule search box to open the search popup — it opens
  **centered on the screen** (Windows search style)
- **Fuzzy search**: partial and scattered matches are re-ranked client-side
  (e.g. `dt` or `dte` finds **DeepTerminal** first instead of random junk)
- **Windows-style results**: every row shows the app/file icon, its name and
  a description, grouped under section headers (应用 / 系统设置 / 窗口 …) with
  a category tag on the right and a "新" badge for newly installed apps
- **Keyboard friendly**: ↑ / ↓ move the selection, Enter launches the selected
  result (the first one is preselected, Windows "Best match" style), Esc closes
- Searches: applications, system settings, recent documents, files (Baloo),
  locations, windows, calculator and unit converter
- The "Search on the web" row opens a browser search (Google / Bing / DuckDuckGo)
- **Appearance options** in the official config dialog (right-click the
  widget → Configure Azen Search):
  - **内部 (Inside)**: plain text ("Search here") or search icon + text
  - **外壳 (Shell)**: rounded (Windows 11 style) or square (Windows 10 style)
  - **长度 (Length)**: icon-only, small, medium, large

## Installation

### Install for development

```bash
kpackagetool6 -t Plasma/Applet -i .
```

Then right-click the panel → Enter Edit Mode → Add Widgets → search for "Azen Search".

Or install directly into the user directory:

```bash
mkdir -p ~/.local/share/plasma/plasmoids
cp -r . ~/.local/share/plasma/plasmoids/com.azen.winsearch
plasmashell --replace &   # restart plasmashell to load it
```

## Dependencies

- KDE Plasma 6 (KWin / plasmashell 6)
- krunner, baloo (for file search: run `balooctl enable` once)

## License

GPL-3.0-or-later
