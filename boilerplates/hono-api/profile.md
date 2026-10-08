# Profile — hono-api

## Identity and licence

- Name: hono-starter (Node.js template)
- Origin: https://github.com/honojs/starter
- Licence: MIT
- Commit profiled: 110fb1c4dc34e050665ca89e0a2fa1a00fde29ef

The template directory `templates/nodejs/`, commit dated 2026-10-04: what `npm create hono` generates for Node.js, a Hono server with one route. Every path below is relative to `templates/nodejs/`. The licence is declared in the repository's `package.json` and README; no licence file ships.

## Platform

- Platform: api

## QA driver

- QA driver: scenarios

## Commands

```
Install:           npm install
Test:              —
Typecheck:         npx tsc --noEmit
E2E:               —
Build:             npm run build
Dev:               npm run dev
```

No test runner ships: `Test` is `—` until a first story adds one, and its command must then accept paths to test files. `Typecheck` assumes the `typescript` dependency provides the `tsc` binary, as the `build` script already relies on; it was not run here. `npm run dev` runs `tsx watch` and prints `Server is running on http://localhost:3000`.

To run a scenario, build first with `Build`, then start `node dist/index.js` with `PORT=<port>` in the background and wait for the log line `Server is running`; requests go with `curl` to `http://127.0.0.1:<port>/`. The template ignores `PORT`: `src/index.ts` hard-codes port 3000, so until a story makes it read `process.env.PORT` the scenarios driver ends `blocked`.

## Code map

- `src/` — the application sources.
- `src/index.ts` — the whole app: the Hono instance, its single `GET /` route and the call to `serve()`.
- `package.json` — scripts `dev`, `build` and `start`; dependencies `hono` and `@hono/node-server`.
- `tsconfig.json` — TypeScript options, `NodeNext` modules, output to `dist/`.

## Ownership granularity

`src/index.ts` holds the app and every route, so it is shared. A story owns a new `src/routes/<name>.ts` alone, mounted with `app.route()`; the mount line in `src/index.ts` is its one shared edit, so two stories adding routes touch the same file. `package.json` is also shared.

## Where each rule lives

- Routes and handlers: `src/index.ts`, until a story moves them into one file per route under a new routes folder.
- Validation, access and tenant filter: no validator, access or tenant code ships; a story adds them next to the route it protects.

## Capabilities

| Capability | Brick | Notes |
| --- | --- | --- |

This template provides none of the listed capabilities.

## UI inventory

This starter has no screen: it is an HTTP API.

## Known traps

- The port is hard-coded to 3000 in `src/index.ts`; `PORT` and any other setting are ignored.
- No test runner and no lockfile ship.
- `pnpm-workspace.yaml` sits beside a README that uses npm.
- `tsx watch` in `npm run dev` does not type-check; only `npm run build` does.
- `NodeNext` modules with `"type": "module"` need the `.js` extension on relative imports, even for `.ts` files.
- `.env` is ignored by git yet loaded by nothing.
