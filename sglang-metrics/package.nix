# Derivation for the sglang-usage tool. A single binary crate, built
# with cargo. Dependencies are pinned by Cargo.lock and fetched from
# crates.io; the build then runs offline against the pinned sources.
# The only runtime dependency is clap, linked statically.
{ pkgs }:

pkgs.rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sglang-usage";
  version = "1.0.0";

  src = ./.;
  cargoLock = {
    lockFile = ./Cargo.lock;
  };
  doCheck = false;

  meta = with pkgs.lib; {
    description = "Persist SGLang /metrics across sessions in a plain TSV file";
    longDescription = ''
      sglang-usage scrapes the Prometheus /metrics endpoint of a SGLang
      server and appends the usage counters to an append-only TSV file.
      The file grows across SGLang restarts, so token totals accumulate
      forever. The `report` command aggregates the file: token totals,
      request counts, cached tokens, session counts, and an estimate of
      the cloud API cost that local serving saved.
    '';
    license = licenses.mit;
    platforms = platforms.all;
    mainProgram = "sglang-usage";
  };
})
