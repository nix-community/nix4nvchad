# █▄░█ █░█ █▀▀ █░█ ▄▀█ █▀▄ ▀
# █░▀█ ▀▄▀ █▄▄ █▀█ █▀█ █▄▀ ▄
# -- -- -- -- -- -- -- -- --

{ stdenvNoCC
, writeText
, makeWrapper
, lib
, coreutils
, findutils
, git
, gcc
, gcc_new ? gcc
, neovim
, nodejs
, lua5_1
, lua-language-server
, ripgrep
, tree-sitter
, extraPackages ? [ ] # the default value is for import from flake.nix
, extraConfig ? ""
, chadrcConfig ? ""
, starterRepo
, extraPlugins ? "return {}"
, lazy-lock ? ""
}:
let
  inherit (lib)
    lists
    makeBinPath
    licenses
    maintainers
    optionalString
    ;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nvchad";
  version = "2.5";
  src = starterRepo;
  nvChadBin = ../bin/nvchad.sh;
  nvChadContrib = ../contrib;
  extraConfigFile = writeText "extraConfig.lua" extraConfig;
  NewInitFile = writeText "init.lua" ''
    require "init"
    require "extraConfig"
  '';
  extraPluginsFile = writeText "plugins-2.lua" extraPlugins;
  NewPluginsFile = writeText "init.lua" ''
    M1 = require "plugins.init-1"
    M2 = require "plugins.init-2"
    for i = 1, #M2 do
      M1[#M1 + 1] = M2[i]
    end
    return M1
  '';
  NewChadrcFile = writeText "chadrc.lua" chadrcConfig;
  LockFile = writeText "lazy-lock.json" lazy-lock;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = (lists.unique (
    extraPackages
    ++ [
      coreutils
      findutils
      git
      gcc_new
      nodejs
      lua-language-server
      (lua5_1.withPackages (ps: with ps; [ luarocks ]))
      ripgrep
      tree-sitter
    ]
  )) ++ [ neovim ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,config}
    cp -r $src/* $out/config
    chmod 777 $out/config
    chmod 777 $out/config/lua # cp make it unwritable
    chmod 777 $out/config/lua/plugins
    ${optionalString (chadrcConfig != "") "install -Dm777 $NewChadrcFile $out/config/lua/chadrc.lua"}
    mv $out/config/lua/plugins/init.lua $out/config/lua/plugins/init-1.lua
    install -Dm777 $extraPluginsFile $out/config/lua/plugins/init-2.lua
    install -Dm777 $NewPluginsFile $out/config/lua/plugins/init.lua
    install -Dm777 $nvChadBin $out/bin/nvim
    install -Dm777 $LockFile $out/config/lazy-lock.json
    install -Dm777 "$extraConfigFile" $out/config/lua/extraConfig.lua;
    mv $out/config/init.lua $out/config/lua/init.lua
    install -Dm777 $NewInitFile $out/config/init.lua
    wrapProgram $out/bin/nvim --prefix PATH : '${makeBinPath finalAttrs.buildInputs}'
    runHook postInstall
  '';

  postInstall = ''
    mkdir -p $out/share/{applications,icons/hicolor/scalable/apps}
    cp $nvChadContrib/nvim.desktop $out/share/applications
    cp $nvChadContrib/nvchad.svg $out/share/icons/hicolor/scalable/apps
  '';

  meta = {
    description = "Blazing fast Neovim config providing solid defaults and a beautiful UI";
    homepage = "https://nvchad.com/";
    license = licenses.gpl3;
    mainProgram = "nvim";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = with maintainers; [
      MOIS3Y
      bot-wxt1221
    ];
  };
})