# Azen Search

A KDE Plasma 6 widget (Plasmoid): a Windows 11 style search box that can be pinned to a panel (taskbar).

- Click the capsule search box to open the search popup
- Searches: applications, system settings, recent documents, files (Baloo), locations, windows,
  calculator and unit converter
- Enter launches the first result; the "Search on the web" row opens a browser search
- Width and search engine can be adjusted in the widget settings

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
- krunner, baloo (optional; enables file search)

## License

GPL-3.0-or-later
