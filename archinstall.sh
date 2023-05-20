#!/bin/bash

# Убеждаемся, что интернет-соединение работает
ping -c 3 www.archlinux.org
if [ $? -ne 0 ]; then
  echo "Отсутствует интернет-соединение. Подключитесь к сети и повторите попытку."
  exit 1
fi


pacman -Sy --needed --noconfirm archlinux-keyring


sed -i s/'#en_US.UTF-8'/'en_US.UTF-8'/g /etc/locale.gen
sed -i s/'#ru_RU.UTF-8'/'ru_RU.UTF-8'/g /etc/locale.gen
echo 'LANG=ru_RU.UTF-8' > /etc/locale.conf
echo 'KEYMAP=ru' > /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf
setfont cyr-sun16
locale-gen >/dev/null 2>&1; RETVAL=$?
systemctl restart dhcpcd
dhcpcd


# Обновляем системные часы
timedatectl set-ntp true
clear


# Приветствие 
cat <<EOF
       /\\
      /  \\                   Установка Arch Linux 
     /\\   \\      Скрипт писал Avelle (https://github.com/Av3lle)
    /  ..  \\              Telegram (@STANISLAWSKIY9)
   /  '  '  \\
  / ..'  '.. \\
 /_\`        \`_\\
                                    Wrning!!! 
                     Это альфа версия скрипта для утсановки, 
                 в случае каких-либо проблем обращайтесь к автору.
EOF


# Выбираем диск для установки
echo $'\n1 - Автоматическая усановка   2 - Ручная установка'
echo -n "Выберите режим установки: "
read AUTO

clear
lsblk
if [[ $AUTO == 1 ]]; then
  echo $'\n1 - UEFI   2 - BIOS'
  echo -n "Выберите один из вариантов: "

  # Выбор диска для автоматической установки 
  echo -n $'\nВыберите диск для установки (Например: nvme0n1): '
  read DRIVE_AUTO

  echo $'\n1 - ext4   2 - btrfs   3 - xfs'
  echo -n 'Выберите тип файловой сисетемы: '
  read FILE_SYSTEM

  echo -n $'\nВведите размер swap файла без еденицы измерения (Размер измеряется в GiB, например: 8 = 8GiB): '
  read SWAP

  if [[ $UB == 1 ]]; then
    parted --script /dev/${DRIVE_AUTO} mklabel gpt
    parted --script /dev/${DRIVE_AUTO} mkpart EFI fat32 1MiB 512MiB
    mkfs.vfat -F32 /dev/${DRIVE_AUTO}1
    parted --script /dev/${DRIVE_AUTO} set 1 esp on
    parted --script /dev/${DRIVE_AUTO} mkpart swap linux-swap 512MiB ${SWAP}GiB
  else
    parted --script /dev/${DRIVE_AUTO} mklabel gpt
    parted --script /dev/${DRIVE_AUTO} mkpart BIOS ext4 1MiB 100MiB
    mkfs.ext4 /dev/${DRIVE_AUTO}1
    parted --script /dev/${DRIVE_AUTO} set 1 boot on
    parted --script /dev/${DRIVE_AUTO} mkpart swap linux-swap 100MiB ${SWAP}GiB
  fi
  
  if [[ $FILE_SYSTEM == 1 ]] || [[ $FILE_SYSTEM == ext4 ]] || [[ $FILE_SYSTEM == Ext4 ]] || [[ $FILE_SYSTEM == EXT4 ]]; then
    parted --script /dev/${DRIVE_AUTO} mkpart root ext4 ${SWAP}GiB 100%
    mkfs.ext4 /dev/${DRIVE_AUTO}3
  elif [[ $FILE_SYSTEM == 2 ]] || [[ $FILE_SYSTEM == btrfs ]] || [[ $FILE_SYSTEM == Btrfs ]] || [[ $FILE_SYSTEM == BTRFS ]]; then
    parted --script /dev/${DRIVE_AUTO} mkpart root btrfs ${SWAP}GiB 100%
    mkfs.btrfs /dev/${DRIVE_AUTO}3
  elif [[ $FILE_SYSTEM == 3 ]] || [[ $FILE_SYSTEM == xfs ]] || [[ $FILE_SYSTEM == Xfs ]] || [[ $FILE_SYSTEM == XFS ]]; then
    parted --script /dev/${DRIVE_AUTO} mkpart root xfs ${SWAP}GiB 100%
    mkfs.xfs /dev/${DRIVE_AUTO}3
  else
    echo "Произошла ошибка! Будет выбран ext4!"
    sleep 2
    parted --script /dev/${DRIVE_AUTO} mkpart root ext4 ${SWAP}GiB 100%
    mkfs.ext4 /dev/${DRIVE_AUTO}3
  fi

  # Монтирование и создание необходимых директорий
  if [[ $UB == 1 ]]; then
    mount /dev/${DRIVE_AUTO}3 /mnt
    mkdir /mnt/boot
    mkdir /mnt/boot/efi
    mount /dev/${DRIVE_AUTO}1 /mnt/boot/efi
  else
    mount /dev/${DRIVE_AUTO}3 /mnt
    mkdir /mnt/boot
    mount /dev/${DRIVE_AUTO}1 /mnt/boot
  fi

  # Подключение swap раздела
  mkswap /dev/${DRIVE_AUTO}2
  swapon /dev/${DRIVE_AUTO}2
else
  echo -n $'\nВыберите диск для установки (Например: nvme0n1): '
  read DRIVE

  echo $'\n1 - fdisk    2 - parted    3 - gdisk    4 - cfdisk'
  echo -n "Выберите утилиту для того чтобы разбить диски(и) на раздел(ы): "
  read PARTITION_UTIL

  if [[ $PARTITION_UTIL == 1 ]] || [[ $PARTITION_UTIL == fdisk ]] || [[ $PARTITION_UTIL == Fdisk ]] || [[ $PARTITION_UTIL == FDISK ]]; then
    fdisk /dev/${DRIVE}
  elif [[ $PARTITION_UTIL == 2 ]] || [[ $PARTITION_UTIL == parted ]] || [[ $PARTITION_UTIL == Parted ]] || [[ $PARTITION_UTIL == PARTED ]]; then
    parted /dev/${DRIVE}
  elif [[ $PARTITION_UTIL == 3 ]] || [[ $PARTITION_UTIL == gdisk ]] || [[ $PARTITION_UTIL == Gdisk ]] || [[ $PARTITION_UTIL == GDISK ]]; then
    gdisk /dev/${DRIVE}
  elif [[ $PARTITION_UTIL == 4 ]] || [[ $PARTITION_UTIL == cfdisk ]] || [[ $PARTITION_UTIL == Cfdisk ]] || [[ $PARTITION_UTIL == CFDISK ]]; then
    cfdisk /dev/${DRIVE}
  else
    echo "Произошла ошибка! Будет выбран cfdisk!"
    sleep 2
    cfdisk $DRIVE
  fi


  # Выбираем тип файловой системы
  clear
  echo "1 - ext4   2 - btrfs   3 - xfs"
  echo -n "Выберите тип файловой сисетемы: "
  read FILE_SYSTEM
  clear

  lsblk
  echo -n "Выберите загрузочный раздел (Например: sda1): "
  read BOOT_PARTITION

  echo -n "Выберите корневой раздел (Например: sda2): "
  read ROOT_PARTITION

  mkfs.vfat -F32 /dev/${BOOT_PARTITION}
  if [[ $FILE_SYSTEM == 1 ]] || [[ $FILE_SYSTEM == ext4 ]] || [[ $FILE_SYSTEM == Ext4 ]] || [[ $FILE_SYSTEM == EXT4 ]]; then
    mkfs.ext4 /dev/${ROOT_PARTITION}
  elif [[ $FILE_SYSTEM == 2 ]] || [[ $FILE_SYSTEM == btrfs ]] || [[ $FILE_SYSTEM == Btrfs ]] || [[ $FILE_SYSTEM == BTRFS ]]; then
    mkfs.btrfs /dev/${ROOT_PARTITION}
  elif [[ $FILE_SYSTEM == 3 ]] || [[ $FILE_SYSTEM == xfs ]] || [[ $FILE_SYSTEM == Xfs ]] || [[ $FILE_SYSTEM == XFS ]]; then
    mkfs.xfs /dev/${ROOT_PARTITION}
  else
    echo "Произошла ошибка! Будет выбран ext4!"
    sleep 2
    mkfs.ext4 mkfs.ext4 /dev/${ROOT_PARTITION}
  fi

  # Монтируем корневой раздел + создаем каталоги
  mount /dev/${ROOT_PARTITION} /mnt
  mkdir /mnt/boot
  mkdir /mnt/boot/efi
  mount /dev/${BOOT_PARTITION} /mnt/boot/efi


  # Запрашиваем у пользователя монтирование домашнего каталога в другой раздел
  echo -n "Хотите монтирвать домашний каталог на другой раздел? (Y/n): "
  read HOME

  if [[ $HOME == Y ]] || [[ $HOME == yes ]] || [[ $HOME == Yes ]] || [[ $HOME == YES ]] || [[ $HOME == y ]] || [[ $HOME == д ]] || [[ $HOME == да ]] || [[ $HOME == Да ]] || [[ $HOME == ДА ]]; then
    echo -n "Укажите раздел для монтирвания (Например: sda3): "
    read HOME_PARTITION
    echo "Идет монтирвание '/home' в дургой раздел..."
    mkdir /mnt/home
    mount /dev/${HOME_PARTITION} /mnt/home
    sleep 2
  else
    :
  fi
fi


# Проверяем созданные нами разделы 
clear
echo "Проверьте разделы! "
lsblk
sleep 5
clear


# Выбор ядра Linux и его установка
#echo "1 - linux-lts   2 - linux-zen   3 - linux-xanmod   4 - linux-lqx"
echo "1 - linux   2 - linux-lts   3 - linux-zen"
echo -n "Выберите ядро для установки: "
read KERNEL

echo "Идет установка ядра..."
if [[ $KERNEL == 2 ]] || [[ $KERNEL == linux-lts ]] || [[ $KERNEL == Linux-lts ]] || [[ $KERNEL == LINUX-LTS ]]; then
  pacstrap /mnt base base-devel linux-firmware linux-lts linux-lts-headers
elif [[ $KERNEL == 3 ]] || [[ $KERNEL == linux-zen ]] || [[ $KERNEL == Linux-zen ]] || [[ $KERNEL == LINUX-ZEN ]]; then
  pacstrap /mnt base base-devel linux-firmware linux-zen linux-zen-headers
elif [[ $KERNEL == 1 ]] || [[ $KERNEL == linux ]] || [[ $KERNEL == Linux ]] || [[ $KERNEL == LINUX ]]; then
  pacstrap /mnt base base-devel linux-firmware linux linux-headers
fi


# Генерируем файл fstab
clear
echo "Идет генерация fstab"
genfstab -U /mnt >> /mnt/etc/fstab
clear
cat < /mnt/etc/fstab
sleep 5
lsblk
sleep 5
clear


# Исполнение скрипта в chroot начиная с part2
sed '1,/^#part2$/d' archinstall.sh > /mnt/post_archinstall.sh
chmod +x /mnt/post_archinstall.sh
arch-chroot /mnt ./post_archinstall.sh 1


#part2

if [[ $1 = 1 ]]; then
  # Устанавливаем язык
  echo $'\nИдет настройка локалей...'
  echo $'en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8' > /etc/locale.gen

  locale-gen

  echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
  echo $'KEYMAP=ru\nFONT=cyr-sun16' > /etc/vconsole.conf


  # Настройка даты и времении
  echo $'\nИдет настройка даты и времени, по умолчанию МСК...'
  ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
  hwclock --systohc --utc
  sleep 2


  # Устанавливаем и настраиваем сеть
  echo "Идет настройка сети..."
  pacman -S --needed --noconfirm networkmanager iwd nano
  systemctl enable NetworkManager
  systemctl enable iwd.service


  # Устанавливаем загрузчик
  clear
  echo "Идет настройка загрузчика..."
  lsblk

  pacman -S --needed --noconfirm grub efibootmgr
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
  grub-mkconfig -o /boot/grub/grub.cfg
  sleep 5
  clear


  # Создание пароля для root
  echo "Введите пароль для вашего root пользователя: "
  passwd
  sleep 1
  clear


  # Создание пользователя, назначение пароля и выдача привелегий
  echo -n "Введите желаемое имя компьютера: "
  read HOSTNAME
  echo $HOSTNAME > /etc/hostname

  echo -n "Введите желаемое имя пользователя: "
  read USERNAME
  useradd -m -g users -G wheel,audio,video $USERNAME

  echo "Введите пароль для пользователя $USERNAME"
  passwd $USERNAME
  sleep 2

  echo "Выдача привелегий для $USERNAME и группе wheel!"
  echo "$USERNAME ALL=(ALL) ALL" >> /etc/sudoers.d/$USERNAME
  echo $'\n%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers
  sleep 2
  clear

  echo "Идет настройка файла /etc/hosts"
  echo "127.0.0.1       localhost" >> /etc/hosts
  echo "::1             localhost" >> /etc/hosts
  echo "127.0.1.1       $HOSTNAME" >> /etc/hosts
  cat < /etc/hosts
  sleep 4
  clear


  # Настройка reflector
  echo "Идет настройка зеркал..."
  pacman -Syy reflector archlinux-keyring --noconfirm
  reflector --sort rate -l 20 --save /etc/pacman.d/mirrorlist
  pacman-mirrors --fasttrack
  sleep 3
  clear


  # multilib rep enable
  echo "Добавление multilib репозитория..."
  sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf


  # Настройка pacman.conf
  sed -i s/'#ParallelDownloads = 5'/'ParallelDownloads = 5'/g /etc/pacman.conf
  sed -i s/'#VerbosePkgLists'/'VerbosePkgLists'/g /etc/pacman.conf
  sed -i s/'#Color'/'ILoveCandy'/g /etc/pacman.conf
  sed -i s/'CheckSpace'/'#CheckSpace'/g /etc/pacman.conf
  sed -i s/'#VerbosePkgLists'/'VerbosePkgLists'/g /etc/pacman.conf
  pacman -Sy
  sleep 2
  clear


  # Настройка makepkg
  echo "Идет настройка makepkg..."
  sed -i s/'CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"'/'CXXFLAGS="-march=native -mtune=native -O2 -pipe -fno-plt"'/g /etc/makepkg.conf
  sed -i s/'#RUSTFLAGS="-C opt-level=2"'/'RUSTFLAGS="-C opt-level=2 -C target-cpu=native"'/g /etc/makepkg.conf
  sed -i s/'MAKEFLAGS="-j2"'/'MAKEFLAGS="-j$(($(nproc)+1))"'/g /etc/makepkg.conf
  sed -i s/'BUILDENV=(!distcc color !ccache check !sign)'/'BUILDENV=(!distcc color ccache check !sign)'/g /etc/makepkg.conf
  fileName="/etc/makepkg.conf"
  flags="\"-march=native -mtune=native -O2 -pipe -fno-plt\""

  CFLAGSline=`grep -hnr "\"" $fileName | grep CFLAGS | cut -d ":" -f1 |head -n1`
  for (( i=$CFLAGSline+1;i<`wc -l $fileName|cut -d " " -f1`;i++ )) {
    output=`sed -n "$i p" $fileName`
    if [[ `echo $output | grep "\""` ]];then
      break
    fi
  }
  sed -i "s/CFLAGS=.*/CFLAGS=$flags/" $fileName
  sed -i "$(($CFLAGSline+1)),$i d" $fileName


  # Установка micro-code
  cpu=$(cat /proc/cpuinfo | grep -m 1 "model name" | cut -c 14)
  if [[ $cpu == A ]]; then
    echo "Идет установка amd-ucode..."
    pacman -S --needed --noconfirm amd-ucode
  else
    echo "Идет установка intel-ucode..."
    pacman -S --needed --noconfirm intel-ucode
  fi
  echo "Пересобираем образы initramfs..."
  sudo mkinitcpio -P
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  sleep 4
  clear


  # Установка звукового драйвера
  echo "1 - PulseAudio   2 - PipeWire   3 - Alsa"
  echo -n "Выберите звуковой драйвер: "
  read AUDIO_DRIVER

  if [[ $AUDIO_DRIVER == 1 ]] || [[ $AUDIO_DRIVER == pulse ]] || [[ $AUDIO_DRIVER == Pulse ]] || [[ $AUDIO_DRIVER == PULSE ]]; then
    echo "Идет установка PulseAudio"
    pacman -S --needed --noconfirm pulseaudio pulseaudio-alsa pulseaudio-jack pavucontrol
  elif [[ $AUDIO_DRIVER == 2 ]] || [[ $AUDIO_DRIVER == pipe ]] || [[ $AUDIO_DRIVER == Pipe ]] || [[ $AUDIO_DRIVER == PIPE ]]; then
    echo "Идет установка PipeWire"
    pacman -S --needed --noconfirm pacman -S pipewire pipewire-alsa pipewire-jack lib32-pipewire lib32-pipewire-jack libpulse lib32-libpulse xdg-desktop-portal pavucontrol
    systemctl enable --now pipewire
  elif [[ $AUDIO_DRIVER == 3 ]] || [[ $AUDIO_DRIVER == alsa ]] || [[ $AUDIO_DRIVER == Alsa ]] || [[ $AUDIO_DRIVER == ALSA ]]; then
    echo "Идет установка Alsa"
    pacman -S --needed --noconfirm alsa-utils alsa-firmware alsa-card-profiles alsa-plugins pavucontrol
  else
    echo "Произошла ошибка! Выбран звуковой драйвер Alsa"
  fi
  sleep 6
  clear


  # Выбор видео драйвера
  echo "1 - AMD   2 - Nvidia   3 - Intel"
  echo -n "Выберите производителя вашей видеокарты для установки драйвера: "
  read VIDEO_DRIVER
  if [[ $VIDEO_DRIVER == 1 ]] || [[ $VIDEO_DRIVER == amd ]] || [[ $VIDEO_DRIVER == Amd ]] || [[ $VIDEO_DRIVER == AMD ]]; then
    echo $'\nИдет установка драйверов на AMD...'
    pacman -S --needed --noconfirm xf86-video-ati xf86-video-amdgpu mesa mesa-demos lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader amdvlk lib32-amdvlk network-manager-applet
  elif [[ $VIDEO_DRIVER == 2 ]] || [[ $VIDEO_DRIVER == nvidia ]] || [[ $VIDEO_DRIVER == Nvidia ]] || [[ $VIDEO_DRIVER == NVIDIA ]]; then
    echo $'\n1 - Проприетарный драйвер   2 - Open source драйвер'
    echo -n "Выберите тип драйверов: "
    read NVIDIA
    if [[ $NVIDIA == 1 ]]; then
      echo "Идет установка проприетарного драйвера..."
      pacman -S --needed --noconfirm mesa mesa-demos lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader nvidia-dkms nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader lib32-opencl-nvidia opencl-nvidia network-manager-applet nvidia-settings
    elif [[ $NVIDIA == 2 ]]; then
      echo "Идет установка Open source драйвера..."
      pacman -S --needed --noconfirm mesa mesa-demos lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader xf86-video-nouveau nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader lib32-opencl-nvidia opencl-nvidia network-manager-applet nvidia-settings
    else
      :
    fi
  elif [[ $VIDEO_DRIVER == 3 ]] || [[ $VIDEO_DRIVER == intel ]] || [[ $VIDEO_DRIVER == Intel ]] || [[ $VIDEO_DRIVER == INTEL ]]; then
    echo $'\nИдет установка драйверов на Intel...'
    pacman -S --needed --noconfirm mesa mesa-demos xf86-video-intel lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader network-manager-applet libva-intel-driver lib32-libva-intel-driver
  else
    :
  fi
  sleep 4
  clear


  # Установка графического окружения и сервера отображения Xorg
  echo $'1 - DE \n2 - WM \n3 - No desktop'
  echo -n "Выберите рабочее окружение: "
  read DESKTOP

  if [[ $DESKTOP == 1 ]] || [[ $DESKTOP == de ]] || [[ $DESKTOP == DE ]]; then
    echo $'\n1 - Gnome   2 - Gnome (minimal)   3 - KDE   4 - KDE (Minimal)   5 - Xfce   6 - Xfce (Minimal)'
    echo -n "Выберите графической окружение из перечисленных: "
    read DE
    pacman -S --needed --noconfirm xorg xorg-server firefox
    if [[ $DE == 1 ]] || [[ $DE == gnome ]] || [[ $DE == Gnome ]] || [[ $DE == GNOME ]]; then
      pacman -S --needed --noconfirm gnome gnome-extra gdm
      systemctl enable gdm.service
    elif [[ $DE == 2 ]] || [[ $DE == gnome_minimal ]] || [[ $DE == Gnome_minimal ]] || [[ $DE == GNOME_MINIMAL ]]; then
      pacman -S --needed --noconfirm gnome nautilus gnome-terminal gdm
      systemctl enable gdm.service
    elif [[ $DE == 3 ]] || [[ $DE == kde ]] || [[ $DE == Kde ]] || [[ $DE == KDE ]]; then
      pacman -S --needed --noconfirm plasma plasma-wayland-session kde-applications
      systemctl enable sddm.service
    elif [[ $DE == 4 ]] || [[ $DE == kde_minimal ]] || [[ $DE == Kde_minimal ]] || [[ $DE == KDE_MINIMAL ]]; then
      pacman -S --needed --noconfirm plasma plasma-wayland-session konsole dolphin
      systemctl enable sddm.service
    elif [[ $DE == 5 ]] || [[ $DE == xfce ]] || [[ $DE == Xfce ]] || [[ $DE == XFCE ]]; then
      pacman -S --needed --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
      systemctl enable lightdm.service
    elif [[ $DE == 6 ]] || [[ $DE == xfce_minimal ]] || [[ $DE == Xfce_minimal ]] || [[ $DE == XFCE_MINIMAL ]]; then
      pacman -S --needed --noconfirm xfce4 thunar mousepad xfce4-terminal lightdm lightdm-gtk-greeter
      systemctl enable lightdm.service
    else
      echo "Произошла ошибка. Был выбран вариант без рабочего окружения."
    fi
  elif [[ $DESKTOP == 2 ]] || [[ $DESKTOP == wm ]] || [[ $DESKTOP == WM ]]; then
    echo $'\n1 - i3   2 - bspwm   3 - openbox   4 - xmonad   5 - awesome'
    echo -n "Выберите оконный менеджер из перечисленных: "
    read WM
    pacman -S --needed --noconfirm xorg xorg-server lightdm lightdm-gtk-greeter
    systemctl enable lightdm.service
    sleep 2
    pacman -S --needed --noconfirm xterm alacritty mousepad dmenu thunar firefox
    if [[ $WM == 1 ]] || [[ $WM == i3 ]] || [[ $WM == I3 ]]; then
      pacman -S --needed --noconfirm i3
    elif [[ $WM == 2 ]] || [[ $WM == bspwm ]] || [[ $WM == Bspwm ]] || [[ $WM == BSPWM ]]; then
      pacman -S --needed --noconfirm bspwm
    elif [[ $WM == 3 ]] || [[ $WM == openbox ]] || [[ $WM == Openbox ]] || [[ $WM == OPENBOX ]]; then
      pacman -S --needed --noconfirm openbox
    elif [[ $WM == 4 ]] || [[ $WM == xmonad ]] || [[ $WM == Xmonad ]] || [[ $WM == XMONAD ]]; then
      pacman -S --needed --noconfirm xmonad
    elif [[ $WM == 5 ]] || [[ $WM == awesome ]] || [[ $WM == Awesome ]] || [[ $WM == AWESOME ]]; then
      pacman -S --needed --noconfirm awesome
    else
      echo "Произошла ошибка. На вашу систему будет установлен i3"
      pacman -S --needed --noconfirm i3
      sleep 2
    fi
  else
    :
  fi
  clear

  
  echo "Идет установка необходимых шрифтов..."
  pacman -S --needed --noconfirm ttf-liberation ttf-dejavu noto-fonts noto-fonts-emoji
  clear
  
  
  # Установка yay, gamemode, mangohud, goverlay
  echo -n "Хотите установить пакеты для игр? (Y/n): "
  read GAMES_PACKAGE
  if [[ $GAMES_PACKAGE == y ]] || [[ $GAMES_PACKAGE == Y ]] || [[ $GAMES_PACKAGE == yes ]] || [[ $GAMES_PACKAGE == YES ]] || [[ $GAMES_PACKAGE == Yes ]]; then
    echo "Идет установка Steam..."
    pacman -S --needed --noconfirm steam
    
    echo "Идет установка discord..."
    pacman -S --needed --noconfirm discord
    
    echo "Идет установка gamemode..."
    pacman -S --needed --noconfirm gamemode

    echo "Идет установка yay..."
    pacman -S --needed --noconfirm git ccache ninja
    sed -i s/"%wheel ALL=(ALL:ALL) ALL"/"%wheel ALL=(ALL:ALL) NOPASSWD: ALL"/g /etc/sudoers
    cd "/home/${USERNAME}" && sudo -u $USERNAME git clone https://aur.archlinux.org/yay.git && cd yay
    sudo -u $USERNAME makepkg -sri --needed --noconfirm
    cd .. && rm -rf yay
    clear

    echo "Идет установка mangohud-git..."
    sudo -u $USERNAME yay -S --needed --noconfirm mangohud-git 
    clear

    echo "Идет установка goverlay-git..."
    sudo -u $USERNAME yay -S --needed --noconfirm goverlay-git

    sleep 4

    # Оптимизация OpenGL
    echo "__GL_THREADED_OPTIMIZATIONS=1" | tee -a /etc/environment
    echo "MESA_GL_VERSION_OVERRIDE=4.5" | tee -a /etc/environment
    echo "MESA_GLSL_VERSION_OVERRIDE=450" | tee -a /etc/environment
    
    sed -i s/"%wheel ALL=(ALL:ALL) NOPASSWD: ALL"/"%wheel ALL=(ALL:ALL) ALL"/g /etc/sudoers
  else
    :
  fi
  clear


  # Systemd
  sed -i s/'#SystemMaxUse='/'SystemMaxUse=1'/g /etc/systemd/journald.conf
  sed -i s/'#SystemMaxFileSize='/'SystemMaxFileSize=1'/g /etc/systemd/journald.conf
  sed -i s/'#SystemMaxFiles=100'/'SystemMaxFiles=1'/g /etc/systemd/journald.conf
  sed -i s/'#RuntimeMaxUse='/'RuntimeMaxUse=1'/g /etc/systemd/journald.conf
  sed -i s/'#RuntimeMaxFileSize='/'RuntimeMaxFileSize=1'/g /etc/systemd/journald.conf
  sed -i s/'#RuntimeMaxFiles=100'/'RuntimeMaxFiles=1'/g /etc/systemd/journald.conf
  sed -i s/'#ForwardToSyslog=no'/'ForwardToSyslog=no'/g /etc/systemd/journald.conf
  sed -i s/'#ForwardToWall=yes'/'ForwardToWall=yes'/g /etc/systemd/journald.conf
  journalctl --vacuum-size=1M
  journalctl --verify
  clear

  # Установка доп. пакетов по желанию пользователя
  echo -n "Хотите установить доп. пакеты в систему? (Y/n): "
  read CUSTOM_PACK
  if [[ $CUSTOM_PACK == y ]] || [[ $CUSTOM_PACK == Y ]] || [[ $CUSTOM_PACK == yes ]] || [[ $CUSTOM_PACK == YES ]] || [[ $CUSTOM_PACK == Yes ]]; then
    echo -n "Впишите пакеты через пробел, которые хотите установить: "
    read PACK
    pacman -S --needed --noconfirm $PACK
    sleep 4
  else
    :
  fi


  clear
  pacman -Scc --needed --noconfirm
  yay -Scc --needed --noconfirm
  sleep 4
  exit
else
  umount -R /mnt
  rm -rf /post_archinstall.sh
  clear 
  echo "Система будет перезагружена через 10 сек."
  sleep 10
  reboot
fi
