
## How It Works

1.  **Intelligent Detection:** The installer automatically finds your "Windows Boot Manager" entry in the GRUB bootloader configuration.
2.  **Script Creation:** It creates a small executable script (`boot_to_windows.sh`) on your device that uses the detected Windows entry to initiate a reboot.
3.  **Passwordless Execution:** The installer configures your system's `sudoers` file to allow the `boot_to_windows.sh` script to run with elevated privileges **without asking for your `sudo` password** once it's set up. This means a seamless transition directly from Gaming Mode!
4.  **Steam Integration Guidance:** While fully automatic Steam integration is complex due to Steam's internal file formats, the installer provides clear, step-by-step instructions on how to easily add the generated script as a "Non-Steam Game" to your Steam library.
5.  **Gaming Mode Ready:** Once added, you can launch the "Boot To Windows" shortcut directly from your Gaming Mode library, and it will reboot your device into Windows without any further prompts or manual bootloader steps.

---

## Installation Steps

Follow these steps on your ROG Ally or Steam Deck (ensure you are in **Desktop Mode** for installation).

1.  **Download the Installer:**
    * Open a browser on your device (e.g., Firefox).
    * Navigate to the direct download link for the installer:
        [Download `Boot_to_Windows.desktop` Installer](https://raw.githubusercontent.com/Delil-A11yX/SteamOS-Boot-to-Windows-Shortcut/refs/heads/main/Boot_to_Windows.desktop)
    * Download this file to your `~/Downloads` folder or directly to your Desktop.

2.  **Move to Desktop:**
    * If you downloaded it to `~/Downloads`, drag and drop the `Boot_to_Windows.desktop` file from your Downloads folder to your Desktop for easy access.

3.  **Execute the Installer:**
    * **Double-click** the `Boot_to_Windows.desktop` file on your Desktop.
    * A prompt will appear. Select **"Execute in Terminal"**.
    * A terminal window will open. The script will start and ask you to press Enter to continue.
    * **Enter `sudo` Password (Once for Installation):** The script requires elevated permissions to create and configure system files, including the `sudoers` entry. When prompted, enter your `sudo` password (the one you use for system changes on your Steam Deck/Ally). Type it carefully and press Enter. **This is the only time you will need to enter your password for this tool.**

4.  **Follow On-Screen Prompts:**
    * The script will automatically search for your "Windows Boot Manager" entry in your GRUB configuration.
    * It will display the found entry and ask you to **confirm** if it looks correct. Type `y` and press Enter to proceed.
    * It will then create the necessary `boot_to_windows.sh` executable script in `$HOME/SteamOS_Tools/` and configure your system for passwordless execution of this specific script.

5.  **Add to Steam (IMPORTANT - Manual Step):**
    * **Please note:** Fully automated addition to Steam's Game Mode is complex and prone to breaking with Steam updates. Therefore, you need to perform this final step manually. The installer script will print these instructions for you as well:
        1.  Ensure you are in **Desktop Mode**.
        2.  Open the **Steam** client.
        3.  In your Steam Library, look at the bottom-left corner and click on **"ADD A GAME"** -> **"Add a Non-Steam Game..."**.
        4.  In the new window, click **"BROWSE..."**.
        5.  Navigate to the newly created script: `$HOME/SteamOS_Tools/boot_to_windows.sh`.
        6.  Select `boot_to_windows.sh` and click **"Open"**.
        7.  Click **"Add Selected Programs"**.
        8.  **(Optional but Recommended):** In your Steam Library, right-click the new entry (it will likely be named `boot_to_windows.sh`), select **"Properties"**, and change its name to something more user-friendly like **"Boot To Windows"** or **"Switch to Windows"**. You can also set a custom icon if you wish.
    * You might need to restart Steam (or your entire device) for the new entry to appear correctly in Gaming Mode.

---

## How to Use After Installation

Once installed and added to Steam:

1.  Switch to **Gaming Mode** on your ROG Ally / Steam Deck.
2.  Find the **"Boot To Windows"** entry (or whatever you named it) in your Steam Library. It will be under the "Non-Steam" category if you didn't organize it.
3.  Launch it like any other game.
4.  A **small terminal window will briefly appear and then disappear** as your device prepares to reboot. **No password will be required here, and no manual bootloader steps!**
5.  Your device will then restart directly into Windows!

---

## Troubleshooting & Support

* **`sudo` Password during INSTALLATION:** This is required only during the initial setup to configure the system. If you have trouble, ensure you're using the correct password.
* **Windows Not Found during installation:** If the installer script fails to find your Windows entry, it means the `grep` command couldn't locate "Windows Boot Manager" in your GRUB configuration. This usually indicates a non-standard installation or a missing GRUB update. You might need to manually inspect `/boot/grub/grub.cfg` to find the exact name of your Windows entry or ensure GRUB has been updated after Windows installation.
* **Script Not Launching in Steam:** Ensure you made the `boot_to_windows.sh` executable (the installer does this automatically) and that you added it correctly as a non-Steam game following the manual instructions.
* **Feedback & Issues:** If you encounter any problems not listed here, or have suggestions for improvements, please open an issue on this GitHub repository. Your feedback is highly appreciated!

