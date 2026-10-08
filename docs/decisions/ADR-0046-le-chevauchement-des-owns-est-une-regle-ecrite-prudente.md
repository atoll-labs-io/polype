---
adr: 0046
title: Le chevauchement des Owns est une règle écrite, prudente, posée dans le skill stories-review
status: accepted
date: 2026-10-08
scope: story s69-owns-overlap-globs
supersedes: []
superseded-by: []
---

# ADR-0046 — Le chevauchement des Owns est une règle écrite, prudente, posée dans le skill stories-review

## Context and Problem Statement
ADR-0038 a fait des globs `*` / `**` des entrées `Owns` valides, mais `/po-drive`, la relecture des stories et la revue comparent encore les `Owns` comme des chemins littéraux (revue de s61, majeur). `crates/*/Cargo.toml` contre `crates/core/` n'a aucune règle : deux lanes qui se chevauchent peuvent partir ensemble. Il faut dire qui décide d'un chevauchement entre deux entrées, comment, et où cette règle est écrite une seule fois.

## Considered Options
- **Un script de chevauchement dans `method/hooks/`, réutilisant `entry_matches` de `po-bounds.sh`** — exact pour un chemin contre une entrée, mais deux globs entre eux demandent un autre algorithme ; le `stories-reviewer` n'a pas de shell (`method/agents/stories-reviewer.md`), et `method/hooks/` est hors du périmètre de la story.
- **Règle et exemples dans `method/AGENTS.md`** — lue par tous, mais hors périmètre, et le fichier de règles reste court parce que chaque agent le charge.
- **Règle et exemples dans `method/templates/stories.md`, à côté de la syntaxe** — hors périmètre, et aucun des trois lecteurs ne charge ce gabarit pour juger.
- **Règle et exemples copiés dans les trois fichiers** — le critère `overlap_examples_are_written_once` l'interdit, et trois copies divergent.
- **Exemples dans `review-antihallu`** — la revue ne compare qu'un chemin réel du diff à une entrée ; la comparaison entrée contre entrée est le travail de la relecture des stories et de `/po-drive`.
- **Règle écrite, segment par segment, prudente (« dans le doute, elles se chevauchent »), phrase de règle reprise dans les trois fichiers, exemples seulement au contrôle 8 du skill `stories-review`, cités par les deux autres.**

## Decision Outcome
Chosen option: **la règle écrite et prudente, exemples au contrôle 8 de `stories-review`**, parce que les trois lecteurs sont des agents dont l'un n'a pas de shell, que l'erreur coûteuse est de lancer ensemble deux lanes qui se chevauchent alors que l'erreur inverse coûte seulement une vague d'attente, et que le contrôle 8 est déjà l'endroit où chaque paire d'`Owns` est comparée.

### Consequences
- Good, because un glob ne passe plus pour disjoint d'un dossier qu'il recouvre, et la même phrase de règle se lit dans les trois fichiers.
- Bad, because la règle est prudente : `**/*.md` contre `**/*.ts`, ou `docs/*.md` contre `docs/*.ts`, comptent comme chevauchants alors qu'aucun chemin ne correspond aux deux ; une story attend parfois une vague pour rien.
- Neutral: `method/AGENTS.md`, `method/commands/po-stories.md`, `method/commands/po-status.md` et `method/templates/stories.md` parlent encore de « partager un chemin » sans renvoyer à la règle ; une story qui les possède pourra les aligner.
