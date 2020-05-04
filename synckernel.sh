rm -rf debs
lxc file pull -r armbian/root/build/output/debs .
scp  -o PubkeyAuthentication=no debs/*.deb validi@odroidc2.local:/home/validi/
