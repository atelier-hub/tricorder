{
  description = "Cardano Hoarding Node";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tmp-postgres = {
      url = "github:jfischoff/tmp-postgres";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
      tmp-postgres,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system}.extend (
        final: prev: {
          haskellPackages = prev.haskellPackages.override {
            overrides = hfinal: hprev: {
              eve = prev.haskellPackages.callCabal2nix "eve" (prev.fetchFromGitHub {
                owner = "cgeorgii";
                repo = "eve";
                rev = "nixified";
                sha256 = "sha256-wX1UTtO7e0FHk8eoGywocYCMUa9r+BYzR6RWFKjM2C8=";
              }) { };

              # Build tmp-postgres from source with tests disabled
              tmp-postgres = prev.haskell.lib.dontCheck (
                prev.haskellPackages.callCabal2nix "tmp-postgres" tmp-postgres { }
              );
            };
          };
        }
      );
    in
    {
      # Main packages - Haskell project built with callCabal2nix
      packages.${system} = {
        hoard = pkgs.haskellPackages.callCabal2nix "hoard" ./. { };
        default = self.packages.${system}.hoard;
      };

      # Custom apps for code quality tools and dev services
      apps.${system} = {
        # Weeder: detects unused code by building HIE files and analyzing dependencies
        weeder = {
          type = "app";
          program = "${pkgs.writeShellScript "weeder-app" ''
            echo "Building project with HIE files..."
            ${pkgs.haskellPackages.cabal-install}/bin/cabal build --ghc-options=-fwrite-ide-info
            echo "Running weeder to detect unused code..."
            ${pkgs.haskellPackages.weeder}/bin/weeder
          ''}";
        };

        # HLint auto-fix: applies safe refactorings to all Haskell files
        hlint-fix = {
          type = "app";
          program = "${pkgs.writeShellScript "hlint-fix-app" ''
            echo "Running hlint --refactor on all Haskell files..."
            find src app test -name "*.hs" -exec ${pkgs.haskellPackages.hlint}/bin/hlint --refactor {} \;
            echo "Hlint refactoring complete!"
          ''}";
        };

        # PostgreSQL: local dev database with auto-init
        postgres = {
          type = "app";
          program = "${pkgs.writeShellScript "postgres-app" ''
            set -e
            PGDATA="$PWD/postgres-data"
            PGHOST="$PWD/postgres-data"

            # Initialize database if it doesn't exist
            if [ ! -d "$PGDATA" ]; then
              echo "Initializing PostgreSQL database in $PGDATA..."
              ${pkgs.postgresql}/bin/initdb -D "$PGDATA" --no-locale --encoding=UTF8

              # Configure for local socket-only access
              cat >> "$PGDATA/postgresql.conf" <<EOF
            unix_socket_directories = '$PGHOST'
            listen_addresses = '''
            port = 5432
            EOF

              echo "Database initialized!"

              # Start postgres temporarily to create roles and databases
              ${pkgs.postgresql}/bin/pg_ctl -D "$PGDATA" -o "-k $PGHOST" -w start

              # Create postgres role (superuser for dev convenience)
              ${pkgs.postgresql}/bin/createuser -h "$PGHOST" -s postgres

              # Create hoard_dev database
              ${pkgs.postgresql}/bin/createdb -h "$PGHOST" -U postgres hoard_dev

              # Stop postgres
              ${pkgs.postgresql}/bin/pg_ctl -D "$PGDATA" stop

              echo "Created postgres role and hoard_dev database!"
            fi

            echo "Starting PostgreSQL..."
            echo "Connection info:"
            echo "  Socket: $PGHOST/.s.PGSQL.5432"
            echo "  Database: hoard_dev"
            echo "  User: postgres (no password needed)"
            echo ""
            echo "To connect: psql -h $PGHOST -U postgres hoard_dev"
            echo "Press Ctrl+C to stop"
            echo ""

            # Start postgres
            ${pkgs.postgresql}/bin/postgres -D "$PGDATA" -k "$PGHOST"
          ''}";
        };
      };

      # Build checks and validation
      checks.${system} = {
        hoard = pkgs.haskell.lib.overrideCabal (pkgs.haskellPackages.callCabal2nix "hoard" ./. { }) (drv: {
          doCheck = true;
          testToolDepends = (drv.testToolDepends or [ ]) ++ [
            pkgs.postgresql
            pkgs.sqitchPg
          ];
          # initdb requires HOME to exist; Nix sandbox doesn't provide one
          preCheck = ''
            export HOME="$TMPDIR"
          ''
          + (drv.preCheck or "");
        });
        git-hooks = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            hlint.enable = true;
            hpack.enable = true;
            nixfmt-rfc-style.enable = true;
            ormolu.enable = true;
          };
        };
      };

      # Development environment with tools and git hooks
      devShells.${system}.default = pkgs.haskellPackages.shellFor {
        packages = p: [ self.packages.${system}.hoard ];

        # Haskell development tools
        buildInputs = with pkgs.haskellPackages; [
          cabal-install
          ghcid
          haskell-language-server
          hlint
          tasty-discover
          weeder
        ];

        # Non-Haskell tools
        nativeBuildInputs = with pkgs; [
          hpack
          nixfmt
          postgresql # psql and other postgres client tools
          pre-commit
          sqitchPg # database migration tool
        ];

        # Git hooks integration and PostgreSQL configuration
        shellHook = ''
          ${self.checks.${system}.git-hooks.shellHook}
          # Set PGHOST for PostgreSQL Unix socket connections
          export PGHOST="$PWD/postgres-data"
          echo "PostgreSQL socket directory: $PGHOST"
        '';
      };
    };
}
