FROM ubuntu:24.04

# This is a simple ubuntu dockerfile for you to test the README install commands.

# ------------------------
# Basic Environment Setup
# ------------------------

# Add basic utilities
RUN apt-get update -y && apt-get install curl xz-utils sudo -y

# Add and swap to our test user
RUN useradd -m -s /bin/bash vapuser
RUN usermod -aG sudo vapuser
RUN passwd -d vapuser
USER vapuser

# -------------------
# Nix Configuration!
# -------------------

# Create the nix config folder
RUN mkdir -p /home/vapuser/.config/nix

# Create the home-manager config folder
RUN mkdir -p /home/vapuser/.config/home-manager

# Install nix
RUN bash -c "sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon"
RUN echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
ENV PATH=/home/vapuser/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH
