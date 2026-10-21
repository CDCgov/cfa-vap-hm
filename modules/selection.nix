# Decides which optional home-manager modules get imported.
#
# - modules/manifest.json (tracked) declares the selectable extras: each
#   option maps to a module file under modules/.
# - modules/state.json (tracked) holds the default selection every fresh
#   clone starts with.
# - modules/user-state.json (user-local, gitignored) optionally overrides
#   the defaults per user; the TUI (cfa-vap-tui, alias `hmt`)
#   writes there. It takes precedence when present. Since the flake source
#   never contains gitignored files, it is read through $HOME - this flake
#   evaluates impurely anyway (see flake.nix).
# - Missing or invalid selections fall back to the group's default, so the
#   config always evaluates.
{
  lib,
  pkgs,
  homedir ? "",
  ...
}:
let
  inherit (builtins)
    all
    elem
    fromJSON
    getAttr
    hasAttr
    isList
    isString
    pathExists
    readFile
    ;

  manifest = fromJSON (readFile ./manifest.json);

  defaultState = if pathExists ./state.json then fromJSON (readFile ./state.json) else { };

  userStateFile = "${homedir}/.config/home-manager/modules/user-state.json";

  useUserState = homedir != "" && pathExists userStateFile;

  stateSource = if useUserState then "modules/user-state.json" else "modules/state.json";

  state = if useUserState then fromJSON (readFile userStateFile) else defaultState;

  # Validate one group's selection against the manifest; warn and fall back to
  # the default when the state file holds something that can't be selected.
  selectionOf =
    group:
    let
      ids = map (option: option.id) group.options;
      previous = if hasAttr group.id state then getAttr group.id state else group.default;
      # Migrate saved selections from when oh-my-zsh was optional.
      raw =
        if group.id == "options" && isList previous then
          builtins.filter (id: id != "omz") previous
        else
          previous;
      valid = isList raw && all (id: isString id && elem id ids) raw;
    in
    lib.warnIfNot valid "${stateSource}: invalid selection for group '${group.id}', using its default" (
      if valid then raw else group.default
    );

  pathOf =
    group: id:
    (lib.findFirst (
      option: option.id == id
    ) (throw "modules/manifest.json: group '${group.id}' has no option '${id}'") group.options).path;

  # The manifest-relative paths of every module the user has selected.
  selectedPaths = lib.concatMap (group: map (pathOf group) (selectionOf group)) manifest.groups;

  modulesWithStatus = lib.concatMap (
    group: map (option: option // { enabled = elem option.id (selectionOf group); }) group.options
  ) manifest.groups;
  enabledModules = builtins.filter (option: option.enabled) modulesWithStatus;
  disabledModules = builtins.filter (option: !option.enabled) modulesWithStatus;
  moduleLines = options: lib.concatMapStringsSep "\n" (option: "    • ${option.title}") options;
  enabledSummary = ''
      On (${toString (builtins.length enabledModules)})
    ${if enabledModules == [ ] then "    (none)" else moduleLines enabledModules}
  '';
  disabledSummary = ''
      Off (${toString (builtins.length disabledModules)})
    ${if disabledModules == [ ] then "    (none)" else moduleLines disabledModules}
  '';
in
{
  # Paths are relative to this file (modules/); the module system merges the
  # imported modules with home.nix, so selection is purely additive.
  imports = map (relative: ./. + "/${relative}") selectedPaths;

  home.activation.moduleSummary = lib.hm.dag.entryAfter [ "switchMessage" ] ''
    printf '\n── Module selection ──────────────────────\n\n'
    printf '%s' ${lib.escapeShellArg enabledSummary} | ${pkgs.lolcat}/bin/lolcat --force --seed 1
    printf '\n\033[90m%s\033[0m\n' ${lib.escapeShellArg disabledSummary}
    printf '  Core environment: always on\n─────────────────────────────────────────\n'
  '';
}
