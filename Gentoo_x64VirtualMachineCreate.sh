#! bin/bash

VBoxManage createvm --name "Gentoodeneme" --register
VBoxManage list ostypes | less
VBoxManage modifyvm "Gentoodeneme" --memory 1024 --acpi on --cpus 2 --boot1 dvd --nic1 nat --ostype Gentoo_64

VBoxManage createhd --filename 'Gentoodeneme'.vdi --size 16384 --format VDI
VBoxManage modifyvm "Gentoodeneme" --hda 'Gentoodeneme'.vdi

VBoxManage storagectl "Gentoodeneme" --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach "Gentoodeneme" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium 'Gentoodeneme'.vdi

VBoxManage storagectl "Gentoodeneme" --name "IDE Controller" --add ide
VBoxManage storageattach "Gentoodeneme" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium /home/muhammet/İndirilenler/install-amd64-minimal-20190728T214502Z.iso #directory where .iso file is located

VBoxManage startvm gentooclone
VBoxManage controlvm gentooclone --vrde on
