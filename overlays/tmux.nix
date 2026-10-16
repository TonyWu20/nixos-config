# tmux: pin tmux to 3.8 instead of the nixpkgs 3.7c.
#
# The nixpkgs expression hard-codes version = "3.7c" and the matching
# tarball. version is not an argument of the package function, so a
# plain .override { version = "3.8"; } has no effect. overrideAttrs
# replaces attributes after the function runs. The versionCheckHook
# install check compares `tmux -V` against the version attribute, so
# the two are overridden together.
#
# The hash is the recursive hash of the unpacked source tree, not of
# the tarball. fetchFromGitHub downloads through fetchzip in this
# nixpkgs. That fetcher unpacks the archive and hashes the tree.

final: prev:
let
  src = final.fetchFromGitHub {
    owner = "tmux";
    repo = "tmux";
    tag = "3.8";
    hash = "sha256-pv2wlr3coo+E0pfpb58giJJQn9PGgMFqtVA6nk+9JdE=";
  };
in
{
  tmux = prev.tmux.overrideAttrs (old: {
    version = "3.8";
    inherit src;
    meta = old.meta // {
      changelog = "https://github.com/tmux/tmux/raw/3.8/CHANGES";
    };
  });
}
