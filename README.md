# Validityclient
This is the NFC-scanner client written in Dart for the Validicity system. This software runs on a fanless small Linux-machine that has an NFC-scanner attached. At the moment we are using an ODROID-C2 machine.
It scans NFC tags and communicates with the Validicity server via a REST API, authenticated using OAuth2.

All these instructions are based on running a Linux development machine, typically Ubuntu LTS.

## ODROID-C2

Start by disconnecting jumper next to HDMI port, this is needed if powering using power cable.

Connect the RTC module, inserted in top corner of board near IR sensor, inner row of pins.

* https://wiki.odroid.com/accessory/add-on_boards/rtc_shield

TODO: Haven't verified it works...

## Armbian

Some links: 

* https://www.armbian.com/odroid-c2/
* https://docs.armbian.com/
* https://wiki.odroid.com/odroid-c2/odroid-c2
* https://www.armbian.com/odroid-c2/#kernels-archive-all

Download Balena Etcher: https://github.com/balena-io/etcher/releases

* Download in 7zip format, extract .img file.
* Install and run Balena etcher, flash it onto eMMC card.
* Insert eMMC on the C2 and boot with screen and keyboard attached.
* Login as "root"/"1234", change root password
* Create user "validi" with password "validi"

Update and upgrade installed packages:

    sudo apt update && sudo apt upgrade

Run `armbian-config` to:

* Upgrade
* Set timezone
* Set keyboard
* Announce system in the network

After having turned on Avahi broadcasting this should work:

```
ssh -o PubkeyAuthentication=no validi@odroidc2.local
```
## Building kernel
Unfortunately we need libcomposite etc, so we need to dig in and build our own kernel. We find good documentation on how to do it here:

* https://docs.armbian.com/Developer-Guide_Build-Preparation/

We however use LXC instead of Vagrant to get a clean Ubuntu environment, like:



Then we can:

    cd build
    ./compile.sh  BOARD="odroidc2" BRANCH="current" KERNEL_ONLY="yes" KERNEL_CONFIGURE="yes" RELEASE="buster"

Then we need to enable USB Gadget stuff.


## USB keyboard emulation
In order for this to work we need to fix some settings in the dtb file controlling the device tree.

* https://github.com/qlyoung/keyboard-gadget
  * "HID support (f_hid) was added in kernel 3.19, so you need >= 3.19 to use ConfigFS to build HID gadgets"

Two threads on the forum discuss how to do this:

* https://forum.odroid.com/viewtopic.php?f=139&t=30267
* https://forum.odroid.com/viewtopic.php?t=36602

We roughly follow the article that was later written (based on the above) how to do it in ArchLinux: https://magazine.odroid.com/article/hid-gadget-device-using-odroid-c2/

We first decompile the dtb file to a dts file for editing:

    cd /boot/dtbs/amlogic/
    sudo dtc -I dtb -O dts meson-gxbb-odroidc2.dtb > ~/meson-gxbb-odroidc2.dts

Edit with `nano ~/meson-gxbb-odroidc2.dts` and fix:

* In the section `mmc@74000` change to `max-frequency = <0x8f0d180>;`. This makes eMMC more reliable.
* In the section `usb@c9000000` change to `dr_mode = "peripheral";` and `status = "okay";`
* In the section `phy@c0000000` change to `status = "okay";` **NOTE: This took a while to find...**

Then rebuild dtb file and put in place:

    sudo dtc -I dts -O dtb ~/meson-gxbb-odroidc2.dts > ~/meson-gxbb-odroidc2.dtb
    cp ~/meson-gxbb-odroidc2.dtb /boot/dtbs/amlogic/

After a `sudo reboot` we should have something like this:

    validi@odroidc2:~$ dmesg | grep usb
    [    0.000000] Kernel command line: root=UUID=caee3fd2-9a01-4f26-9a06-ff264ad49170 rootwait rootfstype=ext4 console=ttyAML0,115200 console=tty1 consoleblank=0 coherent_pool=2M loglevel=1 ubootpart=cab90000-01 usb-storage.quirks=0x2537:0x1066:u,0x2537:0x1068:u   cgroup_enable=memory swapaccount=1
    [    1.387447] usbcore: registered new interface driver usbfs
    [    1.387477] usbcore: registered new interface driver hub
    [    1.387535] usbcore: registered new device driver usb
    [    1.899430] GPIO line 501 (usb-hub-reset) hogged as output/high
    [    1.920702] usbcore: registered new interface driver usb-storage
    [    1.952200] usbcore: registered new interface driver usbhid
    [    1.952202] usbhid: USB HID core driver
    [    1.987698] dwc2 c9000000.usb: c9000000.usb supply vusb_d not found, using dummy regulator
    [    1.987746] dwc2 c9000000.usb: c9000000.usb supply vusb_a not found, using dummy regulator
    [    1.988919] dwc2 c9000000.usb: dwc2_check_param_tx_fifo_sizes: Invalid parameter g-tx-fifo-size, setting to default average
    [    1.988924] dwc2 c9000000.usb: dwc2_check_param_tx_fifo_sizes: Invalid parameter g_tx_fifo_size[1]=0
    [    1.988928] dwc2 c9000000.usb: dwc2_check_param_tx_fifo_sizes: Invalid parameter g_tx_fifo_size[2]=0
    [    1.988932] dwc2 c9000000.usb: dwc2_check_param_tx_fifo_sizes: Invalid parameter g_tx_fifo_size[3]=0
    [    1.988935] dwc2 c9000000.usb: dwc2_check_param_tx_fifo_sizes: Invalid parameter g_tx_fifo_size[4]=0
    [    1.988939] dwc2 c9000000.usb: dwc2_check_param_tx_fifo_sizes: Invalid parameter g_tx_fifo_size[5]=0
    [    1.988950] dwc2 c9000000.usb: EPs: 7, dedicated fifos, 1984 entries in SPRAM
    [    1.989447] dwc2 c9100000.usb: c9100000.usb supply vusb_d not found, using dummy regulator
    [    1.989506] dwc2 c9100000.usb: c9100000.usb supply vusb_a not found, using dummy regulator
    [    2.049718] dwc2 c9100000.usb: DWC OTG Controller
    [    2.049736] dwc2 c9100000.usb: new USB bus registered, assigned bus number 1
    [    2.049765] dwc2 c9100000.usb: irq 36, io mem 0xc9100000
    [    2.049902] usb usb1: New USB device found, idVendor=1d6b, idProduct=0002, bcdDevice= 5.04
    [    2.049906] usb usb1: New USB device strings: Mfr=3, Product=2, SerialNumber=1
    [    2.049911] usb usb1: Product: DWC OTG Controller
    [    2.049914] usb usb1: Manufacturer: Linux 5.4.35-meson64 dwc2_hsotg
    [    2.049919] usb usb1: SerialNumber: c9100000.usb
    [    2.445495] usb 1-1: new high-speed USB device number 2 using dwc2
    [    2.466910] usb 1-1: New USB device found, idVendor=05e3, idProduct=0610, bcdDevice=32.98
    [    2.466915] usb 1-1: New USB device strings: Mfr=0, Product=1, SerialNumber=0
    [    2.466920] usb 1-1: Product: USB2.0 Hub
    [    2.757523] usb 1-1.1: new low-speed USB device number 3 using dwc2
    [    2.875831] usb 1-1.1: New USB device found, idVendor=04d9, idProduct=1818, bcdDevice= 1.01
    [    2.875839] usb 1-1.1: New USB device strings: Mfr=0, Product=2, SerialNumber=0
    [    2.875843] usb 1-1.1: Product: USB Keyboard
    [    2.887749] input: USB Keyboard as /devices/platform/soc/c9100000.usb/usb1/1-1/1-1.1/1-1.1:1.0/0003:04D9:1818.0001/input/input0
    [    2.946065] hid-generic 0003:04D9:1818.0001: input,hidraw0: USB HID v1.10 Keyboard [USB Keyboard] on usb-c9100000.usb-1.1/input0
    [    2.969545] input: USB Keyboard Consumer Control as /devices/platform/soc/c9100000.usb/usb1/1-1/1-1.1/1-1.1:1.1/0003:04D9:1818.0002/input/input1
    [    3.029823] input: USB Keyboard System Control as /devices/platform/soc/c9100000.usb/usb1/1-1/1-1.1/1-1.1:1.1/0003:04D9:1818.0002/input/input2
    [    3.030013] hid-generic 0003:04D9:1818.0002: input,hidraw1: USB HID v1.10 Device [USB Keyboard] on usb-c9100000.usb-1.1/input1
    validi@odroidc2:~$ ls /sys/class/udc/
    c9000000.usb
    validi@odroidc2:~$ uname -a
    Linux odroidc2 5.4.35-meson64 #trunk SMP PREEMPT Thu Apr 23 18:16:56 CEST 2020 aarch64 GNU/Linux
    validi@odroidc2:~$ 


## Install Validicityclient
In `/home/validi` do:

    git clone git@github.com:Validicity/validicityclient.git

## Install keyboard
The emulated keyboard runs as a service.
Create a systemd service `/etc/systemd/system/emulatedkeyboard.service`, you can copy it from `/home/validi/validicityclient/keyboard` using:

    sudo cp /home/validi/validicityclient/keyboard/emulatedkeyboard.service /etc/systemd/system/

To start the service using systemd:

    sudo systemctl daemon-reload
    sudo systemctl start emulatedkeyboard
    sudo systemctl status emulatedkeyboard

Enable the systemd service so that emulatedkeyboard starts at boot.

    sudo systemctl enable emulatedkeyboard.service

## Test emulation




## Install Dart
Armbian does not have Dart in its regular repos so we need to do it manually:

    wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.7.2/sdk/dartsdk-linux-arm64-release.zip
    unzip dartsdk-linux-arm64-release.zip

Add to .profile:

    PATH="$HOME/dart-sdk/bin:$PATH"

...and run it once in this shell too. Verify you can see `dart`, `dart2native`, `pub` etc.

## Install libnfc and libfand libfreefare
Install prerequisites:

```
sudo apt install libusb-dev libtool libglib2.0-dev
```

Blacklist modules that conflict:

```
sudo nano /etc/modprobe.d/blacklist-libnfc.conf
blacklist nfc
blacklist pn533
blacklist pn533_usb
```

```
git clone git@github.com:nfc-tools/libnfc.git
cd libnfc
```

Add udev rule:

```
sudo cp contrib/udev/93-pn53x.rules /lib/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Reinsert reader in USB port, I think that's needed, it should NOT light up red anymore!

Build and install libnfc:

```
autoreconf -vis
./configure
make
sudo make install
sudo ldconfig
```

Then also libfreefare:

```
git clone git@github.com:nfc-tools/libfreefare.git
autoreconf -vis
./configure
make
sudo make install
sudo ldconfig
```

## Get Validicity software

```
git clone git@github.com:Validicity/validicityclient.git
git clone git@github.com:Validicity/validicitylib.git
```


## Install ntag-driver
Now that libnfc and libfreefare is installed, we can go to `ntag-driver` directory and:

```
cd ~/validicityclient/ntag-driver
make
sudo make install
```

You can try it out by just running `ntag-driver` and hitting enter to scan. Make sure the reader is connected.


## Install Validicityclient
Finally time to build `validicityclient`:

```
cd ~/validicityclient
make
sudo make install
cp validicityclient.yaml ~/
```

Try it out with `validicityclient -h` and `validicityclient testnfc`!

## Install as service
Check services:

    sudo service --status-all

Then add a systemd service for it, so create `/etc/systemd/system/validityclient.service`:

    [Service][Unit]
    Description=Validity client
    After=network.target

    [Service]
    User=validity
    Group=validity
    KillMode=mixed
    KillSignal=SIGTERM
    Restart=always
    RestartSec=2s
    NoNewPrivileges=yes
    StandardOutput=syslog+console
    StandardError=syslog+console
    SyslogIdentifier=Validity
    ExecStart=/user/local/bin/validityclient run

    [Install]
    WantedBy=multi-user.target

Now add it:

    sudo systemctl daemon-reload
    sudo systemctl enable validityclient.service
    sudo systemctl start validityclient.service


Check status with `sudo systemctl status validityclient`.

For logging, SystemD uses /var/log/system.log. To filter the log use:

    sudo journalctl -fu validityclient


## How it operates
This client picks up a YAML configuration from the local file `~/validicity.yaml` and then proceeds to run continuously until interrupted via Linux signal.


## Notes


## Kernel

[ o.k. ] Kernel build done [ @host ]
[ o.k. ] Target directory [ /root/build/output/debs/ ]
[ o.k. ] File name [ linux-image-current-meson64_20.05.0-trunk_arm64.deb ]
[ o.k. ] Runtime [ 93 min ]
[ o.k. ] Repeat Build Options [ ./compile.sh  BOARD=odroidc2 BRANCH=current KERNEL_ONLY=yes KERNEL_CONFIGURE=yes  ]