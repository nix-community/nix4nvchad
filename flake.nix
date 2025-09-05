{
  description = ''
    NvChad is Blazing fast Neovim config
    providing solid defaults and a beautiful UI https://nvchad.com/
    This home manager module will add NvChad configuration to your Nix setup
    You can specify in the configuration your own extended configuration
    built on the starter repository
    You can also add runtime dependencies that will be isolated from the main
    system but available to NvChad. This is useful for adding lsp servers.
    If you are using your own Neovim build and not from nixpkgs
    you can also specify your package.
    In addition, you can continue to configure NvChad in the usual way
    manually by disabling the hm-activation option
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    nvchad-starter = {
      url = "github:NvChad/starter/main"; # people who want to use a different starter could override this.
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nvchad-starter,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = rec {
          nvchad = pkgs.callPackage ./nix/nvchad.nix { starterRepo = nvchad-starter; };
          default = nvchad;
        };
        apps = rec {
          nvchad =
            flake-utils.lib.mkApp { 
              drv = self.packages.${system}.nvchad;
              name = "nvim";
            }
            # ? workaround add meta attrs to avoid warning message
            // {
              meta = self.packages.${system}.nvchad.meta;
            };
          default = nvchad;
        };
        checks = self.packages.${system};
      }
    )
    // {
      homeManagerModules = rec {
        nvchad = import ./nix/module.nix { starterRepo = nvchad-starter; };
        default = nvchad;
      };
      homeManagerModule = self.homeManagerModules.nvchad;
    };
}
