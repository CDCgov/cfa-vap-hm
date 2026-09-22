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

if ! command -v az >/dev/null 2>&1; then
  echo -e "${BOLD_RED}Azure CLI is not installed or not on PATH. Please install it before running this script.${NOCOLOR}" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo -e "${BOLD_RED}jq is not installed or not on PATH. Please install it before running this script.${NOCOLOR}" >&2
  echo -e "On Ubuntu, simply run: sudo apt install jq -y"
  exit 1
fi

# Login to azure
az login --identity

KEY_VAULT_NAME="CFA-Predict"
SECRET_NAME="cfa-vap-network-drives"

DRIVE_JSON="$(az keyvault secret show \
  --vault-name "$KEY_VAULT_NAME" \
  --name "$SECRET_NAME" \
  --query value -o tsv)"

# Optional safety check
if [[ -z "$DRIVE_JSON" || "$DRIVE_JSON" == "null" ]]; then
  echo "Failed to load drive map from Key Vault" >&2
  exit 1
fi

# Validate before changing the system, then unpack each drive into a TSV row.
# Whitespace and backslashes require escaping in fstab and are not supported here.
DRIVE_ROWS="$(jq -er '
  .drives
  | if type != "array" then error("drives must be an array") else . end
  | if length == 0 then error("drives must not be empty") else . end
  | .[]
  | if (.mount_point | type) != "string" or (.network_path | type) != "string"
    then error("Each drive requires mount_point and network_path strings")
    else . end
  | if (.mount_point | test("^/[^[:space:]\\\\]+$"))
       and (.network_path | test("^//[^[:space:]\\\\]+$"))
    then [.mount_point, .network_path] | @tsv
    else error("Drive paths must be absolute and contain no whitespace or backslashes")
    end
' <<< "$DRIVE_JSON")"

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
  bash "./utils/reset_vap_drives.sh"
  echo ""
fi

# Ensure /etc/fstab exists
sudo touch /etc/fstab

print_info "Setting up mount directories and fstab entries..."
echo ""

# Loop through each drive
while IFS=$'\t' read -r mount_point network_path; do
  # JSON strings do not expand shell variables; replace this placeholder only.
  network_path="${network_path//\$USERNAME/$USERNAME}"

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
done <<< "$DRIVE_ROWS"

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
  while IFS=$'\t' read -r mount_point _; do
    symlink_name=~/"${mount_point##*/}"
    if [ ! -L "$symlink_name" ]; then
      ln -s "$mount_point" "$symlink_name"
      print_success "Created symlink: $symlink_name -> $mount_point"
    else
      print_info "Symlink already exists: $symlink_name"
    fi
  done <<< "$DRIVE_ROWS"
  echo ""
fi

print_header "Setup Complete"
