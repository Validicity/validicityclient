# Validityclient
This is the NFC-scanner client written in Dart for the Validicity system. This software runs on a fanless small Linux-machine that has an NFC-scanner attached.
It scans NFC tags and communicates with the Validicity server via a REST API, authenticated using OAuth2.

## SSH
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

## Update
Update and upgrade installed packages:

    sudo apt update && sudo apt upgrade

# Install

## Install Dart

```

```
And then:

```
sudo apt-get install dart
```

## Install libnfc and libfreefare
Prerequisites:

```
sudo apt install libusb-0.1-4 libusb-dev
```

Blacklist modules that conflict:

```
sudo nano /etc/modprobe.d/blacklist-libnfc.conf
blacklist nfc
blacklist pn533
blacklist pn533_usb
```

Add udev rule:

```
sudo cp contrib/udev/93-pn53x.rules /lib/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Reinsert reader in USB port, I think that's needed. Build and install libnfc:

```
git clone git@github.com:nfc-tools/libnfc.git
cd libnfc
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

## Install ntag-driver
Now that libnfc and libfreefare is installed, we can go to `ntag-driver` directory and:

```
make
sudo make install
```

You can try it out by just running `ntag-driver` and hitting enter to scan. Make sure the reader is connected.


## Install Validicityclient
Finnaly time to build `validicityclient`:

```
git clone git@github.com:Validicity/validicityclient.git
cd validicityclient
make
sudo make install
```

Try it out with `validicityclient -h`!

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

# Run
Just run with `validicityclient` to get help.


## Notes
