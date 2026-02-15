# █░█ █▀▄▀█ ▄▄ █▀▄▀█ █▀█ █▀▄ █░█ █░░ █▀▀ ▀
# █▀█ █░▀░█ ░░ █░▀░█ █▄█ █▄▀ █▄█ █▄▄ ██▄ ▄
# -- -- -- -- -- -- -- -- -- -- -- -- -- -

{ starterRepo }:
{
  config,
  pkgs,
  lib ? pkgs.lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    types
    mkOption
    literalExpression
    mkIf
    hm
    ;
  cfg = config.programs.nvchad;
  nvchad = pkgs.callPackage ./nvchad.nix {
    inherit starterRepo;
    neovim = cfg.neovim;
    gcc_new = cfg.gcc;
    extraPackages = cfg.extraPackages;
    extraPlugins = cfg.extraPlugins;
    extraConfig = cfg.extraConfig;
    chadrcConfig = cfg.chadrcConfig;
    lazy-lock = cfg.lazy-lock;
    withDesktopFile = cfg.withDesktopFile;
  };
in
{
  options.programs.nvchad = {
    enable = mkEnableOption "Whether to enable NvChad.";
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        List of additional packages available for NvChad as runtime dependencies
        NvChad extensions assume that the libraries it need
        will be available globally.
        By default, all dependencies for the starting configuration are included.
        Overriding the option will expand this list.
      '';
      example = literalExpression ''
        with pkgs; [
          nodePackages.bash-language-server
          emmet-language-server
          nixd
          (python3.withPackages(ps: with ps; [
            python-lsp-server
            flake8
          ]))
        ];
      '';
    };
    neovim = mkOption {
      type = types.package;
      default = pkgs.neovim;
      defaultText = literalExpression "pkgs.neovim";
      description = "neovim package for use under nvchad wrapper";
    };
    extraPlugins = mkOption {
      type = types.str;
      default = "";
      description = ''
        The extra plugins you want to install.
        That's a part of lazy.nvim config.
        return {...}
      '';
    };
    extraConfig = mkOption {
      type = types.str;
      default = "";
      description = ''
        These config are loaded after nvchad in the end of init.lua in starter
      '';
    };
    chadrcConfig = mkOption {
      type = types.str;
      default = "";
      description = ''
        This config replaces the chadrc.lua file.
        Make sure to include `local M = {}` at the top,
        and `return M` at the bottom.
      '';
    };
    gcc = mkOption {
      type = types.package;
      default = pkgs.gcc;
      description = "The gcc you want to use";
    };
    lazy-lock = mkOption {
      type = types.str;
      default = "";
      description = ''
        Your lazy-lock.json. Left it blank if is not needed
      '';
    };
    withDesktopFile = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to add a .desktop file for Nvchad";
    };
    backup = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Since the module violates the principle of immutability
        and copies NvChad to ~/.config/nvim rather than creating
        a symbolic link by default, it will create a backup copy of
        ~/.config/nvim_%Y_%m_%d_%H_%M_%S.bak when each generation.
        This ensures that the module
        will not delete the configuration accidentally.
        You probably do not need backups, just disable them
        config.programs.nvchad.backup = false;
      '';
    };
    hm-activation = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If you do not want home-manager to manage nvchad configuration, 
        set the false option. In this case, HM will not copy the configuration
        saved in /nix/store to ~/.config/nvim.
        This way you can customize the configuration in the usual way
        by cloning it from the NvChad repository.
        By default, the ~/.config/nvim is managed by HM.
      '';
    };
  };
  config =
    let
      confDir = "${config.xdg.configHome}/nvim";
    in
    mkIf cfg.enable {
      assertions = [
        {
          assertion = !config.programs.neovim.enable;
          message = ''
            NvChad provides a neovim binary, please choose which you want to use.

            Use the default neovim binary:
            programs.neovim.enable = true;

            Use the Nvchad neovim binary:
            programs.nvchad.enable = true;

            You cannot use both at the same time.
          '';
        }
      ];
      home = {
        packages = [ nvchad ];
        activation =
          let
            coreutils = pkgs.coreutils;
          in
          mkIf cfg.hm-activation {
            backupNvChad = hm.dag.entryBefore [ "checkLinkTargets" ] ''
              if [ -d "${confDir}" ]; then
                ${
                  (
                    if cfg.backup then
                      ''
                        backup_name="nvim_$(${coreutils}/bin/date +'%Y_%m_%d_%H_%M_%S').bak"
                        ${coreutils}/bin/mv \
                          ${confDir} \
                          ${config.xdg.configHome}/$backup_name
                      ''
                    else
                      ''
                        ${coreutils}/bin/rm -r ${confDir}
                      ''
                  )
                }
              fi
            '';
            copyNvChad = hm.dag.entryAfter [ "writeBoundary" ] ''
              ${coreutils}/bin/mkdir -p ${confDir}
              ${coreutils}/bin/cp -r ${nvchad}/config/* ${confDir}
              for file_or_dir in $(${pkgs.findutils}/bin/find ${confDir}); do
                if [ -d "$file_or_dir" ]; then
                  ${coreutils}/bin/chmod 755 $file_or_dir
                else
                  ${coreutils}/bin/chmod 664 $file_or_dir
                fi
              done
            '';
          };
      };
    };
}
