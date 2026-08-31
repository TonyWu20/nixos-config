# Derivation for the sglang-usage tool. A single std-only Rust
# file, built with rustc. No crates, no lockfile, no network.
{ pkgs }:

let
  rustc = pkgs.rustc;
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "sglang-usage";
  version = "1.0.0";

  src = ./.;
  nativeBuildInputs = [ rustc ];

  buildPhase = ''
    runHook preBuild
    mkdir -p $out/bin
    ${rustc}/bin/rustc -O src/main.rs -o $out/bin/sglang-usage
  '';

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
  };
})
