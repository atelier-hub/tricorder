{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.tricorder;
in
{
  options.programs.tricorder = {
    enable = lib.mkEnableOption "tricorder GHCi build daemon";
    package = lib.mkPackageOption pkgs "tricorder" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
