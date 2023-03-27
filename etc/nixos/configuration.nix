# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# When configuration is changed, rerun `nixos-rebuild switch`.


{ config, pkgs, callPackages, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # (see https://nixos.wiki/wiki/Flakes)
  
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  networking.hostName = "alonzo";       # after F1 driver Fernando (not Church) 

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  environment.variables.EDITOR = "emacs";

  services.autorandr.enable = true;


  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
  };

  # Configure keymap in X11
  ## services.xserver = {
  ##  layout = "us";
  ##  xkbVariant = "";
  ## };
  services.xserver = {
    enable = true;
    autorun = true;
    layout = "us,no";
    xkbModel = "pc105";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable fingerprint reader: login/unlock with fingerprint; add one with `fprintd-enroll`
  services.fprintd.enable = true;
  # services.fprintd.tod.enable = true;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;
  # security.pam.services.login.fprintAuth = true;
  # security.pam.services.xscreensaver.fprintAuth = true;
  # similarly for other PAM providers


  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # -- Doom Emacs -----------------------------------------------------------------
  # see: https://github.com/nix-community/emacs-overlay#quickstart
  # services.emacs.package = pkgs.emacsUnstable;
  nixpkgs.overlays = [
    (import (builtins.fetchTarball https://github.com/nix-community/emacs-overlay/archive/master.tar.gz))
  ];
  # -------------------------------------------------------------------------------


  # List packages installed in system profile. To search: `nix search wget` or `nix-env -qaP wget`
  environment.systemPackages = with pkgs; [ 
    wget
    vscode

    firefox
    google-chrome
    dmenu
    fira-code

    alacritty
    fzf
    silver-searcher 

    meld 
    git 
    direnv

    nodejs
    gnumake
    cmake

    ripgrep 
    rlwrap 
    nixfmt
    shellcheck

    emacs
    coreutils
    fd
    (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
    emacsPackages.undo-fu
    haskellPackages.ghc
    haskellPackages.cabal-install
    haskellPackages.haskell-language-server
    haskellPackages.hoogle

  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1"; # see https://nixos.wiki/wiki/Slack

  # Some programs need SUID wrappers, can be configured further or are started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ## ohMyZsh.enable = true;
    ## ohMyZsh.theme = "lambda";
    ## ohMyZsh.plugins = [ "git" ];
  };

  # FONTS
  fonts.fonts = with pkgs; [
    noto-fonts noto-fonts-cjk noto-fonts-emoji
    liberation_ttf
    fira-code fira-mono fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];


  # Define a user account.
  users.users.williamdemeo = {
    isNormalUser = true;
    description = "William DeMeo";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ tdesktop oh-my-zsh starship texlive.combined.scheme-medium megasync ];
  };


  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # Enable automatic weekly garbage collection (gc).

  nix.gc = {
                  automatic = true;
                  dates = "weekly";
                  options = "--delete-older-than 7d";
           };


  # After `sudo nixos-rebuild switch`, check gc is running: `systemctl list-timers`.


  # Reduce "swappiness".

  boot.kernel.sysctl = { "vm.swappiness" = 10;};

  # After `sudo nixos-rebuild switch`, check swappiness: `cat /proc/sys/vm/swappiness`.



}

