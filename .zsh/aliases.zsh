alias his='history'
alias ...='cd ../..'
alias ....='cd ../../..'
alias e="emacs"
alias vim='nvim'
alias v='nvim'
alias vi='nvim'
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
alias gcam='git commit -a -m'
alias gpo='git push origin'
alias gpom='git push origin master'
alias gst='git stash'
alias gsl='git stash list'
alias gsu='git stash -u'
alias gsp='git stash pop'

# docker
alias d=‘docker’
alias dc=‘docker-compose’
alias dcnt=‘docker container’
alias dcur=‘docker container ls -f status=running -l -q’
alias dexec=‘docker container exec -it $(dcur)’
alias dimg=‘docker image’
alias drun=‘docker container run —rm -d’
alias drunit=‘docker container run —rm -it’
alias dstop=‘docker container stop $(dcur)’

alias dot='cd ~/.dotfiles'
alias .zsh='cd ~/.dotfiles/.zsh'
alias vidot='cd ~/.dotfiles|vim' 

alias -g @g="| ag"
alias -g @l="| less"
