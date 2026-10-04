# 2026-10-04 - Commit split for television, mdfried, NFS, and rushi work

## Context

The working tree held changes from several unrelated topics.
The tmux status line work was in progress and stayed out of this commit set.

## Decisions

- Commit everything except the `tmux/` directory and `tmux-statusline.png`.
  Both stay uncommitted until the tmux work is done.
- Split the changes into six topic commits instead of one.
- Commit `flake.nix` and `flake.lock` together in the television commit.
  Their hunks mix the rushi-config git fetcher switch, the new tv-rushi
  input, and the nvimdots to my-nvim rename. Splitting the lock file by
  topic is not practical.
- Use this directory as the session decision log.
  Each decision set gets one dated file here.

## Commit map

1. television module, fish wiring, flake inputs (flake.nix, flake.lock)
2. mdfried module, home package tweaks
3. NFS on nixos-pro5000, exports moved out of head-node
4. core module: fish babelfish, nix-daemon-restart service
5. rushi home wiring: default package, tony-node secrets, empty nvim module
6. sglang-metrics rates, gitignore sessions/
