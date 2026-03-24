# Observability VM — Alerting

> Status: Draft

## Key Alert Rules

Configure these in Grafana Alerting → Alert Rules.

| Metric | Condition | Severity | Reason |
|--------|-----------|----------|--------|
| `node_memory_MemAvailable_bytes` | < 2GB | Warning | System RAM pressure |
| `node_filesystem_avail_bytes{mountpoint="/"}` | < 50GB | Warning | Disk space getting low |
| `up` | == 0 | Critical | Any exporter is down |

Add project-specific alert rules (e.g., GPU metrics, service latency) in your project's observability docs.

---

## Notification Channels

In Grafana: **Alerting → Contact Points → New Contact Point**

Recommended channels (set up at least one):
- **Webhook** — POST to a Discord/Slack webhook
- **Email** — SMTP configuration in Grafana settings
- **Pushover / PagerDuty** — for critical on-call alerts

---

## Silence Rules

Suppress expected alerts:
- During planned maintenance windows: Grafana → Alerting → Silences → New Silence
