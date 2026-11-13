---
adr: 0115
title: Le binaire de l'automate est précompilé et vérifié, compilé en repli
status: accepted
date: 2026-11-13
scope: framing
supersedes: []
superseded-by: []
---

# ADR-0115 — Le binaire de l'automate est précompilé et vérifié, compilé en repli

## Context and Problem Statement
L'ADR-0106 retient un binaire Rust pour l'automate. Tout ce que Polype pose aujourd'hui est du texte, que git porte dans chaque clone et chaque worktree ; un binaire dépend de la plateforme et doit être compilé quelque part. Il faut décider où il est construit et comment il arrive sur une machine qui installe Polype (D11), avant que `/po-stories` reprenne M21.

## Considered Options
Classées par les critères du porteur : libre ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA.

1. **Binaires précompilés par plateforme, publiés avec leur somme de contrôle à chaque version, que l'installeur télécharge et vérifie ; compilation depuis les sources en repli** quand aucun binaire n'existe pour la plateforme — aucune chaîne Rust à avoir dans le cas courant, aucune plateforme exclue. Demande un workflow de release, et deux chemins d'installation à tester.
2. **Binaires précompilés seuls** — un seul chemin à tester. Une plateforme non publiée n'est pas servie.
3. **Compilation depuis les sources à chaque installation** — rien à publier, le binaire correspond toujours aux sources. Chaque machine doit avoir une chaîne Rust, alors que Polype ne suppose aucune installation particulière ([`direction.md`](../direction.md)).
4. **Binaire commité dans le dépôt de chaque projet** — le clone suffit et chaque worktree l'a, comme les hooks. Git grossit à chaque version et une seule plateforme est servie.

## Decision Outcome
Chosen option: **l'option 1**, tranché par le porteur le 2026-11-13 : une machine qui installe Polype n'a pas besoin de Rust, la somme de contrôle dit ce qui tourne, et la compilation en repli évite qu'une plateforme non publiée soit exclue.

Restent à fixer par les stories de M21 et leurs plans, le porteur tranchant ce qui est un choix technique : la liste des plateformes publiées, l'endroit où l'installeur lit la somme attendue, et le chemin où le binaire est posé.

### Consequences
- Good, because l'installation ne demande que de quoi télécharger et vérifier une somme.
- Bad, because Polype gagne un workflow de release à tenir, et l'installeur deux chemins à tester.
- Bad, because le binaire ne voyage plus par git : un clone d'un projet ne l'a pas tant que l'installeur n'a pas tourné, et un worktree de story doit le trouver hors de son arbre.
- Neutral: une somme publiée seulement à côté du binaire ne détecte qu'un téléchargement abîmé ; elle ne prouve l'origine que si l'installeur versionné porte la somme attendue.
