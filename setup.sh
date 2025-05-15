#!/usr/bin/env bash
# setup.sh – Kubuntu bootstrap script (idempotent)
# Installs Nix + Home Manager, syncs home.nix, and sets up GUI + CLI apps.
# Re‑run safely: existing components are detected and skipped.
# -----------------------------------------------------------------------------
set -euo pipefail

# ─── Guards ────────────────────────────────────────────────────────────────
if [[ $(id -u) -eq 0 ]]; then
  echo "❌ Please run this script as your normal user, *not* as root or with sudo." >&2
  exit 1
fi

# Ask for sudo once up‑front so commands later don’t stall mid‑script
sudo -v || { echo "❌ Need sudo privileges to continue." >&2; exit 1; }

# ─── Helpers ────────────────────────────────────────────────────────────────
log()  { printf "\033[1;36m→ %s\033[0m\n" "$*"; }
warn() { printf "\033[1;33m⚠ %s\033[0m\n" "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }
minutes() { printf "   ⏱  %ss\n" "$(( $(date +%s) - $1 ))"; }

step() { log "${1}"; _STEP_TIMER=$(date +%s); }
finish() { minutes "$_STEP_TIMER"; }

# ─── 1 ▸ Install / activate Nix ────────────────────────────────────────────
step "Step 1/11 ▸ Ensuring Nix is available…"
if have nix; then
  log "Nix already available ✔"; finish
else
  if [[ -f /nix/receipt.json || -d /nix/store ]]; then
    warn "Partial / previous Nix detected – attempting to source env…"
    # shellcheck disable=SC1091
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" 2>/dev/null || true
  fi
  if ! have nix; then
    log "Installing Nix (Determinate Systems)…"
    curl --proto '=https' --tlsv1.2 -sSfL https://install.determinate.systems/nix | sh -s -- install
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
  finish
fi

# ─── 2 ▸ Home Manager bootstrap ────────────────────────────────────────────
step "Step 2/11 ▸ Ensuring Home Manager is available…"
if have home-manager; then
  log "Home Manager already available ✔"; finish
else
  log "Bootstrapping Home Manager…"
  nix run home-manager/master -- init --switch
  finish
fi

mkdir -p "$HOME/.config/home-manager"

# ─── 3 ▸ Prepare home.nix ──────────────────────────────────────────────────
step "Step 3/11 ▸ Preparing home.nix…"
HM_NIX="$HOME/.config/home-manager/home.nix"
STATE_VERSION="24.11"
if [[ -f "$HM_NIX" ]]; then
  STATE_VERSION=$(grep -Eo 'home\.stateVersion = "([0-9]+\.[0-9]+)"' "$HM_NIX" | grep -Eo '[0-9]+\.[0-9]+' || echo "$STATE_VERSION")
  cp -v "$HM_NIX" "${HM_NIX}.bak.$(date +%s)"
fi
log "Using home.stateVersion = $STATE_VERSION"

curl -fsSL -o "$HM_NIX" https://raw.githubusercontent.com/tanujdargan/kubuntu/refs/heads/main/home.nix
sed -i "s/home\.stateVersion = \".*\";/home.stateVersion = \"$STATE_VERSION\";/" "$HM_NIX"
finish

# ─── 4 ▸ Apply Home Manager config ─────────────────────────────────────────
step "Step 4/11 ▸ Applying Home Manager flake (may take a while)…"
nix run home-manager/master -- switch --flake "$HOME/.config/home-manager"
log "Home Manager switch done ✔"; finish

# ─── 5 ▸ Spotify repo & install ────────────────────────────────────────────
step "Step 5/11 ▸ Spotify…"
if have spotify || dpkg -l | grep -q spotify-client; then
  log "Spotify already installed ✔"; finish
else
  log "Installing Spotify…"
  if [[ ! -f /etc/apt/sources.list.d/spotify.list ]]; then
    curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | \
      sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null
    sudo apt-get -qq update
  fi
  sudo DEBIAN_FRONTEND=noninteractive apt-get -y install spotify-client
  finish
fi

# ─── 6 ▸ Flatpak & KDE integration ─────────────────────────────────────────
step "Step 6/11 ▸ Flatpak + KDE integration…"
if have flatpak; then
  log "Flatpak already installed ✔"; finish
else
  log "Installing Flatpak…"
  sudo DEBIAN_FRONTEND=noninteractive apt-get -y install flatpak kde-config-flatpak
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  finish
fi

# ─── 7 ▸ Brave Browser ─────────────────────────────────────────────────────
step "Step 7/11 ▸ Brave Browser…"
if have brave-browser || dpkg -l | grep -q brave-browser; then
  log "Brave already installed ✔"; finish
else
  log "Installing Brave…"
  curl -fsS https://dl.brave.com/install.sh | sudo bash
  finish
fi

# ─── 8 ▸ Discord ───────────────────────────────────────────────────────────
step "Step 8/11 ▸ Discord…"
if have discord; then
  log "Discord already installed ✔"; finish
else
  log "Installing Discord .deb…"
  wget -q --content-disposition "https://discord.com/api/download?platform=linux"
  sudo DEBIAN_FRONTEND=noninteractive apt-get -y install ./discord-*.deb
  rm -f discord-*.deb
  finish
fi

# ─── 9 ▸ Vencord ───────────────────────────────────────────────────────────
step "Step 9/11 ▸ Vencord…"
if [[ -d "$HOME/.config/Vencord" ]]; then
  log "Vencord already present ✔"; finish
else
  log "Installing Vencord…"
  sh -c "$(curl -sS https://raw.githubusercontent.com/Vendicated/VencordInstaller/main/install.sh)"
  finish
fi

# ─── 10 ▸ Spicetify ────────────────────────────────────────────────────────
step "Step 10/11 ▸ Spicetify…"
if have spicetify; then
  log "Spicetify CLI already installed ✔"; finish
else
  log "Installing Spicetify CLI…"
  sudo chmod a+wr /usr/share/spotify /usr/share/spotify/Apps -R || true
  curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
fi

spicetify backup apply >/dev/null 2>&1 || true
if [[ ! -d "$HOME/.config/spicetify/Extensions/spicetify-marketplace" ]]; then
  log "Installing Spicetify Marketplace…"
  yes | sh -c "$(curl -sS https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh)" >/dev/null 2>&1 || true
fi
finish

# ─── 11 ▸ Flatpak GUI apps ────────────────────────────────────────────────
step "Step 11/11 ▸ Flatpak GUI apps…"
GUI_APPS=(md.obsidian.Obsidian org.telegram.desktop com.slack.Slack \
          com.obsproject.Studio org.fkoehler.KTailctl)
for APP in "${GUI_APPS[@]}"; do
  if flatpak list --app | grep -q "${APP##*.}"; then
    log "$APP already installed ✔"
  else
    log "Installing $APP via Flatpak…"
    flatpak -y --noninteractive install flathub "$APP"
  fi
done
finish

log "\n🎉 All tasks completed successfully!"
