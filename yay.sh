echo -n "Хотите установить пакеты для игр? (Y/n): "
  read GAMES_PACKAGE
  if [[ $GAMES_PACKAGE == y ]] || [[ $GAMES_PACKAGE == Y ]] || [[ $GAMES_PACKAGE == yes ]] || [[ $GAMES_PACKAGE == YES ]] || [[ $GAMES_PACKAGE == Yes ]]; then
    echo "Идет установка Steam..."
    pacman -S --needed --noconfirm steam
    clear
    
    echo "Идет установка discord..."
    pacman -S --needed --noconfirm discord
    clear
    
    echo "Идет установка gamemode..."
    pacman -S --needed --noconfirm gamemode
    clear

    echo "Идет установка yay..."
    pacman -S --needed --noconfirm git
    sed -i s/"$USERNAME ALL=(ALL) ALL"/"$USERNAME ALL=(ALL) NOPASSWD: ALL"/g /etc/sudoers.d/$USERNAME
    cd "/home/${USERNAME}" && sudo -u $USERNAME git clone https://aur.archlinux.org/yay.git && cd yay
    sudo -u $USERNAME makepkg -sri --needed --noconfirm
    cd .. && rm -rf yay
    clear
    
    echo "Идет установка mangohud-git и goverlay-git..."
    yay -S --needed --noconfirm mangohud-git goverlay-git
    sleep 4
    

    # Оптимизация OpenGL
    echo "__GL_THREADED_OPTIMIZATIONS=1" | tee -a /etc/environment
    echo "MESA_GL_VERSION_OVERRIDE=4.5" | tee -a /etc/environment
    echo "MESA_GLSL_VERSION_OVERRIDE=450" | tee -a /etc/environment
    
    sed -i s/"$USERNAME ALL=(ALL) NOPASSWD: ALL"/"$USERNAME ALL=(ALL) ALL"/g /etc/sudoers.d/$USERNAME
  else
    :
  fi
  clear
