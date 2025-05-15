# ~/.config/home-manager/home.nix
{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.username = "tanujd";
  home.homeDirectory = "/home/tanujd";

  home.packages = with pkgs; [
    powertop
    tlp
    auto-cpufreq
    thermald
    alsa-utils
    qbittorrent
    git
    wget
    cmake
    alacritty
    gcc
    kitty
    nodejs
    curl
    htop
    gparted
    lm_sensors
    nodejs_22
    openssh
    pnpm
    zip
    unzip
    rustup
    neofetch
    acpi

    (python3.withPackages (ps: with ps; [
      jupyter
      matplotlib
      numpy
      pep8
      requests
      scipy
      setuptools
      virtualenv
    ]))
  ];

  programs.git.enable = true;
  programs.firefox.enable = true;

  home.stateVersion = "24.11";
}
