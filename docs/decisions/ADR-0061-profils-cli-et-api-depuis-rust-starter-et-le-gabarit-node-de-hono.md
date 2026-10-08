---
adr: 0061
title: Le profil CLI part de rust-starter, le profil API du gabarit Node.js de honojs/starter
status: accepted
date: 2026-10-08
scope: story s86-cli-api-profiles
supersedes: []
superseded-by: []
---

# ADR-0061 — Les profils CLI et API partent de rust-starter et du gabarit Node.js de Hono

## Context and Problem Statement
s86 demande un profil de CLI en Rust avec clap et un profil d'API Hono en TypeScript, chacun écrit depuis un gabarit de départ public, sous licence libre, à un commit nommé. La story ne nomme aucun dépôt, et pour Hono le dépôt officiel porte une douzaine de gabarits, un par environnement d'exécution. Le profil fixe ce que `/po-setup` copie dans `AGENTS.local.md` et ce que le pilote `scenarios` lance : le choix doit être lu une fois, pas refait par l'implémenteur.

## Considered Options
- **CLI — `rust-starter/rust-starter`** — clap 4 en derive, espace de travail `cli` / `core` / `utils`, tests d'intégration du binaire avec `assert_cmd`, MIT, dernier commit en mai 2025.
- **CLI — `rust-cli/cli-template`** — le gabarit du groupe de travail CLI de Rust ; écarté : il repose sur structopt et non sur clap, édition 2018, figé depuis 2020, et ses fichiers portent des marqueurs `cargo-generate` qui ne compilent pas tels quels.
- **CLI — `rust-github/template`** — gabarit `cargo-generate` générique ; écarté : il n'embarque pas clap.
- **API — `honojs/starter`, gabarit `templates/nodejs`** — processus Node ordinaire lancé par `node dist/index.js`, que le pilote `scenarios` démarre et arrête lui-même sur la boucle locale (ADR-0059), MIT.
- **API — `honojs/starter`, gabarit `templates/bun`** — écarté : l'application est exportée sans serveur, le port et le démarrage dépendent du runtime Bun, absent d'une machine Node.
- **API — `honojs/starter`, gabarits `cloudflare-workers`, `vercel`, `aws-lambda` et apparentés** — écartés : ils tournent dans l'émulateur ou la plateforme d'un hébergeur, que le pilote ne démarre pas sans outillage propre.

## Decision Outcome
Chosen option: **`rust-starter/rust-starter` pour `boilerplates/rust-cli/` et `honojs/starter` (`templates/nodejs`) pour `boilerplates/hono-api/`**, parce que ce sont les seuls candidats qui portent la pile demandée par la story (clap, Hono) et se lancent comme un processus local qu'un scénario démarre, interroge puis arrête.

### Consequences
- Good, because chaque profil se vérifie contre un commit précis d'un dépôt public, comme celui de next-forge (ADR-0010).
- Bad, because le gabarit Node de Hono fixe le port 3000 dans `src/index.ts` : tant qu'un projet ne lit pas le port depuis l'environnement, sa QA par scénarios s'arrête en `blocked` (`qa-drivers/scenarios.md`), et le profil doit le dire.
- Bad, because `honojs/starter` déclare sa licence MIT dans son `package.json` et son README sans fichier de licence à la racine.
- Neutral: rust-starter ignore `Cargo.lock` et réserve clap à Linux dans `utils/Cargo.toml` ; le profil le range dans ses pièges plutôt que de choisir un gabarit sans clap.
