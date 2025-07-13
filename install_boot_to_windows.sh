#!/bin/bash
#
# Boot to Windows - Installer Script for SteamOS
# Final User-Friendly Version: Creates the final script on the user's Desktop.
#

echo "================================================="
echo "=== Boot to Windows Shortcut Installer        ==="
echo "================================================="

# Verify script is run as root and get the original user.
if [ -z "$SUDO_USER" ]; then
    echo "[ERROR] This script must be run with 'sudo'. Aborting."
    exit 1
fi

# Temporarily disable SteamOS read-only mode
echo
echo "--- [STEP 1/4] Disabling SteamOS read-only mode..."
sudo steamos-readonly disable
echo "[OK] Filesystem is now writeable."

# Find Windows Boot Manager entry
echo
echo "--- [STEP 2/4] Searching for Windows Boot Manager entry..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')

if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[ERROR] Could not find 'Windows Boot Manager' entry."
    sudo steamos-readonly enable
    exit 1
fi
echo "[OK] Found Windows Boot entry: Boot$WINDOWS_ENTRY_ID"

# Create the final boot script on the user's Desktop
FINAL_SCRIPT_PATH="/home/$SUDO_USER/Desktop/boot-windows.sh"
echo
echo "--- [STEP 3/4] Creating the final boot script on your Desktop..."

cat << EOF > "$FINAL_SCRIPT_PATH"
#!/bin/bash
# This script switches the boot entry to Windows and reboots.
sudo /usr/sbin/efibootmgr -n "$WINDOWS_ENTRY_ID" && sudo /usr/bin/systemctl reboot
EOF

chmod +x "$FINAL_SCRIPT_PATH"
# Set ownership so the user can manage the file
chown "$SUDO_USER":"$SUDO_USER" "$FINAL_SCRIPT_PATH"
echo "[OK] 'boot-windows.sh' script created successfully on your Desktop."

# The sudoers rule created manually via 'visudo' is independent of this script's location
# and will continue to work. We assume it has been set correctly.
echo
echo "--- [STEP 4/4] Re-enabling SteamOS read-only mode..."
sudo steamos-readonly enable
echo "[OK] Filesystem is now protected again."

# Final instructions
echo
echo "================================================="
echo "=== SETUP COMPLETE!                           ==="
echo "================================================="
echo
echo "The executable file 'boot-windows.sh' is now on your Desktop."
echo "You can now add this file to Steam as a Non-Steam Game."
