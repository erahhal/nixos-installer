# nixos-installer

## WARNING - THIS WILL DELETE THE CONTENTS OF YOUR MACHINE

* Create USB stick with NixOS ISO (Minimal ISO image)
  * Download here: https://nixos.org/download.html
  * Replace [iso-filename] with the name of the ISO image just downloaded
  * Replace [device] with usb stick's device, usually /dev/sda or /dev/sdb
  * `dd bs=4M if=[iso-filename] of=[device]`
* Boot machine using usb stick
* At prompt, get the installer script
  * `curl -L -O https://github.com/erahhal/nixos-installer/archive/refs/heads/master.zip`
  * `unzip master.zip`
  * `cd nixos-installer-master`
  * `./install-base.sh`
  * Type "Ignore" if presented with warnings
  * Enter new root password when prompted
