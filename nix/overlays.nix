{ nvchad-starter }:
{
  nvchad = final: prev: {
    nvchad = final.callPackage ./nvchad.nix {
      starterRepo = nvchad-starter;
    };
  };
}
