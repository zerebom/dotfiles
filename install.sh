#!/bin/bash

cd ~
#cd ~
if ! which zsh ; then
	apt install zsh -y
fi

apt-get update
yes | apt-get install exa
yes | apt-get install neovim
yes | curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
yes | sh -c "$(curl -fsSL https://starship.rs/install.sh)"
git clone https://github.com/x-motemen/ghq
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
yes | ~/.fzf/install
#curl -L -O https://github.com/miiton/Cica/releases/download/v5.0.2/Cica_v5.0.2_with_emoji.zip
#unzip Cica_v5.0.2_with_emoji.zip
#sudo mkdir  /usr/share/fonts/truetype/cica
#sudo cp *.ttf /usr/share/fonts/truetype/cica/
#sudo fc-cache -vf
cd /dotfiles
make install
zsh
