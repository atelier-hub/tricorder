{
  writeShellApplication,
  nix,
  yq-go,
  hpack,
}:
writeShellApplication {
  name = "nix2hpack";
  runtimeInputs = [
    nix
    yq-go
    hpack
  ];
  text = ''
    info() {
      echo "$@" >&2
    }

    usage() {
      info "Usage: nix2hpack <package-dir> [dest-dir]"
      info "Args:"
      info "  package-dir: Path to package directory with a 'package.nix' file to convert."
      info "  dest-dir:    Optional. Destination directory for the generated 'package.yaml' file."
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

    dir="$1"
    pkgnix="$dir/package.nix"
    if [ ! -f "$pkgnix" ]; then
      info "No package.nix file found in $dir"
      exit 1
    fi

    dest="''${2:-"$dir/package.yaml"}"
    if [ "$dest" = "" ]; then
      info "Specified empty destination.";
      exit 1
    fi

    echo "# Generated with nix2hpack from package.nix" > "$dest"
    echo "" >> "$dest"
    nix-instantiate --strict --json --eval "$pkgnix" \
      | yq --prettyPrint --input-format json --output-format yaml >> "$dest"

    hpack "$dest"
  '';
}
