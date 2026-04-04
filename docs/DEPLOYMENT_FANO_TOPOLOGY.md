# Deployment Fano Topology

This document freezes the deployment Fano topology as a **responsibility and communication witness**, not as routing authority.

Executable truth still lives in:

- nginx vhosts
- systemd units
- DNS records
- runtime binaries

If config and this topology disagree, deployed config wins and this document must be updated.

## Deployment Points

The 7 deployment points are:

- `public_site`
- `browser_projection`
- `browser_narrative`
- `runtime_sse`
- `api_service`
- `downloads`
- `admin_mcp`

These are host+role deployment points. They are not runtime semantics, routing authority, or access-control primitives.

## Host Assignment

- `medium`
  - `public_site`
  - `browser_projection`
  - `browser_narrative`
- `large`
  - `runtime_sse`
  - `api_service`
  - `admin_mcp`
- `small`
  - `downloads`

Current deployed-role mapping:

- `universallifeprotocol.com` on `medium` = `public_site`
- `/browser/projection/*` on `medium` = `browser_projection`
- `/browser/narrative/*` on `medium` = `browser_narrative`
- `/events` on `large` = `runtime_sse`
- future `/api/` on `large` = `api_service`
- `matroid-garden.com` on `small` = `downloads`

## Fano Lines

The deployment adjacency primitive reuses the 7-line Fano shape:

- `public_site`, `browser_projection`, `runtime_sse`
- `public_site`, `browser_narrative`, `api_service`
- `public_site`, `downloads`, `admin_mcp`
- `browser_projection`, `browser_narrative`, `downloads`
- `browser_projection`, `api_service`, `admin_mcp`
- `browser_narrative`, `runtime_sse`, `admin_mcp`
- `runtime_sse`, `api_service`, `downloads`

This topology is used to express lawful adjacency and intended separation of responsibilities.
Deploy relations described here are downstream responsibility, claim, receipt, and provenance context only.
They do not replace nginx, systemd, DNS, or runtime truth.

## Communication Expectations

- `public_site` may speak to `browser_projection` and `browser_narrative`.
- browser roles may speak to `runtime_sse` and later `api_service`.
- `downloads` remains isolated from runtime services in the current deploy shape.
- `admin_mcp` speaks to service roles, not to public browser roles directly.
- no direct dependency from public browser roles to `downloads` unless a page explicitly links to a downloadable artifact.
- no direct public dependency on `admin_mcp`.

Intended proxy paths:

- `/events` -> `runtime_sse`
- later `/api/` -> `api_service`

## Artifact

The machine-readable deployment topology artifact is:

- [deploy/fano_service_topology.json](/home/main/Programs/meta-interpreter/deploy/fano_service_topology.json)

This artifact is downstream governance/deploy metadata only.
It may support deploy claims, receipts, and provenance notes, but it is not routing authority.
