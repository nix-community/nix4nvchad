# █▄░█ █░█ █▀▀ █░█ ▄▀█ █▀▄ ▀
# █░▀█ ▀▄▀ █▄▄ █▀█ █▀█ █▄▀ ▄
# -- -- -- -- -- -- -- -- --

{
  stdenvNoCC,
  writeText,
  fetchFromGitHub,
  makeWrapper,
  lib,
  coreutils,
  findutils,
  git,
  gcc,
  neovim,
  nodejs,
  lua5_1,
  lua-language-server,
  ripgrep,
  tree-sitter,
  extraPackages ? [ ], # the default value is for import from flake.nix
  extraConfig ? "",
  starterRepo,
  lazy-lock ? "",
}:
with lib;
stdenvNoCC.mkDerivation rec {
  pname = "nvchad";
  version = "2.5";
  src = starterRepo;
  nvChadBin = ../bin/nvchad.sh;
  nvChadContrib = ../contrib;
  buildInputs = [ makeWrapper ];
  extraConfigFile = writeText "extraConfig.lua" extraConfig;
  NewInitFile = writeText "init.lua" ''
    require "init"
    require "extraConfig"
  '';
  LockFile = writeText "lazy-lock.json" lazy-lock;
  nativeBuildInputs =
    (lists.unique (
      extraPackages
      ++ [
        coreutils
        findutils
        git
        gcc
        nodejs
        lua-language-server
        (lua5_1.withPackages (ps: with ps; [ luarocks ]))
        ripgrep
        tree-sitter
      ]
    ))
    ++ [ neovim ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,config}
    cp -r $src/* $out/config
    chmod 777 $out/config
    chmod 777 $out/config/lua # cp make it unwritable
    install -Dm777 $nvChadBin $out/bin/nvim
    install -Dm777 $LockFile $out/config/lazy-lock.json
    install -Dm777 "$extraConfigFile" $out/config/lua/extraConfig.lua;
    mv $out/config/init.lua $out/config/lua/init.lua
    install -Dm777 $NewInitFile $out/config/init.lua
    wrapProgram $out/bin/nvim --prefix PATH : '${makeBinPath nativeBuildInputs}'
    runHook postInstall
  '';
  postInstall = ''
    mkdir -p $out/share/{applications,icons/hicolor/scalable/apps}
    cp $nvChadContrib/nvim.desktop $out/share/applications
    cp $nvChadContrib/nvchad.svg $out/share/icons/hicolor/scalable/apps
  '';
  meta = {
    description = ''
      Blazing fast Neovim config providing solid defaults and a beautiful UI
    '';
    homepage = "https://nvchad.com/";
    license = licenses.gpl3;
    mainProgram = "nvim";
    maintainers = with maintainers; [
      MOIS3Y
      bot-wxt1221
    ];
  };
}
