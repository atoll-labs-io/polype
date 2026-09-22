# Brick — SMTP relay (Email)

- Capability: Email
- Default brick (ADR-0020): SMTP through a relay of the project's choice
- Status: documentation only — this note describes a deployment and its contracts; it ships no code.

## What it provides

Outgoing mail: the application hands a message to an SMTP relay, which accepts it for delivery. Any SMTP library works against it, so moving to another relay, or to a managed sending API, is a change of settings.

## How it runs at mustelinet

- The relay is the project's choice: one it runs on a VM, or one it rents. Whether a mustelinet VM may open outbound SMTP connections is `not documented — ask the host`.
- Until the host answers, a prototype sends to a capture server (Mailpit or an equivalent) on a VM of the private network: messages are kept for inspection and nothing leaves mustelinet. Its web interface stays private too, reached through SSH (`ssh.mustelinet.com:2222`).
- The relay is never published: SMTP is TCP, and the edge carries HTTP and HTTPS only.

## Settings

- `SMTP_HOST` and `SMTP_PORT` — the relay, or the capture server on the private network.
- `SMTP_USER` and `SMTP_PASSWORD` — the relay's credentials, when it asks for them.
- `MAIL_FROM` — the sender address.

These are the brick's settings, read by the deployed application; they are not `AGENTS.local.md` settings.

## Backups

- What: nothing beyond the relay's credentials, kept in the project's secret store; sent mail is not the application's data.
- The capture server's messages are disposable.

## What mustelinet does not provide

- No managed database — so nothing about mail is stored by the host; any record of what was sent lives in our PostgreSQL.
- No managed object storage — so attachments come from our Garage, never from a host bucket.
- Publication over HTTP and HTTPS only — so no SMTP port is published; the application only sends, and receiving mail at mustelinet is out of reach.
- Outbound SMTP — `not documented — ask the host`; until answered, only the capture server is known to work.

## Contract test checklist

Every brick of this capability must pass these; the list adds mustelinet's constraints to the contract of the capability-bricks skill.

- [ ] Nominal: a message sent is accepted for delivery.
- [ ] Refusal: an invalid recipient address is rejected before sending.
- [ ] Data effect: a test SMTP server captures the message with its recipient and subject.
- [ ] Mustelinet: a message reaches the relay from a mustelinet VM, or the question to the host about outbound SMTP is answered and recorded.
