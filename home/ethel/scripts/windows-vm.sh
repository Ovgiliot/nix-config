#!/usr/bin/env bash
# Smart launcher for the Windows VM.
# Starts the VM if stopped, resumes if paused, connects via SPICE remote-viewer.

VM_NAME="win10"
URI="qemu:///system"

# Verify the VM exists.
if ! virsh -c "$URI" list --all --name | grep -qx "$VM_NAME"; then
	notify-send -u critical "Windows VM" "VM '$VM_NAME' not found. Create it first with virt-manager."
	exit 1
fi

STATE=$(virsh -c "$URI" domstate "$VM_NAME" 2>/dev/null)

case "$STATE" in
running)
	notify-send -t 2000 "Windows VM" "Already running — connecting."
	;;
paused)
	virsh -c "$URI" resume "$VM_NAME"
	notify-send -t 2000 "Windows VM" "Resumed from pause."
	;;
"shut off")
	virsh -c "$URI" start "$VM_NAME"
	notify-send -t 2000 "Windows VM" "Starting…"
	# Wait for the SPICE display to become available.
	for _ in $(seq 1 15); do
		if virsh -c "$URI" domdisplay "$VM_NAME" 2>/dev/null | grep -q "spice"; then
			break
		fi
		sleep 1
	done
	;;
*)
	notify-send -u critical "Windows VM" "Unexpected state: $STATE"
	exit 1
	;;
esac

# Get the SPICE URI and connect.
DISPLAY_URI=$(virsh -c "$URI" domdisplay "$VM_NAME" 2>/dev/null)
if [ -z "$DISPLAY_URI" ]; then
	notify-send -u critical "Windows VM" "No display found. Is SPICE configured in the VM?"
	exit 1
fi

exec remote-viewer "$DISPLAY_URI"
