# Run these from the top level of the repo only as we use '.' syntax

# Prototyping commands - use outside of container only:

test:
	docker build . -t vap-hm && docker run -it --rm vap-hm

# Install command - use outside of container only:

init:
	nix run home-manager -- init --switch --flake . --impure

install:
	bash setup.sh

# Use either in container or outside:

switch:
	home-manager switch --flake . --impure

