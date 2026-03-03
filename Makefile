build:
	docker build . -t nix-vap

go: build
	docker run -it --rm -v "$(PWD):/home/vapuser/.config/home-manager" nix-vap bash