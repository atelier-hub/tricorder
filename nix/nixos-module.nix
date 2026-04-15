{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.ghcib;
in
{
  options.programs.ghcib = {
    enable = lib.mkEnableOption "ghcib GHCi build daemon";
    package = lib.mkPackageOption pkgs "ghcib" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
