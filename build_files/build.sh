#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
systemctl enable systemd-timesyncd
systemctl enable systemd-resolved.service

dnf -y install 'dnf5-command(config-manager)'

dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf config-manager setopt tailscale-stable.enabled=0
dnf -y install --enablerepo='tailscale-stable' tailscale

if [ "$(rpm -E "%{fedora}")" == 43 ] ; then
  dnf -y copr enable ublue-os/flatpak-test
  dnf -y copr disable ublue-os/flatpak-test
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
  rpm -q flatpak --qf "%{NAME} %{VENDOR}\n" | grep ublue-os
fi


dnf -y copr enable ublue-os/packages
dnf -y copr disable ublue-os/packages
dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install uupd ublue-os-udev-rules

systemctl enable uupd.timer

dnf -y copr enable zirconium/packages
dnf -y copr disable zirconium/packages
dnf -y --enablerepo copr:copr.fedorainfracloud.org:zirconium:packages install matugen

dnf -y copr enable avengemedia/danklinux
dnf -y copr disable avengemedia/danklinux
dnf -y --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux install quickshell-git


dnf -y copr enable avengemedia/dms-git
dnf -y copr disable avengemedia/dms-git
dnf -y \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:dms-git \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux \
    install --setopt=install_weak_deps=False \
    dms \
    dms-cli \
    dms-greeter \
    dgop \
    dsearch

dnf -y install \
    brightnessctl \
    cava \
    ddcutil \
    ptyxis \
    fpaste \
    git-core \
    labwc \
    glycin-thumbnailer \
    gnome-disk-utility \
    gnome-keyring \
    gnome-keyring-pam \
    greetd \
    greetd-selinux \
    just \
    nautilus \
    openssh-askpass \
    orca \
    pipewire \
    playerctl \
    steam-devices \
    udiskie \
    webp-pixbuf-loader \
    wireplumber \
    wl-clipboard \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    xdg-user-dirs

rm -rf /usr/share/doc/just

dnf install -y --setopt=install_weak_deps=False \
    kf6-kirigami \
    qt6ct \
    plasma-breeze \
    kf6-qqc2-desktop-style

sed --sandbox -i -e '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd


# Add Flathub to the image for eventual application
mkdir -p /etc/flatpak/remotes.d/
curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
systemctl enable --global gnome-keyring-daemon.service
systemctl enable --global gnome-keyring-daemon.socket
systemctl enable brew-setup.service
systemctl enable flatpak-preinstall.service
systemctl enable --global bazaar.service


tee /usr/lib/sysusers.d/greeter.conf <<'EOF'
g greeter 767
u greeter 767 "Greetd greeter"
EOF
