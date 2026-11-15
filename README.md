# wezterm

個人用の WezTerm 設定です。

## 構成

| ファイル | 内容 |
| --- | --- |
| `wezterm.lua` | WezTerm の設定本体 |
| `tmux-bg.sh` | tmux の現在の window 番号を WezTerm のユーザー変数 (`tmux_window`) として通知するスクリプト |
| `backgrounds/` | 背景画像 |
| `.mise.toml` | [mise](https://mise.jdx.dev/) で管理するツール (`gh`) |

## tmux 連携（`~/.tmux.conf`）

tmux の window 番号に応じて WezTerm の背景画像を切り替えます。
`tmux-bg.sh` が現在の window 番号を WezTerm のユーザー変数 `tmux_window` として送り、`wezterm.lua` がそれを受け取って画像を差し替えます。

| window 番号 | 背景画像 |
| --- | --- |
| 0 | `soundonly_S_re.jpg` |
| 1〜7 | `soundonly_<番号>_re.jpg` |
| それ以外 | `2414983186-kabekin_0019_Layer_64-4xjV-1920x1080-MM-100.jpg` |
| tmux 外 | 背景画像のスライドショー |

`~/.tmux.conf` に次の設定を追加してください。

```tmux
# 背景画像を透過させるため、tmux 側の背景色を default にする
set -g window-style 'bg=default'
set -g window-active-style 'bg=default'
set -g focus-events on

# window 切替などのたびに WezTerm へ現在の window 番号を通知
set-hook -g after-select-window   'run-shell -b "~/.config/wezterm/tmux-bg.sh"'
set-hook -g client-session-changed 'run-shell -b "~/.config/wezterm/tmux-bg.sh"'
set-hook -g client-attached       'run-shell -b "~/.config/wezterm/tmux-bg.sh"'
set-hook -g client-focus-in       'run-shell -b "~/.config/wezterm/tmux-bg.sh"'
set-hook -g window-linked         'run-shell -b "~/.config/wezterm/tmux-bg.sh"'
set-hook -g window-unlinked       'run-shell -b "~/.config/wezterm/tmux-bg.sh"'
set-hook -g client-detached       'run-shell -b "~/.config/wezterm/tmux-bg.sh clear #{client_tty}"'
```

補足:

- `window-style` / `window-active-style` を `bg=default` にしないと、tmux が背景を塗りつぶして画像が見えません。
- `focus-events on` は、`client-focus-in` フックを動かすために必要です。
- `tmux-bg.sh` は `~/.config/wezterm/` に置く前提です。別の場所に置く場合は、フックのパスを変更してください。
- 上の表は window 番号が 0 始まり（tmux の既定値）であることを前提にしています。`base-index 1` にすると、window 0 用の画像は使われません。
- window を閉じたあとに番号を詰めたい場合は、`set-option -g renumber-windows on` も入れておくと便利です。

## 背景画像について

`backgrounds/` 内の画像は、公式に配布・提供されているものです。
著作権は各権利者に帰属します。この画像は**私用（個人利用）のみ**を目的として置いています。
再配布や商用利用など、私用の範囲を超える利用はしないでください。
