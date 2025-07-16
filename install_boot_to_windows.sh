#!/bin/bash
#
# AUTO-INSTALLER: Boot to Windows via systemd (SteamOS)
# No sudoers hacks. Fully Gaming Mode compatible. One-click setup.
#

echo "================================================="
echo "=== Boot to Windows | One-Klick Setup         ==="
echo "================================================="
echo

# Check sudo
if [ -z "$SUDO_USER" ]; then
    echo "[ERROR] Dieses Skript muss via .desktop-Datei mit sudo gestartet werden."
    exit 1
fi

# Schreibschutz deaktivieren
echo "[INFO] Deaktiviere temporär den Schreibschutz..."
steamos-readonly disable
echo "[OK] Schreibgeschützt ist deaktiviert."
echo

# Windows Boot ID ermitteln
echo "[INFO] Ermittle Windows Boot Manager ID..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')
if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[ERROR] Windows Boot Manager konnte nicht gefunden werden."
    steamos-readonly enable
    exit 1
fi
echo "[OK] Gefundene Boot-ID: $WINDOWS_ENTRY_ID"
echo

# systemd-Service einrichten
SERVICE_PATH="/etc/systemd/system/boot-to-windows.service"
echo "[INFO] Erstelle systemd-Service unter $SERVICE_PATH..."

cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Boot into Windows and reboot
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/efibootmgr -n $WINDOWS_ENTRY_ID
ExecStartPost=/usr/bin/systemctl reboot
User=root
EOF

chmod 644 "$SERVICE_PATH"
systemctl daemon-reexec
systemctl daemon-reload
echo "[OK] Service erstellt und registriert."
echo

# Desktop-Skript erstellen
BOOT_SCRIPT="/home/$SUDO_USER/Desktop/Boot to Windows.sh"
echo "[INFO] Erstelle Startskript auf dem Desktop..."

cat <<EOF > "$BOOT_SCRIPT"
#!/bin/bash
systemctl start boot-to-windows.service
EOF

chmod +x "$BOOT_SCRIPT"
chown "$SUDO_USER:$SUDO_USER" "$BOOT_SCRIPT"
echo "[OK] Startskript: $BOOT_SCRIPT"
echo

# SteamOS wieder schreibgeschützt machen
echo "[INFO] Aktiviere wieder den Schreibschutz..."
steamos-readonly enable
echo "[OK] Schreibschutz aktiv."
echo

# Fertig
echo "================================================="
echo "=== SETUP ABGESCHLOSSEN                       ==="
echo "================================================="
echo "✔ systemd-Service: boot-to-windows.service"
echo "✔ Startskript:    $BOOT_SCRIPT"
echo
echo "➡ Füge diese Datei in Steam hinzu:"
echo "   $BOOT_SCRIPT"
echo
echo "✅ Du kannst jetzt aus dem Gaming Mode direkt in Windows booten – ohne Passwort, ohne Terminal."
