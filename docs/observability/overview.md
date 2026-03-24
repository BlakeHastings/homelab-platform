# Observability Overview

> Status: Active

Every node ships data to a central **observability VM** running the LGTM stack. Nodes themselves run only lightweight exporters and shippers — no local data storage.

---

## Data Flow

```
Every Linux node
  ├── Node Exporter      :9100  → Prometheus scrapes
  ├── DCGM Exporter      :9400  → Prometheus scrapes (GPU nodes only)
  └── Grafana Alloy             → ships container + journal logs to Loki

Windows nodes
  └── Windows Exporter   :9182  → Prometheus scrapes

Observability VM
  ├── Prometheus   :9090  — stores all metrics (scraped from all nodes)
  ├── Loki         :3100  — stores all logs (shipped from Alloy)
  ├── Tempo        :3200  — stores all traces (received via OTLP)
  └── Grafana      :3000  — unified dashboards + alerting
```

---

## What Each Signal Tells You

| Signal | Tool | Key Questions |
|--------|------|--------------|
| Metrics | Prometheus → Grafana | CPU/RAM/disk/network per node; GPU VRAM %, temperature, utilization; service request rates and error rates |
| Logs | Loki → Grafana | Container stderr/stdout; systemd journal events; service startup failures |
| Traces | Tempo → Grafana | End-to-end request latency; which service handled what; where time was spent |

---

## Automatic Setup

The `base-vm.yml` Ansible playbook installs Node Exporter and Grafana Alloy automatically on every provisioned VM. GPU exporters (DCGM) are installed by project-specific playbooks for nodes with NVIDIA hardware.

---

## Checklist: Adding a New Node

When any new machine joins the cluster:

- [ ] Node Exporter running (Linux) or Windows Exporter running (Windows) — installed by `base-vm.yml` for Proxmox VMs
- [ ] DCGM Exporter running (if node has NVIDIA GPU)
- [ ] Grafana Alloy running and pointed at observability VM — installed by `base-vm.yml`
- [ ] Add node's scrape targets to your project's `prometheus.yml` and reload Prometheus
- [ ] Verify node appears in Node Exporter Full dashboard in Grafana

→ Detailed setup: [exporters.md](exporters.md)
→ LGTM stack deployment: [homelab-services/services/observability](https://github.com/BlakeHastings/homelab-services/tree/main/services/observability)
