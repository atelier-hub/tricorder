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
      info "Usage: nix-hpack [--keep] [packages...]"
      info "Args:"
      info "  --keep:    Keep the generated package.yaml file. By default, the generated"
      info "             package.yaml file is deleted once hpack has generated the .cabal"
      info "             file."
      info "  packages:  Path to a package directory containing a 'package.nix' to"
      info "             convert."
      info "             Defaults to converting every package under the current working"
      info "             directory."
    }

    packages=()
    keep_package_yaml=false
    for arg in "$@"; do
      case "$arg" in
        --help|-h)
          usage
          exit 0
          ;;
        --keep)
          keep_package_yaml=true
          ;;
        *)
          packages+=("$arg")
          ;;
      esac
    done

    if [ ''${#packages[@]} -eq 0 ]; then
      # If no packages are specified, find all packages in the current
      # directory.
      mapfile -t packages < <(find "$PWD" -type f -name "package.nix" -printf "%h\n")
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
      export NIX_STATE_DIR="$nix_state"
      export NIX_LOG_DIR="$nix_state/log"
      nix-instantiate --strict --json --eval "$source" \
        | yq --prettyPrint --input-format json --output-format yaml >> "$temp_yaml"
      rm -rf "$nix_state"

      hpack --silent "$temp_yaml" &>/dev/null
      if test "$keep_package_yaml" = "false"; then
        rm -rf "$temp_yaml"
      fi
    done
  '';
}
