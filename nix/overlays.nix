packages: {
  default = final: _: {
    tricorder = packages.${final.stdenv.system}.default;
  };
}
