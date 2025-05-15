# kubuntu setup

This is my daily driver build, home.nix contains all the non-gui packages that can run outside sandboxes to prevent issues and installing nixGL. The setup script installs all essentials for me via nix home-manager and direct installs as well.

To run do: `curl -O https://raw.githubusercontent.com/tanujdargan/kubuntu/refs/heads/main/setup.sh` then give execute permissions to the script `chmod u+x ./setup.sh` and run it using `./setup.sh`.

This script will do the following:
1) Install Nix Home Manager using Determinate Nix Installer
2) Prepare Home Manager as per your version
3) Apply my home.nix config file to install packages.
4) Install Spotify via apt directly from its repo for easy Spicetify install
5) Install Flatpak
6) Install Brave Browser via apt and its official repo
7) Install Discord via apt and its official .deb file
8) Install Vencord via apt
9) Install Spicetify
10) Install remaining GUI based apps via flatpak
