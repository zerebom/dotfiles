

# すでにマージ済みのブランチを削除
# ref:https://qiita.com/ucan-lab/items/97c53a1a929d2858275b
PROTECT_BRANCHES='master|development|main'

function medicine () {
	echo '{"codes": ["610406079"], "search_date": { "year": 2022, "month": 11, "day": 11 } } }' | ./scripts/evans receipt-local cli call henryapp.receipt.MasterService.ListMedicines
}

git-delete-merged-branch() {
    git fetch --prune
    git branch --merged | egrep -v "\*|${PROTECT_BRANCHES}" | xargs git branch -d
}

#一括リント
function lint(){
	black --exclude="injection\.py|stageouts\.py" $1 --diff --check&&
	mypy --exclude="injection\.py|stageouts\.py" $1&&
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
function fbr() {
  local branches branch
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# fbrm - checkout git branch (including remote branches)
function fbrm() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fshow - git commit browser
function fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

# expand global aliases by space
# http://blog.patshead.com/2012/11/automatically-expaning-zsh-global-aliases---simplified.html
globalias() {
  if [[ $LBUFFER =~ ' [A-Z0-9]+$' ]]; then
    zle _expand_alias
    # zle expand-word
  fi
  zle self-insert
}

zle -N globalias

bindkey " " globalias

zle -N fbrm
bindkey '^B' fbrm

zle -N fshow
bindkey '^L' fshow

zle -N peco-history-selection
bindkey '^R' peco-history-selection

zle -N ghq-fzf
bindkey '^]' ghq-fzf

bindkey '^x' anyframe-widget-cdr


function cd() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local lsd=$(echo ".." && ls -p | grep '/$' | sed 's;/$;;')
        local dir="$(printf '%s\n' "${lsd[@]}" |
            fzf --reverse --preview '
                __cd_nxt="$(echo {})";
                __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")";
                echo $__cd_path;
                echo;
                ls -p --color=always "${__cd_path}";
        ')"
        [[ ${#dir} != 0 ]] || return 0
        builtin cd "$dir" &> /dev/null
    done
}
