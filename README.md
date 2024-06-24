# debian-setup

This script goes hand-in-hand with the [Debian installation guide](https://github.com/DavidVogelxyz/library/blob/master/install-os/install-debian.md) found in the [Library repo](https://github.com/davidvogelxyz/library).

Use the guide up until the point of chrooting into the new environment. From there, use the following commands:

```
apt update && apt install -y git
mkdir -pv ~/.local/src && cd ~/.local/src
git clone https://github.com/davidvogelxyz/debian-setup && cd debian-setup
bash debian-setup.sh
```

Answer a few questions and save time on installation!

## Future goals

Get the script working such that the guide can do pre-`chroot` operations too. Include:

- `debootstrap`
- running the `mount --rbind` command
- copying "/etc/resolv.conf"
- making adjustments to "/mnt/etc/apt/sources.list"
