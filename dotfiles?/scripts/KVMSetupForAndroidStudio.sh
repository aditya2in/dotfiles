# 1. Install QEMU, libvirt, and edk2-ovmf for KVM virtualization
echo "Installing qemu, libvirt, and edk2-ovmf..."
sudo pacman -S qemu libvirt edk2-ovmf --noconfirm

# 2. Add your user to the 'kvm' and 'libvirt' groups
echo "Adding user '$USER' to 'kvm' and 'libvirt' groups..."
sudo usermod -aG kvm $USER
sudo usermod -aG libvirt $USER

# 3. Enable and start the libvirtd service
echo "Enabling and starting libvirtd.service..."
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service

# 4. Verify KVM installation (optional, but highly recommended)
echo "Verifying KVM installation..."
kvm-ok

# 5. Important: Reboot your system for group changes to take effect
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!! Please reboot your system NOW for group changes to take effect.   !!!"
echo "!!! You can type 'sudo reboot' after this script finishes.          !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
