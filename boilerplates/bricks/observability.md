# Brick — OpenTelemetry collector (Observability)

- Capability: Observability
- Default brick (ADR-0020): OpenTelemetry sent to a self-hosted collector
- Example host: [mustelinet](../../docs/references/mustelinet.md)
- Status: documentation only — this note describes a deployment and its contracts; it ships no code.

## What it provides

Traces, errors and metrics: the application's OpenTelemetry SDK exports them over OTLP to a collector, which forwards them to a storage and viewing backend. ADR-0020 settles the collector only; the backend is the project's choice.

## How it runs at the host

- The collector runs on a VM or as a deployment on the host's managed Kubernetes when it offers one, on the private network.
- The application exports OTLP to it over the private network; nothing is published through the edge.
- A backend with a web interface is either kept private and reached through the host's SSH access, or published over HTTPS through the edge with its own certificate.
- Receivers, ports and pipelines: follow the OpenTelemetry Collector documentation; this note fixes none.

## Settings

- `OTEL_EXPORTER_OTLP_ENDPOINT` — the collector's OTLP address on the private network.
- `OTEL_SERVICE_NAME` — the name under which the application reports.
- The collector's own configuration file, kept in git.

These are the brick's settings, read by the deployed application and the collector; they are not `AGENTS.local.md` settings.

## Backups

- What: the collector's configuration, which lives in git.
- Telemetry is disposable: losing it loses history, not the product. The backend's retention is the project's choice.

## What the host may not provide

- No managed database, when the host has none — so any backend that stores telemetry is ours to run, on its own volume.
- No managed object storage, when the host has none — so a backend that wants a bucket uses our Garage.
- Publication over HTTP and HTTPS only, when the host's edge is limited to them — so OTLP stays on the private network, and a backend interface is either private or served over HTTPS with its own certificate.

## Contract test checklist

Every brick of this capability must pass these; the list adds the host's constraints to the contract of the capability-bricks skill.

- [ ] Nominal: a request emits a trace and an error is recorded with its context.
- [ ] Refusal: an unreachable collector never fails the user's request — the telemetry is dropped, the request succeeds.
- [ ] Data effect: the span or error arrives at a test collector.
- [ ] Host: with the collector stopped, the application still answers through the edge over HTTPS.
