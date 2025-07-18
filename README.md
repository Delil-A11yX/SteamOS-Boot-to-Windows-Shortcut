# Boot to Windows Shortcut for SteamOS

A simple, one-click installer that creates a "Boot to Windows" shortcut on your Desktop. This shortcut works seamlessly from both Desktop and Gaming Mode, rebooting your device directly into Windows with no password prompts required.

This tool saves you the hassle of manually shutting down your device, entering the bootloader, and selecting your Windows partition every time you want to switch. While it may not save a huge amount of time, it adds a significant layer of convenience to the dual-booting experience.

This tool is designed for dual-boot users on the Steam Deck or other PCs running SteamOS.

## How It Works

For those interested in the technical details, here’s a step-by-step breakdown of what the installer does after you run it:

1.  **System Preparation:** First, it temporarily disables the read-only protection of SteamOS, allowing it to create the necessary system files.
2.  **Automatic Detection:** The script automatically scans your system's EFI boot entries using `efibootmgr` to find the unique ID for the "Windows Boot Manager". This means you don't have to find it manually.
3.  **Service Creation:** It creates a small background service (`systemd` service). This service holds the two core commands: setting the next boot target to Windows (`efibootmgr -n...`) and rebooting the system (`systemctl reboot`).
4.  **Safe Permission Granting:** To allow you to trigger this service without a password, a `Polkit` rule is created. This is the modern and secure way on Linux to grant specific permissions for system actions, without touching the global `sudoers` file.
5.  **Shortcut Creation:** A simple, executable shortcut script is placed on your Desktop. This script's only job is to start the background service when you click it.
6.  **System Protection:** Finally, the installer re-enables the read-only filesystem, leaving your system safe and protected.

## Key Features

* **One-Click Install:** Run a single installer from your Desktop to set everything up automatically.
* **No Password Needed:** After setup, no password is required to boot into Windows.
* **Gaming Mode Ready:** Launch the shortcut directly from your Steam library like any other game.
* **Modern & Safe:** Uses `systemd` services and `Polkit` rules for permissions, which is the modern and preferred method on Linux.

---

## Compatibility & Limitations

This script is designed to be as simple as possible and therefore only supports the most common dual-boot configuration. Please read these limitations before use:

* **Internal Drive Only:** The script is designed for a standard dual-boot where **Windows is installed on an internal SSD/NVMe drive**. It will likely fail if you are running Windows from an external USB drive, as the boot entry name will be different.
* **No Custom Bootloaders:** This script is only compatible with the default **SteamOS bootloader (`systemd-boot`)**. If you use a custom bootloader like Clover, rEFInd, or GRUB, this script will not work as intended and may simply reboot you into your bootloader's selection menu.

### How to Adapt the Script (Advanced Users)

If you have a non-standard setup (like a Windows installation on a USB drive), the installer will likely fail because it can't find the "Windows Boot Manager" entry. You can adapt the script with these manual steps:

1.  **Find Your Boot Entry Name:** Open a Konsole terminal in Desktop Mode and run `sudo efibootmgr`. Look through the list to find the exact name of your Windows entry (e.g., `UEFI: SanDisk Extreme` or `Windows To Go`).
2.  **Edit the Installer Script:**
    * Download the `install_boot_to_windows.sh` script from the GitHub repository.
    * Open it with a text editor (like Kate).
    * Find this line (around line 25):
        `WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "Windows Boot Manager" | grep -oP 'Boot\K\d{4}')`
    * Replace `"Windows Boot Manager"` with the exact name you found in step 1. For example:
        `WINDOWS_ENTRY_ID=$(efibootmgr | grep -i "UEFI: SanDisk Extreme" | grep -oP 'Boot\K\d{4}')`
3.  **Run the Modified Script:** Save your changes and run the modified local script from the terminal with `sudo bash ./install_boot_to_windows.sh`.

---

## ⚠️ Disclaimer & Disadvantages

**Please read this carefully before installing. Use this tool at your own risk.**

This script modifies system-level configurations. While it is designed to be safe, you should be aware of what it does.

1.  **Broad Permissions:** To achieve a password-less experience, this script adds a **Polkit rule**. The rule provided is intentionally broad for maximum compatibility. It grants your user (`deck`) the ability to manage **all** `systemd` services (start, stop, restart) without a password. This is a potential security risk if malicious software were ever to run under your user account.
2.  **System Modifications:** This script will disable the read-only filesystem temporarily to create two files in the `/etc/` directory:
    * `/etc/systemd/system/boot-to-windows.service` (The background service)
    * `/etc/polkit-1/rules.d/99-boot-to-windows.rules` (The permission rule)
    The read-only protection is re-enabled automatically afterward.
3.  **Future SteamOS Updates:** This tool works with the current version of SteamOS. Future updates from Valve could potentially change how `systemd` or `Polkit` works, which might break this tool or require it to be updated.

**It is always recommended to have a backup of your important data before making any system-level changes.**

---

## Installation

The installation is fully automated. You only need to run the installer once.

1.  **Switch to Desktop Mode** on your Steam Deck.
2.  [➡️ **Click Here to Download the Boot to Windows Installer** ⬅️](https://github.com/Delil-A11yX/SteamOS-Boot-to-Windows-Shortcut/releases/download/V1.0/Boot_to_Windows.desktop)
3.  **Run the Installer:**
    * Move the downloaded `.desktop` file to your Desktop.
    * Double-click the installer icon.
    * A prompt will appear. Choose **"Execute in Terminal"**.
    * A terminal window will open and ask for your `sudo` password. Type it in and press Enter.
4.  **Done!** The script will automatically perform all necessary steps. A new shortcut named **`Boot to Windows.sh`** will appear on your Desktop.

## How to Use

Once the installation is complete:

1.  **Add to Steam:** In Steam's Desktop Mode, go to `Games` -> `Add a Non-Steam Game to My Library...`. Click `Browse...` and select the `Boot to Windows.sh` file from your Desktop.
2.  **Launch from Gaming Mode:** Switch back to Gaming Mode. You will find "Boot to Windows" in your library (usually under the "Non-Steam" tab). Launch it like any other game.
3.  Your device will reboot directly into Windows.

---

## Uninstallation

If you wish to remove this tool and all its components, you can do so manually.

1.  **Switch to Desktop Mode**.
2.  Open a Konsole terminal and run the following commands one by one:

    ```bash
    # Disable read-only mode to remove system files
    sudo steamos-readonly disable

    # Disable and remove the systemd service
    sudo systemctl disable --now boot-to-windows.service
    sudo rm /etc/systemd/system/boot-to-windows.service

    # Remove the Polkit rule
    sudo rm /etc/polkit-1/rules.d/99-boot-to-windows.rules

    # Remove the Desktop shortcut
    rm ~/Desktop/"Boot to Windows.sh"

    # Reload systemd to un-register the service
    sudo systemctl daemon-reload

    # Re-enable read-only mode
    sudo steamos-readonly enable

    echo "Uninstallation complete."
    ```
3.  Finally, remove the shortcut from your Steam library (Right-click -> Manage -> Remove non-Steam game).
