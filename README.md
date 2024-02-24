# debian-setup

This script goes hand-in-hand with the Debian installation guide found in the [Library repo](https://github.com/davidvogelxyz/library).

Use the guide up until the point of chrooting into the new environment. From there, use the following commands (but, note that `curl` needs to be installed on the system):

```
cd

curl -LJO https://raw.githubusercontent.com/DavidVogelxyz/debian-setup/master/debian-setup.sh

bash debian-setup.sh
```

Answer a few questions and save time on installation!

## Future goals

Get the script working such that the guide can do pre-`chroot` operations too. Include:

- `debootstrap`
- running the "mount --rbind" command
- copying "/etc/resolv.conf"
- making adjustments to "/mnt/etc/apt/sources.list"
