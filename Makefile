# Run these from the top level of the repo only as we use '.' syntax

# Prototyping commands - use outside of container only:

test:
	docker build . -t vap-hm && docker run -it --rm vap-hm

# Install command - use outside of container only:

init:
	nix run home-manager -- init --switch --flake . --impure

# Quick switch command - use either in container or outside:

switch:
	home-manager switch --flake . --impure

# Install script - requires running a few times and user input; used for internal automation testing only
install:
	bash setup.sh

# --- NON DECLARATIVE CONVENIENCE SCRIPTS ---
make drives:
	bash ./legacy/setup_fstab.sh
