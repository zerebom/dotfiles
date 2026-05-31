#profiling
#zmodload zsh/zprof && zprof

#it can force /etc/z* files after /etc/zshenv to be skipped
setopt no_global_rcs

# homebrew インストール先（Apple Silicon は /opt/homebrew、Intel/Linux は環境ごと）
brewPrefix=""

case "$(uname)" in
  "Darwin")
    brewPrefix="/opt/homebrew"
    ;;
  "Linux")
    brewPrefix="/home/linuxbrew/.linuxbrew"
    if [ ! -d "$brewPrefix" ]; then
      brewPrefix="/home/$USER/.linuxbrew"
    fi
esac

if [ -f "$brewPrefix/bin/brew" ]; then
  eval $($brewPrefix/bin/brew shellenv)
fi

source $HOME/.zsh/exports.zsh
source $HOME/.zsh/aliases.zsh
[[ -f "$HOME/.zsh/secrets.zsh" ]] && source "$HOME/.zsh/secrets.zsh"

# rbenv
if [ -d "${HOME}/.rbenv" ]; then
  eval "$(rbenv init -)"
fi

# direnv
if type direnv > /dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
