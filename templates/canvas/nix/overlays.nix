packages: {
  default = final: _: {
    canvas = packages.${final.stdenv.system}.default;
  };
}
