# Installation

To install and use `nix4nvchad`, you must have Nix flakes enabled on your system. 

There are two primary ways to integrate `nix4nvchad` into your setup: using the provided **Home Manager module** or using the **Standalone Package**.

## Setting up Inputs

First, you need to add the repository to your `flake.nix` inputs. 

You can use the default configuration which automatically pulls the standard NvChad starter repository, or you can override it to use your own fork or local configuration folder.

**Default Input:**

> [!NOTE]
> The default configuration pulls the standard [NvChad starter template](https://github.com/NvChad/starter). This is a minimal, blazing-fast setup. It's especially useful for servers or lightweight environments where you just want a solid Neovim base without writing custom plugins.

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  # ...
}
```

**Input with Custom Starter Repository:**

If you have a customized NvChad setup that follows the structure of the starter template, you can override the `nvchad-starter` input. This tells the flake to build NvChad using your source instead of the default.

> [!TIP]
> **Why do this?** Keeping your NvChad configuration in a separate repository using vanilla Lua allows you to use the exact same configuration on systems without Nix. In your Nix configuration, you only need to enable `nix4nvchad` and pass `extraPackages` to ensure all LSPs and tools are perfectly wired up. See [Advanced Usage](advanced_usage.md#overriding-the-starter-repository) for more details.

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    # Your custom NvChad configuration repository or local folder
    my-nvchad-config = {
      url = "github:YOUR_USERNAME/your-nvchad-repo";
      # Or for a local folder: url = "path:./nvim-config";
      flake = false;
    };

    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nvchad-starter.follows = "my-nvchad-config"; # Overrides the starter
    };
  };
  # ...
}
```

## Configuring Outputs

Once your inputs are set, you need to make `nix4nvchad` available in your outputs. You can access the package or module directly by its path, or by passing `inputs` into your NixOS/Home Manager configuration.

**Example 1: Passing `inputs` to a NixOS Module (with Home Manager):**
```nix
  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.my-system = nixpkgs.lib.nixosSystem {
      inherit system;
      # Makes 'inputs' available in NixOS configuration.nix
      specialArgs = { inherit inputs; }; 
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager {
          # Makes 'inputs' available in Home Manager home.nix
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.myuser = import ./home.nix;
        }
      ];
    };
  };
```

**Example 2: Passing `inputs` for Standalone Home Manager (or nix-darwin):**
```nix
  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
  let
    system = "aarch64-darwin"; # Or x86_64-linux
    pkgs = import nixpkgs { inherit system; };
  in
  {
    homeConfigurations."myuser" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      # Makes 'inputs' available in home.nix
      extraSpecialArgs = { inherit inputs; };
      modules = [ ./home.nix ];
    };
  };
```

## Method 1: Home Manager Module (Recommended)

If you use Home Manager, you can simply import the module.

> [!WARNING]
> **Do not install the standard `neovim` package and `nix4nvchad` at the same time.** 
> `nix4nvchad` wraps the `nvim` executable and exposes it to the system. If you enable both the Home Manager `programs.neovim` module (or install `pkgs.neovim` globally) and `nvchad`, it will lead to an executable collision. Even if it installs, whichever `nvim` binary appears first in your `$PATH` will take precedence, resulting in undefined behavior and failing plugins.

**❌ WRONG:**
```nix
{ inputs, pkgs, ... }: {
  imports = [ inputs.nix4nvchad.homeManagerModules.default ];

  programs.nvchad.enable = true;
  programs.neovim.enable = true; # Collision!
  home.packages = [ pkgs.neovim ]; # Collision!
}
```

**✅ CORRECT:**
```nix
{ inputs, pkgs, ... }: {
  imports = [ inputs.nix4nvchad.homeManagerModules.default ];

  programs.nvchad = {
    enable = true;
    # You can configure extra options here (see the Configuration section)
  };
}
```

## Method 2: Standalone Package

If you do not use Home Manager or prefer to handle the package directly, you can access the derivation from the flake outputs. 

You can use the package as-is if you rely entirely on a custom starter repository (defined in inputs) or just want the default setup.

```nix
{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  environment.systemPackages = [ inputs.nix4nvchad.packages.${system}.default ];
}
```

### Overriding the Package

If you need to inject Nix packages or configure extra options via Nix, you can use the `.override` method to customize the package before installing it. 

*Details on all available override parameters are in the [Configuration](configuration.md) section.*

#### Local variable definition
```nix
{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  nvchad = inputs.nix4nvchad.packages.${system}.default.override {
    # Custom configuration goes here
  };
in
{
  environment.systemPackages = [ nvchad ];
  # Or for Home Manager: home.packages = [ nvchad ];
}
```

### Using an Overlay (Recommended for Standalone)
To make your customized NvChad globally accessible as `pkgs.nvchad`, you can define an overlay.

```nix
{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  nixpkgs.overlays = [
    (final: prev: {
      nvchad = inputs.nix4nvchad.packages.${system}.default.override {
        # Custom configuration goes here
      };
    })
  ];

  # Now you can use it just like any other package from nixpkgs
  environment.systemPackages = [ pkgs.nvchad ];
}
```