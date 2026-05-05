#!/bin/bash

# Remove entries from fstab that start with //cfanetapp or //saazurefilesync1

set -euo pipefail

FSTAB="/etc/fstab"
BACKUP="/etc/fstab.backup.$(date +%Y-%m-%d_%H-%M-%S)"
MOUNT_POINTS=("/media/S_CFA" "/media/S_CFA_Predict" "/media/S_CDC" "/media/P" "/media/U")

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

# Create backup
log_info "Creating backup of fstab..."
sudo cp "$FSTAB" "$BACKUP"
log_info "Backup created at: $BACKUP"

USERNAME=$(id -un)

# Start from scratch

# Remove fstab entries matching network drive paths and the comment lines delimiting them
log_info "Removing fstab entries for //cfanetapp and //saazurefilesync1..."
sudo grep -v "^[[:space:]]*//cfanetapp\|^[[:space:]]*//saazurefilesync1\|^[[:space:]]*#[[:space:]]*[SPU]" "$FSTAB" | sudo tee "${FSTAB}.tmp" > /dev/null
sudo mv "${FSTAB}.tmp" "$FSTAB"
log_info "Network drive entries removed from fstab"

# Reload systemd
log_info "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Unmount and remove directories
log_info "Removing mount points..."
for mount in "${MOUNT_POINTS[@]}"; do
    if [ -d "$mount" ]; then
        sudo umount "$mount" && log_info "Unmounted: $mount" || log_error "Failed to unmount: $mount"
        sudo rmdir "$mount" 2>/dev/null && log_info "Removed: $mount" || log_error "Failed to remove: $mount"
    fi
done

log_info "Cleanup complete"
log_info "Current /etc/fstab Contents"
sudo cat /etc/fstab
