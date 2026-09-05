# herdr-mirror/hosts.toml — per-host herdr-mirror host list.
#
# herdr-mirror reads ~/.config/herdr-mirror/hosts.toml (see the "Configuration"
# section of https://github.com/nikok6/herdr-mirror). Each [hosts.<alias>]
# entry mirrors one remote herdr server. `target` is the ssh alias (the Host
# block key in this machine's ssh config), so herdr-mirror shells out to
# `ssh <target>` and reuses the local ssh config for user/identity/port.
#
# The host list is derived from programs.ssh.settings, so each machine in the
# flake writes its own hosts.toml from its own ssh config:
#   - nixos (head node) uses nixos-main/home_ssh.nix
#   - nixos-pro5000 uses nixos-pro5000/home_ssh.nix
#
# The github.com remote (the `gh` host) is a git remote, not a herdr host,
# and is excluded.

{ config, lib, ... }:

let
  sshSettings = config.programs.ssh.settings or { };

  # home-manager does not preserve the `host` field on ssh settings; the ssh
  # alias is the Host block key itself, which is what you `ssh` to.
  aliasOf = name: _: name;

  # Drop the github.com remote (git remote, not a herdr host). The `gh` entry
  # resolves to github.com; the machine entries resolve to IPs.
  isGitHub = _: value:
    (value.hostname or "") == "github.com"
    || (value.host or "") == "github.com";

  machines = lib.filterAttrs (name: value: !isGitHub name value) sshSettings;

  hostBlock = name: _: "[hosts.${name}]\n" + "target = \"${name}\"\n";

  tomlText =
    "# Managed by nixos-config (herdr/herdr-mirror-hosts.nix) — generated from the\n"
    + "# local ssh config; edit programs.ssh.settings instead of this file.\n"
    + builtins.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs hostBlock machines));
in
{
  home.file.".config/herdr-mirror/hosts.toml" = {
    text = tomlText;
  };
}
