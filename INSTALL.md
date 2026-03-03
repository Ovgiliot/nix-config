# Installation Guide

This configuration ships its own installer image. It is a custom NixOS ISO with the tools and a `bootstrap` command already built in — no manual cloning or package installation required on the target machine.

---

## What you need

- A USB drive (at least 2 GB)
- A second machine (Linux, x86_64) with Nix installed to build and flash the USB
- The target machine (x86_64, UEFI)
- An internet connection on the target machine

---

## Step 1 — Build and flash the USB

On your **build machine**, inside this repository:

```bash
# Build the installer ISO (takes a few minutes on first run)
nix build .#installMedia-x86_64

# Flash it to a USB drive — replace /dev/sdX with your USB device
nix run .#flash -- /dev/sdX
```

> **Find your USB device:** run `lsblk` before and after plugging in the USB drive. The new entry is your device. Use the whole-disk path (e.g. `/dev/sdb`), not a partition (e.g. `/dev/sdb1`).
>
> **Warning:** the USB drive will be completely erased.

The flash command installs [Ventoy](https://ventoy.net) on the drive and copies the ISO onto it. When it finishes you will see:

```
==> Done. Boot from USB on any x86_64 UEFI machine.
    Select the NixOS ISO from the Ventoy menu.
    Then: nmtui  ->  bootstrap
```

---

## Step 2 — Boot the USB on the target machine

Plug the USB into the target machine and boot from it. You may need to press `F12`, `F10`, or `Del` to open the boot menu and select the USB drive.

You will land on the **Ventoy menu** — select the NixOS ISO and press Enter.

After a short boot sequence you will reach a shell prompt, already logged in as `root`. The screen will show:

```
Run 'bootstrap' to clone the config and start installation.
```

---

## Step 3 — Connect to the internet

**Ethernet:** already connected automatically. Skip to Step 4.

**WiFi:**

```bash
nmtui
```

This opens a simple text menu. Choose **"Activate a connection"**, select your network, and enter the password. Press **Back** when connected, then **Quit**.

---

## Step 4 — Run the installer

```bash
bootstrap
```

This clones the configuration from GitHub and starts the interactive installer. It will ask you a series of questions:

1. **Profile** — choose what kind of machine this is:
   - `laptop` — portable machine; includes power management, hibernate, and ThinkPad-specific settings
   - `workstation` — desktop; includes gaming support
   - `server` — headless, no graphical interface

2. **Hostname** — a name for this machine (e.g. `thinkpad`, `homeserver`).

3. **GPU vendor** *(laptop and workstation only)* — `intel`, `amd`, or `none`. Used to enable hardware video acceleration. Pick the brand of your graphics chip; `none` always works but disables acceleration.

4. **Keyboard device** *(laptop and workstation only)* — the path to your keyboard for key remapping. The default shown is correct for most ThinkPads. Press Enter to accept it.

5. **System disk** — the installer lists all available disks. If there is only one it is selected automatically. Otherwise type the path shown (e.g. `/dev/nvme0n1`).

   > **Warning:** the selected disk will be completely erased.

6. **Separate home disk** *(only shown when two or more disks are present)* — choose whether `/home` should go on a second disk.

7. **Root partition size** — how much space to give the system (e.g. `60G`). The remainder of the disk becomes `/home`. If using a separate home disk, the system disk is used entirely for the system.

8. **LUKS passphrase** — a strong password that encrypts all data on the disk. You will be asked for it every time you boot (unless you set up TPM2 in the next step). **There is no recovery if you forget this password.**

   The installer asks you to type it twice to confirm.

After you answer these questions, the installation runs without further input. It will:

- Partition and format the disk(s)
- Encrypt everything with your passphrase
- Install NixOS with this configuration
- Copy the configuration to the new system

---

## Step 5 — TPM2 auto-unlock (optional)

If the machine has a TPM2 chip, the installer will ask if you want automatic disk unlock at boot — meaning no passphrase prompt on your own machine. The passphrase still works as a fallback (e.g. if the disk is moved to a different machine).

Choose `yes` to enable it, `no` to always enter the passphrase at boot.

---

## Step 6 — Reboot

When the installer finishes:

```bash
reboot
```

Remove the USB drive when the machine starts to shut down.

---

## First boot

If you did not enable TPM2, you will be asked for your LUKS passphrase. After that you will reach the login screen.

Log in with username `ovg`. No password is set initially — set one immediately after logging in:

```bash
passwd
```

Your configuration is at `~/dotfiles/nix`.

---

## Partition layout reference

| Profile | Single disk | Two disks |
|---------|-------------|-----------|
| **laptop** | ESP 1 GB · swap = RAM (LUKS) · root = *your size* (LUKS) · home = rest (LUKS) | System disk: ESP 1 GB · swap = RAM (LUKS) · root = 100% (LUKS) · Home disk: home = 100% (LUKS) |
| **workstation / server** | ESP 1 GB · root = *your size* (LUKS) · home = rest (LUKS) | System disk: ESP 1 GB · root = 100% (LUKS) · Home disk: home = 100% (LUKS) |

All encrypted partitions share the same passphrase.

---

## Troubleshooting

**The flash command fails.**
Make sure no partitions on the USB drive are mounted. Run `sudo umount /dev/sdX*` and retry.

**The target machine does not boot from USB.**
Enter the firmware boot menu (usually `F12`, `F10`, or `Del` at startup) and select the USB drive manually. Also confirm the machine uses UEFI, not legacy BIOS.

**`bootstrap` fails with a git error.**
The target machine has no internet. Go back to Step 3 and verify the connection with `ping nixos.org`.

**The installer fails during partitioning.**
Reboot the USB and try again. If the disk was partially set up from a previous attempt, the installer will clean it up on the next run.

**I forgot my LUKS passphrase.**
There is no recovery. Reinstall and choose a new passphrase.

**The screen is black after reboot.**
Type your LUKS passphrase at the prompt even if nothing is visible — the system may still be waiting for it. If the machine boots but the display stays blank, switch to a text console with `Ctrl+Alt+F2`.
