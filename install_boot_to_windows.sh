#!/bin/bash
#
# Boot to Windows - Installer Script for SteamOS
# Final version with correct line endings and read-only filesystem handling.
#

# --- Functions ---
log_message() {
    echo
    echo "--- $1 ---"
}

# --- Main Execution ---
echo "================================================="
echo "=== Boot to Windows Shortcut Installer        ==="
echo "================================================="

# Verify the script is run as root and get the original user.
if [ -z "$SUDO_USER" ]; then
    echo "[ERROR] This script must be run with 'sudo'. Aborting."
    sleep 5
    exit 1
fi

# --- 1. Disable SteamOS read-only mode ---
log_message "Disabling SteamOS read-only mode (this is temporary)"
sudo steamos-readonly disable
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to disable read-only mode. The script cannot continue."
    sleep 5
    exit 1
fi
echo "[OK] Filesystem is now writeable."

# --- 2. Find the Windows Boot entry ---
log_message "Searching for Windows Boot Manager entry"
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')

if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[ERROR] Could not find 'Windows Boot Manager' entry."
    sudo steamos-readonly enable # Re-enable read-only mode on failure
    exit 1
fi
echo "[OK] Found Windows Boot entry: Boot$WINDOWS_ENTRY_ID"

# --- 3. Create the final boot script in /usr/local/bin ---
FINAL_SCRIPT_PATH="/usr/local/bin/boot-to-windows"
log_message "Creating the final boot script at: $FINAL_SCRIPT_PATH"

cat << EOF > "$FINAL_SCRIPT_PATH"
#!/bin/bash
# Switches boot entry to Windows and reboots.
sudo efibootmgr -n "$WINDOWS_ENTRY_ID" && sudo systemctl reboot
EOF

chmod +x "$FINAL_SCRIPT_PATH"
echo "[OK] Successfully created the boot script."

# --- 4. Create the necessary sudoers rule ---
SUDOERS_FILE="/etc/sudoers.d/99-boot-to-windows-rule"
log_message "Creating sudoers rule for password-less execution"
echo '%wheel ALL=(ALL) NOPASSWD: /usr/sbin/efibootmgr, /usr/bin/systemctl reboot' > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"
echo "[OK] Sudoers rule created successfully."

# --- 5. Re-enable SteamOS read-only mode ---
log_message "Re-enabling SteamOS read-only mode"
sudo steamos-readonly enable
echo "[OK] Filesystem is now protected again."

# --- 6. Final instructions ---
log_message "SETUP COMPLETE!"
echo
echo "A new command is now available on your system."
echo "Please add it to Steam:"
echo "1. In Steam's Desktop Mode, go to 'Games' -> 'Add a Non-Steam Game to My Library...'"
echo "2. Click 'Browse...'"
echo "3. Navigate to the path: /usr/local/bin/"
echo "4. Select the file named 'boot-to-windows' and add it."
