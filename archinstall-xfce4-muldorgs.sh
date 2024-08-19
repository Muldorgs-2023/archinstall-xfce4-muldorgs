#!/bin/bash

p34='\033[1;1;34m'
p00='\033[0m'
setfont lat9u-10
onroot='arch-chroot /mnt' #root


echo "██    ██  █████  ██   ██  █████  ██      ██       █████        ███████  ██████ ██████  ██ ██████  ████████ ";
echo "██    ██ ██   ██ ██   ██ ██   ██ ██      ██      ██   ██       ██      ██      ██   ██ ██ ██   ██    ██    ";
echo "██    ██ ███████ ███████ ███████ ██      ██      ███████ █████ ███████ ██      ██████  ██ ██████     ██    ";
echo " ██  ██  ██   ██ ██   ██ ██   ██ ██      ██      ██   ██            ██ ██      ██   ██ ██ ██         ██    ";
echo "  ████   ██   ██ ██   ██ ██   ██ ███████ ███████ ██   ██       ███████  ██████ ██   ██ ██ ██         ██    ";
echo "                                                                                                           ";
echo "                                                                                                           ";
echo
# Función para imprimir texto con formato
print_text() {
    local text="$1"
    local color="$2"
    echo -ne "$(tput setaf $color)$(tput bold)$text$(tput sgr0)"
}

# Texto en ASCII
ascii_text() {
    local text="$1"
    local color="$2"
    echo -ne "$(tput setaf $color)$(tput bold)$text$(tput sgr0)"
}

# Mostrar el texto formateado
print_text "Escrito por: " 2
ascii_text "Lord_Sith_Muldorgs" 4
echo 

timedatectl; timedatectl set-ntp 1

fdisk -l; echo -e "$p34:: particion en \"nvme0n1?\"$p00"; read hdd

if [ "$hdd" = "nvme0n1" ]; then
    hdd="${hdd}p"
fi

if [ -b "$hdd" ] && sfdisk -d "$hdd" &> /dev/null; then
    umount -R /mnt; sfdisk --delete "/dev/$hdd"
fi

echo -e "m\ng\nn\n1\n\n+${EFI_boot:=2048}M\nn\n2\n\n\nt\n1\n1\nw" | fdisk /dev/$hdd

mkfs.fat -F 32 -I /dev/"${hdd}1"; mkfs.btrfs -f -n 32k /dev/"${hdd}2"

mount /dev/"${hdd}2" /mnt; btrfs subvolume create /mnt/@; btrfs subvolume create /mnt/@home; btrfs subvolume create /mnt/@dArch; umount /mnt

mount -o compress=zstd:3,subvol=@ /dev/"${hdd}2" /mnt

mkdir -p /mnt/home; mount -o compress=zstd:3,subvol=@home /dev/"${hdd}2" /mnt/home
mkdir -p /mnt/dArch; mount -o compress=zstd:3,subvol=@dArch /dev/"${hdd}2" /mnt/dArch
mkdir -p /mnt/boot; mount /dev/"${hdd}1" /mnt/boot

# Agregar la clave del repositorio y firmarla
$onroot pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
$onroot pacman-key --lsign-key 3056513887B78AEB

# Instalar el keyring y la mirrorlist de Chaotic-AUR
$onroot pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
$onroot pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Agregar el repositorio a pacman.conf
$onroot bash -c "echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /mnt/etc/pacman.conf"

pacstrap /mnt base base-devel linux btrfs-progs nano linux-firmware  --noconfirm --needed

genfstab -U /mnt >> /mnt/etc/fstab
sed -i '/btrfs/s/relatime/noatime,commit=60/' /mnt/etc/fstab

timezone=$(tzselect)
$onroot ln -sf /usr/share/zoneinfo/$timezone /etc/localtime; $onroot hwclock -w

$onroot sed -i '/#es_UY.UTF-8 UTF-8/s/#es_UY.UTF-8 UTF-8/es_UY.UTF-8 UTF-8/' /etc/locale.gen
$onroot locale-gen
$onroot echo -e 'LANG=es_UY.UTF-8' > /mnt/etc/locale.conf

$onroot echo -e 'KEYMAP=es\nFONT=lat9u-10\nFONT_MAP=8859-2' > /mnt/etc/vconsole.conf

echo -e "$p34:: nombre pc \"pchome1\"$p00"; read -t 40 -p "" nombre_pc
nombre_pc=${nombre_pc:=pchome1}
$onroot echo -e $nombre_pc > /mnt/etc/hostname

$onroot pacman -Sy networkmanager --noconfirm --needed; $onroot systemctl enable NetworkManager.service

echo -e "$p34:: root pw. \"root\"$p00"; read -t 40 -p "" root_pw
root_pw=${root_pw:=root}
$onroot echo -e "$root_pw\n$root_pw" | $onroot passwd

$onroot pacman -S grub efibootmgr --noconfirm --needed
$onroot grub-install --target=x86_64-efi --efi-directory=/boot; $onroot grub-mkconfig -o /boot/grub/grub.cfg

echo -e "$p34:: nombre (no root) \"pchome\"$p00"; read -t 40 -p "" nombre
nombre=${nombre:=pchome}
$onroot useradd -m -G wheel $nombre
echo -e "$p34:: pw. (no root) \"pchome\"$p00"; read -t 40 -p "" pw
pw=${pw:=pchome}
echo -e "$pw\n$pw" | $onroot passwd $nombre

$onroot sed -i '/# %wheel ALL=(ALL:ALL) ALL/s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
$onroot sed -i -e '/NoExtract/c\NoExtract = usr/share/fonts/noto* !*NotoSans-* !*NotoSansMono-*' -e '/Color/s/#Color/Color/' -e '/ParallelDownloads = 5/s/#ParallelDownloads = 5/ParallelDownloads = 4/' /etc/pacman.conf
$onroot sed -i '/#MAKEFLAGS="-j2"/s/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf

$onroot echo -e 'vm.swappiness=10' > /mnt/etc/sysctl.d/99-swappiness.conf

procmeninfo=$(grep MemTotal /proc/meminfo | awk  '{print $2}')
A=$(expr $procmeninfo / 2)
MB=$(expr $A / 1024)
$onroot echo -e 'zram' > /mnt/etc/modules-load.d/zram.conf
$onroot cat << EOF > /mnt/etc/udev/rules.d/99-zram.rules
ACTION=="add", KERNEL=="zram0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="${MB}M", RUN="/usr/bin/mkswap -U clear /dev/%k", TAG+="systemd"
EOF
$onroot sed -i '$a /dev/zram0 none swap defaults,pri=100 0 0' /etc/fstab

L='blacklist'
$onroot echo -e "$L iTCO_wdt\n$L sp5100_tco\n$L pcspkr\n$L mousedev\n$L mac_hid\n$L parport_pc\n$L floppy\n$L joydev\n$L pata_acpi\n$L irda\n$L yenta_socket\n$L ns558\n$L ppa\n$L 3c59x\n$L sbp2\n$L lp\n$L pnp\n$L 3c503" > /mnt/etc/modprobe.d/blacklist.conf

$onroot pacman -S xorg-server xf86-video-vesa --noconfirm --needed
$onroot pacman -S xf86-video-intel libva-intel-driver vulkan-intel lib32-vulkan-intel vulkan-tools mesa lib32-mesa intel-media-driver libva-utils vdpauinfo clinfo --noconfirm --needed

$onroot pacman -S dysk bat lsd nano-syntax-highlighting tilix  grub-btrfs smartmontools reflector flatpak gptfdisk nvme-cli inxi duf linux-zen linux-zen-headers linux-zen-docs translate-shell htop bpytop base base-devel shellcheck git neofetch pipewire pipewire-audio wireplumber pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire gst-libav ffmpeg4.4  at xautolock tuned cpupower xorg-xbacklight xorg-xrandr brightnessctl fzf powertop tlp xorg-xset ranger material-gtk-theme-git papirus-icon-theme ant-theme-git gruvbox-plus-icon-theme --noconfirm --needed


$onroot pacman -S  exo garcon thunar thunar-volman tumbler xfce4-appfinder xfce4-panel xfce4-power-manager xfce4-session xfce4-settings xfconf xfdesktop xfwm4 xfwm4-themes mousepad ristretto thunar-archive-plugin thunar-media-tags-plugin xfce4-battery-plugin xfce4-whiskermenu-plugin xfce4-wavelan-plugin xfce4-taskmanager xfce4-systemload-plugin xfce4-screenshooter xfce4-screensaver xfce4-pulseaudio-plugin xfce4-notifyd xfce4-mount-plugin xfce4-docklike-plugin xfce4-clipman-plugin network-manager-applet lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings light-locker accountsservice  xfce4-docklike-plugin pavucontrol--noconfirm --needed; $onroot systemctl enable lightdm.service

$onroot pacman -S lsd bat zsh-doc zsh zsh-history-substring-search zsh-syntax-highlighting zsh-autosuggestions zsh-completions wget  yay vlc mystiq kodi kdenlive  mpv audacity audacity-docs pyradio  mediainfo cava castero obs-studio gpu-screen-recorder-gtk glava torbrowser-launcher tor thunderbird google-chrome discord yt-dlp-git aria2 element-desktop freetube jdownloader2 kasts transmission-cli gnome-boxes visual-studio-code-bin neovim eog gimp darktable rawtherapee  krita onlyoffice-bin okular fontforge grub-customizer cpupower-gui gparted timeshift  cpupower --noconfirm --needed


$onroot pacman -S ueberzug unrar tar p7zip gzip binutils bzip2 xz lrzip lbzip2 lz4 cpio lzip lzop zstd unace arj sharutils lzop unzip zip lhasa cabextract zpaq ark lha unarj android-file-transfer android-tools android-udev msmtp libmtp libcddb gvfs gvfs-afc gvfs-smb gvfs-gphoto2 gvfs-goa gvfs-nfs gvfs-google dosfstools jfsutils f2fs-tools btrfs-progs exfat-utils ntfs-3g reiserfsprogs udftools xfsprogs nilfs-utils mobydroid ifuse adb localsend warpinator polkit gpart mtools fuseiso ffmpeg aom libde265 x265 x264 libmpeg2 gvfs-mtp xvidcore libtheora libvpx schroedinger sdl gstreamer gst-plugins-bad gst-plugins-base gst-plugins-base-libs gst-plugins-good gst-plugins-ugly xine-lib libdvdcss libdvdread dvd+rw-tools lame preload thermald zram-generator keepassxc qalculate-qt fsearch thunar-media-tags-plugin thunar-archive-plugin thunar-shares-plugin thunarx-python thunar-volman xfce4-docklike-plugin xfce4-xkb-plugin bottles wine-staging wine-gecko wine-mono lutris steam mono dxvk-mingw-git nerd-fonts --noconfirm --needed

$onroot pacman -S p7zip ttf-ubuntu-font-family neofetch --noconfirm --needed

$onroot su - $nombre -c 'echo -e "#!/bin/bash\n\nB=\$(dirname \$0)\nE=\$(pwd)\n\nsudo pacman -S git go --noconfirm --needed\ngit clone https://aur.archlinux.org/yay.git; cd yay; makepkg -si; cd \$E\n\nrm -rf \$B/yay\nrm \$0" > ~/yay.sh'
$onroot su - $nombre -c "chmod 700 ~/yay.sh"

$onroot su - $nombre -c "mkdir ~/.config"
$onroot su - $nombre -c "echo -e '[Layout]\nLayoutList=es\nUse=true\n' > ~/.config/kxkbrc"; $onroot su - $nombre -c "echo -e '[Wallet]\nEnabled=false\n' > ~/.config/kwalletrc"; $onroot su - $nombre -c "echo -e '[Basic Settings]\nIndexing-Enabled=false\n' > ~/.config/baloofilerc"; $onroot su - $nombre -c "echo -e '[Plugins]\nbaloosearchEnabled=false\n' > ~/.config/krunnerrc"
$onroot su - $nombre -c "chmod -R go-rwx ~/.config" #$onroot su - $nombre -c 'chmod -R 700 ~/.config'

$onroot btrfs subvolume snapshot / "/dArch/root(1)"
$onroot btrfs subvolume snapshot /home  "/dArch/home(1)"

rm $0
umount -R /mnt
reboot
