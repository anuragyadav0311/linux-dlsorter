# linux-dlsorter

A background script that automatically organizes your Linux downloads — sorting files into designated folders the exact moment they finish downloading. It also sorts any files **already present** in your Downloads folder on startup.

---

## Features

- **Real-time sorting** — watches `~/Downloads` using `inotifywait` and moves files instantly when a download completes
- **Sorts existing files** — on every run, automatically cleans up files already sitting in your Downloads folder
- **Duplicate handling** — if a file with the same name exists in the destination, it appends a number (e.g. `file_1.pdf`) instead of overwriting
- **On-demand sorting** — run with `--sort` or `-s` to instantly sort existing files without starting the watcher
- **Cross-distro** — auto-installs `inotify-tools` via `apt`, `pacman`, `dnf`, or `yum`

### Sorted Categories

| Folder         | Extensions                                          |
|----------------|-----------------------------------------------------|
| `pdf/`         | `.pdf`                                              |
| `documents/`   | `.doc` `.docx` `.odt` `.rtf` `.txt` `.ppt` `.pptx` `.xls` `.xlsx` `.ods` `.odp` `.odg` `.epub` `.md` |
| `images/`      | `.jpg` `.jpeg` `.png` `.gif` `.webp` `.svg` `.bmp` `.tiff` `.tif` `.ico` `.heic` `.raw` |
| `videos/`      | `.mp4` `.mkv` `.webm` `.avi` `.mov` `.flv` `.wmv` `.3gp` `.ts` `.vob` `.m4v` |
| `music/`       | `.mp3` `.wav` `.flac` `.ogg` `.aac` `.wma` `.m4a` `.opus` `.aiff` |
| `archives/`    | `.zip` `.tar` `.gz` `.rar` `.7z` `.bz2` `.xz` `.zst` `.cab` `.iso` |
| `code/`        | `.py` `.cpp` `.c` `.h` `.hpp` `.sh` `.js` `.ipynb` `.html` `.css` `.ts` `.jsx` `.tsx` `.go` `.rs` `.java` `.rb` `.php` `.swift` `.kt` `.vue` `.yaml` `.yml` `.toml` `.r` |
| `datasets/`    | `.csv` `.json` `.xml` `.sql` `.tsv` `.parquet`      |
| `apps/`        | `.appimage` `.deb` `.rpm` `.snap` `.flatpak`        |

---

## Requirements

- Linux
- `bash`
- `inotify-tools` (auto-installed by the setup script)

---

## Installation

Clone the repo and run the setup script:

```bash
git clone https://github.com/anuragyadav0311/linux-dlsorter.git
cd linux-dlsorter
bash setup-auto-sort.sh
```

The setup script will:
1. Install `inotify-tools` if it isn't already present
2. Create the sorter script at `~/.local/bin/auto-sort-downloads.sh`

---

## Usage

### Sort existing files on demand

To sort files already in `~/Downloads` without starting the background watcher:

```bash
~/.local/bin/auto-sort-downloads.sh --sort
# or
~/.local/bin/auto-sort-downloads.sh -s
```

### Run manually

```bash
nohup ~/.local/bin/auto-sort-downloads.sh > /dev/null 2>&1 &
```

### Auto-start on login

Add the above command to your shell's startup file:

```bash
# For bash
echo 'nohup ~/.local/bin/auto-sort-downloads.sh > /dev/null 2>&1 &' >> ~/.bashrc

# For zsh
echo 'nohup ~/.local/bin/auto-sort-downloads.sh > /dev/null 2>&1 &' >> ~/.zshrc
```

### Auto-start with Hyprland (Omarchy)

Add this line to your `~/.config/hypr/hyprland.conf`:

```
exec-once = ~/.local/bin/auto-sort-downloads.sh
```

---

## How It Works

1. On startup, it scans `~/Downloads` for existing files and sorts them into subfolders
2. It then starts a background watcher using `inotifywait`
3. Whenever a file finishes downloading (`close_write`) or is moved into the folder (`moved_to`), it is immediately sorted into the matching subfolder
4. Empty files and directories are ignored
