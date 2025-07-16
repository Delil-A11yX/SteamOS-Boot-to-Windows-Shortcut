#!/bin/bash
#
# FINAL ONE-KLICK INSTALLER: Boot to Windows (SteamOS)
# Unterstützt Desktop + Gaming Mode, 100 % ohne Passwort
#

echo "================================================="
echo "=== Boot to Windows | One-Klick Setup         ==="
echo "================================================="
echo

# Step 1: Muss via sudo gestartet werden
if [ -z "$SUDO_USER" ]; then
    echo "[ERROR] Bitte über .desktop-Datei mit sudo ausführen!"
    exit 1
fi

# Schreibschutz deaktivieren
echo "[INFO] Deaktiviere temporär den Schreibschutz..."
steamos-readonly disable
echo "[OK] Schreibschutz deaktiviert."
echo

# Windows Boot-ID suchen
echo "[INFO] Suche Windows Boot Manager..."
WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')
if [ -z "$WINDOWS_ENTRY_ID" ]; then
    echo "[ERROR] Windows Boot Manager konnte nicht gefunden werden!"
    steamos-readonly enable
    exit 1
fi
echo "[OK] Gefunden: Boot$WINDOWS_ENTRY_ID"
echo

# systemd-Service anlegen
SERVICE_FILE="/etc/systemd/system/boot-to-windows.service"
echo "[INFO] Erstelle systemd-Service unter $SERVICE_FILE..."

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
echo "[OK] systemd-Service eingerichtet."
echo

# Bootskript auf Desktop
BOOT_SCRIPT="/home/$SUDO_USER/Desktop/Boot to Windows.sh"
echo "[INFO] Erstelle Bootskript auf dem Desktop..."

cat <<EOF > "$BOOT_SCRIPT"
#!/bin/bash
systemctl start boot-to-windows.service
EOF

chmod +x "$BOOT_SCRIPT"
chown "$SUDO_USER:$SUDO_USER" "$BOOT_SCRIPT"
echo "[OK] Skript erstellt: $BOOT_SCRIPT"
echo

# Polkit-Regel hinzufügen
POLKIT_FILE="/etc/polkit-1/rules.d/99-boot-to-windows.rules"
echo "[INFO] Erlaube systemctl-Aufruf für Benutzer '$SUDO_USER' ohne Passwort..."

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
echo "[OK] Polkit-Regel erstellt: $POLKIT_FILE"
echo

# Schreibschutz wieder aktivieren
echo "[INFO] Aktiviere Schreibschutz erneut..."
steamos-readonly enable
echo "[OK] System geschützt."
echo

# Fertig
echo "================================================="
echo "=== INSTALLATION ABGESCHLOSSEN                ==="
echo "================================================="
echo "✔ systemd-Service: boot-to-windows.service"
echo "✔ Bootskript:     $BOOT_SCRIPT"
echo "✔ Polkit-Regel:   $POLKIT_FILE"
echo
echo "➡ Jetzt 'Boot to Windows.sh' in Steam einfügen."
echo "➡ Starte es im Gaming Mode – du wirst ohne Passwort direkt nach Windows gebootet."
echo
echo "✅ Viel Erfolg!"
