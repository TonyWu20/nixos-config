# Fixed fish-history cable for television.
#
# Replaces the upstream channel that `tv update-channels` writes to
# ~/.config/television/cable/fish-history.toml. That built-in source
# (`fish -c 'history'`) emits one line per entry, so a shell command that
# contains backslash line continuations is split into several entries by
# television's newline entry splitting.
#
# This cable mirrors what fzf's fzf-history-widget does instead:
#
#   source.command emits records separated by NUL (`history --null`) and
#   source.entry_delimiter = "\0" keeps each command - including embedded
#   newlines and backslash continuations - as a single entry.
#
#   source.display flattens each entry to one results-row by rendering
#   embedded newlines as the fzf wrap-sign "↳ ". The entry stays one line
#   while the continuation structure remains visible.
#
#   source.output is left unset, so a selection hands the raw multi-line
#   command to the shell integration. The fish binding runs `commandline -r`
#   on it, so the prompt shows the command exactly as typed, backslash
#   continuations intact.
#
#   preview pipes the raw entry through a quoted heredoc before running
#   fish_indent. The heredoc body is never parsed by the shell, so quotes,
#   backticks and dollar expansions inside the entry cannot break the
#   preview command. fish_indent then formats the whole command for the
#   preview panel, the same rendering fzf-history-widget uses.
#
# `tv update-channels` skips files that already exist, so this cable
# survives channel updates; only `tv update-channels --force` would
# overwrite it.

{ ... }:

{
  programs.television.channels."fish-history" = {
    metadata = {
      name = "fish-history";
      description = "A channel to select from your fish history";
      # fish_indent is invoked by the preview command
      requirements = [ "fish" "fish_indent" ];
    };

    source = {
      # records separated by NUL; each record is one complete command
      command = "fish -c 'history --null'";
      # keep each NUL-separated record as a single entry
      entry_delimiter = "\\0";
      # render embedded newlines as the fzf wrap-sign so multi-line
      # commands stay one row in the results panel
      display = "{replace:s/\\n/↳ /g}";
      # match the old fzf behavior: source order with an empty query,
      # match-score order while searching
      no_sort = false;
      frecency = false;
    };

    preview = {
      # quoted heredoc: the raw entry, quotes and all, is passed to
      # fish_indent without being parsed by the shell
      command = "cat <<'TV_FISH_HIST_EOF' | fish_indent --ansi\n{}\nTV_FISH_HIST_EOF";
      shell = "bash";
    };
  };
}
