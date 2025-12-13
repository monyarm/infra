if [[ -o login ]]; then
	[[ -f ~/.bashrc ]] && source ~/.bashrc
	[[ -t 0 && $(tty) == /dev/tty1 && ! $DISPLAY ]] && exec dbus-run-session niri --session
else
	exit 1
fi
