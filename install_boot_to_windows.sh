#!/bin/bash
#
# Boot to Windows - Installer Script for SteamOS
# Final version: Correctly implements the user's proven sudoers rule method.
#

echo "================================================="
echo "=== Boot to Windows Shortcut Installer        ==="
echo "================================================="
echo

# Verify the script is run as root.
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run with 'sudo'. Aborting."
    sleep 5
    exit 1
fi

# --- 1. Disable SteamOS read-only mode ---
echo
echo "--- [STEP 1/4] Disabling SteamOS read-only mode..."
sudo steamos-readonly disable
echo "[OK] Filesystem is now writeable."

# --- 2. Find Windows Boot Manager entry ---
echo
echo "--- [STEP 2/4] Searching for Windows Boot Manager entry..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')

if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[ERROR] Could not find 'Windows Boot Manager' entry."
    sudo steamos-readonly enable # Re-enable read-only mode on failure
    exit 1
fi
echo "[OK] Found Windows Boot entry: Boot$WINDOWS_ENTRY_ID"

# --- 3. Create the boot script and the sudoers rule ---
FINAL_SCRIPT_PATH="/usr/local/bin/boot-windows.sh"
SUDOERS_FILE="/etc/sudoers.d/efibootmgr-rule" # Using the exact name from your manual guide

echo
echo "--- [STEP 3/4] Creating boot script and sudoers rule..."

# Create the final boot script
cat << EOF > "$FINAL_SCRIPT_PATH"
#!/bin/bash
# This script switches the boot entry to Windows and reboots.
# It requires passwordless sudo for efibootmgr and reboot.
sudo /usr/sbin/efibootmgr -n "$WINDOWS_ENTRY_ID"
sudo /usr/bin/systemctl reboot
EOF

chmod +x "$FINAL_SCRIPT_PATH"
echo "[OK] Boot script created at $FINAL_SCRIPT_PATH"

# Create the sudoers rule exactly like your manual method, but with reboot included.
# This is the critical fix.
echo '%wheel ALL=(ALL) NOPASSWD: /usr/sbin/efibootmgr, /usr/bin/systemctl reboot' | sudo tee "$SUDOERS_FILE" > /dev/null
sudo chmod 0440 "$SUDOERS_FILE"
echo "[OK] Sudoers rule for passwordless reboot created successfully."

# --- 4. Re-enable SteamOS read-only mode ---
echo
echo "--- [STEP 4/4] Re-enabling SteamOS read-only mode..."
sudo steamos-readonly enable
echo "[OK] Filesystem is now protected again."
echo

# --- Final instructions ---
echo "================================================="
echo "=== SETUP COMPLETE!                           ==="
echo "================================================="
echo
echo "The system is now fully configured."
echo "Please add the '/usr/local/bin/boot-windows.sh' script to Steam."
echo "No launch options are needed."
