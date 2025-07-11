#!/bin/bash

# --- Configuration ---
# Store the boot script in the HOME directory of the *original calling user*
INSTALL_DIR="/home/$ORIGINAL_CALLING_USER/SteamOS_Tools" # <--- CHANGED THIS LINE
BOOT_SCRIPT_FILENAME="boot_to_windows.sh"
BOOT_SCRIPT_PATH="$INSTALL_DIR/$BOOT_SCRIPT_FILENAME"
STEAM_APP_NAME="Boot To Windows" # How it will appear in Steam
STEAM_APP_ID="boot_to_windows" # A unique identifier for Steam, avoid spaces and special chars

# Get the original user who called sudo (passed as first argument from .desktop file)
# This is crucial for correctly setting sudoers permissions and installation path.
ORIGINAL_CALLING_USER="$1"
if [ -z "$ORIGINAL_CALLING_USER" ]; then
    # Fallback if argument is not provided, though it should be.
    # This might happen if the script is run manually without an argument.
    ORIGINAL_CALLING_USER=$(logname 2>/dev/null || whoami)
    log_message "Warning: User not passed as argument. Using '$ORIGINAL_CALLING_USER' from whoami/logname."
fi


# --- Functions ---

log_message() {
    echo "--- $1 ---"
}

error_exit() {
    log_message "ERROR: $1"
    echo "Aborting installation."
    exit 1
}

# Finds the Windows Boot Manager entry using efibootmgr
find_windows_efi_entry() {
    log_message "Searching for Windows Boot Manager entry using efibootmgr..."
    # efibootmgr -v lists all boot entries with their details
    # We look for "Windows Boot Manager" and extract the BootXXXX ID
    local entry_id=$(efibootmgr -v | grep -i "Windows Boot Manager" | grep -Po "Boot\d{4}" | head -n 1)

    if [ -z "$entry_id" ]; then
        error_exit "Could not find 'Windows Boot Manager' entry in EFI boot order. Please ensure Windows is properly installed and recognized by UEFI. You might need to manually inspect 'efibootmgr -v'."
    else
        log_message "Found EFI entry for Windows: '$entry_id'"
        echo "$entry_id" # Return the entry ID (e.g., Boot0001)
        return 0
    fi
}

# Creates the actual boot script that will reboot into Windows
create_boot_script() {
    local windows_efi_id="$1"

    log_message "Creating the boot script: $BOOT_SCRIPT_PATH"
    # Ensure the directory is created by the user running the script (which will be root)
    # The mkdir -p needs to be owned by the ORIGINAL_CALLING_USER to allow Steam to see it.
    # We create it with root, but then chown it immediately.
    mkdir -p "$INSTALL_DIR" || error_exit "Failed to create installation directory: $INSTALL_DIR"
    chown "$ORIGINAL_CALLING_USER":"$ORIGINAL_CALLING_USER" "$INSTALL_DIR" || log_message "Warning: Could not change ownership of installation directory to $ORIGINAL_CALLING_USER." # <--- ADDED THIS LINE

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
        # Permissions should ensure the original user can read/execute
        # Ownership must be set for the actual user, not root, for Steam to launch it.
        chown "$ORIGINAL_CALLING_USER":"$ORIGINAL_CALLING_USER" "$BOOT_SCRIPT_PATH" || log_message "Warning: Could not change ownership of boot script to $ORIGINAL_CALLING_USER."
        chmod +x "$BOOT_SCRIPT_PATH" || error_exit "Failed to make script executable."
        log_message "Boot script made executable."
        return 0
    else
        error_exit "Failed to create the boot script."
    fi
}

# Configures sudoers to allow the original user to run the boot script without a password.
# This function is executed with root privileges, so 'sudo' is not needed within this function.
configure_sudoers() {
    log_message "Configuring sudoers to allow passwordless execution of the boot script for user '$ORIGINAL_CALLING_USER'..."
    local sudoers_file="/etc/sudoers.d/99_boot_to_windows_nopasswd"

    if [ -z "$ORIGINAL_CALLING_USER" ]; then
        error_exit "Original calling user is not set. Cannot configure sudoers. Aborting."
    fi

    # efibootmgr and reboot are explicitly added to NOPASSWD as they are used in the boot script.
    local entry_line="$ORIGINAL_CALLING_USER ALL=(ALL) NOPASSWD: $BOOT_SCRIPT_PATH, /usr/sbin/efibootmgr, /usr/sbin/reboot"

    if [ -f "$sudoers_file" ]; then
        log_message "Existing sudoers configuration found at $sudoers_file. Removing it first."
        rm "$sudoers_file" || error_exit "Failed to remove existing sudoers file."
    fi

    echo "$entry_line" > "$sudoers_file" || error_exit "Failed to write sudoers entry."
    chmod 0440 "$sudoers_file" || error_exit "Failed to set correct permissions for sudoers file."
    log_message "Sudoers configured successfully. The boot script can now be run by $ORIGINAL_CALLING_USER without a password."
    echo ""
    log_message "IMPORTANT: The sudoers configuration grants passwordless sudo to '$BOOT_SCRIPT_PATH', '/usr/sbin/efibootmgr', and '/usr/sbin/reboot' for user '$ORIGINAL_CALLING_USER'."
    log_message "Ensure you understand these elevated privileges."
}


# Provides instructions for adding to Steam (remains the same)
add_to_steam_library_auto() {
    log_message "Due to the complexity and fragility of directly modifying Steam's binary configuration files (shortcuts.vdf) with a simple bash script, a fully automatic and robust addition might not be possible."
    log_message "Therefore, the script will create the necessary executable, and we will provide very clear instructions for the final, reliable step of adding it to Steam."
    log_message ""
    log_message "--- Manual Steam Addition Instructions ---"
    log_message "1. Switch to Desktop Mode (if not already there)."
    log_message "2. Open Steam."
    log_message "3. In your Library, click 'ADD A GAME' (bottom left) -> 'Add a Non-Steam Game...'"
    log_message "4. Click 'BROWSE...' and navigate to: $BOOT_SCRIPT_PATH"
    log_message "5. Select the file and click 'Add Selected Programs'."
    log_message "6. (Optional but recommended): Right-click the new entry in Steam, select 'Properties', and rename it to '$STEAM_APP_NAME'."
    log_message "After adding, you might need to restart Steam (or your Steam Deck) for it to appear correctly in Gaming Mode."
    return 0
}


# --- Main Execution ---

log_message "Starting Automated 'Boot to Windows' Setup"
echo "This script will find your Windows Boot Manager EFI entry, create a boot script,"
echo "configure your system so the script can run without a password, and then"
echo "guide you on how to add it to your Steam library for Gaming Mode."
echo ""
echo "This script requires **root permissions** to perform certain actions (e.g., configuring sudoers)."
echo "You will be prompted for your password via the terminal during this installation process."

# Removed: read -p "Press Enter to continue..." - as this might be causing issues with interactivity.

# This check ensures the script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    error_exit "This script must be run with root privileges. Please ensure you are running it with 'sudo' or via the provided .desktop file."
fi

# 1. Find Windows EFI entry
WINDOWS_EFI_ID=$(find_windows_efi_entry) || exit 1 # Exit if function failed

echo ""
# Removed: Confirmation Required section, as interactivity is problematic
# log_message "Confirmation Required"
# echo "The script will use the following Windows EFI entry ID:"
# echo "-> '$WINDOWS_EFI_ID'"
# read -p "Is this correct? (y/n): " confirm
# if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
#     log_message "Setup aborted by user."
#     exit 0
# fi


# 2. Create the boot script
create_boot_script "$WINDOWS_EFI_ID" || exit 1 # Exit if function failed

# 3. Configure sudoers for passwordless execution
configure_sudoers || exit 1 # Exit if function failed

# 4. Provide instructions for adding to Steam
add_to_steam_library_auto

log_message "Setup Complete!"
echo "Your 'Boot to Windows' script is located at: $BOOT_SCRIPT_PATH"
echo "It is now configured to run without a password prompt in Gaming Mode."
echo "Please follow the instructions above to add it to Steam."
echo "For support or if you encounter issues, please refer to the GitHub repository's README."
echo "Press Enter to close this window..." # Added a final prompt to keep window open
read -n 1 # Added a final read to keep window open
