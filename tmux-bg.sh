#!/bin/sh
# tmux の現在の window 番号を WezTerm にユーザー変数 (tmux_window) として通知する。
#   tmux-bg.sh            : 接続中の全クライアントへ、各セッションの現在の window 番号を送る
#   tmux-bg.sh clear TTY  : TTY のユーザー変数を空にする (detach 時)
send() {
	tty="$1"; val="$2"
	[ -n "$tty" ] && [ -w "$tty" ] || return 0
	printf '\033]1337;SetUserVar=tmux_window=%s\007' "$(printf %s "$val" | base64 | tr -d '\n')" > "$tty"
}

if [ "$1" = "clear" ]; then
	send "$2" ""
	exit 0
fi

tmux list-clients -F '#{client_tty} #{window_index}' 2>/dev/null | while read -r tty idx; do
	send "$tty" "$idx"
done
