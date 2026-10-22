# macOS Terminal Kit

zshを使ったmacOSのターミナル開発環境を、別のMacでも再現するためのセットアップ一式です。
クローンまたはダウンロードする際は、`claude/`を含むディレクトリ構成を維持してください。

## 含まれるファイル

| ファイル | 用途 |
| --- | --- |
| `Brewfile` | Homebrewで導入するツールとNerd Fontの依存関係 |
| `install.sh` | 依存ツールと設定の導入、既存ファイルのバックアップ |
| `starship.toml` | ユーザー名@ホスト名とディレクトリのフルパスを常時表示する2行プロンプト |
| `zsh-extra.zsh` | zshの補完、入力候補、構文強調、fzf、zoxide、エイリアス |
| `claude/statusline.sh` | Claude Codeの2行ステータスライン |
| `claude/settings.json` | 管理対象の`statusLine`設定のみ |
| `tmux.conf` | マウス操作、メニュー（`Ctrl-B` → `m`）、ペイン分割、クリップボードへのコピー |

## インストール

1. 必要に応じて[Homebrew](https://brew.sh/)をインストールします。
2. サブディレクトリ構成を維持して、ファイル一式を**同じローカルディレクトリ**へダウンロードまたはクローンします。
3. そのディレクトリで次を実行します。

   ```bash
   bash install.sh
   ```

4. 新しいターミナルウインドウを開くか、`exec zsh`を実行します。
5. **ターミナル → 設定 → プロファイル → テキスト**で、フォントを**MesloLGS Nerd Font Mono**、標準（Regular）、**14 pt**に設定します。表示されない場合は、ログアウトして再ログインするか、Macを再起動してください。
6. 実行中のtmuxセッションでは、`tmux source-file ~/.tmux.conf`で設定を再読み込みします。

インストーラーは`.zshrc`の既存内容を維持し、設定を読み込むブロックを**1つだけ**追記します。
`~/.tmux.conf`、`~/.config/starship.toml`、`~/.config/zsh-extra.zsh`は、既存ファイルを`~/.mac-terminal-kit-backups/`へバックアップしてから配置します。
再実行しても`.zshrc`の管理ブロックは重複しません。既存の`.zshrc`にStarshipやプラグインの初期化処理がある場合は、内容を確認し、必要に応じて重複を取り除いてください。

## tmuxの操作

| 操作 | キー・方法 |
| --- | --- |
| メニュー | `Ctrl-B` → `m` |
| 左右に分割 | `Ctrl-B` → `|` |
| 上下に分割 | `Ctrl-B` → `-` |
| 設定の再読み込み | `Ctrl-B` → `r` |
| マウスで選択 | tmuxバッファとmacOSクリップボードへコピー（対応するtmux選択モード内） |
| 貼り付け | `Command-V`（macOS）、マウスの中ボタン（tmuxバッファ） |
| ペインを閉じる | `exit`、またはメニューの「Close Pane」 |

**右クリックによる貼り付けは、意図的に無効にしています。** 元のmacOSターミナル環境で安定して動作しなかったためです。
右クリックではtmuxのメニューも表示されません。貼り付けには`Command-V`またはマウスの中ボタンを使ってください。
Vimなどが独自にマウスイベントを処理する場合は、動作が異なることがあります。

## fzfとCLIのショートカット

- `Ctrl-R`：履歴検索、`Ctrl-T`：ファイル選択、`Option-C`：ディレクトリ移動（ターミナルのOption/Meta設定の調整が必要な場合があります）
- `ls`、`ll`、`la`、`tree`：ezaのエイリアス
- `cat`：batのエイリアス。標準のcatを使う場合は`/bin/cat`を実行
- `z <文字列>` / `zi`：zoxideによるディレクトリ移動

## Claude Codeのステータスライン

Claude Code本体は別途インストールしてください。`bash install.sh`は`jq`を導入し、スクリプトを
`~/.claude/statusline.sh`へ配置します。設定は`jq`を使い、`~/.claude/settings.json`の
`statusLine`だけをマージします。他の設定は維持します。不正なJSONや、トップレベルがオブジェクトではない
設定ファイルがある場合、Claude設定の導入を停止します。
変更する既存ファイルは`~/.mac-terminal-kit-backups/<timestamp>-<pid>/`へ
`statusline.sh`および`claude-settings.json`としてバックアップします。
バックアップには個人の設定が含まれる可能性があるため、ローカルで保管してください。
再実行時にClaude設定の変更がなければ、書き換えやバックアップは行いません。

導入後はClaude Codeを再起動してください。1行目にはモデル名、取得できればeffort（推論の強度）、
ディレクトリ、Gitブランチを表示します。2行目にはコンテキスト使用率と、取得できれば5時間・7日間の利用枠の残量を表示します。
コンテキスト情報がなければ`--%`を表示し、取得できないブランチや利用枠の項目は省略します。
detached HEADの場合は短縮コミットIDを表示します。

表示幅はtmuxのペイン幅、端末幅、`COLUMNS`の順に取得し、取得できなければ120列を使います。
70列未満ではcompactモード、45列未満ではminiモードになります。長いディレクトリ名やブランチ名は短縮します。
`STATUSLINE_COLS=80`で幅を指定でき、`STATUSLINE_NERD_FONT=0`でアイコンを無効にできます。
極端に狭いペインや長いモデル名では折り返す場合があるため、必要に応じてペインの幅を調整してください。
継承したPATHに`jq`がない場合は、Homebrewの標準配置先である`/opt/homebrew/bin`と`/usr/local/bin`も検索します。

簡単な動作確認（各コマンドが2行を出力します）：

```bash
printf '%s' '{"model":{"display_name":"Claude"},"context_window":{"used_percentage":42}}' | STATUSLINE_COLS=80 bash ~/.claude/statusline.sh
printf '{}' | bash ~/.claude/statusline.sh
```

tmux内では`STATUSLINE_COLS`の指定を外し、ペイン幅を変えて同じ確認を行い、Nerd Fontのアイコンが正しく表示されることを確認してください。
検証と復元の詳細は[仕様書](docs/CLAUDE-STATUSLINE.md)を参照してください。
Gistではこのディレクトリ構成を維持できないため、導入にはリポジトリのクローンかアーカイブを使ってください。

## 制約・注意点

- macOSのターミナルアプリの設定（テーマ、フォント、ポインタサイズ、スクリーンショットのクリップボード動作、キーリピート）は**GUI・システム側の設定**であり、この設定一式では変更しません。
- 導入ツールのバージョンは固定していません。Homebrewが対象のMacで利用可能なバージョンをインストールします。
- 別のシェルフレームワークを使っている場合、`~/.zshrc`ですでに補完やStarshipを初期化していることがあります。Oh My Zshなどを利用している場合は、二重に初期化しないよう確認してください。
- Homebrewの標準配置先は、Apple Siliconでは`/opt/homebrew`、Intelでは`/usr/local`です。zshスクリプトは配置先を検出します。
