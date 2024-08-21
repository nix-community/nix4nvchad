# NvChad on Nix

![logo](https://camo.githubusercontent.com/0c8e304d05532523126d58c26c874afeefed5df97071e7429dd43d5e8f9b705f/68747470733a2f2f6e76636861642e636f6d2f73637265656e73686f74732f6f6e656461726b2e77656270)

## What is it?

The repository contains nix flake to install the [NvChad](https://nvchad.com/)
configuration on any system that uses `Nix` and `nix flakes`.

### Flake contains:

- nvchad package
- nvchad overlay
- home manager module

You can choose any of the presented methods to install NvChad.


## General notes

NvChad itself is not an executable file, it is a perfect configuration for [Neovim](https://neovim.io/).

Unfortunately there is no easy way to add it to `/nix/store`
More precisely, it’s easy to add it, but it won’t work, at least for now (version 2.5)

This is due to the fact that by default `neovim` reads 
the file `~/.config/nvim/init.lua` and starts.
NvChad lazily loads plugins and on first load, `lazyvim` will save
`lazy-lock.json` next to `~/.config/nvim/init.lua`
As you understand, this is not a problem for any distribution and it 
does not violate the principles of [The Twelve Factor App](https://12factor.net/config)
because, as already said, NvChad is a configuration and not a package with an application.
But with Nix the problem is /nix/store is a read-only system,
the source code trying to write a file or change the current one will result in an error.
There will also be a problem with the ability to change the configuration
on the fly, since this changes the `chadrc.lua` file

The method We used to solve this problem (home-manager module) is a hack.
Don't worry, it doesn't break anything, but it doesn't follow the basic
principle of how home-manager adds configuration files to the user's home directory.
Absolutely all configuration files are stored in `/nix/store/`
By default, the home manager creates symbolic links from `/nix/store/` to the user's home directory.
This ensures that configuration changes after the next generation build are available to the user.

In addition, if you have ever created a declarative configuration
for vanilla `neovim` you know that plugins are also stored in `/nix/store/`
NvChad installs plugins in `~/.local/share/nvim/`.
This is not a problem for us, they are still immutable until you explicitly update them.
If your own NvChad configuration which you pass
to the module as `config.programs.nvchad.extraConfig`
contains `lazy-lock.json` specific plugin versions will be installed.

Here's everything you need to know before you start using NvChad with Nix
If you still need to add NvChad to your configuration, welcome!


## How it works?

- you add this repository as `inputs` to flake.nix of your configuration
- you add a package with `NvChad` to your configuration as an overlay or as a `home-manager` module
- specify extraPackages and extraConfig for the package or module
- you are building a new system generation
- as a result, you will receive an executable file `nvim`, nvim.desktop to launch from the launcher and your own configuration overlay if you passed extraConfig
- each extraPackages is available to NvChad, if this is for example an LSP server, NvChad will find its executable file
- extraPackages are not available globally, they are only available in the NvChad scope
- if you do not pass any parameters only extraPackages for starter configuration are included


# Quick use without installation to try

```console
nix run github:NvChad/nix/#nvchad
```

⚠️**WARNING**⚠️

Run the command above if you are not using your `neovim` configuration!

- If you already have a `neovim` configuration in `~/.config/nvim` and `init.lua` is present there
nvchad will not copy the configuration to the home directory and will probably not start correctly
- If there is no `init.lua` in `~/.config/nvim` but there are any other files, this will overwrite
`~/.config/nvim` with the `NvChad starter` configuration
- Your current configuration will be saved in `~/.config/nvim/nvim_%Y_%m_%d_%H_%M_%S.bak`


# Installation

To install it you **must have flake enabled** and your NixOS configuration
**must be managed with flakes.** See [Flakes](https://nixos.wiki/wiki/Flakes) for
instructions on how to install and enable them on NixOS.

### First step

You can add this flake as inputs in `flake.nix` in the repository
containing your NixOS configuration:

```nix
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ...
    nvchad4nix = {
    url = "github:NvChad/nix";
    inputs.nixpkgs.follows = "nixpkgs";
    };
    # ...
  };
```

This flake provides an overlay for Nixpkgs, with package and a home-manager module.

They are respectively found in the flake as

- `inputs.nvchad4nix.overlays.default`
- `inputs.nvchad4nix.overlays.nvchad`
- `inputs.nvchad4nix.packages.${system}.default`
- `inputs.nvchad4nix.packages.${system}.nvchad`
- `inputs.nvchad4nix.homeManagerModule`
  
(Where `${system}` is either `x86_64-linux` `aarch64-linux` `x86_64-darwin` `aarch64-darwin`)

### Second step

Output data can be added in different ways, for example this is how I do it for NixOS:

In the example below, the home manager is installed as a NixOS module

```nix
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      extraSpecialArgs = { inherit system; inherit inputs; };  # <- passing inputs to the attribute set for home-manager
      specialArgs = { inherit system; inherit inputs; };       # <- passing inputs to the attribute set for NixOS (optional)
    in {
    nixosConfigurations = {
      desktop-laptop = lib.nixosSystem {
        modules = [
          inherit specialArgs;           # <- this will make inputs available anywhere in the NixOS configuration
          ./path/to/configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager = {
              inherit extraSpecialArgs;  # <- this will make inputs available anywhere in the HM configuration
              useGlobalPkgs = true;
              useUserPackages = true;
              users.yourUserName = import ./path/to/home.nix;
            };
          }
        ];
      };
    };
  };
```

If you are new to NixOS here is a useful channel [Vimjoyer](https://www.youtube.com/watch?v=rEovNpg7J0M)


### Third step (Optional)

All we have to do is add nvchad to the list of available packages using overlays

Somewhere in your `configuration.nix`

```nix
{ config, pkgs, inputs, ... }: {  # <-- inputs from flake
  # ...
  nixpkgs = { 
    overlays = [
      (final: prev: {
        nvchad = inputs.nvchad4nix.packages."${pkgs.system}".nvchad;
      })
    ];
  };
  # ...
}
```

Or add directly to `flake.nix`

```nix
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      extraSpecialArgs = { inherit system; inherit inputs; };  # <- passing inputs to the attribute set for home-manager
      specialArgs = { inherit system; inherit inputs; };       # <- passing inputs to the attribute set for NixOS (optional)
    in {
    nixosConfigurations = {
      desktop-laptop = lib.nixosSystem {
        modules = [
          inherit specialArgs;           # <- this will make inputs available anywhere in the NixOS configuration
          ./path/to/configuration.nix
          {  # <- # example to add the overlay to Nixpkgs:
            nixpkgs = {
              overlays = [
                inputs.nvchad4nix.overlays.default
              ];
            };
          }
          home-manager.nixosModules.home-manager {
            home-manager = {
              inherit extraSpecialArgs;  # <- this will make inputs available anywhere in the HM configuration
              useGlobalPkgs = true;
              useUserPackages = true;
              users.yourUserName = import ./path/to/home.nix;
            };
          }
        ];
      };
    };
  };
```


Now you can call the package anywhere as a package from nixpkgs

- `pkgs.nvchad`

Examples:
- `users.users.<name>.packages = [ pkgs.nvchad ];` NixOS
- `home.packages = with pkgs; [ pkgs.nvchad ];`  home-manager

# Configuration

Depending on which usage method you choose, take a look at a couple of snippets:

### home-manager module

Somewhere in your `home.nix` or a separate module:

Default:

```nix
{ inputs, config, pkgs, ... }: {
  imports = [
    inputs.nvchad4nix.homeManagerModule
  ];
  programs.nvchad.enable = true;
}
```

Or with customization of options:


```nix
{ inputs, config, pkgs, ... }: {
  imports = [
    inputs.nvchad4nix.homeManagerModule
  ];
  programs.nvchad = {
    enable = true;
    extraPackages = with pkgs; [
      nodePackages.bash-language-server
      docker-compose-language-service
      dockerfile-language-server-nodejs
      emmet-language-server
      nixd
      (python3.withPackages(ps: with ps; [
        python-lsp-server
        flake8
      ]))
    ];
    extraConfig = pkgs.fetchFromGitHub {  # <- you can set your repo here
      owner = "NvChad";
      repo = "starter";
      rev = "41c5b467339d34460c921a1764c4da5a07cdddf7";
      sha256 = "sha256-yxZTxFnw5oV/76g+qkKs7UIwgkpD+LkN/6IJxiV9iRY=";
      name = "nvchad-2.5-starter";
    };
    hm-activation = true;
    backup = true;
  };
}
```

You can also add your repository with vanilla `NvChad` setup
and your overlay based on [Starter](https://github.com/NvChad/starter) on pure `.lua`
to flake.nix `inputs`

```nix
  inputs = {
    # Default:
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # NvChad:
    nvchad4nix = {
      url = "github:NvChad/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvchad-on-steroids = {  # <- here
      url = "github:MOIS3Y/nvchad-on-steroids";
      flake = false;
    };
  };
```

And then:

Somewhere in your `home.nix` or a separate module

```nix
{ inputs, config, pkgs, ... }: {
  imports = [
    inputs.nvchad4nix.homeManagerModule
  ];
  programs.nvchad = {
    enable = true;
    extraPackages = with pkgs; [
      emmet-language-server
      nixd
    extraConfig = inputs.nvchad-on-steroids; # <- here extraConfig from inputs
    hm-activation = true;
    backup = false;
  };
}
```

#### Available options:

- enable
- extraPackages
- extraConfig
- hm-activation
- backup

##### enable (optional)

`true` or `false`

if false ignore this module when build new generation

##### neovim (optional)

`pkgs.neovim`

"neovim package for use under nvchad wrapper"


##### extraPackages (optional)

`[]` list of pkgs

List of additional packages available for NvChad as runtime dependencies
NvChad extensions assume that the libraries it need
will be available globally.
By default, all dependencies for the starting configuration are included.
Overriding the option will expand this list.

##### extraConfig (optional)

`/nix/store/your-config-package`

Your own NvChad configuration based on the starter repository.
Overriding the option will override the default configuration
included in the module. This should be the path to the nix store.
The easiest way is to use pkgs.fetchFromGitHub

##### hm-activation (optional)

`true` or `false`

It's a trick
If you do not want home-manager to manage nvchad configuration, 
set the false option. In this case, HM will not copy the configuration
saved in /nix/store to ~/.config/nvim.
This way you can customize the configuration in the usual way
by cloning it from the NvChad repository.
By default, the ~/.config/nvim is managed by HM.

##### backup (optional)

`true` or `false`

Since the module violates the principle of immutability
and copies NvChad to `~/.config/nvim` rather than creating
a symbolic link by default, it will create a backup copy of
`~/.config/nvim_%Y_%m_%d_%H_%M_%S.bak` when each generation.
This ensures that the module
will not delete the configuration accidentally.
You probably do not need backups, just disable them
`config.programs.nvchad.backup = false;`


### package override

**Note!** remember that the package is available globally for installation,
use the overlay from the section [Installation](#installation)

The package build can be customized:

```nix
{ config, pkgs, ... }: let
  my-awesome-nvchad-conf = pkgs.fetchFromGitHub {
    owner = "NvChad";
    repo = "starter";
    rev = "41c5b467339d34460c921a1764c4da5a07cdddf7";
    sha256 = "sha256-yxZTxFnw5oV/76g+qkKs7UIwgkpD+LkN/6IJxiV9iRY=";
    name = "nvchad-2.5-starter";
  };
in {
  home.packages = with pkgs; [
    (pkgs.nvchad.override {
      extraPackages = [ nixd emmet-language-server ];
      extraConfig = my-awesome-nvchad-conf;
    })
  ];
}
```

Or with inputs:

```nix
{ inputs, config, pkgs, ... }: {
  home.packages = with pkgs; [
    (pkgs.nvchad.override {
      extraPackages = [ nixd emmet-language-server ];
      extraConfig = inputs.my-awesome-nvchad-conf;
    })
  ];
}
```

# Usage

Whichever method you choose, after installation you'll probably want to run `NvChad`
Using the `nvim` wrapper executable it will be automatically available in your `$PATH`
You can also launch through the application manager (rofi, wofi, etc)
The package comes with `nvim.desktop`

If you are not using the HM module or have disabled `hm-activation`:
- `NvChad` expects `~/.config/nvim/init.lua` to be available at startup
- if the file does not exist, `NvChad` will copy it and all files from `/nix/store/hash-nvchad-2.5/config`
- this will be either your configuration or starter
- if `~/.config/nvim/` is not empty `NvChad` will create a backup copy nearby

 #### Note!

If you are using the NvChad home-manager module, do not add neovim from the standard module:

```nix
programs.neovim.enable = true;
```
Also, do not add neovim as a package to the configuration:
 ```nix
home.packages = [ pkgs.neovim ];
```
