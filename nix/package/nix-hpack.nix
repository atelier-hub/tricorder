{
  writeShellApplication,
  nix,
  yq-go,
  hpack,
  mktemp,
  findutils,
}:
writeShellApplication {
  name = "nix-hpack";
  runtimeInputs = [
    nix
    yq-go
    hpack
    mktemp
    findutils
  ];
  text = ''
    info() {
      echo "$@" >&2
    }

    usage() {
      info "Usage: nix-hpack [packages...]"
      info "Args:"
      info "  packages:  Path to a package directory containing a 'package.nix' to"
      info "             convert."
      info "             Defaults to converting every package under the current working"
      info "             directory."
    }

    for arg in "$@"; do
      case "$arg" in
        --help|-h)
          usage
          exit 0
          ;;
      esac
    done

    packages=("$@")

    if [ ''${#packages[@]} -eq 0 ]; then
      # If no packages are specified, find all packages in the current
      # directory.
      mapfile -t packages < <(find . -type f -name "package.nix" -printf "%h\n")
    fi

    for package in "''${packages[@]}"; do
      info "Converting $package"
      source="$package/package.nix"

      if [ ! -f "$source" ]; then
        info "No package.nix file found in $package"
        exit 1
      fi

      temp_yaml="$package/package.yaml"

      # nix-instantiate tries to initialize /nix/var/nix on startup, which fails
      # in a sandbox. Repackageect to a writable tmpdir for pure --eval use.
      nix_state=$(mktemp -d)
      export NIX_STATE_package="$nix_state"
      export NIX_LOG_package="$nix_state/log"

      nix-instantiate --strict --json --eval "$source" \
        | yq --prettyPrint --input-format json --output-format yaml >> "$temp_yaml"

      hpack --silent "$temp_yaml" &>/dev/null
      rm -rf "$temp_yaml" "$nix_state"
    done
  '';
}
