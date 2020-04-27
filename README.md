# Validityclient
This is the NFC-scanner client written in Dart for the Validicity system. This software runs on a fanless small Linux-machine that has an NFC-scanner attached.
It scans NFC tags and communicates with the Validicity server via a REST API, authenticated using OAuth2.

## SSH Beaglebone
Login as "debian" on Beaglebone:

```
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no debian@beaglebone.local  ("temppwd" out of the box)
```

Install proper SSH key (from your own machine):

```
ssh-copy-id -i .ssh/<your-key> -o PreferredAuthentications=password -o PubkeyAuthentication=no debian@beaglebone.local
```

And after this we should be able to just login without password:

```
ssh debian@beaglebone.local
```

## SSH ODROID-C2

After having turned on Avahi broadcasting using `armbian-config` this should work:

```
ssh -o PubkeyAuthentication=no validi@odroidc2.local
```


## Update
Update and upgrade installed packages:

    sudo apt update && sudo apt upgrade

# Install

## Install Dart Beaglebone

```
sudo apt-get update
sudo apt-get install apt-transport-https
sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
```
And then:

```
sudo apt update && sudo apt install dart
```

## Install Dart ODROID-C2
Armbian does not have Dart in its regular repos so we need to do it manually:

    wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.7.2/sdk/dartsdk-linux-arm64-release.zip
    unzip dartsdk-linux-arm64-release.zip

Add to .profile:

    PATH="$HOME/dart-sdk/bin:$PATH"

...and run it once in this shell too. Verify you can see `dart`, `dart2native`, `pub` etc.

## Install libnfc and libfreefare
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
