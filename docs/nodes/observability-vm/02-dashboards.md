# Observability VM — Dashboards

> Status: Draft

## Import Pre-Built Dashboards

In Grafana: **Dashboards → Import → Enter ID**

| Dashboard | ID | What It Shows |
|-----------|-----|--------------|
| Node Exporter Full | `1860` | CPU, RAM, disk, network for all Linux nodes |
| NVIDIA GPU Metrics (DCGM) | `12239` | VRAM usage, GPU %, temperature, power per GPU |

---

## Adding a New Node to Existing Dashboards

The Node Exporter Full and NVIDIA dashboards use `job` and `instance` label selectors. When a new node is scraped by Prometheus, it automatically appears in the dropdowns — no dashboard edits needed.

---

## Recommended Dashboard Layout

Suggested folder structure in Grafana:

```
Dashboards/
├── Infrastructure/
│   ├── Node Overview (Node Exporter Full)
│   └── GPU Cluster (DCGM)
└── Alerts/
    └── Alert Overview
```

---

## Next Step

→ [03-alerting.md](03-alerting.md)
