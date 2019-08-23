#!/bin/bash
echo "Welcome to Gentoo Installation"
ping -w 3 -c 5 www.gentoo.org
echo "***If pinging, there is no problem with your network."
#**Disk Partition
parted /dev/sda --script mklabel gpt
parted /dev/sda --script unit mib
parted /dev/sda --script mkpart primary 1 3
parted /dev/sda --script name 1 grub
parted /dev/sda --script set 1 bios_grub on
parted /dev/sda --script mkpart primary 3 131
parted /dev/sda --script name 2 boot
parted /dev/sda --script mkpart primary 131 643
parted /dev/sda --script name 3 swap
parted /dev/sda --script mkpart primary 643 -- -1
parted /dev/sda --script name 4 rootfs
parted /dev/sda --script set 2 boot on

#**FileSystems Creation
mkfs.ext2 /dev/sda2
mkfs.ext4 /dev/sda4

#**Activating the swap partition
mkswap /dev/sda3
swapon /dev/sda3

#**Mounting
mount /dev/sda2 /mnt/gentoo
mount /dev/sda4 /mnt/gentoo
chmod 777 /var/tmp
parted /dev/sda --script print

# # #**Date
ntpd -q -g

#**Stage tarball downloading
cd /mnt/gentoo
wget distfiles.gentoo.org/releases/amd64/autobuilds/20190814T214502Z/stage3-amd64-20190814T214502Z.tar.xz

#**Stage tarball unpacking
cd /mnt/gentoo
tar xpvf /mnt/gentoo/stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

#**Configuring compile options
echo MAKEOPTS='"-j2"' >> /mnt/gentoo/etc/portage/make.conf

mirrorselect -i -c 'TURKEY' >> /mnt/gentoo/etc/portage/make.conf

mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf



# **Copy DNS Info
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount /dev/sda4 /mnt/gentoo
#**Mounting the necessary filesystems
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

#**Entering the new environment
chroot /mnt/gentoo /bin/bash << END
source /etc/profile
export PS1="(chroot) ${PS1}"

#**Mounting the boot partition
mount /dev/sda2 /boot

#**Configuring Portage
emerge-webrsync

#**Reading New Items
#Kritik mesajları rsync ağacı üzerinden kullanıcılara iletmek için 
#bir iletişim ortamı sağlamak için haber öğeleri oluşturuldu.
eselect news read

#**Choosing the right profile (Doğru profili seçmek)
eselect profile set default/linux/amd64/17.0

#**Updating the @world set
emerge --verbose --update --deep --newuse @world

#**Configuring the USE variable
emerge --info | grep ^USE

#Kullanılabilir USE flaglerinin tam açıklaması /var/db/repos/gentoo/profiles/use.desc adresindeki sistemde bulunabilir.
less /var/db/repos/gentoo/profiles/use.desc


#**Timezone
echo "Europe/Istanbul" >> /etc/timezone
#/etc/localtime dosyasını bizim için güncelleyecek olan sys-libs/timezone-data paketini yeniden yapılandıralım.
emerge --config sys-libs/timezone-data

#**Configure locales
#Bir sistemin desteklemesi gereken yerler /etc/locale.gen dosyasının içinde belirtilmelidir.
echo "en_US ISO-8859-1" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen

env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

#**Installing the sources (Kaynakları İndirme)
emerge sys-kernel/gentoo-sources

#**Using Genkernel
emerge sys-kernel/genkernel
#nano -w /etc/fstab
#/etc/fstab dosyasını düzenleyelim.
echo "/dev/sda2     /boot       ext2    defaults, noatime    0 2" >> /etc/fstab
echo "/dev/sda3     none        swap    sw                   0 0" >> /etc/fstab
echo "/dev/sda4     /           ext4    noatime              0 1" >> /etc/fstab
echo "/dev/cdrom    /mnt/cdrom  auto    noauto, user         0 0" >> /etc/fstab

echo "sys-apps/util-linux static-libs" >> /etc/portage/package.use/custom
mkdir /etc/portage/package.license
echo "sys-kernel/linux-firmware linux-fw-redistributable no-source-code" >> /etc/portage/package.license/custom 
#genkernel all, bütün donanımı destekleyen bir çekirdek derler bu yüzden uzun sürebilir.
genkernel all

echo "hostname="'"muhammetkiran.online"' > /etc/conf.d/hostname
echo "127.0.0.1     muhammetkiran.online muhammetkiran" > /etc/hosts
echo "::1           localhost" >> /etc/hosts

#Root şifresini "12345" olarak belirler.
echo root:"12345" | chpasswd

emerge app-admin/sysklogd 
rc-update add sysklogd default

#GRUB2 Kurulumu
emerge --verbose sys-boot/grub:2
grub-install /dev/sda

#Configuring
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G users,wheel,audio -s /bin/bash muhammetkrn1
echo muhammetkrn1:"13579" | chpasswd
END

cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
sleep 2
reboot
