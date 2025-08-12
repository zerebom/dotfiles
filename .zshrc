# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"


# キーバインディング: vi-modeベースでemacsのキーも使える設定
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



REPORTTIME=3


function history-all { history -E 1}
# Lazy load pyenv
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    # Create wrapper functions for pyenv commands
    pyenv() {
        unset -f pyenv
        eval "$(command pyenv init -)"
        pyenv "$@"
    }
    
    python() {
        unset -f python
        eval "$(command pyenv init -)"
        python "$@"
    }
    
    python3() {
        unset -f python3
        eval "$(command pyenv init -)"
        python3 "$@"
    }
    
    pip() {
        unset -f pip
        eval "$(command pyenv init -)"
        pip "$@"
    }
    
    pip3() {
        unset -f pip3
        eval "$(command pyenv init -)"
        pip3 "$@"
    }
fi
# Lazy load direnv
if command -v direnv >/dev/null 2>&1; then
    # Hook direnv into cd command
    _direnv_hook() {
        eval "$(direnv hook zsh)"
        unset -f _direnv_hook
    }
    
    # Override cd to initialize direnv on first use
    cd() {
        _direnv_hook 2>/dev/null
        builtin cd "$@"
    }
fi


### history ###
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

# History options
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS

# General options
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt GLOBDOTS
setopt INTERACTIVE_COMMENTS
setopt MAGIC_EQUAL_SUBST
setopt PRINT_EIGHT_BIT
setopt NO_FLOW_CONTROL

zshaddhistory() {
    local line="${1%%$'\n'}"
    [[ ! "$line" =~ "^(cd|history|jj?|lazygit|la|ll|ls|rm|rmdir|trash)($| )" ]]
}

### key bindings ###
clear-screen-and-update-prompt() {
    ALMEL_STATUS=0
    almel::precmd
    zle .clear-screen
}
zle -N clear-screen clear-screen-and-update-prompt

widget::history() {
    local selected="$(history -inr 1 | fzf --exit-0 --query "$LBUFFER" | cut -d' ' -f4- | sed 's/\\n/\n/g')"
    if [ -n "$selected" ]; then
        BUFFER="$selected"
        CURSOR=$#BUFFER
    fi
    zle -R -c # refresh screen
}

widget::ghq::source() {
    local session color icon green="\e[32m" blue="\e[34m" reset="\e[m" checked="\uf631" unchecked="\uf630"
    local sessions=($(tmux list-sessions -F "#S" 2>/dev/null))

    ghq list | sort | while read -r repo; do
        session="${repo//[:. ]/-}"
        color="$blue"
        icon="$unchecked"
        if (( ${+sessions[(r)$session]} )); then
            color="$green"
            icon="$checked"
        fi
        printf "$color$icon %s$reset\n" "$repo"
    done
}
widget::ghq::select() {
    local root="$(ghq root)"
    widget::ghq::source | fzf --exit-0 --preview="fzf-preview-git ${(q)root}/{+2}" --preview-window="right:60%" | cut -d' ' -f2-
}
widget::ghq::dir() {
    local selected="$(widget::ghq::select)"
    if [ -z "$selected" ]; then
        return
    fi

    local repo_dir="$(ghq list --exact --full-path "$selected")"
    BUFFER="cd ${(q)repo_dir}"
    zle accept-line
    zle -R -c # refresh screen
}
widget::ghq::session() {
    local selected="$(widget::ghq::select)"
    if [ -z "$selected" ]; then
        return
    fi

    local repo_dir="$(ghq list --exact --full-path "$selected")"
    local session_name="${selected//[:. ]/-}"

    if [ -z "$TMUX" ]; then
        BUFFER="tmux new-session -A -s ${(q)session_name} -c ${(q)repo_dir}"
        zle accept-line
    elif [ "$(tmux display-message -p "#S")" = "$session_name" ] && [ "$PWD" != "$repo_dir" ]; then
        BUFFER="cd ${(q)repo_dir}"
        zle accept-line
    else
        tmux new-session -d -s "$session_name" -c "$repo_dir" 2>/dev/null
        tmux switch-client -t "$session_name"
    fi
    zle -R -c # refresh screen
}

forward-kill-word() {
    zle vi-forward-word
    zle vi-backward-kill-word
}

zle -N widget::history
zle -N widget::ghq::dir
zle -N widget::ghq::session
zle -N forward-kill-word

bindkey "^R"        widget::history                 # C-r
bindkey "^G"        widget::ghq::session            # C-g
bindkey "^[g"       widget::ghq::dir                # Alt-g
bindkey "^A"        beginning-of-line               # C-a
bindkey "^E"        end-of-line                     # C-e
bindkey "^K"        kill-line                       # C-k
bindkey "^Q"        push-line-or-edit               # C-q
bindkey "^W"        vi-backward-kill-word           # C-w
bindkey "^X^W"      forward-kill-word               # C-x C-w
bindkey "^?"        backward-delete-char            # backspace
bindkey "^[[3~"     delete-char                     # delete
bindkey "^[[1;3D"   backward-word                   # Alt + arrow-left
bindkey "^[[1;3C"   forward-word                    # Alt + arrow-right
bindkey "^[^?"      vi-backward-kill-word           # Alt + backspace
bindkey "^[[1;33~"  kill-word                       # Alt + delete
bindkey -M vicmd "^A" beginning-of-line             # vi: C-a
bindkey -M vicmd "^E" end-of-line                   # vi: C-e



### directory stack ###
setopt pushd_ignore_dups # pushd したとき、ディレクトリがすでにスタックに含まれていればスタックに追加しない
setopt auto_pushd # cd [TAB] で以前移動したディレクトリを表示
DIRSTACKSIZE=100


# git のカラー表示
# git config --global color.ui auto # 一度だけ実行すればOK


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

# zsh-completions の設定。コマンド補完機能
autoload -Uz compinit
# Zinit用のcompinit最適化
() {
    local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
    if [[ $zcompdump -nt /usr/share/zsh ]] && [[ ! $zcompdump.zwc -ot $zcompdump ]]; then
        compinit -C
    else
        compinit
        [[ -f "$zcompdump" && ! -f "$zcompdump.zwc" ]] && zcompile "$zcompdump"
    fi
}

# [TAB] でパス名の補完候補を表示したあと、
# 続けて [TAB] を押すと候補からパス名を選択できるようになる
# 候補を選ぶには [TAB] か Ctrl-N,B,F,P
zstyle ':completion:*:default' menu select=1

# コマンドのスペルを訂正する
setopt correct

# '#' 以降をコメントとして扱う
setopt interactive_comments

### cdr ###
zstyle ':chpwd:*' recent-dirs-max 5000
zstyle ':chpwd:*' recent-dirs-default yes
zstyle ':completion:*' recent-dirs-insert both

function chpwd() { ls } # cd後 自動ls

# 拡張 glob を有効にする
# 拡張 glob を有効にすると # ~ ^ もパターンとして扱われる
# glob: パス名にマッチするワイルドカードパターンのこと
# ※ たとえば mv hoge.* ~/dir というコマンドにおける * のこと
setopt extended_glob

# 単語の一部として扱われる文字のセットを指定する
# ここではデフォルトのセットから / を抜いたものにしている
# ※ たとえば Ctrl-W でカーソル前の1単語を削除したとき / までで削除が止まる
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'


LC_CTYPE=en_US.UTF-8
LC_ALL=en_US.UTF-8




# Travis CI integration (if available)
[ -f "$HOME/.travis/travis.sh" ] && source "$HOME/.travis/travis.sh"




# >>> conda initialize >>>
# Lazy load conda to improve startup performance
load_conda() {
    __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
            . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
        else
            export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
        fi
    fi
    unset __conda_setup
    unset -f conda
    unset -f load_conda
}

# Create a wrapper function for conda
conda() {
    load_conda
    conda "$@"
}
# <<< conda initialize <<<


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
export PATH="$HOME/go/1.16.0/bin:$PATH"
# export PATH="$HOME/.nvm/versions/node/v18.17.1/bin:$PATH" # 削除: ハードコードされたNode.jsパス





## コマンドラインをエディタで起動する
bindkey '^y' edit-command-line

# viminsとemacsの共存
bindkey -M viins '\er' history-incremental-pattern-search-forward
bindkey -M viins '^?'  backward-delete-char
bindkey -M viins '^A'  beginning-of-line
#bindkey -M viins '^B'  backward-char
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

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/command:$PATH"
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

# Prevent duplicate PATH entries
typeset -U path PATH
setopt no_global_rcs
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"

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
zinit ice wait"1" lucid
zinit load zdharma-continuum/history-search-multi-word

# Two regular plugins loaded without investigating.
zinit ice wait"0a" lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

zinit ice wait"0b" lucid atinit"zpcompinit; zpcdreplay"
zinit light zdharma-continuum/fast-syntax-highlighting

#color theme
zinit ice wait"0c" lucid
zinit light simnalamburt/shellder

# Snippet
#zinit snippet https://gist.githubusercontent.com/hightemp/5071909/raw/
### End of Zinit's installer chunk

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"




# pnpm
# pnpm
export PNPM_HOME="/Users/zerebom/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# nvm を即座にロード（全てのnpmグローバルパッケージが即座に使える）
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# compinit は .zshenvまたは他の場所で一度だけ実行


. "$HOME/.cargo/env"



# bun completions
[ -s "/Users/zerebom/.bun/_bun" ] && source "/Users/zerebom/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Google Cloud SDK - lazy load
GCLOUD_SDK_PATH="$HOME/google-cloud-sdk"
if [ -d "$GCLOUD_SDK_PATH" ]; then
    export PATH="$GCLOUD_SDK_PATH/bin:$PATH"
    
    # Load completion only when gcloud is used
    gcloud() {
        unset -f gcloud
        [ -f "$GCLOUD_SDK_PATH/path.zsh.inc" ] && . "$GCLOUD_SDK_PATH/path.zsh.inc"
        [ -f "$GCLOUD_SDK_PATH/completion.zsh.inc" ] && . "$GCLOUD_SDK_PATH/completion.zsh.inc"
        gcloud "$@"
    }
fi

# Windsurf (if available)
[ -d "$HOME/.codeium/windsurf/bin" ] && export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# npm global
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$PATH:/path/to/osascript"
