# Fig pre block. Keep at the top of this file.
export PATH="${PATH}:${HOME}/.local/bin"
eval "$(fig init zsh pre)"

#
if [ "$(arch)" = "arm64" ]; then
  eval $(/opt/homebrew/bin/brew shellenv);
else
  eval $(/usr/local/bin/brew shellenv);
fi

# キーバインディングを emacs 風にする
#bindkey -d
bindkey -e
bindkey -v
autoload -Uz add-zsh-hook # call hook functions
# cdr
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
bindkey "^U" backward-kill-line

#source $HOME/.zsh/prompt.zsh
source $HOME/.zsh/function.zsh
source $HOME/.zsh/fzf.zsh

export STARSHIP_CONFIG=~/.starship.toml
eval "$(starship init zsh)"

. $HOME/ghq/github.com/rupa/z/z.sh


REPORTTIME=3


function history-all { history -E 1}
eval "$(pyenv init -)"
eval "$(direnv hook zsh)"


### history ###
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

setopt share_history #zsh間で履歴共有
setopt hist_ignore_dups # 直前と同じコマンドの場合はヒストリに追加しない
setopt hist_ignore_all_dups # 同じコマンドをヒストリに残さない
setopt hist_ignore_space # スペースから始まるコマンド行はヒストリに残さない
setopt hist_reduce_blanks # ヒストリに保存するときに余分なスペースを削除する

### directory stack ###
setopt pushd_ignore_dups # pushd したとき、ディレクトリがすでにスタックに含まれていればスタックに追加しない
setopt auto_pushd # cd [TAB] で以前移動したディレクトリを表示
DIRSTACKSIZE=100


### plugins(zplug) ###
#export ZPLUG_HOME=/root/.zplug
#source $ZPLUG_HOME/init.zsh
#source ~/.zplug/init.zsh
#zplug 'zplug/zplug', hook-build:'zplug --self-manage' # 自身をプラグインとして管理する
##zplug "mafredri/zsh-async" # 非同期処理
#zplug "zsh-users/zsh-syntax-highlighting" # 構文ハイライト
#zplug "zsh-users/zsh-history-substring-search" # コマンド履歴
#
## 入力補完
##zplug "zsh-users/zsh-autosuggestions"
#zplug "zsh-users/zsh-completions"
#zplug "chrissicool/zsh-256color"

# インストールされてないプラグインをインストール
#if ! zplug check --verbose; then
#  printf "Install? [y/N]: "
#  if read -q; then

# プラグインを読み込みコマンドを$PATHへ追加
#zplug load



# git のカラー表示
git config --global color.ui auto


# 色を使用出来るようにする
autoload -Uz colors
colors


setopt nonomatch #glob でno matchだった場合の警告を消す
setopt print_eight_bit # 日本語ファイル名を表示可能にする
setopt auto_cd # cd なしでもディレクトリ移動
setopt no_beep # ビープ音の停止
setopt nolistbeep # ビープ音の停止(補完時)


### complement ###

fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)    # gitのbranch名補完
setopt auto_menu                        # 補完候補が複数あるときに自動的に一覧表示
bindkey "^[[Z" reverse-menu-complete    # Shift-Tabで補完候補を逆順する("\e[Z"でも動作する)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # 補完時に大文字小文字を区別しない
zstyle ':completion:*:sudo:*' command-path $DEFAULT_PREFIX/sbin $DEFAULT_PREFIX/bin \
    /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin    # sudo の後ろでコマンド名を補完
#if [ -e $DEFAULT_PREFIX/share/zsh-completions ]; then
#  fpath=($DEFAULT_PREFIX/share/zsh-completions $fpath)   # zsh-completions有効化
#fi

# zsh-completions の設定。コマンド補完機能
#autoload -U compinit && compinit -u

# [TAB] でパス名の補完候補を表示したあと、
# 続けて [TAB] を押すと候補からパス名を選択できるようになる
# 候補を選ぶには [TAB] か Ctrl-N,B,F,P
zstyle ':completion:*:default' menu select=1

# コマンドのスペルを訂正する
setopt correct

# '#' 以降をコメントとして扱う
setopt interactive_comments

### cdr ###
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':chpwd:*' recent-dirs-max 5000
zstyle ':chpwd:*' recent-dirs-default yes
zstyle ':completion:*' recent-dirs-insert both

# cd した先のディレクトリをディレクトリスタックに追加する
# cd [TAB] でディレクトリのヒストリが表示されるので、選択して移動できる
# ※ ディレクトリスタック: 今までに行ったディレクトリのヒストリのこと
setopt auto_pushd

function chpwd() { ll } # cd後 自動ls

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




# added by travis gem
[ ! -s /Users/wantedly206/.travis/travis.sh ] || source /Users/wantedly206/.travis/travis.sh


#export PATH="$HOME/.poetry/bin:$PATH"
#export PATH="/opt/homebrew/bin:$PATH"
#export PATH="/opt/homebrew/opt/python@3.9/libexec/bin:$PATH"

# tmux
#if [ $SHLVL = 1 ]; then
#  tmux
#fi


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/kokoro/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/kokoro/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/Users/kokoro/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/kokoro/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
export PATH="$HOME/go/1.16.0/bin:$PATH"


#eval "$(goenv init -)"

#anyframe
fpath=($HOME/.zsh/anyframe(N-/) $fpath)
autoload -Uz anyframe-init
anyframe-init
zstyle ":anyframe:selector:" use fzf



## コマンドラインをエディタで起動する
#$autoload -Uz edit-command-line
#zle -N edit-command-line
bindkey '^y' edit-command-line

# viminsとemacsの共存
bindkey -M viins '\er' history-incremental-pattern-search-forward
bindkey -M viins '^?'  backward-delete-char
bindkey -M viins '^A'  beginning-of-line
bindkey -M viins '^B'  backward-char
bindkey -M viins '^D'  delete-char-or-list
bindkey -M viins '^E'  end-of-line
bindkey -M viins '^F'  forward-char
bindkey -M viins '^G'  send-break
bindkey -M viins '^H'  backward-delete-char
bindkey -M viins '^K'  kill-line
bindkey -M viins '^N'  down-line-or-history
bindkey -M viins '^P'  up-line-or-history
#bindkey -M viins '^R'  history-incremental-pattern-search-backward
bindkey -M viins '^U'  backward-kill-line
bindkey -M viins '^W'  backward-kill-word
bindkey -M viins '^Y'  yank

export PATH="$HOME/.nodenv/bin:$PATH"
export PATH="$HOME/command/:$PATH"
eval "$(nodenv init -)"
eval "$(rbenv init - zsh)"



#eval "$(rbenv init - zsh)"
if (( $+commands[arch] )); then
  alias a64="exec arch -arch arm64e '$SHELL'"
  alias x64="exec arch -arch x86_64 '$SHELL'"
fi

function runs_on_ARM64() { [[ `uname -m` = "arm64" ]]; }
function runs_on_X86_64() { [[ `uname -m` = "x86_64" ]]; }

BREW_PATH_OPT="/opt/homebrew/bin"
BREW_PATH_LOCAL="/usr/local/bin"
function brew_exists_at_opt() { [[ -d ${BREW_PATH_OPT} ]]; }
function brew_exists_at_local() { [[ -d ${BREW_PATH_LOCAL} ]]; }

setopt no_global_rcs
typeset -U path PATH
path=($path /usr/sbin /sbin)

if runs_on_ARM64; then
  path=($BREW_PATH_OPT(N-/) $BREW_PATH_LOCAL(N-/) $path)
else
  path=($BREW_PATH_LOCAL(N-/) $path)
fi
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"
eval "$(nodenv init -)"

if (which zprof > /dev/null 2>&1) ;then
  zprof
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust


## plugins(zinit)
## Plugin history-search-multi-word loaded with investigating.
zinit load zdharma-continuum/history-search-multi-word

# Two regular plugins loaded without investigating.
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting

#color theme
zinit light simnalamburt/shellder

# Snippet
#zinit snippet https://gist.githubusercontent.com/hightemp/5071909/raw/
### End of Zinit's installer chunk

# Fig post block. Keep at the bottom of this file.
eval "$(fig init zsh post)"
