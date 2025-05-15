#!/usr/bin/env bash
date
set -euo pipefail

readonly APPS=(
  tor-browser arc firefox microsoft-edge orion google-chrome
  anki blender signal notion obsidian karabiner-elements raycast
  logi-option+ home-assistant microsoft-powerpoint microsoft-excel
  orcaslicer twingate mullvadvpn visual-studio-code ghostty
  raspberry-pi-imager macvim nikitabobko/tab/aerospace balenaetcher
  docker pika chatgpt discord obs bitwarden sf-symbols wezterm
  alacritty warp keycastr webstorm
)
readonly FONTS=(
  sf-symbols font-jetbrains-mono font-sketchybar-app-font font-hack-nerd-font
)
readonly CLI_TOOLS=(
  atuin bat btop cmatrix eza fzf git neovim nmap stow thefuck tldr yazi
  zoxide zsh-autosuggestions zsh-syntax-highlighting lazygit
)
readonly WALLPAPERS=(1 2 3 4)

prompt() {
  local message="$1" # This is the text we display
  local default="$2" # This is what we use if no input
  local input        # Temporary variable to store user input

  read -rp "$message" input

  if [ -z "$input" ]; then
    echo "$default"
  else
    echo "$input"
  fi
}

yes_no() {
  local message="$1" # The question text
  local default="$2" # Default Y or n
  local answer       # To store the user’s answer

  while true; do
    answer=$(prompt "$message [Y/n]: " "$default")
    case "$answer" in
    [Yy]) return 0 ;; # If answer starts with Y or y, return true
    [Nn]) return 1 ;; # If it starts with N or n, return false
    *)
      echo "Please press [Y/n]."
      ;; # Otherwise, loop again
    esac
  done
}

select_option() {
  local message="$1"
  local default="$2"
  local opts=($3) # Convert string into array
  local choice    # To store user’s selection

  while true; do
    read -rp "$message [${opts[*]}]: " choice
    choice="${choice:-$default}" # Use default if empty

    for opt in "${opts[@]}"; do
      if [ "$choice" = "$opt" ]; then
        echo "$choice"
        return 0
      fi
    done
    echo "Invalid choice! Please pick one of: ${opts[*]}"
  done
}

main() {
  echo "This is an automated mac setup script."
  cd "$HOME" # Go to your home folder so we install things in the right place

  if yes_no "Do you want to install Homebrew?" Y; then
    echo "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "Skipping Homebrew."
  fi

  if yes_no "Install all nice Mac applications?" Y; then
    mode=$(select_option "Choose install mode" a "a m")
    if [ "$mode" = "a" ]; then
      echo "Installing ALL apps…"
      for app in "${APPS[@]}"; do
        echo "-> Installing $app"
        brew install --cask "$app"
      done
    else
      echo "Let’s pick apps one by one…"
      for app in "${APPS[@]}"; do
        if yes_no "Would you like to install $app?" N; then
          echo "Installing $app…"
          brew install --cask "$app"
        else
          echo "Skipping $app."
        fi
      done
    fi
  else
    echo "No apps will be installed."
  fi

  if yes_no "Install developer fonts (monospaced, icons)?" Y; then
    for font in "${FONTS[@]}"; do
      echo "Installing $font…"
      brew install --cask "$font"
    done
  fi

  if yes_no "Install command-line tools?" Y; then
    mode=$(select_option "All tools or manual?" a "a m")
    if [ "$mode" = "a" ]; then
      echo "Installing ALL CLI tools…"
      for tool in "${CLI_TOOLS[@]}"; do
        echo "-> Installing $tool"
        brew install "$tool"
      done
    else
      for tool in "${CLI_TOOLS[@]}"; do
        if yes_no "Install $tool?" Y; then
          echo "Installing $tool…"
          brew install "$tool"
        else
          echo "Skipping $tool."
        fi
      done
    fi
  fi

  if yes_no "Hide the Dock automatically?" Y; then
    echo "Hiding Dock…"
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 1
    defaults write com.apple.dock autohide-time-modifier -float 0.5
    killall Dock # Restart Dock to apply changes
  fi

  if yes_no "Enable firewall with stealth mode?" Y; then
    echo "Turning on firewall…"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
  fi

  if yes_no "Clone and apply custom dotfiles?" Y; then
    echo "Getting dotfiles…"
    git clone https://github.com/xM0Se/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    stow . # Use GNU Stow to symlink your dotfiles
    cd "$HOME"
  fi

  if yes_no "Set a nice desktop wallpaper?" Y; then
    choice=$(select_option "Pick wallpaper number" 1 "${WALLPAPERS[*]}")
    echo "Setting wallpaper #$choice…"
    osascript -e "tell application \"System Events\" to set picture of every desktop to \"$HOME/mac_setup/wallpaper/wallpaper${choice}.jpg\""
  fi

  echo "🏁 All done! Your Mac is ready to go!"
}

if yes_no "Ready to start the setup script?" Y; then
  main
else
  echo "mac_setup script aborted"
fi
