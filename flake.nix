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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nvchad-starter.url = "github:NvChad/starter/main"; # people who want to use diffrent starter could override this.
    nvchad-starter.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      nvchad-starter,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      # Executed by `nix build .#<name>`
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        rec {
          nvchad = pkgs.callPackage ./nix/nvchad.nix { starterRepo = "${nvchad-starter}"; };
          default = nvchad;
        }
      );
      # Executed by `nix run .#<name>
      apps = forAllSystems (system: rec {
        nvchad = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/nvim";
        };
        default = nvchad;
      });
      homeManagerModules = rec {
        nvchad = import ./nix/module.nix {
          inherit nvchad-starter;
        };
        default = nvchad;
      };
      homeManagerModule = self.homeManagerModules.nvchad;
      checks = self.packages;
    };
}
