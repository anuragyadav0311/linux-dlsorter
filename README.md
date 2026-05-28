# linux-dlsorter

A background script that automatically organizes your Linux downloads — sorting files into designated folders the exact moment they finish downloading. It also sorts any files **already present** in your Downloads folder on startup.

---

## Features

- **Real-time sorting** — watches `~/Downloads` using `inotifywait` and moves files instantly when a download completes
- **Sorts existing files** — on every run, automatically cleans up files already sitting in your Downloads folder
- **Duplicate handling** — if a file with the same name exists in the destination, it appends a number (e.g. `file_1.pdf`) instead of overwriting
- **On-demand sorting** — run with `--sort` or `-s` to instantly sort existing files without starting the watcher
- **Cross-distro** — auto-installs missing dependencies via `apt`, `pacman`, or `dnf`

### Sorted Categories

| Folder | Extensions |
|--------|------------|
| `pdf/` | `.pdf` |
| `documents/` | `.doc` `.docx` `.odt` `.ott` `.rtf` `.txt` `.text` `.md` `.markdown` `.tex` `.pages` `.wpd` `.wps` |
| `presentations/` | `.ppt` `.pptx` `.pptm` `.pps` `.ppsx` `.odp` `.otp` `.key` |
| `spreadsheets/` | `.xls` `.xlsx` `.xlsm` `.xlsb` `.ods` `.ots` `.numbers` |
| `images/` | `.jpg` `.jpeg` `.png` `.gif` `.webp` `.svg` `.bmp` `.tif` `.tiff` `.heic` `.heif` `.avif` `.ico` `.raw` `.cr2` `.nef` `.arw` `.dng` |
| `videos/` | `.mp4` `.mkv` `.webm` `.avi` `.mov` `.wmv` `.flv` `.m4v` `.mpg` `.mpeg` `.3gp` `.ts` |
| `music/` | `.mp3` `.wav` `.flac` `.ogg` `.oga` `.m4a` `.aac` `.wma` `.opus` `.mid` `.midi` |
| `archives/` | `.zip` `.tar` `.gz` `.tgz` `.bz2` `.tbz2` `.xz` `.txz` `.rar` `.7z` `.zst` `.lz` `.lzma` `.iso` |
| `code/` | `.py` `.pyw` `.js` `.mjs` `.cjs` `.ts` `.tsx` `.jsx` `.java` `.c` `.cc` `.cpp` `.cxx` `.h` `.hh` `.hpp` `.cs` `.go` `.rs` `.rb` `.php` `.swift` `.kt` `.kts` `.scala` `.lua` `.pl` `.pm` `.r` `.sh` `.bash` `.zsh` `.fish` `.ps1` `.bat` `.cmd` `.html` `.htm` `.css` `.scss` `.sass` `.less` `.vue` `.svelte` `.ipynb` `.sql` `.dockerfile` `.makefile` |
| `datasets/` | `.csv` `.tsv` `.json` `.jsonl` `.ndjson` `.xml` `.parquet` `.avro` `.orc` `.feather` `.db` `.sqlite` `.sqlite3` `.h5` `.hdf5` `.pkl` `.pickle` `.sav` `.dta` `.xpt` `.arff` `.mat` |
| `fonts/` | `.ttf` `.otf` `.woff` `.woff2` `.eot` `.fon` `.fnt` |
| `ebooks/` | `.epub` `.mobi` `.azw` `.azw3` `.fb2` `.djvu` `.cbz` `.cbr` `.lit` `.lrf` |
| `designs/` | `.psd` `.psb` `.ai` `.eps` `.indd` `.idml` `.fig` `.sketch` `.xd` `.afdesign` `.afphoto` `.ase` `.cdr` |
| `3d_models/` | `.obj` `.fbx` `.stl` `.glb` `.gltf` `.dae` `.3ds` `.blend` `.ply` `.step` `.stp` `.iges` `.igs` `.usd` `.usdz` |
| `configs/` | `.yaml` `.yml` `.toml` `.ini` `.conf` `.cfg` `.env` `.properties` `.plist` `.desktop` `.service` `.lock` |
| `apps/` | `.appimage` `.deb` `.rpm` `.flatpakref` `.flatpak` `.snap` `.apk` `.exe` `.msi` `.pkg` `.dmg` `.run` `.bin` |

---

## Requirements

- Linux
- `bash`
- `inotify-tools` and `gum` (auto-installed by the setup script)

---

## Installation

Clone the repo and run the setup script:

```bash
git clone https://github.com/anuragyadav0311/linux-dlsorter.git
cd linux-dlsorter
bash setup-auto-sort.sh
```

The setup script will:
1. Install missing dependencies if they are not already present
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
