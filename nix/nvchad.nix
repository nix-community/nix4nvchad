# █▄░█ █░█ █▀▀ █░█ ▄▀█ █▀▄ ▀
# █░▀█ ▀▄▀ █▄▄ █▀█ █▀█ █▄▀ ▄
# -- -- -- -- -- -- -- -- --

{ stdenvNoCC
,fetchFromGitHub
,makeWrapper
,lib
,coreutils
,findutils
,git
,gcc
,neovim
,nodejs
,lua5_1
,lua-language-server
,ripgrep
,tree-sitter
,extraPackages ? []
,extraConfig ? ./starter.nix
}: with lib;
stdenvNoCC.mkDerivation rec {
  pname = "nvchad";
  version = "2.5";
  src = (
    if extraConfig == ./starter.nix then fetchFromGitHub (import extraConfig) 
    else extraConfig
  );
  nvChadBin = ../bin/nvchad.sh;
  nvChadContrib = ../contrib;
  buildInputs = [ makeWrapper ];
  nativeBuildInputs = (
    lists.unique (
      extraPackages ++ [
        coreutils
        findutils
        git
        gcc
        nodejs
        lua-language-server
        (lua5_1.withPackages(ps: with ps; [ luarocks ]))
        ripgrep
        tree-sitter
      ]
    )
  ) ++ [ neovim ];
  installPhase = ''
    mkdir -p $out/{bin,config}
    cp -r $src/* $out/config
    install -Dm755 $nvChadBin $out/bin/nvim
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
    maintainers = with maintainers; [ MOIS3Y ];
  };
}
