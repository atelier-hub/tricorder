{
  writeShellApplication,
  nix,
  yq-go,
  hpack,
  mktemp,
}:
writeShellApplication {
  name = "nix-hpack";
  runtimeInputs = [
    nix
    yq-go
    hpack
    mktemp
  ];
  text = ''
    info() {
      echo "$@" >&2
    }

    usage() {
      info "Usage: nix-hpack <source> [destination]"
      info "Args:"
      info "  source:      Path to a directory containing a 'package.nix' file, or to a"
      info "               '.nix' file, to convert."
      info "  destination: Optional. Destination for the generated '.cabal' file. If a"
      info "               directory is specified, the cabal file retains its"
      info "               package-specific file name."
      info "               Defaults to the same directory as 'source'."
    }

    if [ "$#" -lt 1 ] || [ "$1" = "" ]; then
      info "No package directory specified."
      usage
      exit 1
    fi

    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
      usage
      exit 0
    fi

    source_file="$1"
    source_dir="$(dirname -- "$source_file")"
    if [ -d "$source_file" ]; then
      source_dir="$source_file"
      source_file="$source_file/package.nix"
      if [ ! -f "$source_file" ]; then
        info "No package.nix file found in $source_dir"
        exit 1
      fi
    fi

    if [ ! -f "$source_file" ]; then
      info "No nix file to convert to hpack yaml found at $source_dir"
      exit 1
    fi

    dest="''${2:-"$source_dir"}"
    if [ "$dest" = "" ]; then
      info "Specified empty destination.";
      exit 1
    fi

    yaml_dest="$source_dir/package.yaml"

    # nix-instantiate tries to initialize /nix/var/nix on startup, which fails
    # in a sandbox. Redirect to a writable tmpdir for pure --eval use.
    nix_state=$(mktemp -d)
    export NIX_STATE_DIR="$nix_state"
    export NIX_LOG_DIR="$nix_state/log"

    nix-instantiate --strict --json --eval "$source_file" \
      | yq --prettyPrint --input-format json --output-format yaml >> "$yaml_dest"

    hpack --silent "$yaml_dest" &>/dev/null
    mv "$source_dir"/*.cabal "$dest" &>/dev/null || true
    rm -rf "$yaml_dest" "$nix_state"
  '';
}
