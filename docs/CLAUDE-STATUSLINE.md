# Claude Codeステータスライン仕様

現在のMacのスクリプトを取り込み、表示ロジックは維持する。
追加するのはjqがPATHにない場合のHomebrew標準パス補完のみ。
Apple Silicon / Intel向けに `/opt/homebrew/bin` / `/usr/local/bin` を補完する。
APIキー、トークン、ユーザー設定全体は管理しない。

## 配置と設定

- `claude/statusline.sh` → `~/.claude/statusline.sh`（実行権限あり）
- `claude/settings.json` → 既存設定のトップレベル `statusLine` のみ置換
- 設定値: type=command、command=`~/.claude/statusline.sh`、padding=0

インストーラーは既存JSONが単一のオブジェクトであることをjqで検証する。
不正JSON、空ファイル、配列等はエラーで停止し、Claudeファイルは変更しない。
他の設定キーは値を維持する。変更時にはJSONの整形が変わることがある。
マージ候補を同じディレクトリの一時ファイルに生成し、意味上の差分がある場合のみ
既存設定をバックアップして反映する。既存シンボリックリンクはリンク先を更新する。
実行中の同時編集は想定しない。新規設定と設定バックアップの権限は600。
シェル・tmux設定の導入はClaude設定の検証より先に行われる。

バックアップ先は `~/.mac-terminal-kit-backups/<timestamp>-<pid>/`。
既存スクリプトは `statusline.sh`、設定は `claude-settings.json` に保存する。
設定全体のバックアップは機密情報を含みうるためリポジトリに入れない。
復元時はClaude Codeを終了し、対応するバックアップを元のパスにコピーする。
その後インストーラーを再実行すると管理対象のstatusLineが再適用される。

## 表示

1行目: モデル、取得可能ならeffort、ディレクトリ、Gitブランチ（detached HEADは短縮ID）。
2行目: コンテキスト使用率バー、取得可能なら5時間・7日枠の残量とリセットまでの時間。
使用率がない場合は `--%`、Git外ではブランチを省略する。
effortは入力・環境変数・ユーザー設定の順に取得する。

幅はSTATUSLINE_COLS、tmuxペイン、tty、COLUMNS、120の順。
70列以上はfull、45〜69列はcompact、45列未満はmini。
miniではeffort・アイコン・7日枠を省略する。
極端に狭い幅や長いモデル名の折り返しを完全に防ぐ仕様ではない。
Nerd Fontの実際の字幅は端末とフォントに依存する。

## 検証項目

- bash構文確認、元スクリプトとの同一入力に対する出力比較
- full / compact / miniで2行、モデル・ディレクトリ・ブランチ・使用率
- current_usageからの使用率計算、情報欠落・不正JSON時のフォールバック
- 一時HOMEで初回導入、既存キー保持、バックアップ、再実行時の変更なし
- 不正な既存設定で停止し、Claudeファイルを維持すること
- tmuxセッション内での幅検出と出力、実端末でのフォントと折り返し確認

実端末上のClaude Code表示とIntel実機での動作は別途確認する。
