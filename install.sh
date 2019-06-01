#!/bin/bash

headless="false"

echo "$@" > target

# Parse options
while getopts ":hc" opt; do
  case ${opt} in
    h )
      echo "Usage:"
      echo "    ./install.sh [target]"
      echo ""
      echo "    ./install.sh -h           Display this help message."
      echo "    ./install.sh -c           Install for a headless system."
      exit 0
      ;;
    c )
      echo "Installing headless"
      headless="true"
      ;; 
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

shopt -s dotglob nullglob

git pull > /dev/null
git submodule init > /dev/null
git submodule update --recursive --remote > /dev/null
mkdir -p ~/.config/

if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
  curl -L -o ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi


target=$1; shift  # Remove 'install.sh' from the argument list

install_target() {
  path="$PWD/additional/$target"
  #TODO
  ln -sfn $path/* ~/
  echo "Installing $target"
}

case "$target" in
  main)
    install_target
    ;;
  brown_cs)
    install_target
    ;;
  brown_ccv)
    install_target
    ;;
  devbox)
    install_target
    ;;
  "")
    ;;
  *)
    echo "Invalid target."
    exit 1
    ;;
esac

ln -sfn "$PWD/nvim" ~/.config/
ln -sfn "$PWD/bat" ~/.config/
ln -sfn "$PWD/rtv" ~/.config/
ln -sfn "$PWD/mutt" ~/.mutt
ln -sfn "$PWD/fzf_ros" ~/.fzf_ros
ln -sfn "$PWD/scripts" ~/
ln -sfn "$PWD/.profile" ~/
ln -sfn "$PWD/.cvsignore" ~/
ln -sfn "$PWD/.gitconfig_base" ~/
ln -sfn "$PWD/.muttrc" ~/
mkdir -p ~/.ssh
ln -sfn "$PWD/ssh_config" ~/.ssh/config

if [[ "$headless" == "false" ]]; then
  echo "Installing headed"
  ln -sfn "$PWD/.xinitrc" ~/
  ln -sfn "$PWD/i3" ~/.config/
  ln -sfn "$PWD/i3status" ~/.config/
  ln -sfn "$PWD/keyboard" ~/
  ln -sfn "$PWD/qutebrowser" ~/.config/
  ln -sfn "$PWD/compton" ~/.config/
  ln -sfn "$PWD/flashfocus" ~/.config/
  mkdir -p ~/.local/etc/
  ln -sfn "$PWD/st" ~/.local/etc/
  ln -sfn "$PWD/zathura" ~/.config/
  mkdir -p ~/.local/share/
  ln -sfn "$PWD/applications" ~/.local/share/
  ln -sfn "$PWD/mimeapps.list" ~/.config
  ln -sfn "$PWD/user-dirs.dirs" ~/.config
  a="@reboot bash -c 'source $PWD/.profile && $PWD/scripts/keyboard_setup' &"
  keyboard_job="$a"
else
  keyboard_job=""
fi 

c_start="#start dotfiles install DON'T DELETE THIS COMMENT"
mail="MAILTO=ryan_greenblatt@brown.edu"
hourly_job="cd $PWD && ./autoinstall.sh"
install_job="0 4 * * * $hourly_job"
c_end="#end dotfiles install DON'T DELETE THIS COMMENT"

full=$(printf "\n%s\n%s\n%s\n%s\n%s\n " "$c_start" "$mail" "$keyboard_job" \
  "$install_job" "$c_end") 

current_cron=$(crontab -l 2>/dev/null)

line_start=$(echo "$current_cron" | grep -Fn -m 1 "$c_start" | 
  grep -Eo '^[^:]+')
exit_status=$?
if [ "$exit_status" -eq 0 ]; then

  line_end=$(echo "$current_cron" | grep -Fn -m 1 "$c_end" | 
    grep -Eo '^[^:]+')
  exit_status=$?
  if [ $exit_status -ne 0 ]; then
    >&2 echo "first cron tab comment found, but second wasn't found, exiting"
    exit 1
  fi
  sed_end=d
  current_cron=$(echo "$current_cron" | sed -e "$line_start,$line_end$sed_end")
else
  echo "cron jobs not found, adding"
fi

echo "$current_cron$full" | crontab -

if hash zsh 2> /dev/null; then
  echo "zsh is installed"
  if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then 
    echo ".zshrc must be deleted or moved before install"
    exit 1
  fi
  if [ -f "$HOME/.zimrc" ] && [ ! -L "$HOME/.zimrc" ]; then 
    echo ".zimrc must be deleted or moved before install"
    exit 1
  fi
  if [ -f "$HOME/.zlogin" ] && [ ! -L "$HOME/.zlogin" ]; then 
    echo ".zlogin must be deleted or moved before install"
    exit 1
  fi
  ./zimfw/install.sh > /dev/null
  rm -f ~/.zshrc ~/.zimrc ~/.zlogin
  ln -sfn "$PWD/.zshrc" ~/
  ln -sfn "$PWD/.zimrc" ~/
  ln -sfn "$PWD/.zlogin" ~/

  if [ ! -d ~/.zgen ]; then
    git clone https://github.com/tarjoilija/zgen.git "$HOME/.zgen"
  fi
fi
