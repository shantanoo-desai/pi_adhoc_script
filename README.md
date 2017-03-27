# Pi Ad Hoc Creator

This `bash` script performs the following:

* Checks for the type of Pi:
    * __Raspberry Pi 2 Model B__
    * __Raspberry Pi 3__

* Checks for either:
    * internal wireless chipset for __Pi - 3__
    * external wireless chipsets for __Pi - 2__

* Adds appropriate kernel modules in the `/etc/modules` folder for boot

* changes the `/etc/rc.local` file for setting up an ad-hoc network on boot
with following parameters:

    - Mode Ad-Hoc
    - Channel 1
    - ESSID `test-adhoc`
    - Tx power to 0dBm (if possible)

* Changes the `/network/interfaces` file and other networking files to provide:

    - __IPv6 SLAAC__ addresses on `wlan0`
    - no __IPv6__ addresses on `eth0`

### External Wireless Chipsets

* __ONLY__ dongles with following drivers are capable to work in ad-hoc operation:
    * `r8188eu`
    * `rt2x00lib`

* __Edimax 7811UN__ with `8192cu` drivers are __INCOMPATIBLE__.

### Accessibility

Pis can be accessible once running the script and rebooted using:

    ping6 -I wlan0 ff02::1

from a native Linux PC with the _Same_ ad-hoc network configuration or from a Pi with the same configuration. Pis are addressed with `fe80::` link-local addresses.

to perform `ssh` in to the pi:

    ssh -l pi fe80::abcd:1ff:fe22:dead%wlan0

the `%wlan0` is important

to perform `scp` use `[]` as follows:

    scp someFile.txt pi@[fe80::abcd:1ff:fe22:dead%wlan0]:/home/pi/

### Requirements

Just your Pi with an external chipset based USB dongle and root privileges to trigger the script.

    sudo ./adhoc_setup.sh

### ISSUES with External Dongles

* `r8188eu` chipsets are miserable with not letting the user set `txpower`
and also `channel` parameters. `txpower` will return an Error, whileas `channel`
set to another value will not. 

* even upon setting `sudo iwconfig wlan0 channel 06` or another value, only
the default value of channel 1 i.e. __ 2.412 GHz__ is set.

### License

Issued under __MIT License__
