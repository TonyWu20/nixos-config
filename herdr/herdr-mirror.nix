# herdr-mirror — herdr plugin that mirrors remote herdr workspaces locally.
#
# Fetches the prebuilt binary from GitHub Releases (same pattern as herdr-nix
# for the herdr binary), packages the plugin manifest so herdr can discover
# it, and registers the plugin via `herdr plugin link` during activation.
#
# Upstream: https://github.com/nikok6/herdr-mirror

{ herdr-nix, config, lib, pkgs, ... }:

let
  version = "0.4.1";
  system = pkgs.stdenv.system;

  assets = {
    "aarch64-darwin" = {
      url = "https://github.com/nikok6/herdr-mirror/releases/download/v${version}/herdr-mirror-darwin-aarch64";
      hash = "sha256:4da1b73417f6b7a340404e70c0c4ef1640bff2c4587857d2a5ef6fac7531c83e";
    };
    "x86_64-darwin" = {
      url = "https://github.com/nikok6/herdr-mirror/releases/download/v${version}/herdr-mirror-darwin-x86_64";
      hash = "sha256:0a531c6f6eae5933477e193aa6a721c03ab0643ca6558edfa95389c89a91d476";
    };
    "aarch64-linux" = {
      url = "https://github.com/nikok6/herdr-mirror/releases/download/v${version}/herdr-mirror-linux-aarch64";
      hash = "sha256:9c4b1a4306bcd1e5b7cb87548b3b439839af99835aa21547346f66ee96e7be3a";
    };
    "x86_64-linux" = {
      url = "https://github.com/nikok6/herdr-mirror/releases/download/v${version}/herdr-mirror-linux-x86_64";
      hash = "sha256:6bb804faeb3be7f89b359765f6daad24ff6c74c19ded339d9186ab4b892d8ea8";
    };
  };

  asset = assets.${system}
    or (throw "herdr-mirror: no prebuilt release for system ${system}");

  # Standalone binary (lands on PATH for CLI use: herdr-mirror status, etc.)
  herdrMirror = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr-mirror";
    inherit version;
    src = pkgs.fetchurl {
      inherit (asset) url hash;
    };
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/herdr-mirror"
      runHook postInstall
    '';
  };

  # Plugin manifest (no [[build]] section — the binary is provided by Nix,
  # so herdr does not need to run scripts/install.sh)
  manifest = pkgs.writeText "herdr-mirror-herdr-plugin.toml" ''
    id = "mirror"
    name = "Herdr Mirror"
    version = "${version}"
    min_herdr_version = "0.7.2"
    description = "Mirror a remote herdr server's workspaces and agents into the local sidebar"
    platforms = [ "macos", "linux" ]

    [[panes]]
    id = "pick-host"
    title = "New workspace"
    command = [ "./target/release/herdr-mirror", "pick-workspace", "--menu" ]

    [[actions]]
    id = "start"
    title = "Mirror: start / resume"
    description = "Start (or resume) the mirror daemon for all configured hosts"
    command = [ "./target/release/herdr-mirror", "start" ]

    [[actions]]
    id = "pause"
    title = "Mirror: pause"
    description = "Pause syncing — mirror workspaces stay put; resume with start"
    command = [ "./target/release/herdr-mirror", "pause" ]

    [[actions]]
    id = "status"
    title = "Mirror: status"
    description = "Log daemon, host, and mirror-object status"
    command = [ "./target/release/herdr-mirror", "status" ]

    [[actions]]
    id = "once"
    title = "Mirror: sync once"
    description = "One-shot mirror pass without starting the daemon"
    command = [ "./target/release/herdr-mirror", "once" ]

    [[actions]]
    id = "remote-new-workspace"
    title = "Mirror: new workspace"
    description = "New workspace on the remote host (the invoking mirror's host, else hosts.toml default_host)"
    command = [ "./target/release/herdr-mirror", "remote-workspace" ]

    [[actions]]
    id = "new-workspace-pick"
    title = "Mirror: new workspace — pick host"
    description = "Pop up a picker: create the new workspace on this machine or on a configured host"
    command = [ "./target/release/herdr-mirror", "pick-workspace" ]

    [[actions]]
    id = "remote-new-tab"
    title = "Mirror: new tab"
    description = "New tab on the remote when invoked inside a mirror; a plain local tab anywhere else"
    command = [ "./target/release/herdr-mirror", "remote-tab" ]

    [[actions]]
    id = "remote-split-right"
    title = "Mirror: split right"
    description = "Split the mirrored remote pane right; splits locally when invoked outside a mirror"
    command = [ "./target/release/herdr-mirror", "remote-split", "right" ]

    [[actions]]
    id = "remote-split-down"
    title = "Mirror: split down"
    description = "Split the mirrored remote pane down; splits locally when invoked outside a mirror"
    command = [ "./target/release/herdr-mirror", "remote-split", "down" ]

    [[actions]]
    id = "hide"
    title = "Mirror: hide"
    description = "Hide this connection's mirrored terminals locally — remote keeps running"
    command = [ "./target/release/herdr-mirror", "hide" ]

    [[actions]]
    id = "show"
    title = "Mirror: show"
    description = "Bring back a connection's mirrored terminals after hiding them"
    command = [ "./target/release/herdr-mirror", "show" ]

    [[actions]]
    id = "restore"
    title = "Mirror: restore closed mirrors"
    description = "Bring back mirror workspaces/panes you closed locally"
    command = [ "./target/release/herdr-mirror", "restore" ]

    [[actions]]
    id = "teardown"
    title = "Mirror: teardown"
    description = "Stop the daemon and close all mirror workspaces"
    command = [ "./target/release/herdr-mirror", "teardown" ]

    [[events]]
    on = "workspace.focused"
    command = [ "./target/release/herdr-mirror", "ensure" ]

    [[events]]
    on = "workspace.created"
    command = [ "./target/release/herdr-mirror", "intercept-new", "workspace" ]

    [[events]]
    on = "tab.created"
    command = [ "./target/release/herdr-mirror", "intercept-new", "tab" ]

    [[events]]
    on = "pane.created"
    command = [ "./target/release/herdr-mirror", "intercept-new", "pane" ]
  '';

  # Bundle the binary + manifest into the directory layout herdr expects:
  #   $out/
  #     herdr-plugin.toml
  #     target/release/herdr-mirror
  herdrMirrorPlugin = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr-mirror-plugin";
    inherit version;
    src = manifest;
    dontUnpack = true;
    dontBuild = true;
    nativeBuildInputs = [ herdrMirror ];
    preferLocalBuild = true;
    installPhase = ''
      mkdir -p $out/target/release
      cp ${herdrMirror}/bin/herdr-mirror $out/target/release/herdr-mirror
      cp $src $out/herdr-plugin.toml
    '';
  };

  herdrBin = "${herdr-nix.packages.${system}.herdr}/bin/herdr";
in
{
  # Binary on PATH for CLI use (herdr-mirror status, etc.) and the plugin
  # directory in the Nix store (kept alive by the home profile).
  home.packages = [ herdrMirror herdrMirrorPlugin ];

  # Register the plugin with herdr's plugin registry.
  # `herdr plugin link` writes to the user's herdr registry so herdr
  # discovers the plugin at startup. Safe to re-run: it updates the link.
  home.activation."herdr-mirror-plugin" =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${herdrBin} plugin link ${herdrMirrorPlugin} --enabled \
        || echo "warning: herdr plugin link failed (herdr not ready?)" >&2
    '';
}
