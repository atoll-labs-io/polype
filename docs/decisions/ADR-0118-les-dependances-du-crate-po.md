---
adr: 0118
title: Les dépendances du crate po
status: accepted
date: 2026-11-13
scope: story s164-state-as-json
supersedes: []
superseded-by: []
---

# ADR-0118 — Les dépendances du crate `po`

## Context and Problem Statement
s164 fait entrer le crate `po` dans le dépôt (ADR-0106, ADR-0116, ADR-0117). Il lui faut, pour tout M21 et une fois pour toutes, puisque aucune story suivante n'en ajoute : écrire et lire du JSON (la sortie de chaque verbe ; les décisions de la boîte que s165 reçoit sur l'entrée standard et que s166 relit, donc une donnée venue de l'extérieur), lire les arguments de sept verbes et de quelques options, et donner une date avec son décalage horaire (`asked`, `answer.at`, `started` de [`interface-agent.md`](../interface-agent.md), dont s165, s166 et s169 ont besoin).

## Considered Options
Classées par les critères du porteur : libre ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA. Toutes sont libres (MIT ou Apache-2.0) et ne demandent aucun service.

Mesures du planner, `cargo build --release` d'un crate d'essai, compilation à froid des dépendances déjà téléchargées :

| Option | Binaire | Compilation à froid | Crates tirées |
| --- | --- | --- | --- |
| aucune dépendance | 0,44 Mo | 0,1 s | 0 |
| `serde_json` + `chrono` (`clock`, `std`) | 0,58 Mo | 3,4 s | 8 |
| `serde_json` + `jiff` | 1,0 Mo | 6,2 s | 6 |

Mesures du chef de projet, même méthode, sur la même machine (16 cœurs), crates d'essai minuscules :

| Option | Binaire | Compilation à froid | Crates compilées |
| --- | --- | --- | --- |
| 1 — `serde_json` seul (`Value`) + `chrono` | 0,65 Mo | 3,5 s | 10 |
| 1 bis — `serde` dérivé + `serde_json` + `chrono` | 0,65 Mo | 4,9 s | 18 |
| 4 — `serde` dérivé + `serde_json` + `clap` + `chrono` | 1,25 Mo | 7,4 s | 32 |

1. **`serde_json` sans dérivation, `chrono` réduit à `clock` et `std`, les arguments lus à la main sur `std::env::args`** — le JSON lu et écrit en `serde_json::Value`, sans macro procédurale à compiler ; la validation d'une décision venue de l'extérieur s'écrit à la main sur des `Value`.
1 bis. **`serde` avec dérivation, `serde_json`, `chrono` (`default-features = false`, `clock`, `std`), les arguments lus à la main, sans `clap`** — proposée par le porteur. Le contrat devient des types que le compilateur vérifie ; une entrée venue de l'extérieur avec un champ inconnu ou manquant est refusée par construction (`deny_unknown_fields`). Tire `syn` et les macros procédurales : 1,4 s de compilation à froid de plus que l'option 1, même binaire.
2. **`serde_json` et `jiff`, arguments à la main** — même chose que 1, avec la bibliothèque de dates plus récente. Deux fois plus lourde en binaire pour un besoin réduit à « maintenant, avec son décalage ».
3. **Aucune dépendance** — le JSON écrit et relu à la main, le décalage horaire par `localtime_r` de la libc, en `unsafe`. La plus sobre sur le papier ; l'écart ne se voit sur aucun matériel, et elle fait tenir un analyseur JSON à la main sur une entrée qui vient de l'extérieur.
4. **`serde` avec dérivation, `serde_json`, `clap` et `chrono`** — la forme du profil `boilerplates/rust-cli`. Binaire deux fois plus gros, compilation à froid doublée, trente-deux crates.

## Decision Outcome
Chosen option: **l'option 1 bis**, tranchée par le porteur le 2026-11-13 ; le planner recommandait l'option 1. Ses raisons :

- le contrat de [`interface-agent.md`](../interface-agent.md) devient des types que le compilateur vérifie, au lieu de clés écrites en chaînes ;
- une décision venue de l'extérieur (s165, s166) dont un champ manque ou est inconnu est refusée par construction (`deny_unknown_fields`), au lieu d'une validation écrite à la main sur `serde_json::Value` ;
- c'est la forme que les modèles écrivent le mieux (quatrième critère), pour un coût de matériel nul (même binaire) et 1,4 s de compilation, une fois.

`clap` est écarté pour deux raisons : ses refus par défaut sont du texte sur `stderr`, contre la règle du contrat « tout verbe, refus compris, écrit un seul objet JSON » ; et c'est lui qui tire l'essentiel des crates en plus (14 sur 32), autant de chaîne d'approvisionnement à tenir pour s171.

Dans le crate : `serde = { version = "1", features = ["derive"] }`, `serde_json = "1"`, `chrono = { version = "0.4", default-features = false, features = ["clock", "std"] }`, `Cargo.lock` commité, compilation en `--locked`.

### Consequences
- Good, because chaque objet du contrat est une structure dérivée, et un champ renommé ou oublié est une erreur de compilation, pas un écart découvert par l'agent extérieur.
- Good, because une entrée venue de l'extérieur est refusée par l'analyseur dès qu'elle sort de sa forme, sans code de validation à tenir à côté.
- Bad, because la compilation depuis les sources tire `syn` et les macros procédurales, et télécharge plus de crates la première fois ; s171 précompile le binaire et retire ce coût au cas courant.
- Bad, because `deny_unknown_fields` contredit l'ADR-0117 si on l'applique à ce qu'une version plus récente de `po` a écrit sur le disque : un champ ajouté (que le contrat permet sans changer de numéro) ferait rejeter le fichier par un binaire plus ancien. Il ne vaut donc que pour ce qui entre de l'extérieur (l'entrée standard, les arguments) ; les fichiers que `po` relit sont lus par des vues qui ignorent les champs qu'elles ne connaissent pas.
- Bad, because l'ordre des clés d'un objet suit l'ordre des champs des structures : le contrat n'en promet aucun.
- Neutral: une story qui voudrait une dépendance de plus s'arrête et le dit, comme les notes de s165 à s170 l'exigent ; une nouvelle ADR la tranche.
