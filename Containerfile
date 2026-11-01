FROM quay.io/fedora/fedora-bootc:44

# Utilities
RUN dnf -y install \
        dnf5-plugins \
        intel-gmmlib \
        bolt \
        libva-intel-media-driver \
        pciutils \
        smartmontools \
        gvfs \
        thermald \
        fprintd \
        libfprint \
        kernel-modules-extra \
        btop \
        fastfetch \
        vim-enhanced \
        git \
        curl \
        wget \
        persepolis \
        util-linux-core \
        util-linux \
        glibc-locale-source \
        glibc-langpack-en \
        plymouth\
        plymouth-theme-breeze \
        7zip \
        zip \
        sudo

# Network, Bluetooth, Wifi
RUN dnf -y install \
        NetworkManager \
        NetworkManager-wifi \
        NetworkManager-bluetooth \
        wireless-regdb \
        bluez-obexd

# Firewall
RUN dnf -y install \
        firewalld \
        firewall-config \
        sealert \
        setroubleshoot

# Sound
RUN dnf -y install \
        alsa-utils \
        alsa-ucm \
        alsa-sof-firmware \
        pipewire-utils

# Media, Codecs
RUN dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
RUN dnf install -y --allowerasing ffmpeg vlc gthumb

#Install Fonts
# Install Fonts
RUN mkdir -p /usr/local/share/fonts/FiraCode /usr/local/share/fonts/Symbols && \
    curl -fLo /tmp/FiraCode.zip \
        https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/FiraCode.zip && \
    curl -fLo /tmp/NerdFontsSymbolsOnly.zip \
        https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/NerdFontsSymbolsOnly.zip && \
    unzip -o /tmp/FiraCode.zip "*.ttf" -d /usr/local/share/fonts/FiraCode/ && \
    unzip -o /tmp/NerdFontsSymbolsOnly.zip "*.ttf" -d /usr/local/share/fonts/Symbols/ && \
    fc-cache -fV && \
    rm -f /tmp/FiraCode.zip /tmp/NerdFontsSymbolsOnly.zip

# Nix Dir, will be bind mounted to /var/nix
RUN mkdir -p /nix

# Plymouth Enable 
COPY plymouth.toml /usr/lib/bootc/kargs.d/50-plymouth.toml
RUN plymouth-set-default-theme breeze


# Plasma Desktop
RUN dnf -y install @kde-desktop keepassxc

# Garbage removal
RUN dnf remove -y plasma-welcome

# Helium Browser
RUN dnf copr enable -y imput/helium && dnf install -y helium-bin

# Clean UP
RUN dnf clean all -y

# Enable desktop, NW
RUN systemctl enable plasmalogin.service -f
RUN systemctl enable NetworkManager.service -f
RUN systemctl enable firewalld.service -f
