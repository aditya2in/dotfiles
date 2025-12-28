# Backup s appLICAZTIONZ and doing somethingthe current mirrorlist for safety
echo "Creating a backup of your current pacman mirrorlist..."
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak_$(date +%Y%m%d_%H%M%S)
echo "Backup created at /etc/pacman.d/mirrorlist.bak_$(date +%Y%m%d_%H%M%S)"

# Check if reflector is installed, install if not
echo "Checking for 'reflector' and installing if necessary..."
if ! command -v reflector &> /dev/null
then
    echo "'reflector' not found. Installing now..."
    sudo pacman -S reflector --noconfirm
else
    echo "'reflector' is already installed."
fi

# Generate a new, optimized mirrorlist.
# This finds the 5 most recently synchronized HTTPS mirrors, sorts them by download rate,
# and saves them to your mirrorlist.
# You can adjust '--latest 5' to a higher number if you want more mirrors.
echo "Generating a new pacman mirrorlist using reflector..."
sudo reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
echo "New mirrorlist generated. Contents of new mirrorlist:"
sudo cat /etc/pacman.d/mirrorlist

# Force Pacman to refresh its package databases against the new mirrors
echo "Synchronizing pacman databases with new mirrors..."
sudo pacman -Syy

# Clear the pacman cache, just in case there are corrupted partial downloads
echo "Clearing pacman cache for corrupted files..."
sudo pacman -Sc --noconfirm # This will remove old cached packages. You can choose not to use --noconfirm if you want to review.

# Now, retry the original installation command for qemu, libvirt, and edk2-ovmf
echo "Retrying installation of qemu, libvirt, and edk2-ovmf..."
sudo pacman -S qemu libvirt edk2-ovmf --noconfirm

# If prompted for qemu provider, type '1' for qemu-base and press Enter.
# You can modify the above line to include the choice, but for interactive choice, it's better to leave it.
# For example: sudo pacman -S qemu-base libvirt edk2-ovmf --noconfirm if you want to explicitly choose.

# Output a reminder for the next steps from the previous conversation
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!! After this installation, remember the next steps:               !!!"
echo "!!! 1. Add your user to 'kvm' and 'libvirt' groups.                 !!!"
echo "!!!    (Already in the previous script, but good to remember)       !!!"
echo "!!! 2. Enable and start 'libvirtd.service'.                         !!!"
echo "!!!    (Already in the previous script, but good to remember)       !!!"
echo "!!! 3. Verify KVM with 'kvm-ok'.                                    !!!"
echo "!!! 4. REBOOT YOUR SYSTEM! This is CRUCIAL for group changes.       !!!"
echo "!!! 5. Then proceed with Android Studio installation.               !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
