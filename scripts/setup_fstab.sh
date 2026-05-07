#!/bin/bash
# This script mounts CFA VAP's shared drives into a native Ubuntu box

set -euo pipefail

# ============================================================================
# COLORS AND FORMATTING
# ============================================================================
BOLD_RED="\e[31;1m"
BOLD_GREEN="\e[32;1m"
BOLD_BLUE="\e[34;1m"
NOCOLOR='\033[0m'
DIVIDER_LINE=$(printf '%.0s━' {1..80})

# ============================================================================
# VARIABLES
# ============================================================================
USERNAME=$(id -un)
USER_ID=$(id -u)
GROUP_ID=$(id -g)

MOUNT_POINTS=(
  "/media/S_CFA"
  "/media/S_CFA_Predict"
  "/media/S_CDC"
  "/media/P"
  "/media/U"
)

NETWORK_DRIVE_PATHS=(
  "<network_drive_see_cdcent>"
  "<network_drive_see_cdcent>"
  "<network_drive_see_cdcent>"
  "<network_drive_see_cdcent>"
  "<network_drive_see_cdcent>"
)

# ============================================================================
# FUNCTIONS
# ============================================================================
print_header() {
  echo -e "${BOLD_BLUE}${DIVIDER_LINE}${NOCOLOR}"
  echo -e "${BOLD_BLUE}$1${NOCOLOR}"
  echo -e "${BOLD_BLUE}${DIVIDER_LINE}${NOCOLOR}"
}

print_success() {
  echo -e "${BOLD_GREEN}✓${NOCOLOR} $1"
}

print_info() {
  echo -e "${BOLD_BLUE}ℹ${NOCOLOR} $1"
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

print_header "CFA Drive Mount Utility"
echo "Welcome, $USERNAME"
echo ""

# Get password
# read -s -p "Please enter your password: " PASSWORD_ENTERED
# echo ""
# echo ""

print_header "Current /etc/fstab Contents"
sudo cat /etc/fstab
echo ""
echo ""

# Prompt user about resetting fstab
echo -e "${BOLD_RED}Would you like to start fresh with a new fstab and fresh symlinks?"
read -p "$(echo -e "${BOLD_RED}(This will retain disk drives but refresh P, S, and U drives and their symlinks) (y/n): ${NOCOLOR}")" -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  print_info "Running reset script..."
  bash "./scripts/reset_fstab.sh"
  echo ""
fi

# Ensure /etc/fstab exists
sudo touch /etc/fstab

print_info "Setting up mount directories and fstab entries..."
echo ""

# Loop through each drive
for i in {0..4}; do
  mount_point="${MOUNT_POINTS[$i]}"
  network_path="${NETWORK_DRIVE_PATHS[$i]}"

  # Create mount directory if needed
  if [ ! -d "$mount_point" ]; then
    sudo mkdir -p "$mount_point"
    print_success "Created directory: $mount_point"
  else
    print_info "Directory already exists: $mount_point"
  fi

  # Determine mount mode
  if uname -a | grep -q "WSL"; then
    mount_mode='drvfs'
  else
    mount_mode='cifs'
  fi

  # Build fstab entry
  settings="$mount_mode ,vers=3.0,sec=krb5,username=$USERNAME,cruid=$USER_ID,uid=$USER_ID,gid=$GROUP_ID"
  fstab_entry="$network_path $mount_point $settings 0 0"


  # Add to fstab if not present
  if ! grep -q "$(printf '%s\n' "$network_path" | sed 's/[[\.*^$/]/\\&/g')" /etc/fstab; then
    print_success "Adding fstab entry for: $network_path"
    echo "# ${mount_point##*/}" | sudo tee -a /etc/fstab > /dev/null
    echo "$fstab_entry" | sudo tee -a /etc/fstab > /dev/null
  else
    print_info "Fstab entry already exists for: $network_path"
  fi
  echo ""
done

echo ""
# Reload daemon
print_info "Reloading systemd daemon..."
sudo systemctl daemon-reload
print_success "Daemon reloaded"
echo ""

print_info "Running sudo mount -a"
sudo mount -a
print_success "Drives mounted"
echo ""

print_header "Current /etc/fstab Contents"
sudo cat /etc/fstab
echo ""
print_header "Current /media/ folder"
ls -la /media/

echo ""
echo -e "${BOLD_RED}Would you like to symlink the /media/ folders to your home directory?"
read -p "$(echo -e "${BOLD_RED}(y/n): ${NOCOLOR}")" -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  print_info "Creating symlinks..."
  for mount_point in "${MOUNT_POINTS[@]}"; do
    symlink_name=~/"${mount_point##*/}"
    if [ ! -L "$symlink_name" ]; then
      ln -s "$mount_point" "$symlink_name"
      print_success "Created symlink: $symlink_name -> $mount_point"
    else
      print_info "Symlink already exists: $symlink_name"
    fi
  done
  echo ""
fi

print_header "Setup Complete"
