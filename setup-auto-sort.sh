#!/bin/bash

# This script sets up the auto-sort-downloads functionality.

# Function to check for a command's existence
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install inotify-tools if not present
install_inotify_tools() {
    if command_exists inotifywait; then
        echo "inotify-tools is already installed."
        return
    fi

    echo "inotify-tools not found. Attempting to install..."
    
    # Detect package manager and install
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y inotify-tools
    elif command_exists pacman; then
        sudo pacman -S --noconfirm inotify-tools
    elif command_exists dnf; then
        sudo dnf install -y inotify-tools
    elif command_exists yum; then
        sudo yum install -y inotify-tools
    else
        echo "Could not find a supported package manager (apt, pacman, dnf, yum)."
        echo "Please install 'inotify-tools' manually and run this script again."
        exit 1
    fi

    if ! command_exists inotifywait; then
        echo "Failed to install inotify-tools. Please install it manually."
        exit 1
    fi
}

# Function to create the auto-sort script
create_sort_script() {
    # Ensure the target directory exists
    mkdir -p "$HOME/.local/bin"

    # Create the script using a heredoc
    cat > "$HOME/.local/bin/auto-sort-downloads.sh" << 'EOF'
#!/bin/bash
DOWNLOAD_DIR="$HOME/Downloads"

# 1. Create all designated folders
mkdir -p "$DOWNLOAD_DIR/pdf" \
         "$DOWNLOAD_DIR/images" \
         "$DOWNLOAD_DIR/videos" \
         "$DOWNLOAD_DIR/archives" \
         "$DOWNLOAD_DIR/documents" \
         "$DOWNLOAD_DIR/music" \
         "$DOWNLOAD_DIR/code" \
         "$DOWNLOAD_DIR/datasets" \
         "$DOWNLOAD_DIR/apps"

# Function to move a file while handling duplicates
move_file() {
    local file="$1"
    local dest_folder="$2"
    local filename=$(basename "$file")
    local dest_path="$dest_folder/$filename"
    local counter=1

    # Check if a file with the same name already exists
    while [ -e "$dest_path" ]; do
        # If it exists, append a number to the filename
        local name="${filename%.*}"
        local ext="${filename##*.}"
        if [ "$name" == "$ext" ]; then # Handle files with no extension
            dest_path="$dest_folder/${name}_$counter"
        else
            dest_path="$dest_folder/${name}_$counter.$ext"
        fi
        counter=$((counter + 1))
    done

    # Move the file to the destination folder with the new name
    mv "$file" "$dest_path"
}

# 2. Sort any files already present in the Downloads folder
sort_existing_files() {
    echo "Sorting existing files in $DOWNLOAD_DIR..."
    find "$DOWNLOAD_DIR" -maxdepth 1 -type f | while read FILE; do
        if [ ! -s "$FILE" ]; then
            continue
        fi

        EXT="${FILE##*.}"
        EXT="${EXT,,}"

        case "$EXT" in
            pdf) move_file "$FILE" "$DOWNLOAD_DIR/pdf/" ;;
            doc|docx|odt|rtf|txt|ppt|pptx|xls|xlsx|ods|odp|odg|epub|md) move_file "$FILE" "$DOWNLOAD_DIR/documents/" ;;
            jpg|jpeg|png|gif|webp|svg|bmp|tiff|tif|ico|heic|raw) move_file "$FILE" "$DOWNLOAD_DIR/images/" ;;
            mp4|mkv|webm|avi|mov|flv|wmv|3gp|ts|vob|m4v) move_file "$FILE" "$DOWNLOAD_DIR/videos/" ;;
            mp3|wav|flac|ogg|aac|wma|m4a|opus|aiff) move_file "$FILE" "$DOWNLOAD_DIR/music/" ;;
            zip|tar|gz|rar|7z|bz2|xz|zst|cab|iso) move_file "$FILE" "$DOWNLOAD_DIR/archives/" ;;
            py|cpp|c|h|hpp|sh|js|ipynb|html|css|ts|jsx|tsx|go|rs|java|rb|php|swift|kt|vue|yaml|yml|toml|r) move_file "$FILE" "$DOWNLOAD_DIR/code/" ;;
            csv|json|xml|sql|tsv|parquet) move_file "$FILE" "$DOWNLOAD_DIR/datasets/" ;;
            appimage|deb|rpm|snap|flatpak) move_file "$FILE" "$DOWNLOAD_DIR/apps/" ;;
        esac
    done
    echo "Existing files sorted."
}

# Handle --sort flag: sort existing files only, then exit
if [ "$1" = "--sort" ] || [ "$1" = "-s" ]; then
    sort_existing_files
    exit 0
fi

sort_existing_files

# 3. Watch for completely written files AND renamed files
inotifywait -m -e close_write,moved_to --format "%w%f" "$DOWNLOAD_DIR" | while read FILE
do
    # Ignore directories and files with size 0
    if [ -d "$FILE" ] || [ ! -s "$FILE" ]; then
        continue
    fi

    # Extract the file extension
    EXT="${FILE##*.}"
    EXT="${EXT,,}"

    # 4. Sort files based on extension
    case "$EXT" in
        pdf) move_file "$FILE" "$DOWNLOAD_DIR/pdf/" ;;
        doc|docx|odt|rtf|txt|ppt|pptx|xls|xlsx|ods|odp|odg|epub|md) move_file "$FILE" "$DOWNLOAD_DIR/documents/" ;;
        jpg|jpeg|png|gif|webp|svg|bmp|tiff|tif|ico|heic|raw) move_file "$FILE" "$DOWNLOAD_DIR/images/" ;;
        mp4|mkv|webm|avi|mov|flv|wmv|3gp|ts|vob|m4v) move_file "$FILE" "$DOWNLOAD_DIR/videos/" ;;
        mp3|wav|flac|ogg|aac|wma|m4a|opus|aiff) move_file "$FILE" "$DOWNLOAD_DIR/music/" ;;
        zip|tar|gz|rar|7z|bz2|xz|zst|cab|iso) move_file "$FILE" "$DOWNLOAD_DIR/archives/" ;;
        py|cpp|c|h|hpp|sh|js|ipynb|html|css|ts|jsx|tsx|go|rs|java|rb|php|swift|kt|vue|yaml|yml|toml|r) move_file "$FILE" "$DOWNLOAD_DIR/code/" ;;
        csv|json|xml|sql|tsv|parquet) move_file "$FILE" "$DOWNLOAD_DIR/datasets/" ;;
        appimage|deb|rpm|snap|flatpak) move_file "$FILE" "$DOWNLOAD_DIR/apps/" ;;
    esac
done
EOF

    # Make the script executable
    chmod +x "$HOME/.local/bin/auto-sort-downloads.sh"
}

# Function to setup autostart
setup_autostart() {
    echo ""
    read -p "Do you want to run the auto-sort script automatically at startup? (y/n): " choice
    case "$choice" in 
        y|Y ) 
            # Detect shell and config file
            local shell_name=$(basename "$SHELL")
            local config_file=""

            case "$shell_name" in
                bash) 
                    config_file="$HOME/.bashrc"
                    autostart_cmd="pgrep -f \"auto-sort-downloads.sh\" > /dev/null || nohup \"$HOME/.local/bin/auto-sort-downloads.sh\" > /dev/null 2>&1 &"
                    ;;
                zsh)
                    config_file="$HOME/.zshrc"
                    autostart_cmd="pgrep -f \"auto-sort-downloads.sh\" > /dev/null || nohup \"$HOME/.local/bin/auto-sort-downloads.sh\" > /dev/null 2>&1 &"
                    ;;
                fish)
                    config_file="$HOME/.config/fish/config.fish"
                    autostart_cmd="pgrep -f \"auto-sort-downloads.sh\" > /dev/null; or nohup \"$HOME/.local/bin/auto-sort-downloads.sh\" > /dev/null 2>&1 &"
                    ;;
                *)
                    config_file="$HOME/.profile"
                    autostart_cmd="pgrep -f \"auto-sort-downloads.sh\" > /dev/null || nohup \"$HOME/.local/bin/auto-sort-downloads.sh\" > /dev/null 2>&1 &"
                    ;;
            esac

            # Ensure config directory exists
            mkdir -p "$(dirname "$config_file")"

            if [ -f "$config_file" ] || [ ! -e "$config_file" ]; then
                # Check if already added
                if [ -f "$config_file" ] && grep -Fq "auto-sort-downloads.sh" "$config_file"; then
                    echo "Autostart command already exists in $config_file."
                else
                    echo "" >> "$config_file"
                    echo "# Auto-sort downloads startup" >> "$config_file"
                    echo "$autostart_cmd" >> "$config_file"
                    echo "Added autostart command to $config_file."
                fi
            else
                echo "Could not handle configuration file $config_file. Please add the following command manually:"
                echo "$autostart_cmd"
            fi
            ;;
        * ) 
            echo "Skipping autostart setup."
            ;;
    esac
}

# --- Main script execution ---
echo "--- Setting up Auto Sort Downloads ---"
install_inotify_tools
create_sort_script
setup_autostart
echo "--- Setup Complete! ---"
echo ""
echo "The sorting script has been created at: ~/.local/bin/auto-sort-downloads.sh"
echo ""
echo "To start sorting your downloads manually now, run this command:"
echo "nohup ~/.local/bin/auto-sort-downloads.sh > /dev/null 2>&1 &"
echo ""
