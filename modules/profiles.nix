# Decides which optional home-manager modules get imported.
#
# - modules/manifest.json declares the selectable groups: a group is either
#   mutually exclusive (exactly one option) or a free combination of options.
# - modules/state.json holds the current selection. It is written by the TUI
#   (utils/module_tui.py, alias `hmt`) but can be hand-edited too.
# - Missing or invalid selections fall back to the group's default, so a fresh
#   clone without state.json still evaluates to the documented defaults.
{ lib, ... }:
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

  state = if pathExists ./state.json then fromJSON (readFile ./state.json) else { };

  # Validate one group's selection against the manifest; warn and fall back to
  # the default when state.json holds something that can't be selected.
  selectionOf =
    group:
    let
      ids = map (option: option.id) group.options;
      raw = if hasAttr group.id state then getAttr group.id state else group.default;
      valid =
        if group.exclusive then
          isString raw && elem raw ids
        else
          isList raw && all (id: isString id && elem id ids) raw;
    in
    lib.warnIfNot valid
      "modules/state.json: invalid selection for group '${group.id}', using its default"
      (if valid then raw else group.default);

  pathOf =
    group: id:
    (lib.findFirst (
      option: option.id == id
    ) (throw "modules/manifest.json: group '${group.id}' has no option '${id}'") group.options).path;

  # The manifest-relative paths of every module the user has selected.
  selectedPaths = lib.concatMap (
    group:
    let
      selection = selectionOf group;
    in
    if group.exclusive then [ (pathOf group selection) ] else map (pathOf group) selection
  ) manifest.groups;
in
{
  # Paths are relative to this file (modules/); the module system merges the
  # imported modules with home.nix, so selection is purely additive.
  imports = map (relative: ./. + "/${relative}") selectedPaths;
}
