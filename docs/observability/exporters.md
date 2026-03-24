# Observability Exporters — Per-Node Setup

> Status: Active

`base-vm.yml` installs Node Exporter and Grafana Alloy automatically on provisioned VMs. Use these instructions for manual setup or for nodes not provisioned by Ansible (e.g., physical machines, Windows nodes).

---

## Node Exporter (All Linux Nodes)

Exposes system metrics (CPU, RAM, disk, network) on `:9100`.

```bash
docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  --network host \
  --pid host \
  -v /:/host:ro,rslave \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host
```

Verify: `curl http://localhost:9100/metrics | head -20`

---

## NVIDIA DCGM Exporter (GPU Nodes Only)

Requires NVIDIA drivers + NVIDIA Container Toolkit installed first.

```bash
docker run -d \
  --name dcgm-exporter \
  --restart unless-stopped \
  --runtime nvidia \
  --gpus all \
  -p 9400:9400 \
  nvcr.io/nvidia/k8s/dcgm-exporter:latest
```

Verify: `curl http://localhost:9400/metrics | grep DCGM_FI_DEV_FB_USED`

Key metrics:

| Metric | Meaning |
|--------|---------|
| `DCGM_FI_DEV_FB_USED` | VRAM used (MiB) |
| `DCGM_FI_DEV_FB_FREE` | VRAM free (MiB) |
| `DCGM_FI_DEV_GPU_UTIL` | GPU compute utilization % |
| `DCGM_FI_DEV_GPU_TEMP` | GPU temperature (°C) |
| `DCGM_FI_DEV_POWER_USAGE` | Power draw (W) |

---

## Windows Exporter (Windows Nodes)

Install on Windows machines instead of Node Exporter. Exposes Windows metrics on `:9182`.

Download from: https://github.com/prometheus-community/windows_exporter/releases

Install as a Windows service:
```powershell
.\windows_exporter.exe --service install
Start-Service windows_exporter
```

---

## Grafana Alloy — Log Shipping (All Linux Nodes)

Alloy collects Docker container logs and systemd journal, ships to Loki on the observability VM.

```bash
# Copy config template and set observability VM IP
cp alloy-config.alloy /etc/alloy/config.alloy
# Edit: replace OBSERVABILITY_SERVER_IP with your observability VM's IP

docker run -d \
  --name alloy \
  --restart unless-stopped \
  -v /etc/alloy/config.alloy:/etc/alloy/config.alloy \
  -v /var/log:/var/log:ro \
  -v /run/log/journal:/run/log/journal:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -p 12345:12345 \
  grafana/alloy:latest \
  run /etc/alloy/config.alloy
```

Config template: [`configs/alloy/alloy-config.alloy`](../../configs/alloy/alloy-config.alloy)

---

## After Adding Exporters

Add the node to your project's Prometheus scrape config:

```yaml
# In your project's prometheus.yml or scrape-targets.yaml
- job_name: 'node-exporter'
  static_configs:
    - targets: ['<node-hostname-or-ip>:9100']
      labels:
        node: '<node-name>'

- job_name: 'dcgm-exporter'   # GPU nodes only
  static_configs:
    - targets: ['<node-hostname-or-ip>:9400']
      labels:
        node: '<node-name>'
```

Reload Prometheus to pick up new targets: `curl -X POST http://observability-vm.local:9090/-/reload`
