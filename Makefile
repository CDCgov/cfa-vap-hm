# Run these from the top level of the repo only as we use '.' syntax

# Prototyping commands - use outside of container only:

build:
	docker build . -t vap-hm

run: build
	docker run -it --rm vap-hm

# Install command - use outside of container only:

init:
	nix run home-manager -- init --switch --flake . --impure

# Use either in container or outside:

switch:
	home-manager switch --flake . --impure

