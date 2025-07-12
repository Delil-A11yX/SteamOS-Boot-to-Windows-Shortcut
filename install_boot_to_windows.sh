#!/bin/bash

# Dieses Skript wird mit sudo-Rechten ausgeführt.
# $SUDO_USER enthält den Namen des Benutzers, der den sudo-Befehl ursprünglich ausgeführt hat.
if [ -z "$SUDO_USER" ]; then
    echo "FEHLER: Dieses Skript muss mit 'sudo' ausgeführt werden."
    exit 1
fi

# Das Installationsverzeichnis im Home-Ordner des ursprünglichen Benutzers
INSTALL_DIR="/home/$SUDO_USER/SteamOS_Tools"
BOOT_SCRIPT_FILENAME="boot_to_windows.sh"
BOOT_SCRIPT_PATH="$INSTALL_DIR/$BOOT_SCRIPT_FILENAME"

# --- Funktionen ---
log_message() {
    echo "--- $1 ---"
}

error_exit() {
    log_message "FEHLER: $1"
    echo "Installation wird abgebrochen."
    exit 1
}

find_windows_efi_entry() {
    log_message "Suche nach Windows Boot Manager Eintrag mittels efibootmgr..."
    # 'efibootmgr' listet alle EFI-Einträge auf. Wir filtern nach "Windows Boot Manager" und extrahieren die Boot-Nummer.
    local entry_id=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')
    if [ -z "$entry_id" ]; then
        error_exit "Konnte 'Windows Boot Manager' Eintrag nicht in der EFI Boot-Reihenfolge finden. Bitte 'efibootmgr -v' manuell prüfen."
    else
        log_message "EFI-Eintrag für Windows gefunden: Boot$entry_id"
        echo "$entry_id"
        return 0
    fi
}

create_boot_script() {
    local windows_efi_id="Boot$1"
    log_message "Erstelle das Boot-Skript unter: $BOOT_SCRIPT_PATH"

    # Erstelle das Verzeichnis und setze sofort den korrekten Besitzer.
    mkdir -p "$INSTALL_DIR"
    chown "$SUDO_USER":"$SUDO_USER" "$INSTALL_DIR"

    # Schreibe das Skript
    cat << EOF > "$BOOT_SCRIPT_PATH"
#!/bin/bash
# Dieses Skript wird vom Benutzer im Gaming Mode ausgeführt.
echo "Boote zu Windows..."
# Das 'sudo' Kommando hier wird wegen der sudoers-Konfiguration nicht nach einem Passwort fragen.
sudo efibootmgr -n "$windows_efi_id"
sudo reboot
EOF

    if [ $? -eq 0 ]; then
        log_message "Boot-Skript erfolgreich erstellt."
        # Stelle sicher, dass das Skript dem ursprünglichen Benutzer gehört und ausführbar ist.
        chown "$SUDO_USER":"$SUDO_USER" "$BOOT_SCRIPT_PATH"
        chmod +x "$BOOT_SCRIPT_PATH"
        log_message "Boot-Skript ausführbar gemacht."
        return 0
    else
        error_exit "Konnte das Boot-Skript nicht erstellen."
    fi
}

configure_sudoers() {
    log_message "Konfiguriere sudoers für passwortlose Ausführung für Benutzer '$SUDO_USER'..."
    local sudoers_file="/etc/sudoers.d/99-boot-to-windows"
    # Diese Zeile erlaubt dem Benutzer, das Boot-Skript ohne Passwort auszuführen.
    local entry_line="$SUDO_USER ALL=(ALL) NOPASSWD: $BOOT_SCRIPT_PATH"

    echo "$entry_line" > "$sudoers_file" || error_exit "Konnte sudoers-Eintrag nicht schreiben."
    chmod 0440 "$sudoers_file" || error_exit "Konnte Berechtigungen für sudoers-Datei nicht setzen."

    log_message "Sudoers erfolgreich konfiguriert."
}

# --- Hauptausführung ---
log_message "Starte automatisches 'Boot zu Windows' Setup"
echo "Dieses Skript wird den Windows Boot-Eintrag finden, ein Boot-Skript erstellen,"
echo "und dein System für einen passwortlosen Neustart aus dem Gaming Mode konfigurieren."
echo

WINDOWS_EFI_ID=$(find_windows_efi_entry)
create_boot_script "$WINDOWS_EFI_ID"
configure_sudoers

log_message "--- Setup Abgeschlossen! ---"
echo "Das 'Boot To Windows' Skript wurde unter $BOOT_SCRIPT_PATH erstellt."
echo "Bitte füge es jetzt manuell als 'Nicht-Steam-Spiel' zu deiner Steam-Bibliothek hinzu."
