#!/bin/bash
#
# Boot to Windows - One-Click Installer for SteamOS
# Final version based on a proven manual setup process, with critical fixes.
# This script must be executed with sudo privileges.
#

# --- Main Execution ---
echo "================================================="
echo "=== Boot to Windows Shortcut Installer        ==="
echo "================================================="
echo

# Verify the script is run as root and get the original user.
if [ -z "$SUDO_USER" ]; then
    echo "[ERROR] This script must be run with 'sudo'. Aborting."
    sleep 5
    exit 1
fi

# --- 1. Find the Windows Boot entry ---
echo "[INFO] Searching for Windows Boot Manager entry..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')

if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[ERROR] Could not find 'Windows Boot Manager' entry. Please check 'sudo efibootmgr' output."
    sleep 5
    exit 1
fi
echo "[OK] Found Windows Boot entry: Boot$WINDOWS_ENTRY_ID"
echo

# --- 2. Create the final boot script in /usr/local/bin ---
# Using the standard path for system-wide scripts.
FINAL_SCRIPT_PATH="/usr/local/bin/boot-to-windows"
echo "[INFO] Creating the final boot script at: $FINAL_SCRIPT_PATH"

# Using cat and EOF to create a clean script file.
cat << EOF > "$FINAL_SCRIPT_PATH"
#!/bin/bash
# This script switches the boot entry to Windows and reboots.
# It is intended to be run from Steam in Gaming Mode.
sudo efibootmgr -n "$WINDOWS_ENTRY_ID" && sudo systemctl reboot
EOF

# Make the script executable for all users.
chmod +x "$FINAL_SCRIPT_PATH"
echo "[OK] Successfully created the boot script."
echo

# --- 3. Create the necessary sudoers rule for password-less execution ---
SUDOERS_FILE="/etc/sudoers.d/99-boot-to-windows-rule"
echo "[INFO] Creating sudoers rule for password-less reboot..."

# CRITICAL FIX: This rule allows BOTH efibootmgr AND systemctl reboot to be run without a password.
echo '%wheel ALL=(ALL) NOPASSWD: /usr/sbin/efibootmgr, /usr/bin/systemctl reboot' > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"

echo "[OK] Sudoers rule created successfully."
echo

# --- 4. Final instructions ---
echo "================================================="
echo "=== SETUP COMPLETE!                           ==="
echo "================================================="
echo "A new command is now available on your system."
echo
echo "NEXT STEP:"
echo "1. In Steam, go to 'Games' -> 'Add a Non-Steam Game to My Library...'"
echo "2. Click 'Browse...'"
echo "3. Navigate to the path: /usr/local/bin/"
echo "4. Select the file named 'boot-to-windows' and click 'Add Selected Programs'."
echo
echo "You can now run the shortcut from your Steam library to boot into Windows."
