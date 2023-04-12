#!/bin/bash

# Убеждаемся, что интернет-соединение работает
ping -c 3 www.archlinux.org
if [ $? -ne 0 ]; then
  echo "Отсутствует интернет-соединение. Подключитесь к сети и повторите попытку."
  exit 1
fi

pacman -Sy --needed --noconfirm archlinux-keyring

# Обновляем системные часы
timedatectl set-ntp true
clear



#   UEFI
#echo "Выберите диск для установки: "
#lsblk
#read DRIVE
#parted --script ${DRIVE} mktable gpt
#parted --script ${DRIVE} mkpart "EFI system partition" fat32 1MiB 512MiB
#parted --script ${DRIVE} set 1 esp on
#parted --script ${DRIVE} mkpart "root partition" ext4 512MiB 100%
#mkfs.vfat -F32 ${DRIVE}1
#mkfs.ext4 ${DRIVE}2

#   BIOS
#parted --script ${DRIVE} mkpart primary ext4 1MiB 100%
#parted --script ${DRIVE} set 1 boot on



lsblk
echo -n "Выберите диск для установки (Например: /dev/nvme0n1): "
read DRIVE

echo "Выберите утилиту для того чтобы разбить диски(и) на раздел(ы): "
echo "1 - fdisk    2 - parted    3 - gdisk    4 - cfdisk"
read PARTITION_UTIL

if [[ $PARTITION_UTIL == 1 ]] || [[ $PARTITION_UTIL == fdisk ]] || [[ $PARTITION_UTIL == Fdisk ]] || [[ $PARTITION_UTIL == FDISK ]]; then
  fdisk $DRIVE
elif [[ $PARTITION_UTIL == 2 ]] || [[ $PARTITION_UTIL == parted ]] || [[ $PARTITION_UTIL == Parted ]] || [[ $PARTITION_UTIL == PARTED ]]; then
  parted $DRIVE
elif [[ $PARTITION_UTIL == 3 ]] || [[ $PARTITION_UTIL == gdisk ]] || [[ $PARTITION_UTIL == Gdisk ]] || [[ $PARTITION_UTIL == GDISK ]]; then
  gdisk $DRIVE
elif [[ $PARTITION_UTIL == 4 ]] || [[ $PARTITION_UTIL == cfdisk ]] || [[ $PARTITION_UTIL == Cfdisk ]] || [[ $PARTITION_UTIL == CFDISK ]]; then
  cfdisk $DRIVE
else
  echo "Произошла ошибка! Будет выбран fdisk!"
  sleep 2
  fdisk $DRIVE
fi


clear
echo "Выберите тип файловой сисетемы: "
echo "1 - ext4   2 - btrfs   3 - xfs"
read FILE_SYSTEM
clear

lsblk
echo -n "Выберите корневой раздел (Например: /dev/sda1): "
read ROOT_PARTITION

echo -n "Выберите загрузочный раздел (Например: /dev/sda1): "
read BOOT_PARTITION

mkfs.vfat -F32 "$BOOT_PARTITION"
if [[ $FILE_SYSTEM == 1 ]] || [[ $FILE_SYSTEM == ext4 ]] || [[ $FILE_SYSTEM == Ext4 ]] || [[ $FILE_SYSTEM == EXT4 ]]; then
  mkfs.ext4 "$ROOT_PARTITION"
elif [[ $FILE_SYSTEM == 2 ]] || [[ $FILE_SYSTEM == btrfs ]] || [[ $FILE_SYSTEM == Btrfs ]] || [[ $FILE_SYSTEM == BTRFS ]]; then
  mkfs.btrfs "$ROOT_PARTITION"
elif [[ $FILE_SYSTEM == 3 ]] || [[ $FILE_SYSTEM == xfs ]] || [[ $FILE_SYSTEM == Xfs ]] || [[ $FILE_SYSTEM == XFS ]]; then
   mkfs.xfs "$ROOT_PARTITION"
else
  echo "Произошла ошибка! Будет выбран ext4!"
  sleep 2
  mkfs.ext4 "$ROOT_PARTITION"
fi


# Монтируем корневой раздел + создаем каталоги
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount "$ROOT_PARTITION" /mnt
mount "$BOOT_PARTITION" /mnt/boot/efi

#efidirectory="/boot/efi/"
#if [ ! -d "$efidirectory" ]; then
#  mkdir -p "$efidirectory"
#fi
#mount "$BOOT_PARTITION" "$efidirectory"
#mkfs.fat -F 32 "$BOOT_PARTITION"


# Проверяем созданные нами разделы 
clear
echo "Проверьте созданные вами разделы! "
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
#elif [[ $KERNEL == 3 ]] || [[ $KERNEL == linux-xanmod ]] || [[ $KERNEL == Linux-xanmod ]] || [[ $KERNEL == LINUX-XANMOD ]]; then
#  pacman -Sy --needed --noconfirm
#  pacstrap /mnt base base-devel linux-xanmod linux-xanmod-headers
#elif [[ $KERNEL == 4 ]] || [[ $KERNEL == linux-lqx ]] || [[ $KERNEL == Linux-lqx ]] || [[ $KERNEL == LINUX-LQX ]]; then
#  pacstrap /mnt base base-devel linux-lqx linux-lqx-headers
fi


# Генерируем файл fstab
echo "Идет генерация fstab"
genfstab -U /mnt >> /mnt/etc/fstab

clear
sed '1,/^#part2$/d' archinstall.sh > /mnt/post_archinstall.sh
chmod +x /mnt/post_archinstall.sh
arch-chroot /mnt ./post_archinstall.sh


#umount -R /mnt
#echo "Система будет перезагружена через 10 сек."
#sleep 10
#reboot

#part2

# Устанавливаем язык и часовой пояс
echo $'\nИдет настройка локалей...'
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" > /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf

echo $'\nИдет настройка даты и времени, по умолчанию МСК ...'
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc
sleep 2

# Устанавливаем и настраиваем сеть
echo "Идет настройка сети..."
pacman -S --needed --noconfirm networkmanager iwd nano
systemctl enable NetworkManager

# Устанавливаем загрузчик
echo "Идет настройка загрузчика..."

pacman -S --needed --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
grub-mkconfig -o /boot/grub/grub.cfg
sleep 2
clear


# Создание пароля для root
echo "Введите пароль для вашего root пользователя: "
passwd
sleep 2
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
sleep 2

# Установка intel-amd ucode
echo "Идет установка Intel-AMD ucode"
pacman -S --needed --noconfirm intel-ucode amd-ucode
sleep 2
clear


# Установка графического окружения и сервера отображения Xorg
#echo -n "Хотите установить рабочее окружение? (Y/n): "
echo $'1 - DE \n2 - WM \n3 - No desktop'
echo -n "Выберите рабочее окружение: "
read DESKTOP

if [[ $DESKTOP == 1 ]] || [[ $DESKTOP == de ]] || [[ $DESKTOP == DE ]]; then
  echo "1 - Gnome   2 - KDE   3 - KDE (Minimal)   4 - Xfce   5 - Xfce (Minimal)"
  echo "Выберите графической окружение из перечисленных: "
  read DE
  pacman -S --needed --noconfirm xorg xorg-server
  if [[ $DE == 1 ]] || [[ $DE == gnome ]] || [[ $DE == Gnome ]] || [[ $DE == GNOME ]]; then
    pacman -S --needed --noconfirm gnome
    systemctl enable gdm.service
  elif [[ $DE == 2 ]] || [[ $DE == kde ]] || [[ $DE == Kde ]] || [[ $DE == KDE ]]; then
    pacman -S --needed --noconfirm plasma plasma-wayland-session kde-applications
    systemctl enable sddm.service
  elif [[ $DE == 3 ]] || [[ $DE == kde_minimal ]] || [[ $DE == Kde_minimal ]] || [[ $DE == KDE_MINIMAL ]]; then
    pacman -S --needed --noconfirm plasma plasma-wayland-session konsole dolphin
    systemctl enable sddm.service
  elif [[ $DE == 4 ]] || [[ $DE == xfce ]] || [[ $DE == Xfce ]] || [[ $DE == XFCE ]]; then
    pacman -S --needed --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
    systemctl enable lightdm.service
  elif [[ $DE == 5 ]] || [[ $DE == xfce_minimal ]] || [[ $DE == Xfce_minimal ]] || [[ $DE == XFCE_MINIMAL ]]; then
    pacman -S --needed --noconfirm xfce4 thunar mousepad xfce4-terminal lightdm lightdm-gtk-greeter
    systemctl enable lightdm.service
  else
    echo "Произошла ошибка. Был выбран вариант без рабочего окружения."
  fi
elif [[ $DESKTOP == 2 ]] || [[ $DESKTOP == wm ]] || [[ $DESKTOP == WM ]]; then
  echo "1 - i3   2 - bspwm   3 - openbox   4 - xmonad   5 - awesome"
  echo "Выберите оконный менеджер из перечисленных: "
  read WM
  pacman -S --needed --noconfirm xorg xorg-server lightdm lightdm-gtk-greeter
  systemctl enable lightdm.service
  sleep 2
  pacman -S --needed --noconfirm alacritty ranger neovim vim dmenu thunar firefox
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
    echo "Произошла ошибка. На вашу системук будет установлен i3"
    pacman -S --needed --noconfirm i3
    sleep 2
  fi
else
  :
fi  

# Выходим из установленной системы
exit

# Отмонтируем разделы и перезагружаем систему
umount -R /mnt
clear

echo "Система будет перезагружена через 10 сек."
sleep 10
reboot
