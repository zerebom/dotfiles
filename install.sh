curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
sh -c "$(curl -fsSL https://starship.rs/install.sh)"
git clone https://github.com/x-motemen/ghq
#cd ghq
#make install
#cd ../
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
curl -L -O https://github.com/miiton/Cica/releases/download/v5.0.2/Cica_v5.0.2_with_emoji.zip
unzip Cica_v5.0.2_with_emoji.zip 
sudo mkdir  /usr/share/fonts/truetype/cica
sudo cp *.ttf /usr/share/fonts/truetype/cica/
sudo fc-cache -vf
zsh
