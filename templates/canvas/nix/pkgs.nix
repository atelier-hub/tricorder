{ inputs, system }:
let
  fourmolu = _: _: {
    fourmolu = inputs.nixpkgs-nixos-unstable.legacyPackages.${system}.fourmolu;
  };
in
import inputs.haskell-nix.inputs.nixpkgs {
  inherit system;
  overlays = [
    inputs.haskell-nix.overlay
    fourmolu
  ];
  inherit (inputs.haskell-nix) config;
}
