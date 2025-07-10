#!/bin/bash

# --- Configuration ---
INSTALL_DIR="$HOME/SteamOS_Tools" # Where the boot script will be stored
BOOT_SCRIPT_FILENAME="boot_to_windows.sh"
BOOT_SCRIPT_PATH="$INSTALL_DIR/$BOOT_SCRIPT_FILENAME"
STEAM_APP_NAME="Boot To Windows" # How it will appear in Steam
STEAM_APP_ID="boot_to_windows" # A unique identifier for Steam, avoid spaces and special chars

# --- Functions ---

log_message() {
    echo "--- $1 ---"
}

error_exit() {
    log_message "ERROR: $1"
    echo "Aborting installation."
    exit 1
}

# Finds the Windows GRUB boot entry
find_windows_grub_entry() {
    log_message "Searching for Windows Boot Manager entry in GRUB..."
    local entry=$(grep -Po "(?<=menuentry ')[^']*(?=')" /boot/grub/grub.cfg | grep -i "Windows Boot Manager" | head -n 1)

    if [ -z "$entry" ]; then
        error_exit "Could not find 'Windows Boot Manager' entry in GRUB. Please ensure Windows is properly installed and recognized by GRUB. You might need to manually inspect /boot/grub/grub.cfg."
    else
        log_message "Found GRUB entry: '$entry'"
        echo "$entry" # Return the entry
        return 0
    fi
}

# Creates the actual boot script that will reboot into Windows
create_boot_script() {
    local windows_entry="$1"

    log_message "Creating the boot script: $BOOT_SCRIPT_PATH"
    mkdir -p "$INSTALL_DIR" || error_exit "Failed to create installation directory: $INSTALL_DIR"

    cat << EOF > "$BOOT_SCRIPT_PATH"
#!/bin/bash

echo "Booting to Windows..."
# Command to set the next boot target to Windows
# The 'sudo' command here will NOT ask for a password due to the sudoers configuration.
sudo grub-reboot "$windows_entry"

# Initiate the reboot
# The 'sudo' command here will NOT ask for a password due to the sudoers configuration.
sudo reboot

# If reboot fails for some reason, inform the user
if [ \$? -ne 0 ]; then
    echo "Error during reboot. Please reboot manually or check sudo permissions."
fi
EOF

    if [ $? -eq 0 ]; then
        log_message "Boot script created successfully."
        chmod +x "$BOOT_SCRIPT_PATH" || error_exit "Failed to make script executable."
        log_message "Boot script made executable."
        return 0
    else
        error_exit "Failed to create the boot script."
    fi
}

# Configures sudoers to allow the deck user to run the boot script without a password.
configure_sudoers() {
    log_message "Configuring sudoers to allow passwordless execution of the boot script..."
    local sudoers_file="/etc/sudoers.d/99_boot_to_windows_nopasswd"
    # Get the current username dynamically
    local current_user=$(whoami)
    local entry_line="$current_user ALL=(ALL) NOPASSWD: $BOOT_SCRIPT_PATH"

    if [ -f "$sudoers_file" ]; then
        log_message "Existing sudoers configuration found at $sudoers_file. Removing it first."
        sudo rm "$sudoers_file" || error_exit "Failed to remove existing sudoers file."
    fi

    # Using tee with sudo to write to a root-owned file
    echo "$entry_line" | sudo tee "$sudoers_file" > /dev/null || error_exit "Failed to write sudoers entry."

    # Set correct permissions for the sudoers file
    sudo chmod 0440 "$sudoers_file" || error_exit "Failed to set correct permissions for sudoers file."
    log_message "Sudoers configured successfully. The boot script can now be run without a password."
    echo ""
    log_message "IMPORTANT: The sudoers configuration means the '$BOOT_SCRIPT_PATH' script can be run with sudo without a password."
    log_message "Ensure you understand that this grants elevated privileges to *that specific script*."
}


# Attempts to add the script as a non-Steam game (instructions only)
add_to_steam_library_auto() {
    log_message "Due to the complexity and fragility of directly modifying Steam's binary configuration files (shortcuts.vdf) with a simple bash script, a fully automatic and robust addition might not be possible."
    log_message "Therefore, the script will create the necessary executable, and we will provide very clear instructions for the final, reliable step of adding it to Steam."
    log_message "This ensures your Steam configuration remains intact and functional."
    log_message ""
    log_message "--- Manual Steam Addition Instructions ---"
    log_message "1. Switch to Desktop Mode (if not already there)."
    log_message "2. Open Steam."
    log_message "3. In your Library, click 'ADD A GAME' (bottom left) -> 'Add a Non-Steam Game...'"
    log_message "4. Click 'BROWSE...' and navigate to: $BOOT_SCRIPT_PATH"
    log_message "5. Select the file and click 'Add Selected Programs'."
    log_message "6. (Optional but recommended): Right-click the new entry in Steam, select 'Properties', and rename it to '$STEAM_APP_NAME'."
    log_message "After adding, you might need to restart Steam (or your Steam Deck) for it to appear correctly in Gaming Mode."
    return 0 # Indicate that instructions were given successfully
}


# --- Main Execution ---

log_message "Starting Automated 'Boot to Windows' Setup"
echo "This script will find your Windows Boot Manager entry, create a boot script,"
echo "configure your system so the script can run without a password, and then"
echo "guide you on how to add it to your Steam library for Gaming Mode."
echo ""
echo "This script requires **sudo permissions** to run system commands and interact with system files."
echo "You will be prompted for your sudo password ONCE during this installation process."
read -p "Press Enter to continue..."

# 0. Check for sudo permissions by running a dummy command
sudo -v || error_exit "Sudo permissions required. Please ensure you have sudo access and enter your password when prompted."

# 1. Find Windows GRUB entry
WINDOWS_GRUB_ENTRY=$(find_windows_grub_entry) || exit 1 # Exit if function failed

echo ""
log_message "Confirmation Required"
echo "The script will use the following Windows GRUB entry:"
echo "-> '$WINDOWS_GRUB_ENTRY'"
read -p "Is this correct? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_message "Setup aborted by user."
    exit 0
fi

# 2. Create the boot script
create_boot_script "$WINDOWS_GRUB_ENTRY" || exit 1 # Exit if function failed

# 3. Configure sudoers for passwordless execution
configure_sudoers || exit 1 # Exit if function failed

# 4. Provide instructions for adding to Steam
add_to_steam_library_auto

log_message "Setup Complete!"
echo "Your 'Boot to Windows' script is located at: $BOOT_SCRIPT_PATH"
echo "It is now configured to run without a password prompt in Gaming Mode."
echo "Please follow the instructions above to add it to Steam."
echo "For support or if you encounter issues, please refer to the GitHub repository's README."
