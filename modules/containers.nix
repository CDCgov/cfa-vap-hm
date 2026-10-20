# Container tooling (docker + podman); a member of the "extras" group
# declared in modules/manifest.json (toggle with `hmt` / tui.py).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    docker-compose
    docker-client
    lazydocker
    podman
  ];

  programs.zsh.shellAliases = {
    dll = "docker ps -aql | xargs -r docker logs"; # docker logs latest
    runlike = "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike";
    runlike_latest = "docker ps -l -q | xargs -r -I{} docker run --rm -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike {}";
  };
}
