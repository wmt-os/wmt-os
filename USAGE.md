# Using WMT OS

## Wi-Fi

The built-in Wi-Fi adapter is enabled on boot. You can configure your network using `nmtui` in the terminal (on the desktop, this is also found in the menu under Settings &#8594; NetworkManager). If your specific netbook shipped with the older 802.11g adapter rather than the 802.11n variant, you may need to ensure your router allows legacy [802.11g](https://en.wikipedia.org/wiki/IEEE_802.11g-2003) clients.

## Updates

Updates ship through the WMT OS APT repository, which is preconfigured on every image. Upgrading is exactly the same as any Debian-based system:

```bash
sudo apt update && sudo apt upgrade
```

When a new kernel installs, it builds its U-Boot files automatically and takes effect on the next reboot, keeping the previous kernel safely as a rollback. No partition mounting or manual file manipulation is required.

## Kernel rollback

If a kernel update causes issues, the boot partition carries a script to easily revert to the previous kernel:

- **Windows or Windows CE:** Run `rollback.cmd`.
- **Linux or macOS:** Run `sh /path/to/rollback.sh`.

The script displays the current and previous kernels and prompts you to switch between them. Re-run it to switch back.

## Kernel command line

Extra arguments can be passed to the kernel at boot by setting `EXTRA_CMDLINE` in `/etc/default/wmt-boot`:

```bash
EXTRA_CMDLINE="loglevel=7"
```

Run `sudo wmt-deploy-boot` to apply the change, which takes effect on the next reboot. The arguments are appended to the built-in boot arguments and persist across kernel updates. Rolling back to the previous kernel also restores its original arguments.

## Desktop hotkeys

The desktop profile ships with a few system-wide hotkeys. These can be overridden per-user by editing `~/.icewm/keys`:

| Keys                  | Action             |
| :-------------------- | :----------------- |
| Super+Up / Super+Down | Display brightness |
| Super+= / Super+-     | Volume             |
| Alt+Ctrl+T            | Terminal           |
| Alt+Ctrl+B            | Web browser        |

On these netbooks, the `Super` key corresponds to the key printed with a `Zzz` sleep icon, located exactly where the Windows key normally sits. If a window opens off-screen, hold `Alt` and drag to move it.

## SSH

Dropbear provides the SSH server, with host keys uniquely generated on first boot. Because Dropbear lacks SFTP support, file transfers must be done using SCP or the [FISH](https://en.wikipedia.org/wiki/Files_transferred_over_shell_protocol) protocol.
