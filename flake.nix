{
  description = "First attempt at a Darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
      # THIS IS ALL GOING TO CHANGE WITH HOME MANAGER, JUST SLING EVERYTHING IN FOR NOW
      pkgs.git-credential-manager
      # MAC STUFF
      pkgs.rectangle
	  # TERMINAL
      pkgs.wezterm
	  # COMMAND LINE TOOLS
      pkgs.git
      pkgs.neovim
	  pkgs.stow
	  pkgs.yazi
	  pkgs.ripgrep
	  pkgs.fzf
	  pkgs.fd
	  # LANGUAGE SUPPORT
	  pkgs.lua-language-server
	  pkgs.stylua
	  pkgs.nodejs_22
	  pkgs.nodePackages.typescript-language-server
	  pkgs.nodePackages.eslint
	  pkgs.prettierd
	  pkgs.nodePackages.nodemon
	  pkgs.vscode-langservers-extracted
        ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # EDITED BELOW HERE
      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # sudo via fingerprint
      security.pam.enableSudoTouchIdAuth = true;

      # system stuff
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
        (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      ];
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."mac".pkgs;
  };
}
