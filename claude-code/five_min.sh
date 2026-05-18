#!/bin/bash
kill $(cat /tmp/claude_watchdog.pid 2>/dev/null) 2>/dev/null
notify() {
	local title=$1 body=$2
	local DEST_TTY

	if [[ -n ${TMUX} ]]; then
		DEST_TTY=$(tmux display-message -p '#{client_tty}')
	elif ! DEST_TTY=${TTY:-$(tty)} || [[ ! -c ${DEST_TTY} ]]; then
		if ! DEST_TTY=/dev/$(ps -p $ -o tty=) || [[ ! -c ${DEST_TTY} ]]; then
			DEST_TTY=/dev/stdout
		fi
	fi

	printf "\e]777;notify;%s;%s\a" "${title}" "${body}" >${DEST_TTY}
}
(
	sleep 120
	notify "Time to stand up and move" "120 seconds has passed"
) &
echo $! >/tmp/claude_watchdog.pid
