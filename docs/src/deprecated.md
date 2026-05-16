# Deprecated Features

This page lists features, attributes, or configuration options that are currently deprecated and slated for removal in future versions of `nix4nvchad`.

## `homeManagerModule` Attribute

The flake output attribute `inputs.nix4nvchad.homeManagerModule` is **deprecated** and will be removed in the near future. 

### Why is it being removed?

In the Nix flake ecosystem, Home Manager modules exported by a flake are inherently non-standard (unlike NixOS or nix-darwin modules). The standard and most widely accepted way to export these is under the `homeManagerModules` (plural) attribute, typically exposing the default module as `homeManagerModules.default`.

Maintaining the singular `homeManagerModule` attribute is redundant, creates unnecessary aliases in the flake output, and can trigger validation warnings in some Nix checking tools.

### What should you use instead?

You should update your imports to use the standard `homeManagerModules.default` path.

**❌ Deprecated:**
```nix
{ inputs, pkgs, ... }: {
  imports = [
    inputs.nix4nvchad.homeManagerModule
  ];
  
  programs.nvchad.enable = true;
}
```

**✅ Recommended:**
```nix
{ inputs, pkgs, ... }: {
  imports = [
    inputs.nix4nvchad.homeManagerModules.default
  ];
  
  programs.nvchad.enable = true;
}
```
