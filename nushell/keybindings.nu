$env.config.keybindings ++= [
  {
    name: fuzzy_history_fzf
    modifier: control
    keycode: char_r
    mode: [emacs , vi_normal, vi_insert]
    event: {
      send: executehostcommand
      cmd: "commandline edit --replace (
        history
          | where exit_status == 0
          | get command
          | reverse
          | uniq
          | str join (char -i 0)
          | fzf --scheme=history --read0 --tiebreak=chunk --layout=reverse --preview='echo {..}' --preview-window='bottom:3:wrap' --bind alt-up:preview-up,alt-down:preview-down --height=70% -q (commandline) --preview='echo -n {} | nu --stdin -c \'nu-highlight\''
          | decode utf-8
          | str trim
      )"
    }
  }
]

