#!/bin/bash
# ===================================================================================
# Fedora to macOS Ultimate Transformation & Optimization Script v5 (Final Automated)
#
# This script is focused on two goals:
#   1. A perfect, zero-touch WhiteSur macOS visual theme setup.
#   2. Maximum battery life through automated, aggressive power tuning.
#
# It automates EVERYTHING:
#   - Installation of the WhiteSur theme suite and macOS fonts.
#   - Installation and configuration of essential GNOME extensions.
#   - Installation of core features like "Quick Look" and "Spotlight".
#   - Aggressive performance and battery life tuning with TLP (no manual edits).
#
# Compatible with Fedora 40+
# Run with: ./fedora_macos_ultimate.sh
# ===================================================================================

# --- Script Configuration ---
set -e # Exit immediately if a command exits with a non-zero status.

# --- Global Variables & Cleanup ---
THEME_DIR="/tmp/macos-setup-$$" # Use process ID for a unique temp folder
trap 'rm -rf "$THEME_DIR"' EXIT # Auto-cleanup temporary files on exit
mkdir -p "$THEME_DIR"

# --- Helper Functions for Cleaner Output ---
print_header() {
    echo ""
    echo "=================================================="
    echo "  $1"
    echo "=================================================="
}

print_step() {
    echo "▶ $1"
}

# --- Main Functions ---

install_base_packages() {
    print_header "Phase 1: System Update & Prerequisites"
    
    print_step "Checking for root user..."
    if [ "$EUID" -eq 0 ]; then 
        echo "❌ Please run as a regular user (not root/sudo)."
        exit 1
    fi

    print_step "Updating all system packages..."
    sudo dnf update -y --refresh

    print_step "Enabling RPM Fusion (Free and Non-Free) repositories..."
    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

    print_step "Installing essential tools and dependencies..."
    sudo dnf install -y \
        gnome-tweaks git sassc wget p7zip p7zip-plugins curl flatpak \
        gnome-shell-extension-user-theme gnome-extensions-app
}

install_themes_and_fonts() {
    print_header "Phase 2: Installing macOS Theme & Fonts"
    
    cd "$THEME_DIR"

    print_step "Installing WhiteSur GTK Theme..."
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
    ./WhiteSur-gtk-theme/install.sh -m -N glassy --round -l

    print_step "Installing WhiteSur Icon Theme..."
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
    ./WhiteSur-icon-theme/install.sh -a

    print_step "Installing McMojave Cursor Theme..."
    git clone https://github.com/vinceliuice/McMojave-cursors.git --depth=1
    ./McMojave-cursors/install.sh
    
    print_step "Installing SF Pro Fonts..."
    git clone https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git --depth=1
    mkdir -p ~/.local/share/fonts
    find SF-Fonts -name "*.otf" -exec cp {} ~/.local/share/fonts/ \;
    fc-cache -f -v
}

apply_theming() {
    print_header "Phase 3: Applying The New Look & Feel"

    print_step "Applying GTK, icon, and cursor themes..."
    gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark"
    gsettings set org.gnome.desktop.interface icon-theme "WhiteSur"
    gsettings set org.gnome.desktop.interface cursor-theme "McMojave-cursors"
    gsettings set org.gnome.desktop.interface font-name "SF Pro Display 11"
    
    print_step "Setting window button layout to the left..."
    gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:"

    print_step "Enabling macOS-style 'Natural Scrolling'..."
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
}

install_and_configure_extensions() {
    print_header "Phase 4: Automating GNOME Extension Setup"
    cd "$THEME_DIR"

    wget -O gnome-ext-install.sh "https://git.io/Jv5kl"
    chmod +x gnome-ext-install.sh

    print_step "Installing 'Dash to Dock' (ID 307)..."
    ./gnome-ext-install.sh 307

    print_step "Installing 'Blur my Shell' (ID 3193)..."
    ./gnome-ext-install.sh 3193

    sleep 5 # Wait for schemas to be available after installation

    print_step "Enabling new extensions..."
    gnome-extensions enable dash-to-dock@micxgx.gmail.com
    gnome-extensions enable blur-my-shell@aunetx

    print_step "Configuring Dash to Dock to act like the macOS dock..."
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
    gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
}

install_power_user_apps() {
    print_header "Phase 5: Power User Application Setup"

    print_step "Installing Ulauncher (Spotlight Replacement)..."
    sudo dnf copr enable -y atim/ulauncher
    sudo dnf install -y ulauncher
    systemctl --user enable --now ulauncher

    print_step "Installing 'Sushi' for macOS-like File Preview (press Spacebar)..."
    sudo dnf install -y gnome-sushi
}

configure_power_and_security() {
    print_header "Phase 6: Automated Security, Battery & Performance Tuning"
    
    print_step "Ensuring Firewall is active..."
    sudo systemctl enable --now firewalld

    print_step "Installing TLP for advanced power management..."
    sudo dnf install -y tlp tlp-rdw
    print_step "Masking conflicting power-profiles-daemon service..."
    sudo systemctl mask power-profiles-daemon
    
    print_step "Applying aggressive battery-saving TLP configuration..."
    cat << EOF | sudo tee /etc/tlp.conf > /dev/null
# --- Automated Max Battery Configuration ---
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
SOUND_POWER_SAVE_ON_BAT=1
PCIE_ASPM_ON_BAT=powersupersave
RUNTIME_PM_ON_BAT=auto
USB_AUTOSUSPEND=1
WOL_DISABLE=Y
WIFI_PWR_ON_BAT=on
EOF

    print_step "Enabling and starting TLP service..."
    sudo systemctl enable --now tlp.service
    echo "✅ TLP is now managing your system's power."

    print_step "Optimizing RAM management with ZRAM..."
    sudo dnf install -y zram-generator
    echo -e "[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd" | sudo tee /etc/systemd/zram-generator.conf
    sudo systemctl daemon-reload

    print_step "Reducing swappiness to prioritize RAM..."
    echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf

    print_step "Installing hardware video acceleration drivers..."
    sudo dnf groupinstall -y --with-optional multimedia
    
    if lscpu | grep -q "AMD"; then
        print_step "AMD Ryzen CPU detected. Installing P-State tools for monitoring..."
        sudo dnf install -y amd-pstate-utils
    fi

    print_step "Setting up Flatpak and Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

final_instructions() {
    print_header "✅ Setup Complete! A Reboot is Required."
    echo ""
    echo "The entire macOS transformation and optimization is complete."
    echo "All settings have been applied automatically."
    echo ""
    echo "To finish the process, please REBOOT your computer now."
    echo ""
    echo "After rebooting, your new desktop will be ready."
    echo "Enjoy your efficient and beautiful new Fedora setup!"
}

# --- Execute Script ---
main() {
    install_base_packages
    install_themes_and_fonts
    apply_theming
    install_and_configure_extensions
    install_power_user_apps
    configure_power_and_security
    final_instructions
}

main