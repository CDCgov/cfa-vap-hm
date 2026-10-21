{ pkgs }:
pkgs.rustPlatform.buildRustPackage {
  pname = "cfa-vap-tui";
  version = "0.1.0";
  src = pkgs.lib.cleanSourceWith {
    src = ./.;
    filter =
      path: type:
      let
        name = baseNameOf path;
      in
      type == "directory"
      && builtins.elem name [
        "src"
        "modules"
        "tests"
      ]
      || builtins.elem name [
        "Cargo.toml"
        "Cargo.lock"
        "manifest.json"
        "state.json"
      ]
      || pkgs.lib.hasSuffix ".rs" name;
  };
  cargoLock.lockFile = ./Cargo.lock;
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postInstall = ''
    wrapProgram $out/bin/cfa-vap-tui \
      --prefix PATH : ${
        pkgs.lib.makeBinPath [
          pkgs.figlet
          pkgs.lolcat
        ]
      }
  '';
  meta.mainProgram = "cfa-vap-tui";
}
