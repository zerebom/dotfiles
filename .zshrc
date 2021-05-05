export PATH=$HOME/.wantedly/bin:$PATH
export PATH=$GOPATH/bin:$PATH
export PATH="$HOME/.poetry/bin:$PATH"
#export PATH=$HOME/.poetry/bin:$PATH
#export PATH=$HOME/.pyenv/bin:$PATH
#export PATH=$HOME/.local/bin:$PATH
#export PATH=/usr/local/bin:$PATH
#export GOPATH=$HOME/go

export GOPRIVATE=github.com/wantedly
export EDITOR=vim
export REFLECTION_SERVER=apis-reflection-server.apis-reflection-server:80

#export ZPLUG_HOME=/root/.zplug
#source $ZPLUG_HOME/init.zsh
source ~/.zplug/init.zsh

function history-all { history -E 1}
eval "$(pyenv init -)"
eval "$(direnv hook zsh)"


# 自身をプラグインとして管理する
zplug 'zplug/zplug', hook-build:'zplug --self-manage'

## おすすめプラグイン

# プロンプト
zplug "sindresorhus/pure"

# 非同期処理
zplug "mafredri/zsh-async"

# 構文ハイライト
zplug "zsh-users/zsh-syntax-highlighting"

# コマンド履歴
zplug "zsh-users/zsh-history-substring-search"

# 入力補完
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
zplug "chrissicool/zsh-256color"

# インストールされてないプラグインをインストール
if ! zplug check --verbose; then
  printf "Install? [y/N]: "
  if read -q; then
    echo; zplug install
  fi
fi


# プラグインを読み込みコマンドを$PATHへ追加
zplug load

# すっきりしたプロンプト表示 (不要ならコメントアウト)
PROMPT='%~ %# '

# zsh-completions の設定。コマンド補完機能
autoload -U compinit && compinit -u

# git のカラー表示
git config --global color.ui auto

# エイリアス
alias his='history'
alias ...='cd ../..'
alias ....='cd ../../..'
alias e="emacs"
alias v='vim'
alias vi='vim'
alias mss='mysql.server start'
alias so='source'
alias be='bundle exec'
alias ber='bundle exec ruby'

# エイリアス: git 系
alias g='git'
alias gs='git status'
alias gb='git branch'
alias gc='git checkout'
alias gct='git commit'
alias gg='git grep'
alias ga='git add'
alias gd='git diff'
alias gl='git log'
alias gcma='git checkout master'
alias gfu='git fetch upstream'
alias gfo='git fetch origin'
alias gmod='git merge origin/develop'
alias gmud='git merge upstream/develop'
alias gmom='git merge origin/master'
alias gcm='git commit -m'
alias gpo='git push origin'
alias gpom='git push origin master'
alias gst='git stash'
alias gsl='git stash list'
alias gsu='git stash -u'
alias gsp='git stash pop'

# 色を使用出来るようにする
autoload -Uz colors
colors

#glob でno matchだった場合の警告を消す
setopt nonomatch

# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# cd なしでもディレクトリ移動
setopt auto_cd

# ビープ音の停止
setopt no_beep

# ビープ音の停止(補完時)
setopt nolistbeep

# cd [TAB] で以前移動したディレクトリを表示
setopt auto_pushd

# ヒストリ (履歴) を保存、数を増やす
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

# 同時に起動した zsh の間でヒストリを共有する
setopt share_history

# 直前と同じコマンドの場合はヒストリに追加しない
setopt hist_ignore_dups

# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups

# スペースから始まるコマンド行はヒストリに残さない
setopt hist_ignore_space

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# キーバインディングを emacs 風にする
# bindkey -d
# bindkey -e

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# [TAB] でパス名の補完候補を表示したあと、
# 続けて [TAB] を押すと候補からパス名を選択できるようになる
# 候補を選ぶには [TAB] か Ctrl-N,B,F,P
zstyle ':completion:*:default' menu select=1

# コマンドのスペルを訂正する
setopt correct

# cd した先のディレクトリをディレクトリスタックに追加する
# cd [TAB] でディレクトリのヒストリが表示されるので、選択して移動できる
# ※ ディレクトリスタック: 今までに行ったディレクトリのヒストリのこと
setopt auto_pushd

# pushd したとき、ディレクトリがすでにスタックに含まれていればスタックに追加しない
setopt pushd_ignore_dups

# 拡張 glob を有効にする
# 拡張 glob を有効にすると # ~ ^ もパターンとして扱われる
# glob: パス名にマッチするワイルドカードパターンのこと
# ※ たとえば mv hoge.* ~/dir というコマンドにおける * のこと
setopt extended_glob

# 単語の一部として扱われる文字のセットを指定する
# ここではデフォルトのセットから / を抜いたものにしている
# ※ たとえば Ctrl-W でカーソル前の1単語を削除したとき / までで削除が止まる
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/wantedly206/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/wantedly206/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/wantedly206/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/wantedly206/Downloads/google-cloud-sdk/completion.zsh.inc'; fi


LC_CTYPE=en_US.UTF-8
LC_ALL=en_US.UTF-8

eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.starship.toml


function peco-history-selection() {
    BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
        CURSOR=$#BUFFER    
        zle reset-prompt
}

zle -N peco-history-selection 
bindkey '^R' peco-history-selection

# added by travis gem
[ ! -s /Users/wantedly206/.travis/travis.sh ] || source /Users/wantedly206/.travis/travis.sh
