#!/usr/bin/env bash
# install.sh — NixOS fresh installer for a live ISO environment.
#
# Must be run inside the NixOS minimal installer ISO (/ is a tmpfs).
# Darwin and already-installed-system paths are intentionally excluded;
# they belong in separate scripts.
#
# Partition layout:
#   All profiles:  /boot  1 GiB  vfat  (ESP)
#   Laptop only:   swap   = RAM  LUKS  (hibernate support)
#   All profiles:  /      user-specified or rest-of-disk  ext4  LUKS
#   All profiles:  /home  rest of disk (or separate disk) ext4  LUKS
#
# Usage: bash install.sh [--unattended] [--skip-install] [--skip-disko]
#   --unattended    Read all parameters from environment variables; skip
#                   interactive prompts, the data-destruction confirmation,
#                   the live ISO guard, and TPM2 enrollment.
#   --skip-install  Do everything except nix eval, nixos-install, and the
#                   dotfiles copy.  Useful for testing disko + file generation.
#   --skip-disko    Implies --skip-install.  Also skip disko partitioning,
#                   hardware.nix generation, and related cleanup.  Generates a
#                   stub hardware.nix.  Useful for testing file generation only.
set -euo pipefail

FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNATTENDED=false
SKIP_INSTALL=false
SKIP_DISKO=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info() { printf '\033[1;34m==> \033[0m%s\n' "$*"; }
ok() { printf '\033[1;32m ok \033[0m%s\n' "$*"; }
warn() { printf '\033[1;33mwarn\033[0m %s\n' "$*" >&2; }
die() {
	printf '\033[1;31merr \033[0m%s\n' "$*" >&2
	exit 1
}

# Clean up sensitive temp files and environment on exit (normal or abnormal).
cleanup() {
	rm -f /tmp/luks-install.key
	unset LUKS_PASSPHRASE INITIAL_PASSWORD HASHED_PASSWORD 2>/dev/null || true
}
trap cleanup EXIT

prompt() {
	local var="$1" msg="$2" default="${3:-}"
	if [[ "$UNATTENDED" == true ]]; then
		if [[ -n "${!var:-}" ]]; then return; fi
		if [[ -n "$default" ]]; then
			printf -v "$var" '%s' "$default"
			return
		fi
		die "--unattended: $var not set in environment."
	fi
	local hint=""
	[[ -n "$default" ]] && hint=" [$default]"
	printf '%s%s: ' "$msg" "$hint"
	read -r "$var"
	if [[ -z "${!var}" && -n "$default" ]]; then
		printf -v "$var" '%s' "$default"
	fi
	[[ -z "${!var}" ]] && die "Required value not provided."
}

prompt_secret() {
	local var="$1" msg="$2"
	if [[ "$UNATTENDED" == true ]]; then
		[[ -n "${!var:-}" ]] || die "--unattended: $var not set in environment."
		return
	fi
	printf '%s: ' "$msg"
	read -rs "$var"
	printf '\n'
	[[ -z "${!var}" ]] && die "Required value not provided."
}

choose() {
	# choose VAR "prompt" option1 option2 ...
	local var="$1" msg="$2"
	shift 2
	local opts=("$@")
	if [[ "$UNATTENDED" == true ]]; then
		[[ -n "${!var:-}" ]] || die "--unattended: $var not set in environment."
		local valid=false
		for opt in "${opts[@]}"; do
			[[ "${!var}" == "$opt" ]] && valid=true
		done
		[[ "$valid" == true ]] || die "--unattended: $var='${!var}' is not one of: ${opts[*]}"
		return
	fi
	echo "$msg"
	for i in "${!opts[@]}"; do
		printf '  %d) %s\n' "$((i + 1))" "${opts[$i]}"
	done
	local choice
	while true; do
		printf 'Choice [1-%d]: ' "${#opts[@]}"
		read -r choice
		if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#opts[@]})); then
			printf -v "$var" '%s' "${opts[$((choice - 1))]}"
			return
		fi
		warn "Enter a number between 1 and ${#opts[@]}."
	done
}

# Numbered disk selection menu using the global ALL_DISKS array.
# choose_disk VAR "prompt message" [excluded_dev]
# Prints each eligible disk as: N) /dev/sdX  SIZE  MODEL
choose_disk() {
	local var="$1" msg="$2" exclude="${3:-}"
	if [[ "$UNATTENDED" == true ]]; then
		[[ -n "${!var:-}" ]] || die "--unattended: $var not set in environment."
		return
	fi
	local disks=()
	for d in "${ALL_DISKS[@]}"; do
		[[ -n "$exclude" && "$d" == "$exclude" ]] && continue
		disks+=("$d")
	done
	[[ ${#disks[@]} -eq 0 ]] && die "No disks available to select from."
	if [[ ${#disks[@]} -eq 1 ]]; then
		printf -v "$var" '%s' "${disks[0]}"
		info "Only one eligible disk — auto-selected: ${disks[0]}"
		return
	fi
	echo "$msg"
	for i in "${!disks[@]}"; do
		local disk_info
		disk_info=$(lsblk -dpno SIZE,MODEL "${disks[$i]}" 2>/dev/null | tr -s ' ' | sed 's/^ //' || echo "unknown")
		printf '  %d) %-20s %s\n' "$((i + 1))" "${disks[$i]}" "$disk_info"
	done
	local choice
	while true; do
		printf 'Choice [1-%d]: ' "${#disks[@]}"
		read -r choice
		if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#disks[@]})); then
			printf -v "$var" '%s' "${disks[$((choice - 1))]}"
			return
		fi
		warn "Enter a number between 1 and ${#disks[@]}."
	done
}

# Return the partition device for a given disk and partition number.
# Handles both SATA (/dev/sda1) and NVMe/eMMC (/dev/nvme0n1p1) naming.
part() {
	local disk="$1" num="$2"
	if [[ "$disk" == *nvme* || "$disk" == *mmcblk* ]]; then
		echo "${disk}p${num}"
	else
		echo "${disk}${num}"
	fi
}

# Enroll a LUKS partition for TPM2 auto-unlock.
# $1 = block device (the raw LUKS partition, e.g. /dev/sda2)
# $2 = path to a file containing the existing LUKS passphrase
enroll_tpm2() {
	local dev="$1" keyfile="$2"
	info "  Enrolling TPM2 for $dev ..."
	systemd-cryptenroll \
		--tpm2-device=auto \
		--tpm2-pcrs="" \
		--unlock-key-file="$keyfile" \
		"$dev" && ok "  $dev enrolled." ||
		warn "  TPM2 enrollment failed for $dev — enroll manually later with:"$'\n'"    sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=\"\" $dev"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
for arg in "$@"; do
	case "$arg" in
	--unattended) UNATTENDED=true ;;
	--skip-install) SKIP_INSTALL=true ;;
	--skip-disko)
		SKIP_DISKO=true
		SKIP_INSTALL=true
		;;
	*) die "Unknown argument: $arg" ;;
	esac
done

# ---------------------------------------------------------------------------
# NixOS state version
# ---------------------------------------------------------------------------
# Derived from the running installer's nixpkgs (e.g. "25.11.20250308.abc1234"
# → "25.11").  Override via STATE_VERSION env var for testing on non-NixOS.
STATE_VERSION="${STATE_VERSION:-}"
if [[ -z "$STATE_VERSION" ]]; then
	STATE_VERSION="$(nixos-version 2>/dev/null | cut -d. -f1,2)" ||
		die "Could not determine NixOS version from nixos-version."
	[[ -n "$STATE_VERSION" ]] || die "Could not parse stateVersion from nixos-version output."
fi

# ---------------------------------------------------------------------------
# 1. Live ISO guard
# ---------------------------------------------------------------------------
if [[ "$UNATTENDED" != true ]]; then
	grep -q '^tmpfs / tmpfs' /proc/mounts 2>/dev/null ||
		die "This script must run inside the NixOS live installer ISO (tmpfs root not detected)."
	info "Live ISO environment confirmed."
else
	warn "Unattended mode — skipping live ISO guard."
fi

# ---------------------------------------------------------------------------
# 2. Architecture detection
# ---------------------------------------------------------------------------
LINUX_SYSTEM="x86_64-linux"
case "$(uname -m)" in
x86_64) LINUX_SYSTEM="x86_64-linux" ;;
aarch64) LINUX_SYSTEM="aarch64-linux" ;;
*) die "Unsupported architecture: $(uname -m)" ;;
esac
info "Architecture: $LINUX_SYSTEM"

# ---------------------------------------------------------------------------
# 3. Pre-flight tool checks
# ---------------------------------------------------------------------------
info "Checking required tools..."
REQUIRED_TOOLS=(blkid alejandra)
[[ "$SKIP_DISKO" != true ]] && REQUIRED_TOOLS+=(disko nixos-generate-config)
[[ "$SKIP_INSTALL" != true ]] && REQUIRED_TOOLS+=(nixos-install)
for tool in "${REQUIRED_TOOLS[@]}"; do
	command -v "$tool" &>/dev/null ||
		die "Required tool not found: $tool. Use the custom installer ISO (nix build .#installMedia-x86_64)."
done
ok "All required tools present."

# ---------------------------------------------------------------------------
# 4. Profile selection
# ---------------------------------------------------------------------------
choose PROFILE "Select a profile:" "laptop" "workstation" "server"
info "Profile: $PROFILE"
# Server profile needs mkpasswd to hash the initial password.
if [[ "$PROFILE" == "server" ]]; then
	command -v mkpasswd &>/dev/null ||
		die "mkpasswd not found. Use the custom installer ISO (nix build .#installMedia-x86_64) or install the 'whois' package."
fi

# ---------------------------------------------------------------------------
# 5. Hostname
# ---------------------------------------------------------------------------
prompt TARGET_HOST "Hostname for this machine"
[[ "$TARGET_HOST" =~ ^[a-zA-Z]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]] ||
	die "Invalid hostname: must start with a letter, end with a letter or digit, and contain only letters, digits, and hyphens."
info "Hostname: $TARGET_HOST"

# ---------------------------------------------------------------------------
# 6. Profile-specific inputs: GPU + kanata (desktop profiles)
# ---------------------------------------------------------------------------
KANATA_DEVICE="${KANATA_DEVICE:-}"
VIDEO_ACCEL="${VIDEO_ACCEL:-}"
if [[ "$PROFILE" == "laptop" || "$PROFILE" == "workstation" ]]; then
	choose VIDEO_ACCEL "GPU vendor (for hardware video acceleration):" "intel" "amd" "none"
	info "Video acceleration: $VIDEO_ACCEL"

	if [[ "$PROFILE" == "laptop" ]]; then
		DEFAULT_KBD="/dev/input/by-path/platform-i8042-serio-0-event-kbd"
		prompt KANATA_DEVICE "Keyboard device path for Kanata" "$DEFAULT_KBD"
	else
		# Workstations typically use USB keyboards — no safe default exists.
		prompt KANATA_DEVICE "Keyboard device path for Kanata (e.g. /dev/input/by-path/…-usb-…-event-kbd)"
	fi
	info "Kanata device: $KANATA_DEVICE"
fi

# ---------------------------------------------------------------------------
# 7. Server: initial password (no autologin on server — must set one)
# ---------------------------------------------------------------------------
INITIAL_PASSWORD="${INITIAL_PASSWORD:-}"
HASHED_PASSWORD=""
if [[ "$PROFILE" == "server" ]]; then
	if [[ "$UNATTENDED" == true ]]; then
		[[ -n "$INITIAL_PASSWORD" ]] || die "--unattended: INITIAL_PASSWORD not set for server profile."
	else
		warn "Server profile has no autologin. An initial password is required for first boot."
		warn "Change it immediately after login with: passwd ovg"
		while true; do
			prompt_secret INITIAL_PASSWORD "Initial password for ovg"
			INITIAL_PASSWORD_CONFIRM=""
			prompt_secret INITIAL_PASSWORD_CONFIRM "Confirm initial password"
			if [[ "$INITIAL_PASSWORD" == "$INITIAL_PASSWORD_CONFIRM" ]]; then
				unset INITIAL_PASSWORD_CONFIRM
				break
			fi
			warn "Passwords do not match. Try again."
		done
	fi
	# Hash the password so plaintext never appears in generated Nix files.
	HASHED_PASSWORD=$(printf '%s' "$INITIAL_PASSWORD" | mkpasswd -m sha-512 --stdin) ||
		die "mkpasswd failed to hash the initial password."
	[[ -n "$HASHED_PASSWORD" ]] || die "mkpasswd produced empty output."
	unset INITIAL_PASSWORD
fi

# ---------------------------------------------------------------------------
# 8. RAM detection (laptop only — determines swap partition size)
# ---------------------------------------------------------------------------
SWAP_SIZE=""
if [[ "$PROFILE" == "laptop" ]]; then
	RAM_KB=$(grep '^MemTotal:' /proc/meminfo | awk '{print $2}')
	RAM_GB=$(((RAM_KB + 1048575) / 1048576)) # round up to nearest GiB
	SWAP_SIZE="${RAM_GB}G"
	info "Detected RAM: ${RAM_GB} GiB — swap will be set to ${SWAP_SIZE}."
fi

# ---------------------------------------------------------------------------
# 9. Disk discovery
# ---------------------------------------------------------------------------
echo ""
info "Available block devices:"
lsblk -dpno NAME,SIZE,MODEL | grep -v '^$' | grep -v loop || true
echo ""

mapfile -t ALL_DISKS < <(lsblk -dpno NAME | grep -v '^$' | grep -v loop || true)
[[ ${#ALL_DISKS[@]} -eq 0 ]] && die "No block devices found."

choose_disk SYSTEM_DISK "Select the system disk (for /boot, swap, /):" ""
[[ -b "$SYSTEM_DISK" ]] || die "Not a block device: $SYSTEM_DISK"
info "System disk: $SYSTEM_DISK"

# ---------------------------------------------------------------------------
# 10. Separate home disk?
# ---------------------------------------------------------------------------
SEPARATE_HOME="${SEPARATE_HOME:-false}"
HOME_DISK="${HOME_DISK:-}"
HOME_DISK_ID="${HOME_DISK_ID:-}"
if [[ "$UNATTENDED" != true ]] && [[ ${#ALL_DISKS[@]} -gt 1 ]]; then
	choose USE_SEPARATE_HOME "Use a separate disk for /home?" "yes" "no"
	if [[ "$USE_SEPARATE_HOME" == "yes" ]]; then
		SEPARATE_HOME=true
		choose_disk HOME_DISK "Select the home disk (for /home):" "$SYSTEM_DISK"
		[[ "$HOME_DISK" != "$SYSTEM_DISK" ]] || die "Home disk must differ from system disk."
		[[ -b "$HOME_DISK" ]] || die "Not a block device: $HOME_DISK"
		info "Home disk: $HOME_DISK"
	fi
fi
# Validate HOME_DISK regardless of mode (interactive mode validates above,
# but unattended mode skips the interactive block entirely).
if [[ "$SEPARATE_HOME" == true ]]; then
	[[ -n "$HOME_DISK" ]] || die "SEPARATE_HOME=true but HOME_DISK is not set."
	[[ "$HOME_DISK" != "$SYSTEM_DISK" ]] || die "Home disk must differ from system disk."
	[[ -b "$HOME_DISK" ]] || die "Not a block device: $HOME_DISK"
fi
info "Separate home disk: $SEPARATE_HOME"

# ---------------------------------------------------------------------------
# 11. Root partition size (single-disk only)
# ---------------------------------------------------------------------------
ROOT_SIZE="${ROOT_SIZE:-}"
if [[ "$SEPARATE_HOME" == false ]]; then
	if [[ "$PROFILE" == "laptop" ]]; then
		info "Boot=1G and swap=${SWAP_SIZE} are reserved automatically."
	else
		info "Boot=1G is reserved automatically."
	fi
	if [[ "$UNATTENDED" == true ]]; then
		[[ -n "$ROOT_SIZE" ]] || die "--unattended: ROOT_SIZE not set in environment."
		[[ "$ROOT_SIZE" =~ ^[0-9]+[GgMmKk]$ ]] || die "--unattended: ROOT_SIZE='$ROOT_SIZE' is not a valid size (e.g. 60G)."
	else
		while true; do
			prompt ROOT_SIZE "Root (/) partition size (e.g. 60G — /home gets the remainder)"
			if [[ "$ROOT_SIZE" =~ ^[0-9]+[GgMmKk]$ ]]; then
				break
			fi
			warn "Invalid size format. Use a number followed by G, M, or K (e.g. 60G)."
			ROOT_SIZE=""
		done
	fi
fi

# ---------------------------------------------------------------------------
# 12. LUKS passphrase
# ---------------------------------------------------------------------------
LUKS_PASSPHRASE="${LUKS_PASSPHRASE:-}"
if [[ "$UNATTENDED" == true ]]; then
	[[ -n "$LUKS_PASSPHRASE" ]] || die "--unattended: LUKS_PASSPHRASE not set in environment."
else
	prompt_secret LUKS_PASSPHRASE "LUKS passphrase (used for all encrypted partitions)"
	LUKS_CONFIRM=""
	prompt_secret LUKS_CONFIRM "Confirm passphrase"
	[[ "$LUKS_PASSPHRASE" == "$LUKS_CONFIRM" ]] || die "Passphrases do not match."
	unset LUKS_CONFIRM
fi

# Write passphrase to a temp keyfile so disko can open partitions non-interactively.
# The passwordFile lines are stripped from disko.nix after disko completes (step 19),
# so the installed system never references this ephemeral path.
KEYFILE="/tmp/luks-install.key"
printf '%s' "$LUKS_PASSPHRASE" >"$KEYFILE"
chmod 600 "$KEYFILE"

# ---------------------------------------------------------------------------
# 13. Resolve stable /dev/disk/by-id paths
# ---------------------------------------------------------------------------
resolve_disk_id() {
	local dev="$1" result=""
	while IFS= read -r link; do
		if [[ "$(readlink -f "$link")" == "$dev" ]]; then
			result="$link"
			break
		fi
	done < <(find /dev/disk/by-id -maxdepth 1 -type l 2>/dev/null | sort)
	if [[ -z "$result" ]]; then
		warn "No by-id symlink found for $dev — using raw device path."
		result="$dev"
	fi
	echo "$result"
}

info "Resolving disk IDs..."
SYSTEM_DISK_ID=$(resolve_disk_id "$SYSTEM_DISK")
info "  System disk: $SYSTEM_DISK_ID"
if [[ "$SEPARATE_HOME" == true ]]; then
	HOME_DISK_ID=$(resolve_disk_id "$HOME_DISK")
	info "  Home disk:   $HOME_DISK_ID"
fi

# ---------------------------------------------------------------------------
# Sanity check: host directory
# ---------------------------------------------------------------------------
HOST_DIR="$FLAKE_DIR/hosts/$TARGET_HOST"
if [[ -d "$HOST_DIR" ]]; then
	if [[ "$UNATTENDED" == true ]]; then
		warn "Host directory $HOST_DIR exists — overwriting in unattended mode."
	else
		warn "Host directory $HOST_DIR already exists."
		printf 'Overwrite? [y/N]: '
		read -r yn
		[[ "$yn" =~ ^[Yy]$ ]] || die "Aborted."
	fi
fi
mkdir -p "$HOST_DIR"

# ---------------------------------------------------------------------------
# 14. Generate hosts/<hostname>/disko.nix
# ---------------------------------------------------------------------------
info "Writing hosts/$TARGET_HOST/disko.nix..."

if [[ "$SEPARATE_HOME" == false ]]; then
	# ── Single disk layout ───────────────────────────────────────────────────
	# Partitions (in order):
	#   1. ESP   1G    vfat    /boot
	#   2. swap  RAM   LUKS    swap    ← laptop only
	#   3. root  SIZE  LUKS    ext4    /
	#   4. home  100%  LUKS    ext4    /home

	if [[ "$PROFILE" == "laptop" ]]; then
		cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Single-disk layout — ESP + encrypted swap + encrypted root + encrypted home.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "${SYSTEM_DISK_ID}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        swap = {
          size = "${SWAP_SIZE}";
          content = {
            type = "luks";
            name = "cryptswap";
            passwordFile = "/tmp/luks-install.key";
            settings.allowDiscards = true;
            content = {type = "swap";};
          };
        };
        root = {
          size = "${ROOT_SIZE}";
          content = {
            type = "luks";
            name = "cryptroot";
            passwordFile = "/tmp/luks-install.key";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["noatime"];
            };
          };
        };
        home = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypthome";
            passwordFile = "/tmp/luks-install.key";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
              mountOptions = ["noatime"];
            };
          };
        };
      };
    };
  };
}
NIXEOF
	else
		# workstation / server — no swap
		cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Single-disk layout — ESP + encrypted root + encrypted home.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "${SYSTEM_DISK_ID}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "${ROOT_SIZE}";
          content = {
            type = "luks";
            name = "cryptroot";
            passwordFile = "/tmp/luks-install.key";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["noatime"];
            };
          };
        };
        home = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypthome";
            passwordFile = "/tmp/luks-install.key";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
              mountOptions = ["noatime"];
            };
          };
        };
      };
    };
  };
}
NIXEOF
	fi

else
	# ── Two-disk layout ──────────────────────────────────────────────────────
	# System disk: ESP [+ swap (laptop only)] + root
	# Home disk:   home

	if [[ "$PROFILE" == "laptop" ]]; then
		cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Two-disk layout — system: ESP + encrypted swap + encrypted root;
#                   home disk: encrypted /home.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk = {
    system = {
      type = "disk";
      device = "${SYSTEM_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          swap = {
            size = "${SWAP_SIZE}";
            content = {
              type = "luks";
              name = "cryptswap";
              passwordFile = "/tmp/luks-install.key";
              settings.allowDiscards = true;
              content = {type = "swap";};
            };
          };
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              passwordFile = "/tmp/luks-install.key";
              settings.allowDiscards = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = ["noatime"];
              };
            };
          };
        };
      };
    };
    home = {
      type = "disk";
      device = "${HOME_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          home = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypthome";
              passwordFile = "/tmp/luks-install.key";
              settings.allowDiscards = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/home";
                mountOptions = ["noatime"];
              };
            };
          };
        };
      };
    };
  };
}
NIXEOF
	else
		# workstation / server — no swap
		cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Two-disk layout — system: ESP + encrypted root;
#                   home disk: encrypted /home.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk = {
    system = {
      type = "disk";
      device = "${SYSTEM_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              passwordFile = "/tmp/luks-install.key";
              settings.allowDiscards = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = ["noatime"];
              };
            };
          };
        };
      };
    };
    home = {
      type = "disk";
      device = "${HOME_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          home = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypthome";
              passwordFile = "/tmp/luks-install.key";
              settings.allowDiscards = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/home";
                mountOptions = ["noatime"];
              };
            };
          };
        };
      };
    };
  };
}
NIXEOF
	fi
fi
ok "hosts/$TARGET_HOST/disko.nix written."

# ---------------------------------------------------------------------------
# 15. Inject host into flake.nix
# ---------------------------------------------------------------------------
info "Injecting $TARGET_HOST into flake.nix..."
MARKER="# <<NIXOS_HOSTS>>"
ENTRY="      ${TARGET_HOST} = mkNixosHost \"${TARGET_HOST}\";"
if grep -q "\"${TARGET_HOST}\"" "$FLAKE_DIR/flake.nix"; then
	warn "$TARGET_HOST already in flake.nix — skipping injection."
else
	awk -v entry="${ENTRY}" -v marker="${MARKER}" '
		index($0, marker) > 0 { print entry }
		{ print }
	' "$FLAKE_DIR/flake.nix" >"$FLAKE_DIR/flake.nix.tmp" &&
		mv "$FLAKE_DIR/flake.nix.tmp" "$FLAKE_DIR/flake.nix"
	ok "flake.nix updated."
fi

# ---------------------------------------------------------------------------
# 16. Set system hostname
# ---------------------------------------------------------------------------
info "Setting hostname to '$TARGET_HOST'..."
hostnamectl set-hostname "$TARGET_HOST" 2>/dev/null ||
	warn "Could not set hostname — set manually with hostnamectl after reboot."

# ---------------------------------------------------------------------------
# 17. Data-destruction warning — require explicit "yes" before wiping
# ---------------------------------------------------------------------------
if [[ "$UNATTENDED" != true ]]; then
	echo ""
	printf '\033[1;31m!!! DATA DESTRUCTION WARNING !!!\033[0m\n'
	echo ""
	echo "The following disk(s) will be COMPLETELY and PERMANENTLY ERASED:"
	echo ""
	SYSTEM_DISK_INFO=$(lsblk -dpno SIZE,MODEL "$SYSTEM_DISK" 2>/dev/null | tr -s ' ' | sed 's/^ //' || echo "unknown")
	echo "  System disk: $SYSTEM_DISK  [$SYSTEM_DISK_INFO]"
	if [[ "$SEPARATE_HOME" == true ]]; then
		HOME_DISK_INFO=$(lsblk -dpno SIZE,MODEL "$HOME_DISK" 2>/dev/null | tr -s ' ' | sed 's/^ //' || echo "unknown")
		echo "  Home disk:   $HOME_DISK  [$HOME_DISK_INFO]"
	fi
	echo ""
	echo "All existing data will be PERMANENTLY LOST."
	echo ""
	printf 'Type "yes" to confirm and continue: '
	read -r confirm
	[[ "$confirm" == "yes" ]] || die "Aborted."
else
	warn "Unattended mode — skipping data destruction confirmation."
fi

# ---------------------------------------------------------------------------
# 18. Run disko
# ---------------------------------------------------------------------------
if [[ "$SKIP_DISKO" != true ]]; then
	info "Partitioning disk(s) with disko..."
	sudo disko --mode disko "$HOST_DIR/disko.nix" || {
		rm -f "$KEYFILE"
		die "disko failed."
	}
	ok "Disk(s) partitioned and mounted at /mnt."
else
	info "Skipping disko partitioning (--skip-disko)."
	# Strip passwordFile lines eagerly — disko won't consume the keyfile.
	sed -i '/passwordFile/d' "$HOST_DIR/disko.nix"
	rm -f "$KEYFILE"
fi

# ---------------------------------------------------------------------------
# 19. Strip passwordFile lines from disko.nix + remove keyfile
# ---------------------------------------------------------------------------
if [[ "$SKIP_DISKO" != true ]]; then
	sed -i '/passwordFile/d' "$HOST_DIR/disko.nix"
	rm -f "$KEYFILE"
	ok "Ephemeral keyfile removed; passwordFile entries stripped from disko.nix."
fi

# ---------------------------------------------------------------------------
# 20. Set swap device path (laptop only)
# ---------------------------------------------------------------------------
# The disko NixOS module (included via default.nix) creates the 'cryptswap'
# LUKS device and its initrd entry.  We set swapLuksUuid="" in default.nix so
# boot.nix does not add a duplicate LUKS entry.  swapDevice is the mapped
# device name that power.nix uses as the hibernate resume target.
SWAP_DEVICE=""
if [[ "$PROFILE" == "laptop" ]]; then
	SWAP_DEVICE="/dev/mapper/cryptswap"
	info "Swap device for hibernate: $SWAP_DEVICE"
fi

# ---------------------------------------------------------------------------
# 21. Generate hardware configuration from mounted /mnt
# ---------------------------------------------------------------------------
if [[ "$SKIP_DISKO" != true ]]; then
	info "Generating hardware configuration..."
	sudo nixos-generate-config --root /mnt --show-hardware-config \
		>"$HOST_DIR/hardware.nix" ||
		die "nixos-generate-config failed."
	ok "hardware.nix written."
else
	info "Skipping hardware.nix generation (--skip-disko). Writing stub."
	cat >"$HOST_DIR/hardware.nix" <<'NIXEOF'
# Stub hardware.nix — generated by install.sh --skip-disko.
# Replace with real output from nixos-generate-config.
{...}: {
  imports = [];
}
NIXEOF
fi

# ---------------------------------------------------------------------------
# 22. Strip disko-managed sections from hardware.nix
# ---------------------------------------------------------------------------
if [[ "$SKIP_DISKO" != true ]]; then
	# nixos-generate-config emits fileSystems.*, swapDevices, and
	# boot.initrd.luks.devices.* using UUID-based paths and auto-generated LUKS
	# names (e.g. "luks-<UUID>").  The disko NixOS module, included via default.nix,
	# is the authoritative source for these options and uses different device paths
	# and LUKS names ("cryptroot", "cryptswap", "crypthome").  Both sets present in
	# the same NixOS evaluation causes a module system conflict on fileSystems.*
	# and redundant LUKS entries.  Strip all three sections here; let disko own
	# them exclusively.
	info "Stripping disko-managed entries from hardware.nix..."
	awk '
	  /^  fileSystems\./              { skip=1; next }
	  /^  swapDevices/                { skip=1; next }
	  /^  boot\.initrd\.luks\.devices\./ { skip=1; next }
	  skip && /^  [}\]]/             { skip=0; next }
	  skip                           { next }
	  { print }
	' "$HOST_DIR/hardware.nix" >"$HOST_DIR/hardware.nix.tmp" &&
		mv "$HOST_DIR/hardware.nix.tmp" "$HOST_DIR/hardware.nix"
	ok "hardware.nix cleaned."
fi

# ---------------------------------------------------------------------------
# 23. Generate hosts/<hostname>/default.nix
# (moved after disko so SWAP_DEVICE is known; no sed patching needed)
# ---------------------------------------------------------------------------
info "Writing hosts/$TARGET_HOST/default.nix..."

if [[ "$PROFILE" == "laptop" ]]; then

	cat >"$HOST_DIR/default.nix" <<NIXEOF
# Laptop host — uses the laptop profile.
# Generated by install.sh.
{inputs}: let
  dotfilesDir = ../../home/ovg;
in {
  system = "${LINUX_SYSTEM}";

  specialArgs = {
    inherit inputs dotfilesDir;
    # Empty: the disko NixOS module (included below) provides the cryptswap
    # LUKS initrd entry.  Set to a UUID only on non-disko systems that manage
    # LUKS without the disko module.
    swapLuksUuid = "";
    # Resume device for hibernate (power.nix).
    # Matches the LUKS name declared in disko.nix.
    swapDevice = "${SWAP_DEVICE}";
    kanataConfig = dotfilesDir + "/kanata.kbd";
    kanataDevice = "${KANATA_DEVICE}";
    videoAcceleration = "${VIDEO_ACCEL}";
    # Primary user for greetd autologin (display.nix).
    primaryUser = "ovg";
  };

  modules = [
    ../../profiles/laptop.nix
    ./hardware.nix
    inputs.disko.nixosModules.disko
    ./disko.nix
    ({pkgs, ...}: {
      networking.hostName = "${TARGET_HOST}";

      programs.fish.enable = true;

      users.users.ovg = {
        isNormalUser = true;
        shell = pkgs.fish;
        description = "ovg";
        extraGroups = ["networkmanager" "wheel" "input" "uinput" "video"];
      };

      system.stateVersion = "${STATE_VERSION}";

      home-manager.users.ovg = {
        home.username = "ovg";
        home.homeDirectory = "/home/ovg";
        home.stateVersion = "${STATE_VERSION}";
      };
    })
  ];
}
NIXEOF

elif [[ "$PROFILE" == "workstation" ]]; then

	cat >"$HOST_DIR/default.nix" <<NIXEOF
# Workstation host — uses the workstation profile.
# Generated by install.sh.
{inputs}: let
  dotfilesDir = ../../home/ovg;
in {
  system = "${LINUX_SYSTEM}";

  specialArgs = {
    inherit inputs dotfilesDir;
    kanataConfig = dotfilesDir + "/kanata.kbd";
    kanataDevice = "${KANATA_DEVICE}";
    videoAcceleration = "${VIDEO_ACCEL}";
    # Primary user for greetd autologin (display.nix).
    primaryUser = "ovg";
  };

  modules = [
    ../../profiles/workstation.nix
    ./hardware.nix
    inputs.disko.nixosModules.disko
    ./disko.nix
    ({pkgs, ...}: {
      networking.hostName = "${TARGET_HOST}";

      programs.fish.enable = true;

      users.users.ovg = {
        isNormalUser = true;
        shell = pkgs.fish;
        description = "ovg";
        extraGroups = ["networkmanager" "wheel" "input" "uinput" "video"];
      };

      system.stateVersion = "${STATE_VERSION}";

      home-manager.users.ovg = {
        home.username = "ovg";
        home.homeDirectory = "/home/ovg";
        home.stateVersion = "${STATE_VERSION}";
      };
    })
  ];
}
NIXEOF

elif [[ "$PROFILE" == "server" ]]; then

	cat >"$HOST_DIR/default.nix" <<NIXEOF
# Headless server host — uses the server profile.
# Generated by install.sh.
{inputs}: let
  dotfilesDir = ../../home/ovg;
in {
  system = "${LINUX_SYSTEM}";

  specialArgs = {
    inherit inputs dotfilesDir;
  };

  modules = [
    ../../profiles/server.nix
    ./hardware.nix
    inputs.disko.nixosModules.disko
    ./disko.nix
    ({pkgs, ...}: {
      networking.hostName = "${TARGET_HOST}";

      programs.fish.enable = true;

      users.users.ovg = {
        isNormalUser = true;
        shell = pkgs.fish;
        description = "ovg";
        extraGroups = ["networkmanager" "wheel"];
        # Hashed initial password — change immediately after first boot
        # with: passwd ovg
        initialHashedPassword = "${HASHED_PASSWORD}";
      };

      system.stateVersion = "${STATE_VERSION}";

      home-manager.users.ovg = {
        home.username = "ovg";
        home.homeDirectory = "/home/ovg";
        home.stateVersion = "${STATE_VERSION}";
      };
    })
  ];
}
NIXEOF

fi
ok "hosts/$TARGET_HOST/default.nix written."

# ---------------------------------------------------------------------------
# 24. Format hosts/<hostname>/ with alejandra (single pass covers all files)
# ---------------------------------------------------------------------------
info "Formatting hosts/$TARGET_HOST/ with alejandra..."
alejandra "$HOST_DIR/" 2>/dev/null || warn "alejandra failed — run 'nix fmt' later."

# ---------------------------------------------------------------------------
# 24b. Validate flake configuration before proceeding
# ---------------------------------------------------------------------------
# Catch Nix evaluation errors (bad imports, missing specialArgs, syntax) now,
# before TPM enrollment or nixos-install.  Eval-only — no packages are built.
# Skipped with --skip-install (nix eval needs the full nix store / network).
if [[ "$SKIP_INSTALL" != true ]]; then
	info "Validating flake configuration for $TARGET_HOST..."
	nix eval ".#nixosConfigurations.${TARGET_HOST}.config.system.build.toplevel" \
		--no-build --accept-flake-config 2>&1 ||
		die "Flake evaluation failed for $TARGET_HOST. Check the generated files in hosts/$TARGET_HOST/."
	ok "Flake configuration is valid."
else
	info "Skipping flake eval (--skip-install)."
fi

# ---------------------------------------------------------------------------
# 25. Optional TPM2 enrollment for password-free LUKS unlock at boot
# ---------------------------------------------------------------------------
# No PCR binding (--tpm2-pcrs="") — unlock always succeeds regardless of
# firmware updates.  Threat model: disk removed to another machine = locked.
if [[ "$UNATTENDED" == true ]]; then
	info "Unattended mode — skipping TPM2 enrollment."
elif systemd-cryptenroll --tpm2-device=list 2>/dev/null | grep -q .; then
	choose ENROLL_TPM "Enroll TPM2 for password-free disk unlock at boot?" "yes" "no"
	if [[ "$ENROLL_TPM" == "yes" ]]; then
		info "Enrolling LUKS partitions with TPM2..."
		TPM_KEYFILE="$(mktemp)"
		printf '%s' "$LUKS_PASSPHRASE" >"$TPM_KEYFILE"

		if [[ "$PROFILE" == "laptop" ]]; then
			# Partition order: ESP(1) swap(2) root(3) [home(4) single-disk]
			enroll_tpm2 "$(part "$SYSTEM_DISK" 2)" "$TPM_KEYFILE"
			enroll_tpm2 "$(part "$SYSTEM_DISK" 3)" "$TPM_KEYFILE"
			if [[ "$SEPARATE_HOME" == false ]]; then
				enroll_tpm2 "$(part "$SYSTEM_DISK" 4)" "$TPM_KEYFILE"
			fi
		else
			# workstation / server: ESP(1) root(2) [home(3) single-disk]
			enroll_tpm2 "$(part "$SYSTEM_DISK" 2)" "$TPM_KEYFILE"
			if [[ "$SEPARATE_HOME" == false ]]; then
				enroll_tpm2 "$(part "$SYSTEM_DISK" 3)" "$TPM_KEYFILE"
			fi
		fi
		rm -f "$TPM_KEYFILE"

		# Home disk (two-disk layout only — encrypted with the same passphrase)
		if [[ "$SEPARATE_HOME" == true ]]; then
			TPM_HOME_KEYFILE="$(mktemp)"
			printf '%s' "$LUKS_PASSPHRASE" >"$TPM_HOME_KEYFILE"
			enroll_tpm2 "$(part "$HOME_DISK" 1)" "$TPM_HOME_KEYFILE"
			rm -f "$TPM_HOME_KEYFILE"
		fi

		ok "TPM2 enrollment complete."
	fi
else
	info "No TPM2 device found — skipping TPM2 enrollment."
	echo "  Enroll manually after first boot with:"
	echo "  sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=\"\" /dev/disk/by-uuid/<luks-uuid>"
fi

# ---------------------------------------------------------------------------
# 26. Clear secrets from environment
# ---------------------------------------------------------------------------
unset LUKS_PASSPHRASE INITIAL_PASSWORD HASHED_PASSWORD

# ---------------------------------------------------------------------------
# 27. nixos-install
# ---------------------------------------------------------------------------
if [[ "$SKIP_INSTALL" != true ]]; then
	info "Checking network connectivity..."
	curl -sf --max-time 10 https://cache.nixos.org/nix-cache-info >/dev/null 2>&1 ||
		warn "Cannot reach cache.nixos.org — nixos-install may fail or be very slow."

	info "Running nixos-install for .#$TARGET_HOST ..."
	sudo nixos-install \
		--flake "${FLAKE_DIR}#${TARGET_HOST}" \
		--root /mnt \
		--no-root-passwd \
		--no-channel-copy \
		--accept-flake-config ||
		die "nixos-install failed."
	ok "NixOS installed."
else
	info "Skipping nixos-install (--skip-install)."
fi

# ---------------------------------------------------------------------------
# 28. Copy dotfiles into the new system
# ---------------------------------------------------------------------------
if [[ "$SKIP_INSTALL" != true ]]; then
	info "Copying dotfiles to /mnt/home/ovg/dotfiles/nix ..."
	sudo mkdir -p /mnt/home/ovg/dotfiles
	sudo cp -rT "$FLAKE_DIR" /mnt/home/ovg/dotfiles/nix
	# Remove result* symlinks left by nix builds — they are dangling on the new
	# system because those store paths do not exist in its Nix store.
	sudo find /mnt/home/ovg/dotfiles/nix -maxdepth 1 -name 'result*' -type l -delete
	# ovg uid=1000 gid=1000 (standard NixOS first user).
	sudo chown -R 1000:1000 /mnt/home/ovg/
	ok "Dotfiles copied."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
if [[ "$SKIP_INSTALL" != true ]]; then
	ok "Installation complete. Remove the USB drive and reboot."
	echo "  reboot"
elif [[ "$SKIP_DISKO" == true ]]; then
	ok "File generation complete (--skip-disko)."
	echo "  Generated files: hosts/$TARGET_HOST/{disko.nix,hardware.nix,default.nix}"
else
	ok "File generation and disk partitioning complete (--skip-install)."
	echo "  Generated files: hosts/$TARGET_HOST/{disko.nix,hardware.nix,default.nix}"
fi
