# Run these from the top level of the repo only as we use '.' syntax

# Use outside of container only:

build:
	docker build . -t vap-hm

run: build
	docker run -it --rm vap-hm

# Use either in container or outside:

switch:
	home-manager switch --flake . --impure