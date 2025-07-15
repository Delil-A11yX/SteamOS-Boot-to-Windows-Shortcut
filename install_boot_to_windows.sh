#!/bin/bash
#
# Boot to Windows - FINAL Automated Installer for SteamOS
# This script creates a persistent solution that survives reboots.
#

echo "================================================="
echo "=== Boot to Windows Shortcut Installer        ==="
echo "================================================="
echo

# Step 1: Verify the script is run correctly
if [ -z "$SUDO_USER" ]; then
    echo "[ERROR] This script must be run via the .desktop file using sudo."
    exit 1
fi

# Step 2: Disable Read-Only Filesystem to make system changes
echo
echo "--- [1/4] Temporarily disabling read-only filesystem..."
sudo steamos-readonly disable
echo "[OK] Filesystem is now writeable."

# Step 3: Find the Windows Boot Entry
echo
echo "--- [2/4] Searching for Windows Boot Manager entry..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')

if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[ERROR] Could not find 'Windows Boot Manager' entry."
    sudo steamos-readonly enable
    exit 1
fi
echo "[OK] Found Windows Boot entry: Boot$WINDOWS_ENTRY_ID"

# Step 4: Create the final boot script on the user's Desktop (a persistent location)
FINAL_SCRIPT_PATH="/home/$SUDO_USER/Desktop/Boot to Windows.sh"
echo
echo "--- [3/4] Creating final boot script on your Desktop..."

cat << EOF > "$FINAL_SCRIPT_PATH"
#!/bin/bash
# This script reboots the system into Windows.
sudo /usr/sbin/efibootmgr -n "$WINDOWS_ENTRY_ID" && sudo /usr/bin/systemctl reboot
EOF

chmod +x "$FINAL_SCRIPT_PATH"
chown "$SUDO_USER":"$SUDO_USER" "$FINAL_SCRIPT_PATH"
echo "[OK] 'Boot to Windows.sh' created successfully."

# Step 5: Create and enable the systemd service for persistent sudoers rule
SERVICE_FILE_PATH="/etc/systemd/system/boot-to-windows-sudo.service"
SUDOERS_FILE_PATH="/etc/sudoers.d/99-boot-to-windows-rule"
echo
echo "--- [4/4] Creating permanent auto-start service for password rule..."

cat << EOF > "$SERVICE_FILE_PATH"
[Unit]
Description=Set passwordless sudo rule for the Boot to Windows script
DefaultDependencies=no
After=sysinit.target
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo '%wheel ALL=(ALL) NOPASSWD: /usr/sbin/efibootmgr, /usr/bin/systemctl reboot' > $SUDOERS_FILE_PATH && chmod 0440 $SUDOERS_FILE_PATH"
ExecStop=/bin/rm $SUDOERS_FILE_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service so it runs on every boot
systemctl enable "$SERVICE_FILE_PATH" > /dev/null 2>&1
# Start the service once immediately
systemctl start boot-to-windows-sudo.service

echo "[OK] Permanent password rule has been set up."

# Re-enable the read-only filesystem
sudo steamos-readonly enable
echo "[OK] Filesystem is protected again."
echo

echo "================================================="
echo "=== SETUP COMPLETE!                           ==="
echo "================================================="
echo "You can now add 'Boot to Windows.sh' from your Desktop to Steam."
