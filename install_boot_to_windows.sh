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

# ... (Rest des Skripts bleibt gleich bis zur sudoers-Konfiguration) ...

# In create_boot_script function:
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
# ... (Rest des Skripts, einschließlich configure_sudoers und add_to_steam_library_auto, bleibt gleich) ...

# Final message needs to be corrected too
log_message "Setup Complete!"
echo "Your 'Boot to Windows' script is located at: $BOOT_SCRIPT_PATH" # This line should now reflect /home/deck/SteamOS_Tools
echo "It is now configured to run without a password prompt in Gaming Mode."
echo "Please follow the instructions above to add it to Steam."
echo "For support or if you encounter issues, please refer to the GitHub repository's README."
echo "Press Enter to close this window..."
read -n 1
