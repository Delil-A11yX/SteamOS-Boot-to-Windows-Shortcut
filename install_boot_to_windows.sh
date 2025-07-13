#!/bin/bash
#
# Boot to Windows - Installer Script for SteamOS
# Final version: Adopts the user's boot number format (e.g., "2" instead of "0002").
#

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

# --- 1. Disable SteamOS read-only mode ---
echo
echo "--- [STEP 1/5] Disabling SteamOS read-only mode..."
sudo steamos-readonly disable
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to disable read-only mode. The script cannot continue."
    exit 1
fi
echo "[OK] Filesystem is now writeable."

# --- 2. Find Windows Boot Manager entry ---
echo
echo "--- [STEP 2/5] Searching for Windows Boot Manager entry..."
# Find the 4-digit hex number and then remove leading zeros to get a simple number (e.g., 0002 -> 2)
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}' | sed 's/^0*//')

if [ -z "$WINDOWS_ENTRY_ID" ]; then
    # If the simple number is empty (e.g., for Boot0000), set it to 0.
    if efibootmgr | grep -i "Windows Boot Manager" | grep -q "Boot0000"; then
        WINDOWS_ENTRY_ID="0"
    else
        echo "[ERROR] Could not find 'Windows Boot Manager' entry."
        sudo steamos-readonly enable # Re-enable read-only mode on failure
        exit 1
    fi
fi
echo "[OK] Found Windows Boot entry: Boot...$WINDOWS_ENTRY_ID"

# --- 3. Create the final boot script in /usr/local/bin ---
FINAL_SCRIPT_PATH="/usr/local/bin/boot-windows.sh"
echo
echo "--- [STEP 3/5] Creating the final boot script at: $FINAL_SCRIPT_PATH..."

# This script will now use the simplified boot number.
cat << EOF > "$FINAL_SCRIPT_PATH"
#!/bin/bash
# Switches boot entry to Windows and reboots.
sudo /usr/sbin/efibootmgr -n "$WINDOWS_ENTRY_ID" && sudo /usr/bin/systemctl reboot
EOF

chmod +x "$FINAL_SCRIPT_PATH"
echo "[OK] Boot script created successfully."

# --- 4. Create the necessary sudoers rule ---
SUDOERS_FILE="/etc/sudoers.d/99-boot-windows-rule"
echo
echo "--- [STEP 4/5] Creating sudoers rule for password-less execution..."
echo '%wheel ALL=(ALL) NOPASSWD: /usr/sbin/efibootmgr, /usr/bin/systemctl reboot' > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"
echo "[OK] Sudoers rule created successfully."

# --- 5. Re-enable SteamOS read-only mode ---
echo
echo "--- [STEP 5/5] Re-enabling SteamOS read-only mode..."
sudo steamos-readonly enable
echo "[OK] Filesystem is now protected again."
echo

# --- Final instructions ---
echo "================================================="
echo "=== SETUP COMPLETE!                           ==="
echo "================================================="
echo
echo "A new command 'boot-windows.sh' has been installed."
echo "Please add it to Steam and run it to test."
