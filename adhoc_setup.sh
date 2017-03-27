#!/bin/bash

# Ths test performs check on the Pi
# Creates an ad-hoc network on next boot
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Author : Shantanoo 'Shan' Desai

PI_TYPE=$(cat /proc/cpuinfo | grep "Revision" | awk '{print $3}')

# if Pi - 3; check internal wireless chipset
INT_WLAN_CHIP=$(lsmod | grep "cfg80211" | awk '{print $4}' | grep "brcmfmac")

# if Pi -2; external USB wireless dongle
# for RT5370 based driver
EXT_WLAN_CHIP_1=$(lsmod | grep "cfg80211" | awk '{print $4}' | grep "rt2x00lib")

# for RTL8188EU based driver
# cannot change tx power here
EXT_WLAN_CHIP_2=$(lsmod | grep "cfg80211" | awk '{print $4}' | grep "r8188eu")


# ROOT Privilege only

if [[ $EUID -ne 0 ]]; then
    echo "Need root Privilege to run this script.."
    exit 1
fi

# Pi check and add necessary modules to `/etc/modules` folder

case "$PI_TYPE" in
    "a02082" | "a22082") # Pi 3 Revision Numbers
    echo
    echo "Model: Raspberry Pi 3.."
    echo "Check for internal wireless chipset.."
    if [[ "$INT_WLAN_CHIP" == "brcmfmac" ]]; then
        echo "ipv6" >> /etc/modules; echo "$INT_WLAN_CHIP" >> /etc/modules
    else
        echo "No Internal chipset found.."
        exit 1
        echo
    fi
    echo "Changing rc.local files"
    cp /etc/rc.local /etc/rc.local.backup
    tee <<- 'EOF' > /etc/rc.local
#!/bin/sh -e
# Ad-Hoc Network creation
echo "Creating Ad-Hoc Network"
iwconfig wlan0 mode ad-hoc essid test-adhoc channel 01 txpower 0
exit 0
EOF

    ;; # Switch Case for Pi-3 Over

    "a01041" | "a21041" | "a22042") # Pi 3 Revision Numbers

    echo
    echo "Model: Raspberry Pi 2.."
    echo "Check for external wireless chipset..";

    if [[ "$EXT_WLAN_CHIP_1" == "rt2x00lib" ]] || [[ "$EXT_WLAN_CHIP_1" == "mac80211,rt2x00lib" ]]; then # if RT5370 Driver
        echo "ipv6" >> /etc/modules; echo "rt2x00lib" >> /etc/modules
        echo
        echo "Changing rc.local files.."
        cp /etc/rc.local /etc/rc.local.backup
        tee <<- 'EOF' > /etc/rc.local
#!/bin/sh -e
echo "Creating Ad-Hoc Network"
ifconfig wlan0 down
iwconfig wlan0 mode ad-hoc essid test-adhoc channel 01 txpower 0
ifconfig wlan0 up
exit 0
EOF
# here-doc ends here for /etc/rc.local

    elif [[ "$EXT_WLAN_CHIP_2" == "r8188eu" ]]; then # if RTL8188EU driver
        echo "ipv6" >> /etc/modules; echo "$EXT_WLAN_CHIP_2" >> /etc/modules
        echo
        echo "Changing rc.local files.."
        cp /etc/rc.local /etc/rc.local.backup
        tee  <<- 'EOF' > /etc/rc.local
#!/bin/sh -e
echo "Creating Ad-Hoc Network"
ifconfig wlan0 down
iwconfig wlan0 mode ad-hoc essid test-adhoc channel 01
# cannot change tx power for r8188eu drivers
# cannot change channel parameters for r8188eu drivers
ifconfig wlan0 up
exit 0
EOF
    else
        echo "no chipset found.."
        exit 1
    fi
 ;; # Switch Case for Pi - 2 ends here
esac

echo
echo "Changing network/interfaces file.."
cp /etc/network/interfaces /etc/network/interfaces.backup
tee <<'EOF' > /etc/network/interfaces
# loopback interface
auto lo
iface lo inet loopback

# ethernet eth0
iface eth0 inet manual

# WLAN wlan0 for Ad Hoc network
# TWIN Node
allow-hotplug wlan0
iface wlan0 inet6 auto

EOF
# here-doc ends for /etc/network/interfaces file

echo
echo "Changing other network configurations.."
echo "slaac slaac" >> /etc/dhcpcd.conf;
echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf

echo "net.ipv6.conf.eth0.disable_ipv6=1" >> /etc/sysctl.conf

exit 0
