# The "lite" profile - just the core essentials defined in home.nix.
# Selected by modules/state.json (toggle with `hmt` / utils/module_tui.py).
#
# Deliberately empty: picking lite means "do not import the heavy full
# profile". Add lite-only overrides here if you ever need them.
{ ... }:
{ }
