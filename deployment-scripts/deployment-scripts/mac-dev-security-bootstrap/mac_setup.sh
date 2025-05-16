#!/usr/bin/env bash
# this is a test
clear
date
set -euo pipefail

readonly BREW_APPS=(
  tor-browser arc firefox microsoft-edge orion google-chrome
  anki blender signal notion obsidian karabiner-elements raycast
  logi-option+ home-assistant microsoft-powerpoint microsoft-excel
  orcaslicer twingate mullvadvpn visual-studio-code ghostty
  raspberry-pi-imager macvim nikitabobko/tab/aerospace balenaetcher
  docker pika chatgpt discord obs bitwarden sf-symbols wezterm
  alacritty warp keycastr webstorm xnapper
)

readonly MAS_APPS_ID=(
  571213070 640199958 1355679052 935235287 1099568401 409201541 1233965871 497799835
)

readonly MAS_APP_NAME=(
  DaVinci_Resolve Apple_Developer Dropover Encrypto Home_Assistant Pages ScreenBrush Xcode
)
readonly FONTS=(
  sf-symbols font-jetbrains-mono font-sketchybar-app-font font-hack-nerd-font
)
readonly CLI_TOOLS=(
  atuin bat btop cmatrix eza fzf git neovim nmap stow thefuck tldr yazi
  zoxide zsh-autosuggestions zsh-syntax-highlighting lazygit bitwarden-cli
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
  # Use ANSI escapes via $'…' so Bash expands them correctly
  local RED=$'\e[1;31m'
  local RESET=$'\e[0m'

  while true; do
    # Prompt using read+printf so we control exactly what’s printed
    printf "%s [Y/n]: " "$message"
    read -r answer
    answer=${answer:-$default}

    case "$answer" in
    [Yy]*) return 0 ;; # Yes
    [Nn]*) return 1 ;; # No
    *)
      clear
      # printf always interprets \e, no -e flag needed
      printf "%sPlease press [Y/n].%s\n" "$RED" "$RESET"
      ;;
    esac
  done
}

wait_for_enter() {
  read -rp $'Are you ready to continue? Press ENTER to proceed...\n' _
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
  clear

  if yes_no "Do you want to install Homebrew?" Y; then
    clear
    echo "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    clear
    echo "Skipping Homebrew."
  fi

  clear
  if yes_no "Install all brew Mac applications?" Y; then
    clear
    mode=$(select_option "Choose install mode" a "a m")
    if [ "$mode" = "a" ]; then
      echo "Installing ALL apps…"
      for app in "${BREW_APPS[@]}"; do
        echo "-> Installing $BREW_APPS"
        brew install --cask "$BREW_APPS"
      done
    else
      clear
      echo "Let’s pick apps one by one…"
      for app in "${BREW_APPS[@]}"; do
        if yes_no "Would you like to install $app ?" N; then
          clear
          echo "Installing $app ..."
          brew install --cask "$app"
          clear
        else
          clear
          echo "Skipping $app."
        fi
      done
    fi
  else
    clear
    echo "No apps will be installed."
  fi
  clear

  if yes_no "Install developer fonts (monospaced, icons)?" Y; then
    for font in "${FONTS[@]}"; do
      echo "Installing $font ..."
      brew install --cask "$font"
    done
  fi
  clear
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

  if yes_no "Install all mas Mac applications (only works when apps where installed an different mac  before and the mas cli tool has been installed)?" Y; then
    clear
    echo "please login into the appstore to continue ..."
    wait_for_enter
    clear
    mode=$(select_option "Choose Installation, mode A for automatic installation and M for manual Installation " a "a m")
    if [ "$mode" = "a" ]; then
      clear
      echo "Installing ALL MAS apps…"
      # loop over indices, not values
      for i in "${!MAS_APPS_ID[@]}"; do
        id=${MAS_APPS_ID[i]}
        name=${MAS_APP_NAME[i]}
        echo "-> Installing $name"
        mas install "$id"
        clear
      done
    else
      clear
      echo "Let’s pick MAS apps one by one…"
      for i in "${!MAS_APPS_ID[@]}"; do
        id=${MAS_APPS_ID[i]}
        name=${MAS_APP_NAME[i]}
        if yes_no "Would you like to install $name ?" N; then
          clear
          echo "Installing $name ..."
          mas install "$id"
          clear
        else
          clear
          echo "Skipping $name."
        fi
      done
    fi
  else
    clear
    echo "No MAS apps will be installed."
  fi
  clear
  if yes_no "Hide the Dock ?" Y; then
    clear
    echo "Hiding Dock…"
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 1
    defaults write com.apple.dock autohide-time-modifier -float 0.5
    killall Dock # Restart Dock to apply changes
  fi
  clear
  if yes_no "Enable firewall with stealth mode?" Y; then
    clear
    echo "Turning on firewall…"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
  fi

  if yes_no "Enable auto updates for mac os and appstore ?" Y; then
    clear
    echo "Enable auto updates (passcode may be nesssery)"
    /usr/bin/sudo /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
    /usr/bin/sudo /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
    /usr/bin/sudo /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool TRUE
    /usr/bin/sudo /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
    /usr/bin/sudo /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
    /usr/bin/sudo /usr/bin/defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool TRUE
  fi
  clear
  if yes_no "" Y; then
    clear
    #set minimum passcode leangth to 20
    /usr/bin/sudo /usr/bin/pwpolicy -n /Local/Default -setglobalpolicy "minChars=20"
    #veryfiy thats it configure
    pwpolicy -n /Local/Default -getglobalpolicy
    #set minimum Shift characters to 1
    /usr/bin/sudo /usr/bin/pwpolicy -n /Local/Default -setglobalpolicy "requiresAlpha=1"
    #set minimum numbers to 2
    /usr/bin/sudo /usr/bin/pwpolicy -n /Local/Default -setglobalpolicy "requiresNumeric=2"
    #set minimum special characters to 1
    /usr/bin/sudo /usr/bin/pwpolicy -n /Local/Default -setglobalpolicy "requiresSymbol=1"
    # set minimum of lowercase and uppercse characters to 1
    /usr/bin/sudo /usr/bin/pwpolicy -n /Local/Default -setglobalpolicy "requiresMixedCase=1".
    # set minimum passcode age to 2 month
    /usr/bin/sudo /usr/bin/pwpolicy -n /Local/Default -setglobalpolicy "maxMinutesUntilChangePassword=43200"
    # set so none of the last 20 passcpodes can be reused
    /usr/bin/sudo /usr/bin/pwpolicy -n /Local/Default -setglobalpolicy "usingHistory=20"

  fi
  clear
  if yes_no "Clone and apply custom dotfiles?" Y; then
    clear
    echo "Getting dotfiles…"
    git clone https://github.com/xM0Se/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    stow . # Use GNU Stow to symlink your dotfiles
    cd "$HOME"
  fi
  clear
  if yes_no "Set a desktop wallpaper?" Y; then
    clear
    choice=$(select_option "Pick wallpaper number" 1 "${WALLPAPERS[*]}")
    echo "Setting wallpaper #$choice ..."
    osascript -e "tell application \"System Events\" to set picture of every desktop to \"$HOME/mac_setup/wallpaper/wallpaper${choice}.jpg\""
  fi

  clear
  echo "🏁 All done! Your Mac is ready to go!"
}

if yes_no "Ready to start the setup script?" Y; then
  main
else
  echo "mac_setup script aborted"
fi
