# nix4nvchad

**A seamless way to integrate NvChad, a blazing fast Neovim configuration, into your Nix setup.**

`nix4nvchad` provides a declarative, reproducible way to install and configure [NvChad](https://nvchad.com/) using Nix flakes. It safely manages NvChad's runtime state by automatically provisioning its configuration directory while keeping your system environment clean by injecting LSP servers and tools exclusively into the Neovim wrapper.

<div align="center">

[![Docs](https://img.shields.io/badge/docs-latest-blue?style=for-the-badge&labelColor=101418)](https://nix-community.github.io/nix4nvchad/)
![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white&labelColor=101418)
![Neovim](https://img.shields.io/badge/Neovim-57A143?style=for-the-badge&logo=neovim&logoColor=white&labelColor=101418)
![Lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white&labelColor=101418)
[![License](https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge&labelColor=101418)](./LICENSE)

<br>

<img src="https://nvchad.com/screenshots/onedark.webp" width="80%" alt="NvChad Screenshot">

</div>

## Key Features

- **Home Manager Integration:** Easily configure NvChad using our provided Home Manager module.
- **Standalone Package:** Use it independently of Home Manager by overriding the Nix derivation directly.
- **Isolated Dependencies:** Manage your runtime dependencies (like LSP servers, formatters, and tools) in isolation. They are made available exclusively to NvChad without polluting your global `$PATH`.
- **Custom Starter:** Swap the default starter repository with your own fork to maintain pure, vanilla Lua configuration while leveraging Nix for dependencies.

## Quick Try

Want to see it in action without installing? You can run it directly:

```console
nix run github:nix-community/nix4nvchad
```

> [!WARNING]  
> If you already have an existing Neovim configuration at `~/.config/nvim`, this command will create a backup before launching. Make sure your environment is safe.

## Usage Guide

Comprehensive guides on installation, configuration, and advanced usage are available in the official **[Documentation](https://nix-community.github.io/nix4nvchad/)**.

### Table of Contents
- [Installation](https://nix-community.github.io/nix4nvchad/installation.html)
- [Configuration Options](https://nix-community.github.io/nix4nvchad/configuration.html)
- [Advanced Usage](https://nix-community.github.io/nix4nvchad/advanced_usage.html)

## License

This project is licensed under the **GPL-3.0** License.
