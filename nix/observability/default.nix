{
  pkgs,
  lib,
  config,
}:
let
  inherit (lib) types mkOption;

  # Module options for observability configuration
  observabilityOpts = {
    # Grafana options
    grafana = {
      allowSignUp = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to allow user registration";
      };
    };

    # Prometheus options
    prometheus = {
      enableRemoteWrite = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable remote write receiver";
      };
      serviceLabel = mkOption {
        type = types.str;
        default = "service";
        description = "Label name for service identification";
      };
      environmentLabel = mkOption {
        type = types.str;
        default = "environment";
        description = "Label name for environment identification";
      };
    };

    # Application metrics options
    metrics = {
      histogramBuckets = mkOption {
        type = types.listOf types.float;
        default = [
          0.001
          0.01
          0.1
          1.0
          10.0
        ];
        description = "Default histogram buckets for duration metrics (in seconds)";
      };
    };
  };

  # Default configuration with all options
  cfg = {
    grafana = {
      inherit (observabilityOpts.grafana)
        allowSignUp
        ;
    };
    prometheus = {
      inherit (observabilityOpts.prometheus)
        enableRemoteWrite
        serviceLabel
        environmentLabel
        ;
    };
    metrics = {
      inherit (observabilityOpts.metrics) histogramBuckets;
    };
  };

  # Helper to read config values using yq
  yq = "${pkgs.yq-go}/bin/yq";

  # Prometheus configuration script that generates config from YAML
  prometheusConfigScript = pkgs.writeShellScript "prometheus-config" ''
    CONFIG_FILE="''${CONFIG_FILE:-${config}}"
    PROMETHEUS_DATA="''${PROMETHEUS_DATA:-$PWD/data/prometheus}"
    mkdir -p "$PROMETHEUS_DATA"

    SCRAPE_INTERVAL=$(${yq} eval '.observability.prometheus.scrape_interval' "$CONFIG_FILE")
    EVAL_INTERVAL=$(${yq} eval '.observability.prometheus.evaluation_interval' "$CONFIG_FILE")
    APP_TARGET=$(${yq} eval '.observability.prometheus.targets.app' "$CONFIG_FILE")
    NODE_EXPORTER_TARGET=$(${yq} eval '.observability.prometheus.targets.node_exporter' "$CONFIG_FILE")
    PROMETHEUS_PORT=$(${yq} eval '.observability.prometheus.port' "$CONFIG_FILE")
    ENVIRONMENT=$(${yq} eval '.observability.environment' "$CONFIG_FILE")

    cat > "$PROMETHEUS_DATA/prometheus.yml" <<EOF
    global:
      scrape_interval: $SCRAPE_INTERVAL
      evaluation_interval: $EVAL_INTERVAL

    scrape_configs:
      - job_name: 'app'
        static_configs:
          - targets: ['$APP_TARGET']
            labels:
              ${cfg.prometheus.serviceLabel.default}: 'app'
              ${cfg.prometheus.environmentLabel.default}: '$ENVIRONMENT'

      - job_name: 'node_exporter'
        static_configs:
          - targets: ['$NODE_EXPORTER_TARGET']
            labels:
              ${cfg.prometheus.serviceLabel.default}: 'system'
              ${cfg.prometheus.environmentLabel.default}: '$ENVIRONMENT'

      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:$PROMETHEUS_PORT']
            labels:
              ${cfg.prometheus.serviceLabel.default}: 'prometheus'
              ${cfg.prometheus.environmentLabel.default}: '$ENVIRONMENT'
    EOF

    echo "$PROMETHEUS_DATA/prometheus.yml"
  '';

  # Tempo configuration script that generates config with runtime paths
  tempoConfigScript = pkgs.writeShellScript "tempo-config" ''
    CONFIG_FILE="''${CONFIG_FILE:-${config}}"
    TEMPO_DATA="''${TEMPO_DATA:-$PWD/data/tempo}"
    mkdir -p "$TEMPO_DATA/blocks" "$TEMPO_DATA/wal"

    HTTP_PORT=$(${yq} eval '.observability.tempo.http_port' "$CONFIG_FILE")
    BLOCK_RETENTION=$(${yq} eval '.observability.tempo.block_retention' "$CONFIG_FILE")
    MAX_BLOCK_DURATION=$(${yq} eval '.observability.tempo.max_block_duration' "$CONFIG_FILE")
    PROMETHEUS_PORT=$(${yq} eval '.observability.prometheus.port' "$CONFIG_FILE")

    cat > "$TEMPO_DATA/tempo.yaml" <<EOF
    server:
      http_listen_port: $HTTP_PORT

    query_frontend:
      search:
        duration_slo: 5s
        throughput_bytes_slo: 1.073741824e+09
      trace_by_id:
        duration_slo: 5s

    distributor:
      receivers:
        otlp:
          protocols:
            http:
            grpc:

    ingester:
      max_block_duration: $MAX_BLOCK_DURATION
      trace_idle_period: 10s
      max_block_bytes: 1000000

    metrics_generator:
      registry:
        external_labels:
          source: tempo
          cluster: local
      storage:
        path: $TEMPO_DATA/generator/wal
        remote_write:
          - url: http://localhost:$PROMETHEUS_PORT/api/v1/write
            send_exemplars: true
      # Traces storage for local_blocks processor
      traces_storage:
        path: $TEMPO_DATA/generator/traces
      # Generate span metrics for "All spans" drilldown in Grafana
      processor:
        service_graphs:
          dimensions:
            - service.name
        span_metrics:
          # Include resource attributes in target_info metric
          enable_target_info: true
          # Custom dimensions from span attributes
          dimensions:
            - span.name
            - span.kind
            - status.code
          # Histogram buckets for duration metrics (in seconds)
          histogram_buckets:
            - 0.001   # 1ms
            - 0.01    # 10ms
            - 0.1     # 100ms
            - 1.0     # 1s
            - 10.0    # 10s
        # Enable TraceQL metrics for span-level queries
        local_blocks:
          max_live_traces: 10000
          max_block_bytes: 100000000
          flush_check_period: 10s

    querier:
      max_concurrent_queries: 20

    compactor:
      compaction:
        block_retention: $BLOCK_RETENTION

    # Enable metrics generator for all tenants
    overrides:
      metrics_generator_processors:
        - service-graphs
        - span-metrics
        - local-blocks

    storage:
      trace:
        backend: local
        local:
          path: $TEMPO_DATA/blocks
        wal:
          path: $TEMPO_DATA/wal
        pool:
          max_workers: 100
          queue_depth: 10000
    EOF

    echo "$TEMPO_DATA/tempo.yaml"
  '';

  # Loki configuration script that generates config with runtime paths
  lokiConfigScript = pkgs.writeShellScript "loki-config" ''
    CONFIG_FILE="''${CONFIG_FILE:-${config}}"
    LOKI_DATA="''${LOKI_DATA:-$PWD/data/loki}"
    mkdir -p "$LOKI_DATA/chunks" "$LOKI_DATA/index" "$LOKI_DATA/boltdb-shipper-active" "$LOKI_DATA/boltdb-shipper-cache" "$LOKI_DATA/wal"

    HTTP_PORT=$(${yq} eval '.observability.loki.http_port' "$CONFIG_FILE")
    RETENTION_PERIOD=$(${yq} eval '.observability.loki.retention_period' "$CONFIG_FILE")

    cat > "$LOKI_DATA/loki.yaml" <<EOF
    auth_enabled: false

    server:
      http_listen_port: $HTTP_PORT
      grpc_listen_port: 0

    common:
      path_prefix: $LOKI_DATA
      replication_factor: 1
      ring:
        kvstore:
          store: inmemory

    schema_config:
      configs:
        - from: "2020-01-01"
          store: tsdb
          object_store: filesystem
          schema: v13
          index:
            prefix: index_
            period: 24h

    storage_config:
      filesystem:
        directory: $LOKI_DATA/chunks
      tsdb_shipper:
        active_index_directory: $LOKI_DATA/boltdb-shipper-active
        cache_location: $LOKI_DATA/boltdb-shipper-cache

    limits_config:
      retention_period: $RETENTION_PERIOD

    compactor:
      working_directory: $LOKI_DATA/compactor
      retention_enabled: true
      delete_request_store: filesystem
    EOF

    echo "$LOKI_DATA/loki.yaml"
  '';

  # Service startup scripts (reusable)
  startNodeExporter = pkgs.writeShellScript "start-node-exporter" ''
    export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
    PORT=$(${yq} eval '.observability.node_exporter.port' "$CONFIG_FILE")

    EXTRA_ARGS=()
    # WSL2 has duplicate /run/user tmpfs mounts that cause duplicate metric errors
    if grep -qi microsoft /proc/version 2>/dev/null; then
      EXTRA_ARGS+=(--collector.filesystem.mount-points-exclude="^/run/user$")
    fi

    echo "Starting Node Exporter on port $PORT..."
    exec ${pkgs.prometheus-node-exporter}/bin/node_exporter \
      --web.listen-address=:$PORT \
      "''${EXTRA_ARGS[@]}"
  '';

  startTempo = pkgs.writeShellScript "start-tempo" ''
    export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
    export TEMPO_DATA="$PWD/data/tempo"
    TEMPO_CONFIG=$(${tempoConfigScript})

    echo "Starting Tempo..."
    exec ${pkgs.tempo}/bin/tempo -config.file="$TEMPO_CONFIG"
  '';

  startLoki = pkgs.writeShellScript "start-loki" ''
    export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
    export LOKI_DATA="$PWD/data/loki"
    LOKI_CONFIG=$(${lokiConfigScript})

    echo "Starting Loki..."
    exec ${pkgs.grafana-loki}/bin/loki -config.file="$LOKI_CONFIG"
  '';

  # Promtail configuration script that generates config with runtime paths
  promtailConfigScript = pkgs.writeShellScript "promtail-config" ''
    CONFIG_FILE="''${CONFIG_FILE:-${config}}"
    PROMTAIL_DATA="''${PROMTAIL_DATA:-$PWD/data/promtail}"
    mkdir -p "$PROMTAIL_DATA"

    LOKI_PORT=$(${yq} eval '.observability.loki.http_port' "$CONFIG_FILE")
    LOG_FILE="$PWD/log.out"

    cat > "$PROMTAIL_DATA/promtail.yaml" <<EOF
    server:
      http_listen_port: 0
      grpc_listen_port: 0

    positions:
      filename: $PROMTAIL_DATA/positions.yaml

    clients:
      - url: http://localhost:$LOKI_PORT/loki/api/v1/push

    scrape_configs:
      - job_name: app
        static_configs:
          - targets:
              - localhost
            labels:
              job: app
              __path__: $LOG_FILE
    EOF

    echo "$PROMTAIL_DATA/promtail.yaml"
  '';

  startPromtail = pkgs.writeShellScript "start-promtail" ''
    export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
    export PROMTAIL_DATA="$PWD/data/promtail"
    PROMTAIL_CONFIG=$(${promtailConfigScript})

    echo "Starting Promtail (tailing $PWD/log.out)..."
    exec ${pkgs.grafana-loki}/bin/promtail -config.file="$PROMTAIL_CONFIG"
  '';

  startPrometheus = pkgs.writeShellScript "start-prometheus" ''
    export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
    export PROMETHEUS_DATA="$PWD/data/prometheus"
    PROMETHEUS_CONFIG=$(${prometheusConfigScript})
    PORT=$(${yq} eval '.observability.prometheus.port' "$CONFIG_FILE")

    echo "Starting Prometheus on port $PORT..."
    exec ${pkgs.prometheus}/bin/prometheus \
      --config.file="$PROMETHEUS_CONFIG" \
      --storage.tsdb.path="$PROMETHEUS_DATA" \
      --web.listen-address=:$PORT \
      ${lib.optionalString cfg.prometheus.enableRemoteWrite.default "--web.enable-remote-write-receiver"} \
      --web.console.templates=${pkgs.prometheus}/etc/prometheus/consoles \
      --web.console.libraries=${pkgs.prometheus}/etc/prometheus/console_libraries
  '';

  startGrafana = pkgs.writeShellScript "start-grafana" ''
        export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
        GRAFANA_DATA="$PWD/data/grafana"
        GRAFANA_PROVISIONING="$GRAFANA_DATA/provisioning"
        GRAFANA_DASHBOARDS="$GRAFANA_PROVISIONING/dashboards"

        PORT=$(${yq} eval '.observability.grafana.port' "$CONFIG_FILE")
        HOST=$(${yq} eval '.observability.grafana.host' "$CONFIG_FILE")
        ADMIN_USER=$(${yq} eval '.observability.grafana.admin_user' "$CONFIG_FILE")
        ADMIN_PASSWORD=$(${yq} eval '.observability.grafana.admin_password' "$CONFIG_FILE")

        mkdir -p "$GRAFANA_DATA"
        mkdir -p "$GRAFANA_PROVISIONING/datasources"
        mkdir -p "$GRAFANA_PROVISIONING/dashboards"
        mkdir -p "$GRAFANA_PROVISIONING/plugins"
        mkdir -p "$GRAFANA_PROVISIONING/alerting"
        mkdir -p "$GRAFANA_DASHBOARDS"

        # Clean up old datasource files
        rm -f "$GRAFANA_PROVISIONING/datasources"/*.yml

        # Generate datasources configuration
        ${grafanaDatasourcesScript} "$GRAFANA_PROVISIONING/datasources/datasources.yml"
        install -m 644 ${ghcDashboard} "$GRAFANA_DASHBOARDS/ghc.json"

        # Generate dashboard provisioning config
        cat > "$GRAFANA_PROVISIONING/dashboards/dashboards.yml" <<EOF
    apiVersion: 1
    providers:
      - name: 'GHC Dashboards'
        orgId: 1
        folder: ""
        type: file
        disableDeletion: false
        updateIntervalSeconds: 10
        allowUiUpdates: true
        options:
          path: $GRAFANA_DASHBOARDS
    EOF

        # Generate grafana.ini
        cat > "$GRAFANA_DATA/grafana.ini" <<EOF
    [server]
    http_port = $PORT
    http_addr = $HOST

    [paths]
    data = $GRAFANA_DATA
    logs = $GRAFANA_DATA/log
    plugins = $GRAFANA_DATA/plugins
    provisioning = $GRAFANA_PROVISIONING

    [security]
    admin_user = $ADMIN_USER
    admin_password = $ADMIN_PASSWORD

    [analytics]
    reporting_enabled = false
    check_for_updates = false

    [users]
    allow_sign_up = ${if cfg.grafana.allowSignUp.default then "true" else "false"}
    EOF

        echo "Starting Grafana on $HOST:$PORT..."
        exec ${pkgs.grafana}/bin/grafana server \
          --homepath ${pkgs.grafana}/share/grafana \
          --config "$GRAFANA_DATA/grafana.ini"
  '';

  # Grafana datasource configuration script
  grafanaDatasourcesScript = pkgs.writeShellScript "grafana-datasources" ''
    CONFIG_FILE="''${CONFIG_FILE:-${config}}"
    OUTPUT_FILE="$1"

    PROMETHEUS_PORT=$(${yq} eval '.observability.prometheus.port' "$CONFIG_FILE")
    TEMPO_PORT=$(${yq} eval '.observability.tempo.http_port' "$CONFIG_FILE")
    LOKI_PORT=$(${yq} eval '.observability.loki.http_port' "$CONFIG_FILE")

    cat > "$OUTPUT_FILE" <<EOF
    apiVersion: 1

    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://localhost:$PROMETHEUS_PORT
        isDefault: true
        editable: false
        jsonData:
          exemplarTraceIdDestinations:
            - name: trace_id
              datasourceUid: tempo

      - name: Tempo
        type: tempo
        access: proxy
        url: http://localhost:$TEMPO_PORT
        uid: tempo
        editable: false
        jsonData:
          nodeGraph:
            enabled: true

      - name: Loki
        type: loki
        access: proxy
        url: http://localhost:$LOKI_PORT
        uid: loki
        editable: false
    EOF
  '';

  # GHC runtime metrics dashboard
  ghcDashboard = pkgs.writeText "ghc-performance.json" (
    builtins.toJSON (import ./dashboards/ghc-performance.nix)
  );

  # Export histogram buckets configuration for use in application config
  metricsConfig = pkgs.writeText "metrics-config.yaml" ''
    metrics:
      histogram_buckets: ${builtins.toJSON cfg.metrics.histogramBuckets.default}
  '';
in
{
  # Export the configuration for external use
  inherit cfg metricsConfig;

  apps = {
    # Prometheus server
    prometheus = {
      type = "app";
      program = "${pkgs.writeShellScript "prometheus-app" ''
        set -e
        export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
        PORT=$(${yq} eval '.observability.prometheus.port' "$CONFIG_FILE")
        APP_TARGET=$(${yq} eval '.observability.prometheus.targets.app' "$CONFIG_FILE")
        NODE_EXPORTER_TARGET=$(${yq} eval '.observability.prometheus.targets.node_exporter' "$CONFIG_FILE")

        echo "Starting Prometheus..."
        echo "  Web UI: http://localhost:$PORT"
        echo "  Scraping: http://$APP_TARGET/metrics, http://$NODE_EXPORTER_TARGET/metrics"
        echo ""
        echo "Press Ctrl+C to stop"
        echo ""

        exec ${startPrometheus}
      ''}";
    };

    # Grafana server
    grafana = {
      type = "app";
      program = "${pkgs.writeShellScript "grafana-app" ''
        set -e
        export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
        PORT=$(${yq} eval '.observability.grafana.port' "$CONFIG_FILE")
        HOST=$(${yq} eval '.observability.grafana.host' "$CONFIG_FILE")
        ADMIN_USER=$(${yq} eval '.observability.grafana.admin_user' "$CONFIG_FILE")

        echo "Starting Grafana..."
        echo "  Web UI: http://$HOST:$PORT"
        echo "  Username: $ADMIN_USER"
        echo "  Dashboards: GHC Performance"
        echo ""
        echo "Press Ctrl+C to stop"
        echo ""

        exec ${startGrafana}
      ''}";
    };

    # Node exporter for system metrics
    node-exporter = {
      type = "app";
      program = "${pkgs.writeShellScript "node-exporter-app" ''
        set -e
        export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
        PORT=$(${yq} eval '.observability.node_exporter.port' "$CONFIG_FILE")

        echo "Starting Node Exporter..."
        echo "  Metrics endpoint: http://localhost:$PORT/metrics"
        echo "  Collecting: CPU, Memory, Disk I/O, Network I/O"
        echo ""
        echo "Press Ctrl+C to stop"
        echo ""

        exec ${startNodeExporter}
      ''}";
    };

    # Tempo for distributed tracing
    tempo = {
      type = "app";
      program = "${pkgs.writeShellScript "tempo-app" ''
        set -e
        export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
        HTTP_PORT=$(${yq} eval '.observability.tempo.http_port' "$CONFIG_FILE")
        OTLP_HTTP_PORT=$(${yq} eval '.observability.tempo.otlp_http_port' "$CONFIG_FILE")

        echo "Starting Tempo..."
        echo "  HTTP: http://localhost:$HTTP_PORT"
        echo "  OTLP HTTP: localhost:$OTLP_HTTP_PORT"
        echo ""
        echo "Press Ctrl+C to stop"
        echo ""

        exec ${startTempo}
      ''}";
    };

    # Loki for log aggregation
    loki = {
      type = "app";
      program = "${pkgs.writeShellScript "loki-app" ''
        set -e
        export CONFIG_FILE="''${CONFIG_FILE:-${config}}"
        HTTP_PORT=$(${yq} eval '.observability.loki.http_port' "$CONFIG_FILE")

        echo "Starting Loki..."
        echo "  HTTP: http://localhost:$HTTP_PORT"
        echo "  Push endpoint: http://localhost:$HTTP_PORT/loki/api/v1/push"
        echo ""
        echo "Press Ctrl+C to stop"
        echo ""

        exec ${startLoki}
      ''}";
    };

    # All-in-one observability stack
    observability = {
      type = "app";
      program = "${pkgs.writeShellScript "observability-app" ''
        set -e

        export CONFIG_FILE="''${CONFIG_FILE:-${config}}"

        # Read config values
        PROMETHEUS_PORT=$(${yq} eval '.observability.prometheus.port' "$CONFIG_FILE")
        GRAFANA_PORT=$(${yq} eval '.observability.grafana.port' "$CONFIG_FILE")
        GRAFANA_HOST=$(${yq} eval '.observability.grafana.host' "$CONFIG_FILE")
        GRAFANA_ADMIN_USER=$(${yq} eval '.observability.grafana.admin_user' "$CONFIG_FILE")
        GRAFANA_ADMIN_PASSWORD=$(${yq} eval '.observability.grafana.admin_password' "$CONFIG_FILE")
        TEMPO_PORT=$(${yq} eval '.observability.tempo.http_port' "$CONFIG_FILE")
        LOKI_PORT=$(${yq} eval '.observability.loki.http_port' "$CONFIG_FILE")
        NODE_EXPORTER_PORT=$(${yq} eval '.observability.node_exporter.port' "$CONFIG_FILE")
        APP_TARGET=$(${yq} eval '.observability.prometheus.targets.app' "$CONFIG_FILE")

        echo "Starting Observability Stack..."
        echo ""
        echo "This will start:"
        echo "  1. Prometheus (metrics storage & querying)"
        echo "  2. Grafana (visualization & dashboards)"
        echo "  3. Node Exporter (system metrics)"
        echo "  4. Tempo (distributed tracing)"
        echo "  5. Loki (log aggregation)"
        echo "  6. Promtail (log shipper, tailing ./log.out)"
        echo ""
        echo "Make sure the application is running on http://$APP_TARGET"
        echo ""

        # Trap to kill all background jobs on exit
        cleanup() {
          echo ""
          echo "Stopping observability stack..."
          kill $(jobs -p) 2>/dev/null || true
          wait
          echo "Stopped!"
        }
        trap cleanup EXIT INT TERM

        # Start all services in background
        ${startNodeExporter} &
        sleep 2

        ${startTempo} &
        sleep 2

        ${startLoki} &
        sleep 2

        ${startPromtail} &
        sleep 1

        ${startPrometheus} &
        sleep 3

        ${startGrafana} &

        echo ""
        echo "Observability stack started!"
        echo ""
        echo "Access points:"
        echo "  Grafana:    http://$GRAFANA_HOST:$GRAFANA_PORT ($GRAFANA_ADMIN_USER/$GRAFANA_ADMIN_PASSWORD)"
        echo "  Prometheus: http://localhost:$PROMETHEUS_PORT"
        echo "  Tempo:      http://localhost:$TEMPO_PORT"
        echo "  Loki:       http://localhost:$LOKI_PORT"
        echo "  Node Exp:   http://localhost:$NODE_EXPORTER_PORT/metrics"
        echo ""
        echo "Dashboards:"
        echo "  -> GHC Performance"
        echo ""
        echo "Press Ctrl+C to stop all services"
        echo ""

        # Wait for any background job to exit
        wait -n
      ''}";
    };
  };
}
