# Cardano Hoarding Node

A service that connects to nodes in the Cardano (preprod, mainnet) network and temporarily stores all observed headers, blocks, and, in the future, transactions. Notable ones (e.g. those involved in slot disputes, invalid, or from competing forks) are retained and exposed via the HTTP API; the rest are evicted.

This makes the hoarding node useful for investigating chain disagreements, mempool anomalies, and adversarial behaviour such as block equivocation.

## Running locally

The dev setup requires three services running concurrently. Open separate terminals for each.

### 1. PostgreSQL

```bash
nix run .#postgres
```

### 2. Cardano node (preprod)

Then start the Cardano node. On first run, the app will ask whether to bootstrap the chain database via Mithril (downloads a verified snapshot):

```bash
nix run .#cardano-node-preprod
```

### 3. Monitoring stack (optional)

Starts Prometheus, Grafana, Loki, Tempo, and Promtail:

```bash
nix run .#monitoring
```

### 4. Database migrations

Apply any pending migrations before starting the node:

```bash
sqitch deploy
```

### 5. Hoarding node

```bash
cabal run
```

Configuration is loaded from `config/dev.yaml`. Any value can be overridden at runtime via environment variables — see [docs/configuration.md](docs/configuration.md).

## Database migrations

Migrations are managed with [Sqitch](https://sqitch.org/). With PostgreSQL running:

```bash
sqitch deploy   # apply pending migrations
sqitch status   # check current state
```

See [db/README.md](db/README.md) for full migration workflows.

## Further documentation

| Topic | Doc |
|---|---|
| Configuration & env var overrides | [docs/configuration.md](docs/configuration.md) |
| Secrets management | [docs/secrets.md](docs/secrets.md) |
| Database schema & migrations | [docs/database-schema.md](docs/database-schema.md), [db/README.md](db/README.md) |
| Observability & metrics | [docs/observability.md](docs/observability.md) |
| Docker images | [docs/docker.md](docs/docker.md) |
| Peer discovery | [docs/peer-discovery-and-connection.md](docs/peer-discovery-and-connection.md) |
