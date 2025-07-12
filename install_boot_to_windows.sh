#!/bin/bash
#
# Boot to Windows - Installer Script for SteamOS
# This script will be executed with sudo privileges.
#

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

# Verify that the script is run as root and get the original user.
if [ "$(id -u)" -ne 0 ] || [ -z "$SUDO_USER" ]; then
    error_exit "This script must be run with 'sudo'. Please use the provided .desktop file."
fi

# 1. Find the Windows Boot entry
log_message "Searching for Windows Boot Manager entry..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')

if [ -z "$WINDOWS_ENTRY_ID" ]; then
    error_exit "Could not find 'Windows Boot Manager' entry. Please check 'sudo efibootmgr' manually."
fi
log_message "Found Windows Boot entry: Boot$WINDOWS_ENTRY_ID"

# 2. Create the final boot script on the user's Desktop
BOOT_SCRIPT_PATH="/home/$SUDO_USER/Desktop/Boot_to_Windows.sh"
log_message "Creating the boot script at: $BOOT_SCRIPT_PATH"

# Use a here-document to create the script file.
cat << EOF > "$BOOT_SCRIPT_PATH"
#!/bin/bash
# This script sets the next boot to Windows and reboots the system.
echo "Setting boot to Windows and rebooting..."
sudo efibootmgr -n "$WINDOWS_ENTRY_ID" && sudo reboot
EOF

if [ $? -ne 0 ]; then
    error_exit "Failed to create the boot script."
fi

# 3. Make the script executable and set correct ownership
chmod +x "$BOOT_SCRIPT_PATH"
chown "$SUDO_USER":"$SUDO_USER" "$BOOT_SCRIPT_PATH"
log_message "Boot script created successfully and made executable."

# 4. Create the sudoers rule for password-less execution
SUDOERS_FILE="/etc/sudoers.d/99-boot-windows-nopasswd"
log_message "Configuring sudoers for password-less execution..."
# This rule allows any user in the 'wheel' group to run efibootmgr and reboot without a password.
# This is a broad but effective rule for this use case.
echo '%wheel ALL=(ALL) NOPASSWD: /usr/sbin/efibootmgr, /usr/sbin/reboot' > "$SUDOERS_FILE"
if [ $? -ne 0 ]; then
    error_exit "Failed to write sudoers rule."
fi

chmod 0440 "$SUDOERS_FILE"
if [ $? -ne 0 ]; then
    error_exit "Failed to set permissions on sudoers file."
fi
log_message "Sudoers rule created successfully."

log_message "--- Setup Complete! ---"
echo "A new executable file 'Boot_to_Windows.sh' has been created on your Desktop."
echo "Please add this file to your Steam library now as a 'Non-Steam Game'."
