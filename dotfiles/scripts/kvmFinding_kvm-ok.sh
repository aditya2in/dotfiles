# Backup your .zshrc file
echo "Creating a backup of your ~/.zshrc file..."
cp ~/.zshrc ~/.zshrc.bak_$(date +%Y%m%d_%H%M%S)
echo "Backup created at ~/.zshrc.bak_$(date +%Y%m%d_%H%M%S)"

# 1. Find the location of kvm-ok
echo "Searching for 'kvm-ok' executable on your system..."
KVM_OK_PATH=$(sudo find /usr/bin /usr/local/bin /opt -name kvm-ok 2>/dev/null | head -n 1)

if [ -z "$KVM_OK_PATH" ]; then
    echo "ERROR: 'kvm-ok' was not found in common binary paths. This is unexpected."
    echo "Please ensure 'qemu-tools' was installed successfully and try again after a full system update."
    echo "You can try a broader search with: sudo find / -name kvm-ok 2>/dev/null"
else
    KVM_OK_DIR=$(dirname "$KVM_OK_PATH")
    echo "Found 'kvm-ok' at: $KVM_OK_PATH"
    echo "Its directory is: $KVM_OK_DIR"

    # 2. Check if the directory is in your current PATH
    echo "Checking your current PATH environment variable..."
    echo "Current PATH: $PATH"

    if [[ ":$PATH:" == *":$KVM_OK_DIR:"* ]]; then
        echo "The directory '$KVM_OK_DIR' is already in your PATH."
        echo "The issue might be your shell's cache. Let's try rehash one more time."
        rehash # For zsh
        hash -r # For bash/zsh
    else
        echo "The directory '$KVM_OK_DIR' is NOT in your PATH."
        echo "Adding '$KVM_OK_DIR' to your PATH in ~/.zshrc..."
        # Add the export line to .zshrc if it's not already there
        if ! grep -q "export PATH=\"$KVM_OK_DIR:\$PATH\"" ~/.zshrc; then
            echo -e "\n# Add kvm-ok directory to PATH" | tee -a ~/.zshrc
            echo "export PATH=\"$KVM_OK_DIR:\$PATH\"" | tee -a ~/.zshrc
            echo "Added 'export PATH=\"$KVM_OK_DIR:\$PATH\"' to ~/.zshrc"
        else
            echo "Path '$KVM_OK_DIR' already seems to be configured in ~/.zshrc."
            echo "It might be commented out or in a different format. Please check ~/.zshrc manually if issues persist."
        fi

        # Source .zshrc to apply changes to current session
        echo "Sourcing ~/.zshrc to apply PATH changes..."
        . ~/.zshrc
    fi

    # Final attempt to run kvm-ok
    echo "Attempting to run 'kvm-ok' after PATH check/update..."
    kvm-ok
fi
