# Tab completion: fzf-fish vs television

This document records the differences between the removed `jethrokuan/fzf`
fish plugin and the in-box television features that replace it.

## What television provides in-box

| Feature | How it works |
|---|---|
| **Shell integration (ctrl-t / ctrl-r)** | `programs.television.enableFishIntegration` sources the package's `share/television/completion.fish`, which defines `tv_smart_autocomplete` (bound to ctrl-t) and `tv_shell_history` (bound to ctrl-r). ctrl-t opens the `files` or `dirs` channel based on the current prompt; ctrl-r opens `fish-history`. |
| **CLI tab completion for `tv`** | The nixpkgs package ships `share/fish/vendor_completions.d/tv.fish` (equivalent of `tv completions fish`). It is linked into the user profile automatically and is picked up by fish via `XDG_DATA_DIRS`. |
| **Channel-based file/dir find + preview** | Configured in `television/default.nix` under `programs.television.channels` (`files`, `dirs`). |

## What is NOT in-box (was in fzf-fish, now absent)

| fzf-fish feature | Status |
|---|---|
| **Universal Tab completion** (`__fzf_complete`: `complete -C <cmd> \| fzf`) | Not provided by television. No custom replacement was written. To add it back, pipe `complete -C` output into `tv --inline` in a hand-rolled fish function bound to Tab. |
| **Per-candidate description preview** (`--preview-window` + `__fzf_complete_preview`) | Not available in `tv --inline`. |
| **Multi-select tab completion** (`FZF_COMPLETE=3`) | Not applicable. |
| **`FZF_TMUX`** tmux-friendly layout | Irrelevant; television manages its own layout. |

## Keybinding map

| Key | Before (fzf-fish) | After (television in-box) |
|---|---|---|
| **Tab** | `__fzf_complete` — fzf picker over `complete -C` output | *Removed.* No universal Tab completion. |
| **ctrl-t** | `__fzf_find_file` (fzf file finder) | `tv_smart_autocomplete` → `files`/`dirs` channel (channel_triggers) |
| **ctrl-r** | `__fzf_reverse_isearch` (fzf history) | `tv_shell_history` → `fish-history` channel |
| **alt-c** | `__fzf_cd` (fzf directory finder) | type `cd` then **ctrl-t** → `dirs` channel |
| **alt-shift-c** | `__fzf_cd --hidden` | type `cd` then **ctrl-t**, switch to Hidden source (ctrl-s in tv) |
| **ctrl-g** | `__fzf_open` (xdg-open) | not replicated |
| **ctrl-o** | `__fzf_open --editor` | F12 in `files` channel (`actions:edit`) |
| **ctrl-/** | fzf `change-preview-window` | `toggle_preview` (tv in-app, via `settings.keybindings`) |

## Settings migrated from `programs.fzf` to `programs.television`

| fzf setting | television equivalent |
|---|---|
| `--height 80%` | `ui.ui_scale = 80` |
| `--border` | `ui.*.border_type = "rounded"` |
| `--preview-window right:67%` | `ui.orientation = "landscape"`, `ui.preview_panel.size = 67` |
| `--ansi` | inherent (tv renders ANSI in previews) |
| `FZF_PREVIEW_FILE_CMD` (bat header/numbers/grid, line-range 300) | `files.preview.command = "bat --style=header,numbers,grid --line-range :300 --color=always '{}'"` |
| `FZF_PREVIEW_DIR_CMD` (eza tree) | `dirs.preview.command = "eza -l --git --no-permissions --icons --no-user --level=2 -T '{}'"` |
| `fd --type file -HI -E .git --color=always` | `files.source.command = [{ name = "Default"; run = "fd -t f -HI -E .git"; }]` |
| `FZF_COMPLETE=1` | n/a (no Tab completion in television) |
| `FZF_TMUX=0` | n/a |
