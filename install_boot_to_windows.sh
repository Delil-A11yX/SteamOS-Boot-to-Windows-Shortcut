#!/bin/bash

# --- Configuration ---
# Store the boot script in the HOME directory of the *original calling user*
# This will ensure it's /home/deck/SteamOS_Tools for the 'deck' user
INSTALL_DIR="/home/$ORIGINAL_CALLING_USER/SteamOS_Tools" # <--- This line is CRUCIAL for correct path
BOOT_SCRIPT_FILENAME="boot_to_windows.sh"
BOOT_SCRIPT_PATH="$INSTALL_DIR/$BOOT_SCRIPT_FILENAME"
STEAM_APP_NAME="Boot To Windows"
STEAM_APP_ID="boot_to_windows"

# Get the original user who called sudo (passed as first argument from .desktop file)
ORIGINAL_CALLING_USER="$1"
if [ -z "$ORIGINAL_CALLING_USER" ]; then
    ORIGINAL_CALLING_USER=$(logname 2>/dev/null || whoami)
fi


# --- Functions ---

log_message() {
    echo "--- $1 ---"
}

error_exit() {
    log_message "ERROR: $1"
    echo "Installation aborted."
    exit 1
}

# Finds the Windows Boot Manager entry using efibootmgr
find_windows_efi_entry() {
    log_message "Searching for Windows Boot Manager entry using efibootmgr..."
    local entry_id=$(efibootmgr -v | grep -i "Windows Boot Manager" | grep -Po "Boot\d{4}" | head -n 1)

    if [ -z "$entry_id" ]; then
        error_exit "Could not find 'Windows Boot Manager' entry in EFI boot order. Please ensure Windows is properly installed and recognized by UEFI."
    else
        log_message "Found EFI entry for Windows: '$entry_id'"
        echo "$entry_id"
        return 0
    fi
}

# Creates the actual boot script that will reboot into Windows
create_boot_script() {
    local windows_efi_id="$1"

    log_message "Creating the boot script: $BOOT_SCRIPT_PATH"
    # Ensure the directory is created by the user running the script (which will be root for mkdir -p)
    mkdir -p "$INSTALL_DIR" || error_exit "Failed to create installation directory: $INSTALL_DIR"
    # Ownership of the directory must be set for the original user
    chown "$ORIGINAL_CALLING_USER":"$ORIGINAL_CALLING_USER" "$INSTALL_DIR" || log_message "Warning: Could not change ownership of installation directory to $ORIGINAL_CALLING_USER."

    cat << EOF > "$BOOT_SCRIPT_PATH"
#!/bin/bash

echo "Booting to Windows..."
# Command to set the next boot target to Windows using efibootmgr
# The 'sudo' command here will NOT ask for a password due to the sudoers configuration.
sudo efibootmgr -n "$windows_efi_id" || { echo "Error setting next boot entry. Check permissions or efibootmgr."; exit 1; }

# Initiate the reboot
# The 'sudo' command here will NOT ask for a password due to the sudoers configuration.
sudo reboot || { echo "Error initiating reboot."; exit 1; }

# If reboot fails for some reason, inform the user
if [ \$? -ne 0 ]; then
    echo "Error during reboot. Please reboot manually or check sudo permissions."
fi
EOF

    if [ $? -eq 0 ]; then
        log_message "Boot script created successfully."
        # Ownership of the script must be set for the original user
        chown "$ORIGINAL_CALLING_USER":"$ORIGINAL_CALLING_USER" "$BOOT_SCRIPT_PATH" || log_message "Warning: Could not change ownership of boot script to $ORIGINAL_CALLING_USER."
        chmod +x "$BOOT_SCRIPT_PATH" || error_exit "Failed to make script executable."
        log_message "Boot script made executable."
        return 0
    else
        error_exit "Failed to create the boot script."
    fi
}

# Configures sudoers to allow the original user to run the boot script without a password.
configure_sudoers() {
    log_message "Configuring sudoers for passwordless execution of the boot script for user '$ORIGINAL_CALLING_USER'..."
    local sudoers_file="/etc/sudoers.d/99_boot_to_windows_nopasswd"

    if [ -z "$ORIGINAL_CALLING_USER" ]; then
        error_exit "Original calling user is not set. Cannot configure sudoers."
    fi

    local entry_line="$ORIGINAL_CALLING_USER ALL=(ALL) NOPASSWD: $BOOT_SCRIPT_PATH, /usr/sbin/efibootmgr, /usr/sbin/reboot"

    if [ -f "$sudoers_file" ]; then
        log_message "Existing sudoers configuration found. Removing it first."
        rm "$sudoers_file" || error_exit "Failed to remove existing sudoers file."
    fi

    echo "$entry_line" > "$sudoers_file" || error_exit "Failed to write sudoers entry."
    chmod 0440 "$sudoers_file" || error_exit "Failed to set correct permissions for sudoers file."
    log_message "Sudoers configured successfully."
    log_message "IMPORTANT: This grants passwordless sudo to '$BOOT_SCRIPT_PATH', '/usr/sbin/efibootmgr', and '/usr/sbin/reboot' for user '$ORIGINAL_CALLING_USER'."
    log_message "Ensure you understand these elevated privileges."
}

# --- Main Execution ---

log_message "Starting Automated 'Boot to Windows' Setup"
echo "This script will find your Windows Boot Manager EFI entry, create a boot script,"
echo "configure your system so the script can run without a password, and then"
echo "guide you on how to add it to your Steam library for Gaming Mode."
echo ""
echo "This script requires **root permissions** for system modifications."
echo "You will be prompted for your password via the terminal during this process."

if [ "$(id -u)" -ne 0 ]; then
    error_exit "This script must be run with root privileges. Please ensure you are running it with 'sudo'."
fi

# 1. Find Windows EFI entry
WINDOWS_EFI_ID=$(find_windows_efi_entry) || exit 1

# 2. Create the boot script
create_boot_script "$WINDOWS_EFI_ID" || exit 1

# 3. Configure sudoers for passwordless execution
configure_sudoers || exit 1

# 4. Provide instructions for adding to Steam
echo ""
log_message "Setup Complete! Your 'Boot to Windows' script is ready."
echo "It is located at: $BOOT_SCRIPT_PATH"
echo "You can now add it to your Steam Library for use in Gaming Mode."
echo ""
echo "--- How to add 'Boot To Windows' to Steam ---"
echo "1. Switch to Desktop Mode (if not already there)."
echo "2. Open Steam."
echo "3. In your Library, click 'ADD A GAME' (bottom left) -> 'Add a Non-Steam Game...'"
echo "4. Click 'BROWSE...' and navigate to: $BOOT_SCRIPT_PATH"
echo "5. Select the file and click 'Add Selected Programs'."
echo "6. (Optional but recommended): Right-click the new entry in Steam, select 'Properties',"
echo "   and rename it to '$STEAM_APP_NAME' (current name is 'boot_to_windows.sh')."
echo "7. (Optional): You can change the icon for better visibility."
echo ""
echo "After adding, restart Steam (or your Steam Deck) for it to appear correctly in Gaming Mode."
echo ""
echo "Press Enter to close this window..."
read -n 1
