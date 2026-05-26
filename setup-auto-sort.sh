#!/bin/bash

# This script sets up the auto-sort-downloads functionality with a professional TUI and Marker File logic.

# Function to check for a command's existence
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_dependencies() {
    local pkgs=("inotify-tools" "gum")
    local missing=()

    for pkg in "${pkgs[@]}"; do
        if ! command_exists "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        return
    fi

    echo "Missing dependencies: ${missing[*]}"
    echo "Attempting to install..."
    
    if command_exists pacman; then
        sudo pacman -S --noconfirm "${missing[@]}"
    elif command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y "${missing[@]}"
    elif command_exists dnf; then
        sudo dnf install -y "${missing[@]}"
    else
        echo "Could not find a supported package manager to install: ${missing[*]}"
        echo "Please install them manually and run this script again."
        exit 1
    fi
}

# Initialize dependencies
install_dependencies

# --- TUI Configuration Phase ---

gum format "# Auto-Sort Downloads Configuration" \
           "This utility will configure your Downloads directory for automatic organization." \
           "Marker files (hidden tags) will be utilized to ensure folder renames do not disrupt functionality."

# 1. Select Categories
CATEGORIES=$(gum choose --no-limit --header "Select categories to enable (Space to toggle, Enter to confirm):" \
    "pdf" "documents" "presentations" "spreadsheets" "images" "videos" "music" "archives" \
    "code" "datasets" "fonts" "ebooks" "designs" "3d_models" "configs" "apps")

if [ -z "$CATEGORIES" ]; then
    echo "No categories selected. Operation terminated."
    exit 0
fi

# 2. Define Folder Names
declare -A FOLDER_NAMES
for CAT in $CATEGORIES; do
    NAME=$(gum input --placeholder "Default: $CAT" --value "$CAT" --header "Enter destination folder name for $CAT:")
    FOLDER_NAMES[$CAT]=${NAME:-$CAT}
done

# --- Script Generation Phase ---

create_sort_script() {
    mkdir -p "$HOME/.local/bin"
    
    # Pre-calculate category mapping for the script
    local MAPPING_BLOCK=""
    for CAT in "${!FOLDER_NAMES[@]}"; do
        MAPPING_BLOCK+="    [\"$CAT\"]=\"${FOLDER_NAMES[$CAT]}\" \n"
    done

    # Create the script using a heredoc
    cat > "$HOME/.local/bin/auto-sort-downloads.sh" << EOF
#!/bin/bash
DOWNLOAD_DIR="\$HOME/Downloads"

# Mapping of internal category to default folder name
declare -A DEFAULT_NAMES
$(echo -e "$MAPPING_BLOCK")

# Function to find or create a folder based on its marker tag
get_dest_folder() {
    local cat="\$1"
    local tag=".sort_tag_\$cat"
    local default_name="\${DEFAULT_NAMES[\$cat]}"
    
    # Attempt to locate a folder containing the marker tag (limit to 2 levels)
    local found_path=\$(find "\$DOWNLOAD_DIR" -maxdepth 2 -name "\$tag" -printf '%h\n' | head -n 1)
    
    if [ -n "\$found_path" ]; then
        echo "\$found_path"
    else
        # Not found, initialize default directory with marker
        local dest="\$DOWNLOAD_DIR/\$default_name"
        mkdir -p "\$dest"
        touch "\$dest/\$tag"
        echo "\$dest"
    fi
}

# Ensure all enabled folders/tags exist at startup
for cat in "\${!DEFAULT_NAMES[@]}"; do
    get_dest_folder "\$cat" > /dev/null
done

# Function to move a file while handling duplicates
move_file() {
    local file="\$1"
    local dest_folder="\$2"
    local filename=\$(basename "\$file")
    local dest_path="\$dest_folder/\$filename"
    local counter=1

    while [ -e "\$dest_path" ]; do
        local name="\${filename%.*}"
        local ext="\${filename##*.}"
        if [ "\$name" == "\$ext" ]; then
            dest_path="\$dest_folder/\${name}_\$counter"
        else
            dest_path="\$dest_folder/\${name}_\$counter.\$ext"
        fi
        counter=\$((counter + 1))
    done

    mv "\$file" "\$dest_path"
}

sort_file() {
    local file="\$1"
    local ext="\${file##*.}"
    ext="\${ext,,}"

    case "\$ext" in
        pdf) [ -n "\${DEFAULT_NAMES[pdf]}" ] && move_file "\$file" "\$(get_dest_folder pdf)" ;;
        doc|docx|odt|ott|rtf|txt|text|md|markdown|tex|pages|wpd|wps) [ -n "\${DEFAULT_NAMES[documents]}" ] && move_file "\$file" "\$(get_dest_folder documents)" ;;
        ppt|pptx|pptm|pps|ppsx|odp|otp|key) [ -n "\${DEFAULT_NAMES[presentations]}" ] && move_file "\$file" "\$(get_dest_folder presentations)" ;;
        xls|xlsx|xlsm|xlsb|ods|ots|numbers) [ -n "\${DEFAULT_NAMES[spreadsheets]}" ] && move_file "\$file" "\$(get_dest_folder spreadsheets)" ;;
        jpg|jpeg|png|gif|webp|svg|bmp|tif|tiff|heic|heif|avif|ico|raw|cr2|nef|arw|dng) [ -n "\${DEFAULT_NAMES[images]}" ] && move_file "\$file" "\$(get_dest_folder images)" ;;
        mp4|mkv|webm|avi|mov|wmv|flv|m4v|mpg|mpeg|3gp|ts) [ -n "\${DEFAULT_NAMES[videos]}" ] && move_file "\$file" "\$(get_dest_folder videos)" ;;
        mp3|wav|flac|ogg|oga|m4a|aac|wma|opus|mid|midi) [ -n "\${DEFAULT_NAMES[music]}" ] && move_file "\$file" "\$(get_dest_folder music)" ;;
        zip|tar|gz|tgz|bz2|tbz2|xz|txz|rar|7z|zst|lz|lzma|iso) [ -n "\${DEFAULT_NAMES[archives]}" ] && move_file "\$file" "\$(get_dest_folder archives)" ;;
        py|pyw|js|mjs|cjs|ts|tsx|jsx|java|c|cc|cpp|cxx|h|hh|hpp|cs|go|rs|rb|php|swift|kt|kts|scala|lua|pl|pm|r|sh|bash|zsh|fish|ps1|bat|cmd|html|htm|css|scss|sass|less|vue|svelte|ipynb|sql|dockerfile|makefile) [ -n "\${DEFAULT_NAMES[code]}" ] && move_file "\$file" "\$(get_dest_folder code)" ;;
        csv|tsv|json|jsonl|ndjson|xml|parquet|avro|orc|feather|db|sqlite|sqlite3|h5|hdf5|pkl|pickle|sav|dta|xpt|arff|mat) [ -n "\${DEFAULT_NAMES[datasets]}" ] && move_file "\$file" "\$(get_dest_folder datasets)" ;;
        ttf|otf|woff|woff2|eot|fon|fnt) [ -n "\${DEFAULT_NAMES[fonts]}" ] && move_file "\$file" "\$(get_dest_folder fonts)" ;;
        epub|mobi|azw|azw3|fb2|djvu|cbz|cbr|lit|lrf) [ -n "\${DEFAULT_NAMES[ebooks]}" ] && move_file "\$file" "\$(get_dest_folder ebooks)" ;;
        psd|psb|ai|eps|indd|idml|fig|sketch|xd|afdesign|afphoto|ase|cdr) [ -n "\${DEFAULT_NAMES[designs]}" ] && move_file "\$file" "\$(get_dest_folder designs)" ;;
        obj|fbx|stl|glb|gltf|dae|3ds|blend|ply|step|stp|iges|igs|usd|usdz) [ -n "\${DEFAULT_NAMES[3d_models]}" ] && move_file "\$file" "\$(get_dest_folder 3d_models)" ;;
        yaml|yml|toml|ini|conf|cfg|env|properties|plist|desktop|service|lock) [ -n "\${DEFAULT_NAMES[configs]}" ] && move_file "\$file" "\$(get_dest_folder configs)" ;;
        appimage|deb|rpm|flatpakref|flatpak|snap|apk|exe|msi|pkg|dmg|run|bin) [ -n "\${DEFAULT_NAMES[apps]}" ] && move_file "\$file" "\$(get_dest_folder apps)" ;;
    esac
}

sort_existing_files() {
    find "\$DOWNLOAD_DIR" -maxdepth 1 -type f | while read FILE; do
        if [ ! -s "\$FILE" ]; then continue; fi
        sort_file "\$FILE"
    done
}

if [ "\$1" = "--sort" ] || [ "\$1" = "-s" ]; then
    sort_existing_files
    exit 0
fi

sort_existing_files

inotifywait -m -e close_write,moved_to --format "%w%f" "\$DOWNLOAD_DIR" | while read FILE
do
    if [ -d "\$FILE" ] || [ ! -s "\$FILE" ]; then continue; fi
    sort_file "\$FILE"
done
EOF

    chmod +x "$HOME/.local/bin/auto-sort-downloads.sh"
}

# --- Autostart Phase ---

setup_autostart() {
    local CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
    
    CHOICE=$(gum choose --header "Select Autostart Method:" \
        "Systemd user service (Recommended)" \
        "XDG Autostart (.desktop file)" \
        "Hyprland (exec-once)" \
        "None / Manual")

    case "$CHOICE" in
        *"Systemd"*)
            if command_exists systemctl; then
                mkdir -p "$CONFIG_DIR/systemd/user"
                cat > "$CONFIG_DIR/systemd/user/auto-sort-downloads.service" << EOF
[Unit]
Description=Auto Sort Downloads Service
After=network.target

[Service]
ExecStart=$HOME/.local/bin/auto-sort-downloads.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
                systemctl --user daemon-reload
                systemctl --user enable auto-sort-downloads.service
                systemctl --user start auto-sort-downloads.service
                gum format "Systemd user service enabled and started."
            else
                gum format "Error: systemctl not found."
                setup_autostart
            fi
            ;;
        *"XDG"*)
            mkdir -p "$CONFIG_DIR/autostart"
            cat > "$CONFIG_DIR/autostart/auto-sort-downloads.desktop" << EOF
[Desktop Entry]
Type=Application
Exec=$HOME/.local/bin/auto-sort-downloads.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Auto Sort Downloads
Comment=Automatically sort downloads folder
EOF
            gum format "Added autostart entry to $CONFIG_DIR/autostart/auto-sort-downloads.desktop."
            ;;
        *"Hyprland"*)
            local HYPR_CONF="$CONFIG_DIR/hypr/hyprland.conf"
            if [ -f "$HYPR_CONF" ]; then
                if ! grep -Fq "auto-sort-downloads.sh" "$HYPR_CONF"; then
                    echo "" >> "$HYPR_CONF"
                    echo "# Auto-sort downloads startup" >> "$HYPR_CONF"
                    echo "exec-once = $HOME/.local/bin/auto-sort-downloads.sh" >> "$HYPR_CONF"
                fi
                gum format "Added autostart command to $HYPR_CONF."
            else
                gum format "Error: Hyprland config not found at $HYPR_CONF."
                setup_autostart
            fi
            ;;
        *)
            gum format "Skipping autostart configuration."
            ;;
    esac
}

# --- Execution ---
create_sort_script
setup_autostart

gum format "## Setup Complete" \
           "The application is installed at: \`~/.local/bin/auto-sort-downloads.sh\`" \
           "Destination folders in \`~/Downloads\` may now be renamed without impacting functionality."
