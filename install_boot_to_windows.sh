#!/bin/bash
#
# FINAL INTELLIGENT INSTALLER FOR "BOOT TO WINDOWS" ON STEAMOS
# Automatically detects standard setups and provides a fallback menu for custom setups.
#

echo "================================================="
echo "=== Boot to Windows | Intelligent Setup       ==="
echo "================================================="
echo

# Step 1: Verify sudo and get user
if [ -z "$SUDO_USER" ]; then
    echo "[ERROR] This script must be run with 'sudo'."
    exit 1
fi

# --- Step 2: Find Windows Boot Entry (Automatic with Manual Fallback) ---
echo "[INFO] Attempting to automatically find 'Windows Boot Manager' entry..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')

if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[WARN] Standard entry not found. Switching to manual selection mode."
    echo "[INFO] Please choose your Windows installation from the list below:"
    echo

    mapfile -t boot_options < <(efibootmgr | grep "^Boot" | sed 's/^*//')

    for i in "${!boot_options[@]}"; do
        echo "  $((i+1))) ${boot_options[$i]}"
    done

    echo
    read -p "Enter the NUMBER that corresponds to your Windows installation (e.g., 1 or 2): " selection

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#boot_options[@]}" ]; then
        echo "[ERROR] Invalid selection. Please run the installer again."
        exit 1
    fi

    selected_line="${boot_options[$((selection-1))]}"
    WINDOWS_ENTRY_ID=$(echo "$selected_line" | grep -oP 'Boot\K[0-9A-Fa-f]{4}')
    echo "[OK] You have selected: $selected_line (Boot$WINDOWS_ENTRY_ID)"
else
    echo "[OK] Found standard entry: Boot$WINDOWS_ENTRY_ID"
fi
echo

# --- Step 3: Proceed with installation using the determined Boot ID ---
echo "[INFO] Temporarily disabling SteamOS read-only mode..."
steamos-readonly disable
echo "[OK] Read-only mode disabled."

# Create the systemd service using the found ID
SERVICE_FILE="/etc/systemd/system/boot-to-windows.service"
echo "[INFO] Creating systemd service..."

cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Boot into Windows and reboot
After=network.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/sbin/efibootmgr -n $WINDOWS_ENTRY_ID
ExecStartPost=/usr/bin/systemctl reboot
EOF

chmod 644 "$SERVICE_FILE"
systemctl daemon-reload
echo "[OK] systemd service created."

# Create the final desktop shortcut
FINAL_SHORTCUT_PATH="/home/$SUDO_USER/Desktop/Boot to Windows.sh"
echo "[INFO] Creating final shortcut on your Desktop..."

cat << EOF > "$FINAL_SHORTCUT_PATH"
#!/bin/bash
systemctl start boot-to-windows.service
EOF

chmod +x "$FINAL_SHORTCUT_PATH"
chown "$SUDO_USER":"$SUDO_USER" "$FINAL_SHORTCUT_PATH"
echo "[OK] 'Boot to Windows.sh' created successfully."

# Create the Polkit rule
POLKIT_FILE="/etc/polkit-1/rules.d/99-boot-to-windows.rules"
echo "[INFO] Creating Polkit rule for password-less execution..."

mkdir -p /etc/polkit-1/rules.d

cat << EOF > "$POLKIT_FILE"
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        (!action.lookup("unit") || action.lookup("unit").indexOf("boot-to-windows.service") >= 0) &&
        subject.user == "$SUDO_USER") {
        return polkit.Result.YES;
    }
});
EOF

chmod 644 "$POLKIT_FILE"
echo "[OK] Polkit rule created."

# Restore SteamOS readonly mode
echo "[INFO] Re-enabling SteamOS read-only mode..."
steamos-readonly enable
echo "[OK] System protection restored."
echo

# Final info
echo "================================================="
echo "=== SETUP COMPLETE!                           ==="
echo "================================================="
echo "✔ systemd service: /etc/systemd/system/boot-to-windows.service"
echo "✔ Desktop shortcut: $FINAL_SHORTCUT_PATH"
echo "✔ Polkit rule:      $POLKIT_FILE"
echo
echo "➡ Add 'Boot to Windows.sh' from your Desktop to Steam manually."
echo "➡ You can now reboot into Windows from Gaming Mode without password."
echo
echo "✅ Done. Enjoy!"
