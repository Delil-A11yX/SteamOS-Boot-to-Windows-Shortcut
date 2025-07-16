#!/bin/bash
#
# FINAL INSTALLER FOR "BOOT TO WINDOWS" ON STEAMOS (SAFE VERSION)
#

echo "================================================="
echo "=== Boot to Windows | Final Setup             ==="
echo "================================================="
echo

# Step 1: Check for correct execution (must be run via sudo)
if [ -z "$SUDO_USER" ]; then
    echo "[ERROR] This script must be run via a .desktop file using sudo."
    exit 1
fi

# Step 2: Make filesystem writeable
echo "[INFO] Temporarily disabling SteamOS read-only mode..."
steamos-readonly disable
echo "[OK] Filesystem is now writeable."
echo

# Step 3: Detect Windows Boot Entry
echo "[INFO] Searching for Windows Boot Manager entry..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')
if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[ERROR] Could not find a Windows Boot Manager entry via efibootmgr."
    steamos-readonly enable
    exit 1
fi
echo "[OK] Found Windows Boot entry: Boot$WINDOWS_ENTRY_ID"
echo

# Step 4: Create Desktop Boot Script
FINAL_SCRIPT_PATH="/home/$SUDO_USER/Desktop/Boot to Windows.sh"
echo "[INFO] Creating boot script on your Desktop..."

cat << EOF > "$FINAL_SCRIPT_PATH"
#!/bin/bash
# This script directly boots into Windows. Requires sudoers rule.
sudo /usr/sbin/efibootmgr -n $WINDOWS_ENTRY_ID && sudo /usr/bin/systemctl reboot
EOF

chmod +x "$FINAL_SCRIPT_PATH"
chown "$SUDO_USER":"$SUDO_USER" "$FINAL_SCRIPT_PATH"
echo "[OK] Script created at: $FINAL_SCRIPT_PATH"
echo

# Step 5: Set up password-less sudo rule
SUDOERS_FILE="/etc/sudoers.d/99-boot-to-windows-permissions"
echo "[INFO] Creating password-less sudo rule for $SUDO_USER..."
echo "$SUDO_USER ALL=(ALL) NOPASSWD: /usr/sbin/efibootmgr, /usr/bin/systemctl reboot" | tee "$SUDOERS_FILE" > /dev/null
chmod 0440 "$SUDOERS_FILE"
echo "[OK] Sudoers rule applied successfully."
echo

# Step 6: Re-enable read-only mode
echo "[INFO] Re-enabling SteamOS read-only protection..."
steamos-readonly enable
echo "[OK] Filesystem is protected again."
echo

# Step 7: Manual instructions
echo "================================================="
echo "=== SETUP COMPLETE                            ==="
echo "================================================="
echo "✔ Boot script created at: $FINAL_SCRIPT_PATH"
echo "✔ sudoers rule added:     $SUDOERS_FILE"
echo
echo "➡ Final step (manual):"
echo "1. Open Steam in Desktop Mode."
echo "2. Go to 'Games' → 'Add a Non-Steam Game to My Library...'"
echo "3. Select: Boot to Windows.sh"
echo "4. Confirm."
echo
echo "💡 Optional: Right-click the shortcut in Steam → Properties → Rename → Change icon if desired."
echo
echo "✅ Once done, you can launch it from Gaming Mode. No password will be asked."
