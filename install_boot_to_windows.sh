#!/bin/bash
#
# Boot to Windows - Installer based on the user's proven manual method.
# With the one necessary correction for standard SteamOS.
#

echo "================================================="
echo "=== Boot to Windows Shortcut Installer        ==="
echo "================================================="
echo

# --- 1. Temporarily disable SteamOS read-only filesystem ---
echo "[INFO] Disabling SteamOS read-only mode..."
sudo steamos-readonly disable
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to disable read-only mode. Aborting."
    exit 1
fi
echo "[OK] Filesystem is writeable."
echo

# --- 2. Find Windows Boot Manager entry (Step 1 from manual guide) ---
echo "[INFO] Searching for Windows Boot Manager entry..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')

if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[ERROR] Could not find 'Windows Boot Manager' entry."
    sudo steamos-readonly enable
    exit 1
fi
echo "[OK] Found Windows Boot entry: Boot$WINDOWS_ENTRY_ID"
echo

# --- 3. Create the boot script (Step 2 from manual guide) ---
# We use the exact naming and path from your guide.
FINAL_SCRIPT_PATH="/usr/local/bin/boot-windows.sh"
echo "[INFO] Creating boot script at: $FINAL_SCRIPT_PATH"

# This script contains BOTH sudo commands needed.
cat << EOF > "$FINAL_SCRIPT_PATH"
#!/bin/bash
sudo /usr/sbin/efibootmgr -n "$WINDOWS_ENTRY_ID" && sudo /usr/bin/systemctl reboot
EOF

# Make it executable, just like in your guide.
sudo chmod +x "$FINAL_SCRIPT_PATH"
echo "[OK] Boot script created successfully."
echo

# --- 4. Create the password-less rule (Step 3 from manual guide - with correction) ---
# We use the exact file name from your guide.
SUDOERS_FILE="/etc/sudoers.d/efibootmgr-rule"
echo "[INFO] Creating sudoers rule for password-less execution..."

# THE CRITICAL CORRECTION FOR STEAMOS: We add 'reboot' to the rule.
# This is the most likely reason it failed before.
echo '%wheel ALL=(ALL) NOPASSWD: /usr/sbin/efibootmgr, /usr/bin/systemctl reboot' | sudo tee "$SUDOERS_FILE" > /dev/null
sudo chmod 0440 "$SUDOERS_FILE"
echo "[OK] Sudoers rule created successfully."
echo

# --- 5. Re-enable SteamOS read-only mode ---
echo "[INFO] Re-enabling SteamOS read-only mode..."
sudo steamos-readonly enable
echo "[OK] Filesystem is protected again."
echo

# --- 6. Final instructions (Step 4 from manual guide) ---
echo "================================================="
echo "=== SETUP COMPLETE!                           ==="
echo "================================================="
echo "The setup is complete and follows your proven method."
echo
echo "NEXT AND FINAL STEP:"
echo "1. In Steam, go to 'Games' -> 'Add a Non-Steam Game to My Library...'"
echo "2. Click 'Browse...'"
echo "3. Navigate to the path: /usr/local/bin/"
echo "4. Select the file named 'boot-windows.sh' and add it."
echo
echo "No launch options should be needed."
