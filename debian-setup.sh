#!/bin/sh

################################
# VARIABLES
################################

additionalpkgs=(
"curl"
"git"
"gpg"
"htop"
"lvm2"
"rsync"
"ssh"
"sudo"
"vim"
)

basepkgs=(
"linux-image-generic"
"build-essential"
"network-manager"
)

cryptanswers=(
"Yes"
"No"
"I don't know"
)

firmwareanswers=(
"Legacy BIOS"
"UEFI"
"I don't know"
)

localeconf=(
'export LANG="en_US.UTF-8"
export LC_COLLATE="C"'
)

regions=(
"en_US"
)

swapanswers=(
"Yes"
"No"
"I don't know"
)

timezones=(
"US/Eastern"
"US/Central"
"US/Mountain"
"US/Pacific"
)

################################
# FUNCTIONS
################################

getuserandpass() {
    echo "Please enter a password for the root user."
    read -sp "Root password: " rootpass1

    echo -e "\\nPlease retype the password."
    read -sp "Verify: " rootpass2

	while ! [ "$rootpass1" = "$rootpass2" ]; do
        echo -e "\\nThe passwords entered do not match each other.\\n\\nPlease enter the passwords again."
        read -sp "Root password: " rootpass1

        echo -e "\\nPlease retype the password."
        read -sp "Verify: " rootpass2
	done

    echo -e "\\n\\nPlease enter a name for the new user that will be created by the script."
    read -p "Username: " username

    while ! echo "$username" | grep -q "^[a-z][a-z0-9_-]*$"; do
        echo "Invalid username. Please provide a username using lowercase letters; numbers, -, or _ can be used if not the first character."
        read -p "Username: " username
    done

    echo -e "\\nPlease enter a password for the new user."
    read -sp "User password: " userpass1

    echo -e "\\nPlease retype the password."
    read -sp "Verify: " userpass2

	while ! [ "$userpass1" = "$userpass2" ]; do
        echo -e "\\nThe passwords entered do not match each other.\\n\\nPlease enter the passwords again."
        read -sp "User password: " userpass1

        echo -e "\\nPlease retype the password."
        read -sp "Verify: " userpass2
	done
}

getnetworkinginfo() {
    echo -e "\\n\\nPlease enter a hostname for the Debian computer."
    read -p "Hostname: " hostname

    while ! echo "$hostname" | grep -q "^[a-z][a-z0-9_-]*$"; do
        echo "Invalid hostname. Please provide a hostname using lowercase letters; numbers, -, or _ can be used if not the first character."
        read -p "Hostname: " hostname
    done

    echo -e "\\nPlease enter the domain of the network. If unsure, just enter 'local'."
    read -p "Local domain: " localdomain

    while ! echo "$localdomain" | grep -q "^[a-z][a-z0-9_.-]*$"; do
        echo "Invalid domain. Please provide a domain using lowercase letters; numbers, -, _, or . can be used if not the first character."
        read -p "Local domain: " localdomain
    done
}

questions() {
    # timezone
    echo -e "\\nWhat timezone are you in?"
    PS3="Please choose a number: "

    select timezone in "${timezones[@]}"; do
        case $REPLY in
            1) timezone="US/Eastern"; break;;
            2) timezone="US/Central"; break;;
            3) timezone="US/Mountain" ; break;;
            4) timezone="US/Pacific" ; break;;
            *) echo "Unknown response. Try again.";;
        esac
    done

    echo "Selected '$timezone'"

    # region
    echo -e "\\nWhat region are you in?"
    PS3="Please choose a number: "

    select region in "${regions[@]}"; do
        case $REPLY in
            1) region="en_US"; break;;
            *) echo "Unknown response. Try again.";;
        esac
    done

    echo "Selected '$region'"

    # BIOS or UEFI?
    echo -e "\\nIs this computer running 'legacy BIOS' or 'UEFI'?"
    PS3="Please choose a number: "

    select firmwareanswer in "${firmwareanswers[@]}"; do
        case $REPLY in
            1) firmwareanswer="BIOS"; break;;
            2) firmwareanswer="UEFI"; break;;
            3) echo "Confirm and come back."; exit 1;;
            *) echo "Unknown response. Try again.";;
        esac
    done

    echo "Selected '$firmwareanswer'"

    [[ $firmwareanswer == "BIOS" ]] && {
        echo
        read -p "What is the device name (ex. sda, sdb, nvme0n1)? " sdx
    }

    # encrypted?
    echo -e "\\nIs this computer's root storage encrypted?"
    PS3="Please choose a number: "

    select cryptanswer in "${cryptanswers[@]}"; do
        case $REPLY in
            1) cryptanswer="yes"; break;;
            2) cryptanswer="no"; break;;
            3) echo "Confirm and come back."; exit 1;;
            *) echo "Unknown response. Try again.";;
        esac
    done

    echo "Selected '$cryptanswer'"

    # swap?
    echo -e "\\nDoes this computer have a swap partition?"
    PS3="Please choose a number: "

    select swapanswer in "${swapanswers[@]}"; do
        case $REPLY in
            1) swapanswer="yes"; break;;
            2) swapanswer="no"; break;;
            3) echo "Confirm and come back."; exit 1;;
            *) echo "Unknown response. Try again.";;
        esac
    done

    echo "Selected '$swapanswer'"
}

confirminputs() {
    echo -e "\\nYou gave the following inputs:"
    echo "Username: $username"
    echo "Hostname: $hostname"
    echo "Local domain: $localdomain"
    echo "Timezone: $timezone"
    echo "Region: $region"
    echo "Firmware: $firmwareanswer"
    [[ $firmwareanswer == "BIOS" ]] && echo "Device: $sdx"
    echo "Encryption: $cryptanswer"
    echo "Swap partition: $swapanswer"

    echo
    read -p "Continue? (y/n): " confirm && [[ $confirm == [yY] ]] || ( echo "Exiting now." && exit 1 )
}

adduserandpass() {
	echo "root:$rootpass1" | chpasswd
	unset rootpass1 rootpass2

    echo -e "\\nCreating new user \"$username\"..."
    useradd -G sudo -s /bin/bash -m "$username"
	export repodir="/home/$username/.local/src"
	mkdir -p "$repodir"
	chown -R "$username": "$(dirname "$repodir")"

	echo "$username:$userpass1" | chpasswd
	unset userpass1 userpass2
}

setuphostname() {
    echo "$hostname" > /etc/hostname
    echo "127.0.0.1     localhost" > /etc/hosts
    echo "::1           localhost" >> /etc/hosts
    echo "127.0.1.1     $hostname $hostname.$localdomain" >> /etc/hosts
}

dobasicadjustments() {
    cat /proc/mounts >> /etc/fstab
    [[ $swapanswer = "yes" ]] && echo "UUID=<UUID_swap> none swap defaults 0 0" >> /etc/fstab
    blkid | grep UUID >> /etc/fstab

    echo "updating packages and installing nala"
    apt update > /dev/null 2>&1
    apt install nala -y > /dev/null 2>&1
}

setuptime() {
    [[ -e /etc/localtime ]] && rm /etc/localtime
    ln -s /usr/share/zoneinfo/$timezone /etc/localtime
    hwclock --systohc
}

setuplocaleconf() {
    echo "adjusting /etc/locale.conf"
    echo "$localeconf" > /etc/locale.conf
}

setuplocalegen() {
    echo "adjusting /etc/locale.gen"
    apt install -y locales > /dev/null 2>&1
    [[ $region == "en_US" ]] && sed -i 's/^# en_US/en_US/g' /etc/locale.gen
    locale-gen > /dev/null 2>&1
}

installpackages() {
    echo -e "\\ninstalling Linux base packages:"

    for basepkg in "${basepkgs[@]}"; do
        echo "'$basepkg' is not yet installed on this computer. Installing '$basepkg' now..."
        apt install -y $basepkg > /dev/null 2>&1
    done

    echo -e "\\ninstalling additional packages:"

    for additionalpkg in "${additionalpkgs[@]}"; do
        echo "'$additionalpkg' is not yet installed on this computer. Installing '$additionalpkg' now..."
        apt install -y $additionalpkg > /dev/null 2>&1
    done
}

dovimconfigs() {
    # clone git repos into new user's repodir
    mkdir -p /root/.config/shell /home/$username/.config/shell
    cd "$repodir"
    git clone https://github.com/davidvogelxyz/dotfiles > /dev/null 2>&1
    git clone https://github.com/davidvogelxyz/vim > /dev/null 2>&1
    cd /root

    # for root user
    ln -s /home/$username/.local/src/vim /root/.vim
    cp /home/$username/.local/src/dotfiles/.config/shell/aliasrc-debian /root/.config/shell/aliasrc
    echo -e "\nsource ~/.config/shell/aliasrc" >> /root/.bashrc

    # for new user
    ln -s /home/$username/.local/src/vim /home/$username/.vim
    cp /home/$username/.local/src/dotfiles/.config/shell/aliasrc-debian /home/$username/.config/shell/aliasrc
    chown -R "$username": /home/$username
    echo -e "\nsource ~/.config/shell/aliasrc" >> "/home/$username/.bashrc"
}

setupfstab() {
    sed -i '/^sysfs/,/^devpts/d' /etc/fstab
    sed -i '/^hugetlbfs/,/^binfmt_misc/d' /etc/fstab
    sed -i '/^mqueue/d' /etc/fstab
    sed -i 's/dev\/shm/tmp/g' /etc/fstab
    sed -i '/^\/dev\/sr0/d' /etc/fstab

    echo
    vim /etc/fstab
}

setupnetworking() {
    systemctl enable NetworkManager
}

docryptsetup() {
    [[ $cryptanswer = "yes" ]] && {
        echo -e "\\ninstalling 'cryptsetup-initramfs':"
        apt install -y cryptsetup-initramfs
        blkid | grep UUID | grep crypto >> /etc/crypttab
        vim /etc/crypttab
    }
}

doinitramfsupdate() {
    echo -e "\\nupdating initramfs"
    update-initramfs -u -k all > /dev/null 2>&1
}

dogrubinstall() {
    echo "installing GRUB"

    [[ $firmwareanswer = "BIOS" ]] && {
        apt install -y grub-pc > /dev/null 2>&1
        grub-install --target=i386-pc /dev/$sdx
    }

    [[ $firmwareanswer = "UEFI" ]] && {
        apt install -y grub-efi > /dev/null 2>&1
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    }

    echo "updating GRUB"
    update-grub > /dev/null 2>&1
}

################################
# ACTUAL SCRIPT
################################

getuserandpass

getnetworkinginfo

questions

confirminputs

adduserandpass

setuphostname

dobasicadjustments

setuptime

setuplocaleconf

setuplocalegen

installpackages

dovimconfigs

setupfstab

setupnetworking

docryptsetup

doinitramfsupdate

dogrubinstall
