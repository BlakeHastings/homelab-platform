# Observability VM — Step 1: LGTM Stack Setup

> Status: Draft — not yet deployed

The observability VM runs the full Grafana/Loki/Tempo/Prometheus stack. All nodes ship metrics, logs, and traces here.

---

## Deploy

```bash
# Copy compose file from homelab-platform
cp /path/to/homelab-platform/configs/docker-compose/observability-vm.yml ./docker-compose.yml

# Create data directories for persistence
mkdir -p data/grafana data/prometheus data/loki data/tempo

# Create a prometheus.yml with your scrape targets (see your project repo)
cp /path/to/your-project/configs/prometheus/scrape-targets.yaml ./prometheus.yml

# Start the stack
docker compose up -d

# Verify all services are healthy
docker compose ps
```

---

## Port Map

| Service | Port | Purpose |
|---------|------|---------|
| Grafana | 3000 | Dashboard UI — access from LAN |
| Prometheus | 9090 | Metrics storage (internal only) |
| Loki | 3100 | Log aggregation — receives from Alloy |
| Tempo | 3200 | Trace UI |
| OTLP HTTP | 4318 | Receives OpenTelemetry traces |
| OTLP gRPC | 4317 | Alternative OTLP endpoint |

Access Grafana: `http://observability-vm.local:3000` (default login: `admin`/`changeme`, change on first login)

---

## Connect Data Sources in Grafana

After first login, add data sources:

1. **Prometheus** → `http://prometheus:9090`
2. **Loki** → `http://loki:3100`
3. **Tempo** → `http://tempo:3200`

All use the Docker service names (internal DNS within the compose network).

---

## Persistence

Each service mounts a local `data/` directory. Do not delete these — they contain all your historical metrics and logs.

```
data/
├── grafana/     # dashboards, users, alert rules
├── prometheus/  # time-series data
├── loki/        # log chunks
└── tempo/       # trace data
```

---

## Adding Nodes

When a new node joins the cluster:
1. Add the node's scrape targets to your project's Prometheus config and reload
2. Set up Node Exporter on the new node (provisioned automatically by `base-vm.yml`)
3. No restart needed — Prometheus picks up new scrape targets on reload

---

## Next Step

→ [02-dashboards.md](02-dashboards.md)
