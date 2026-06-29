{ pkgs }:
{
  # Local dev database with auto-init, listening on TCP localhost using the host
  # and port from config/$CANVAS_ENV.yaml. Data lives under ./data/postgres.
  # Start with: nix run .#postgres
  postgres = {
    type = "app";
    program = "${pkgs.writeShellScript "postgres-app" ''
      set -e

      ENV=''${CANVAS_ENV:-dev}
      CONFIG_FILE="$PWD/config/$ENV.yaml"

      if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Config file not found: $CONFIG_FILE"
        exit 1
      fi

      DB_PORT=''${DB_PORT:-$(${pkgs.yq-go}/bin/yq '.database.port' "$CONFIG_FILE")}
      DB_NAME=''${DB_NAME:-$(${pkgs.yq-go}/bin/yq '.database.database_name' "$CONFIG_FILE")}

      echo "Loading configuration from: $CONFIG_FILE"
      echo "  Database: $DB_NAME"
      echo "  Port:     $DB_PORT (TCP, localhost)"
      echo ""

      PGDATA="$PWD/data/postgres"

      if [ ! -d "$PGDATA" ]; then
        echo "Initializing PostgreSQL database in $PGDATA..."
        ${pkgs.postgresql}/bin/initdb -D "$PGDATA" --no-locale --encoding=UTF8

        cat >> "$PGDATA/postgresql.conf" <<EOF
      listen_addresses = 'localhost'
      port = $DB_PORT
      unix_socket_directories = '$PGDATA'
      EOF

        ${pkgs.postgresql}/bin/pg_ctl -D "$PGDATA" -w -o "-p $DB_PORT" start
        ${pkgs.postgresql}/bin/createuser -h localhost -p "$DB_PORT" -s postgres || true
        ${pkgs.postgresql}/bin/createdb -h localhost -p "$DB_PORT" -U postgres "$DB_NAME" || true
        ${pkgs.postgresql}/bin/pg_ctl -D "$PGDATA" stop
        echo "Created postgres role and $DB_NAME database!"
      fi

      echo "Starting PostgreSQL on localhost:$DB_PORT ..."
      echo "  Connect with: psql -h localhost -p $DB_PORT -U postgres $DB_NAME"
      echo "  Press Ctrl+C to stop"
      echo ""

      ${pkgs.postgresql}/bin/postgres -D "$PGDATA"
    ''}";
  };
}
