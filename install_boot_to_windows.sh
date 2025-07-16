#!/bin/bash
#
# FINAL ONE-CLICK INSTALLER: Boot to Windows (SteamOS)
# Works in Desktop & Gaming Mode – no password prompt required.
#

echo "================================================="
echo "=== Boot to Windows | One-Click Setup         ==="
echo "================================================="
echo

# Step 1: Must be run with sudo
if [ -z "$SUDO_USER" ]; then
    echo "[ERROR] This script must be run via .desktop launcher with sudo."
    exit 1
fi

# Disable SteamOS read-only mode
echo "[INFO] Temporarily disabling SteamOS read-only mode..."
steamos-readonly disable
echo "[OK] Read-only mode disabled."
echo

# Detect Windows Boot ID
echo "[INFO] Searching for Windows Boot Manager..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')
if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[ERROR] Windows Boot Manager not found."
    steamos-readonly enable
    exit 1
fi
echo "[OK] Found: Boot$WINDOWS_ENTRY_ID"
echo

# Create systemd service
SERVICE_FILE="/etc/systemd/system/boot-to-windows.service"
echo "[INFO] Creating systemd service at $SERVICE_FILE..."

cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Boot into Windows and reboot
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/efibootmgr -n $WINDOWS_ENTRY_ID
ExecStartPost=/usr/bin/systemctl reboot
User=root
EOF

chmod 644 "$SERVICE_FILE"
systemctl daemon-reexec
systemctl daemon-reload
echo "[OK] systemd service created."
echo

# Create desktop launch script
BOOT_SCRIPT="/home/$SUDO_USER/Desktop/Boot to Windows.sh"
echo "[INFO] Creating shortcut on Desktop..."

cat <<EOF > "$BOOT_SCRIPT"
#!/bin/bash
systemctl start boot-to-windows.service
EOF

chmod +x "$BOOT_SCRIPT"
chown "$SUDO_USER:$SUDO_USER" "$BOOT_SCRIPT"
echo "[OK] Created: $BOOT_SCRIPT"
echo

# Add polkit rule to allow systemctl start without password
POLKIT_FILE="/etc/polkit-1/rules.d/99-boot-to-windows.rules"
echo "[INFO] Adding Polkit rule for user '$SUDO_USER'..."

mkdir -p /etc/polkit-1/rules.d

cat <<EOF > "$POLKIT_FILE"
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        subject.user == "$SUDO_USER") {
        return polkit.Result.YES;
    }
});
EOF

chmod 644 "$POLKIT_FILE"
echo "[OK] Polkit rule created: $POLKIT_FILE"
echo

# Re-enable read-only mode
echo "[INFO] Re-enabling SteamOS read-only mode..."
steamos-readonly enable
echo "[OK] System protection restored."
echo

# Done
echo "================================================="
echo "=== INSTALLATION COMPLETE                     ==="
echo "================================================="
echo "✔ systemd service: boot-to-windows.service"
echo "✔ shortcut:        $BOOT_SCRIPT"
echo "✔ Polkit rule:     $POLKIT_FILE"
echo
echo "➡ Add the script to Steam manually."
echo "➡ You can now reboot into Windows from Gaming Mode."
echo
echo "✅ Enjoy!"
