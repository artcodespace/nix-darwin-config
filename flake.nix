{
  description = "Nix Darwin configuration for mac";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nix-darwin,
    nixpkgs,
  }: let
    configuration = {pkgs, ...}: {
      # TODO >>> extract this into a configuration.nix file
      # To search by name, run: nix-env -qaP | grep wget
      environment.systemPackages = [
        # Fix for poor mac default window management
        pkgs.rectangle
        pkgs.yabai
      ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true; # default shell on catalina

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # sudo via fingerprint
      security.pam.enableSudoTouchIdAuth = true;

      system.defaults = {
        dock = {
          autohide = true;
          mru-spaces = false;
          persistent-apps = [
            "${pkgs.wezterm}/Applications/Wezterm.app"
            "${pkgs.rectangle}/Applications/Rectangle.app"
          ];
        };
        finder = {
          AppleShowAllExtensions = true;
          FXPreferredViewStyle = "clmv";
        };
        NSGlobalDomain = {
          AppleICUForce24HourTime = true;
          AppleInterfaceStyle = "Dark";
          KeyRepeat = 2;
        };
      };

      system.keyboard = {
        enableKeyMapping = true;
        remapCapsLockToEscape = true;
        swapLeftCtrlAndFn = true;
      };

      fonts.packages = [
        (pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];})
      ];
    };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#mac
    darwinConfigurations.mac = nix-darwin.lib.darwinSystem {
      modules = [configuration];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."mac".pkgs;
  };
}
