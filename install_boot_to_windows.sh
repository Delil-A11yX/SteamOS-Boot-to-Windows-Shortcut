#!/bin/bash
# Script to automatically create a "Boot to Windows" shortcut for SteamOS.
# Based on a proven manual method.

# --- Functions ---
log_message() {
    echo "--- $1 ---"
}

error_exit() {
    log_message "ERROR: $1"
    echo "Installation aborted."
    exit 1
}

# --- Main Execution ---
log_message "Starting 'Boot to Windows' Setup"

# 1. Find the Windows Boot entry
log_message "Searching for Windows Boot Manager entry..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')

if [ -z "$WINDOWS_ENTRY_ID" ]; then
    error_exit "Could not find 'Windows Boot Manager' entry. Please check 'sudo efibootmgr' manually."
fi
log_message "Found Windows Boot entry: Boot$WINDOWS_ENTRY_ID"

# 2. Create the final boot script
# This script will be placed on the user's Desktop for easy access.
BOOT_SCRIPT_PATH="/home/$SUDO_USER/Desktop/Boot_to_Windows.sh"
log_message "Creating the boot script at: $BOOT_SCRIPT_PATH"

echo "#!/bin/bash" > "$BOOT_SCRIPT_PATH"
echo "# This script sets the next boot to Windows and reboots the system." >> "$BOOT_SCRIPT_PATH"
echo "sudo efibootmgr -n $WINDOWS_ENTRY_ID && sudo reboot" >> "$BOOT_SCRIPT_PATH"

if [ $? -ne 0 ]; then
    error_exit "Failed to create the boot script."
fi

# 3. Make the script executable and set correct ownership
chmod +x "$BOOT_SCRIPT_PATH"
chown "$SUDO_USER":"$SUDO_USER" "$BOOT_SCRIPT_PATH"
log_message "Boot script created successfully and made executable."

# 4. Create the sudoers rule for password-less execution
SUDOERS_FILE="/etc/sudoers.d/99-boot-windows"
log_message "Configuring sudoers for password-less execution..."
# This rule allows any user in the 'wheel' group (which 'deck' is a part of)
# to run efibootmgr and reboot without a password.
echo '%wheel ALL=(ALL) NOPASSWD: /usr/sbin/efibootmgr, /usr/sbin/reboot' > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"
log_message "Sudoers rule created successfully."

log_message "--- Setup Complete! ---"
echo "A new executable file 'Boot_to_Windows.sh' has been created on your Desktop."
echo "Please add this file to your Steam library now as a 'Non-Steam Game'."
u
