# Advanced Usage

## Overriding the Starter Repository

By default, `nix4nvchad` pulls the [NvChad starter template](https://github.com/NvChad/starter) to initialize the configuration. This provides a minimal, fast setup out-of-the-box.

> [!IMPORTANT]
> If you have your own fork of the starter repository or a completely customized NvChad structure, you can override the source used to build the derivation. Your repository or local folder **must** follow the structure of the official NvChad starter.

**Benefits of a Custom Starter:**
1. **Portability:** You can maintain your Neovim configuration in pure, vanilla Lua. This means you can clone and use your configuration on any machine or distribution, even if it doesn't have Nix installed.
2. **Minimal Nix Config:** Your Nix configuration remains incredibly clean. You only need to declare `nix4nvchad` and populate `extraPackages` to guarantee that Neovim can find the executables for your LSPs, formatters, and linters.

### Defining the Custom Source

You can override the source by defining it in your `flake.nix` inputs. This can be a GitHub repository or a local path on your machine.

**Example (GitHub Repository):**
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    # Your custom NvChad configuration repository
    my-nvchad-config = {
      url = "github:YOUR_USERNAME/my-nvchad-config";
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

**Example (Local Folder):**
If you manage your dotfiles in a single repository and want to point to a local `nvim` folder:
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    # Path to your local nvim configuration folder
    my-nvchad-config = {
      url = "path:./path/to/your/nvim/folder";
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

Once the input is overridden, `nix4nvchad` will automatically use your custom Lua files to build the wrapped Neovim derivation.
