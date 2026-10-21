#!/usr/bin/env bash
# Docker's official Ubuntu apt repository installation:
# https://docs.docker.com/engine/install/ubuntu/
set -euo pipefail

. /etc/os-release
if [[ "$ID" != ubuntu ]]; then
  printf 'This installer requires Ubuntu.\n' >&2
  exit 1
fi
codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
if [[ -z "$codename" ]]; then
  printf 'Cannot determine the Ubuntu release codename.\n' >&2
  exit 1
fi
target_user="${SUDO_USER:-$(id -un)}"

# Remove installed packages which conflict with Docker's official packages.
conflicts=()
for package in docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc; do
  if [[ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)" == 'install ok installed' ]]; then
    conflicts+=("$package")
  fi
done
if ((${#conflicts[@]})); then
  sudo apt-get remove -y "${conflicts[@]}"
fi

sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $codename
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo docker run --rm hello-world

if ! getent group docker >/dev/null; then
  sudo groupadd docker
fi
sudo usermod -aG docker "$target_user"
printf '\nDocker Engine installed. %s was added to the docker group.\n' "$target_user"
printf 'Log out and back in to activate group membership, then run: docker run --rm hello-world\n'
printf 'Or run newgrp docker yourself to start a new shell with the group active.\n'
