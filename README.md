# WMT OS
This project delivers a complete, modern Debian 13 (Trixie) build for devices powered by the WonderMedia WM8505 SoC.

Development is focused on the Sylvania SYNET07526, the $99 Windows CE 6.0 netbook [sold by CVS in late 2010](https://www.informationweek.com/it-leadership/cvs-offers-99-sylvania-netbook). Equipped with a 300 MHz single-core [ARM926EJ-S](https://en.wikipedia.org/wiki/ARM9#ARM9E-S_and_ARM9EJ-S) SoC (utilizing the same 2001 CPU architecture as the Nintendo Wii... or rather, its coprocessor), 128 MB of RAM, and an 800x480 display, it was considered e-waste even when it was first released. Naturally, that makes it an excellent candidate for a modern Linux distribution today.

> **Disclaimer:** WMT OS is not affiliated with Debian. Debian is a registered trademark owned by Software in the Public Interest, Inc.

![Netbook running Debian 13 displaying Fastfetch](https://github.com/user-attachments/assets/a0ba3743-7c2e-4eb5-988c-63f511753e22)

## Hardware Support

| Component | Status | Notes |
| :--- | :---: | :--- |
| **Display** | 🟢 | Native LCD output |
| **Backlight** | 🟢 | PWM brightness control |
| **Keyboard & Touchpad** | 🟢 | Native KBDC controller |
| **SD Card** | 🟢 | Native SD/MMC controller |
| **Wi-Fi** | 🟢 | Internal USB adapter (toggled via GPIO) |
| **USB Peripherals** | 🟢 | Keyboards, mice, audio, storage, and networking |
| **Graphics Acceleration** | | |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ *Kernel* | 🟢 | DRM/KMS driver with 2D and console acceleration |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ *Userspace* | 🟡 | Custom 2D IOCTL implemented; X11 driver pending |
| **Built-in Audio** | 🟢 | Headphone and speaker output |
| **Battery Monitoring** | 🔴 | Charge level reporting unavailable |
| **Internal Storage** | 🔴 | NAND flash controller inaccessible |

*(Legend: 🟢 Supported | 🟡 Partial | 🔵 Planned | 🔴 Unsupported)*

## Kernel
This project is powered by the actively maintained [linux-wmt](https://github.com/lrussell887/linux-wmt) kernel fork, currently tracking the `6.12.y` LTS branch. Active development continues to modernize the SoC's hardware support, with recent work bringing new DRM/KMS, DMA engine, ASoC, CCF, and Serio drivers to the platform. If you are interested in legacy ARM development, contributions are welcome to help build out further support!

## System Notes
- **First Boot:** The first boot process takes less than 5 minutes. You will be prompted to configure your timezone, set a hostname, and create a root password.
- **Storage:** The root filesystem is automatically expanded to fit the entire SD card on first boot.
- **Memory:** A 256 MB swap file is included in the disk image and is automatically mounted by `/etc/fstab` on boot.
- **Wi-Fi:** The built-in Wi-Fi adapter is enabled on boot. You can configure your network via `nmtui`. Ensure your network allows [802.11g](https://en.wikipedia.org/wiki/IEEE_802.11g-2003) clients.
- **SSH:** [Dropbear SSH](https://matt.ucc.asn.au/dropbear/dropbear.html) replaces OpenSSH to improve performance, with unique host keys generated automatically on first boot. Since Dropbear lacks SFTP support, file transfers must be done using SCP or the [FISH](https://en.wikipedia.org/wiki/Files_transferred_over_shell_protocol) protocol.

## Repository Contents
- **`seed`:** Contains the list of kernel configuration options needed to "seed" support for the WM8505, overriding options in Debian's default `armel_none_rpi` config.
- **`boot.cmd`:** Contains the commands passed to U-Boot needed to load the kernel and boot Debian.
- **`patches/`:** Custom `.patch` files may be placed in this folder, and will be applied to the kernel at build time.
- **Systemd Services:** Custom unit files to handle device-specific setup:
    - `expand-rootfs.service`: Expands the root filesystem using `growpart` and `resize2fs` on first boot.
    - `gen-dropbear-keys.service`: Generates Dropbear SSH host keys on first boot.
    - `update-hosts.service`: Updates `/etc/hosts` with the user-defined hostname on first boot.
    - `wlan-gpio.service`: Uses `gpioset` to connect/disconnect the built-in USB Wi-Fi adapter.

## Building from Source
Building the OS image requires a Debian or Ubuntu-based host system due to its use of `mmdebstrap`.

1. Clone this repository and navigate to its directory:
    ```bash
    git clone https://github.com/lrussell887/wmt-os.git
    cd wmt-os/
    ```
2. Run the build script (requires root privileges):
    ```bash
    sudo ./build.sh
    ```
The resulting build files will be placed in the `build/` directory.

## Releases
Pre-compiled builds are available on the Releases page.
- **`disk-6.12.y-wm8505.img.gz`** - Full disk image containing the `boot` and `rootfs` partitions. Used for fresh installations.
- **`upgrade-6.12.y-wm8505.tar.gz`** - Tarball containing updated `boot` files and kernel modules. Used for upgrading an existing installation without losing data.

## Installing
Follow these steps to set up a new Debian installation.

**Requirements:**
- An SD card between 4GB and 32GB.
- A copy of `disk-6.12.y-wm8505.img.gz`.
- An imaging tool like [Raspberry Pi Imager](https://www.raspberrypi.com/software/) (recommended) or `dd`.

**Installation Steps:**
1. **Image the SD card** using your preferred tool:
    - **Raspberry Pi Imager:**
        - Click "CHOOSE OS", select "Use custom", and open `disk-6.12.y-wm8505.img.gz`.
        - Click "CHOOSE STORAGE" and select your SD card.
        - Click "NEXT". Choose "NO" for applying OS customizations, then "YES" to start flashing.
    - **Command Line (`dd`):**
        - Decompress the image:
          ```bash
          gzip -d /path/to/disk-6.12.y-wm8505.img.gz
          ```
        - Flash the image (replace `/dev/sdX` with your SD card):
          ```bash
          sudo dd if=/path/to/disk-6.12.y-wm8505.img.gz of=/dev/sdX bs=1M conv=fsync
          ```
        - Eject the drive:
          ```bash
          sudo eject /dev/sdX
          ```
2. **Insert the imaged SD card** into your netbook.
3. **Turn on the netbook.** It will automatically boot from the SD card.

## Upgrading
For upgrading an existing Debian installation to a newer kernel.

### Automated Upgrade (Recommended)
Run the following command directly on your netbook (requires internet and root privileges):
```bash
sudo bash -c "$(wget -q -O - https://raw.githubusercontent.com/lrussell887/wmt-os/master/upgrade-kernel.sh)"
```

### Manual Upgrade
If you prefer to upgrade manually from another Linux computer:
1. Mount your SD card's `boot` and `rootfs` partitions (e.g., `/dev/sdX1` and `/dev/sdX2`):
    ```bash
    mkdir boot rootfs
    sudo mount /dev/sdX1 boot
    sudo mount /dev/sdX2 rootfs
    ```
2. Update the `boot` partition:
    ```bash
    sudo rm -rf boot/*
    sudo tar -xzvf /path/to/upgrade-6.12.y-wm8505.tar.gz -C boot --strip-components=1 boot
    ```
3. Update the `rootfs` partition's kernel modules:
    ```bash
    sudo rm -rf rootfs/lib/modules/*
    sudo tar -xzvf /path/to/upgrade-6.12.y-wm8505.tar.gz -C rootfs --strip-components=1 --skip-old-files rootfs
    ```
4. Eject the SD card:
    ```bash
    sudo eject /dev/sdX
    ```

## Credits
Special thanks to wh0's [bookconfig](https://github.com/wh0/bookconfig) for keeping the [linux-vtwm](https://github.com/linux-wmt/linux-vtwm) project alive up to this point. Additional thanks to projectgus's [kernel_wm8505](https://github.com/projectgus/kernel_wm8505) for archiving VIA's original BSP patches, having access to this historical code has proven invaluable to the modernization efforts.
