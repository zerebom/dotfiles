curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
sh -c "$(curl -fsSL https://starship.rs/install.sh)"
git clone https://github.com/x-motemen/ghq
#cd ghq
#make install
#cd ../
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

