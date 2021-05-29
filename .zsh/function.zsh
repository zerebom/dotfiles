
function lint(){
	black --exclude="injection\.py|stageouts\.py" $1 --diff --check&&
	mypy $1&&
	flake8 --exclude=injection.py,stageouts.py $1
}

pss () {
    ps aux | grep -E "PID|$1" | grep -v grep
}

# serach prev command
function peco-history-selection() {
    BUFFER=`history -n 1 | tail -r | awk '!a[$0]++' | fzf `
        CURSOR=$#BUFFER    
        zle reset-prompt
}


# move to repos
function ghq-fzf() {
  local src=$(ghq list | fzf --preview "ls -laTp $(ghq root)/{} | tail -n+4 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}'")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}

# fbr - checkout git branch
fbr() {
  local branches branch
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# fbrm - checkout git branch (including remote branches)
fbrm() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fshow - git commit browser
fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

zle -N fbrm
bindkey '^B' fbrm

zle -N fshow
bindkey '^L' fshow

zle -N peco-history-selection 
bindkey '^R' peco-history-selection

zle -N ghq-fzf
bindkey '^]' ghq-fzf

