---
adr: 0095
title: La charge utile globale se signe et n'accueille aucun fichier étranger
status: accepted
date: 2026-10-18
scope: story s142-payload-refuses-foreign-files
supersedes: [ADR-0088]
superseded-by: []
---

# ADR-0095 — La charge utile se signe et n'accueille aucun fichier étranger

## Context and Problem Statement
Polype ne sait pas ce que la charge utile `~/.claude/polype/` doit contenir. Lancé depuis elle,
l'installeur prend pour source tout fichier présent sous `polype/bin/` et `polype/method/` : un
fichier de la personne déposé là, un `.before-polype` laissé par `--set-aside` ou remis par un
retrait, est posé comme méthode active puis entre au manifeste (#118). Lancé depuis un dépôt, il
ne voit pas un tel fichier, et `remove --global` l'emporte avec le répertoire. De plus, une
retouche d'un fichier livré, lancée depuis la charge utile, se propage aux copies actives (#115).

## Considered Options
- **A. La charge utile se signe.** Une pose ou une mise à jour globale lancée depuis un dépôt
  écrit `polype/payload.sums`, une ligne `cksum` et chemin par fichier de la charge utile, hors
  fichiers d'état. Un fichier hors signature arrête la commande. Retenue.
- **B. Faire confiance à la charge utile lancée depuis elle-même.** Écartée : une retouche s'y
  propage, et un fichier étranger y devient méthode active.
- **C. Exiger un dépôt comme source.** Écartée : l'usage chezmoi, qui synchronise la charge utile
  et la relance sur une autre machine, disparaît.
- **D. Ranger un fichier étranger dans `polype.kept/`.** Écartée : un fichier qui n'a jamais été
  une retouche s'y mêlerait aux retouches gardées (ADR-0093).
- **E. Propager la retouche d'un fichier signé en le disant.** Écartée : elle devient quand même
  méthode active sur toutes les copies, et une ligne de sortie ne suffit pas à la rattraper.

## Decision Outcome
Chosen option: **A. La charge utile se signe**, parce qu'une liste que la charge utile emporte
avec elle sert aux deux canaux : un run depuis un dépôt l'écrit, une charge utile synchronisée la
transporte, et un run depuis la charge utile n'en livre que ce qu'elle signe.

- **Signature.** `payload.sums` vit dans la charge utile, jamais au manifeste. Un run depuis la
  charge utile ne la réécrit pas. Fichiers d'état : `manifest`, `checksums`, `version`,
  `payload.sums`, tout `*.next` et tout `*.polype-next`.
- **Fichier étranger (#118).** Sous `polype/`, un fichier qui n'est pas un fichier d'état, absent
  du manifeste global, et que la source ne livre pas (run depuis un dépôt) ou que `payload.sums`
  ne liste pas (run depuis la charge utile) arrête `install`, `update` et `init` avant toute
  écriture (sortie 1), lien compris, avec ou sans `--set-aside`, avec
  `polype: not laid down by Polype, inside the payload: <chemin>`. Un `*.before-polype` sous
  `polype/` est étranger quoi que dise le manifeste : il n'y est plus jamais remis.
- **Collision.** Une collision sous `polype/` s'arrête de même : `--set-aside` ne s'y applique
  plus. C'est le seul point d'ADR-0088 que cette décision remplace ; ailleurs, sa règle tient.
- **`remove --global`** s'arrête avant toute écriture sur un fichier absent du manifeste et de
  `payload.sums`, et ne lit aucune source livrée. Le `<chemin>.before-polype` d'un chemin du
  manifeste revient comme avant, une fois la charge utile partie.
- **Charge utile non signée**, posée avant ce correctif : `install`, `update` et `init` lancés
  depuis elle s'arrêtent et demandent un run depuis un dépôt Polype ; `check --global` et
  `remove --global` le disent, `remove` se fiant alors au seul manifeste.
- **Retouche d'un fichier signé (#115).** Elle ne sort pas de la charge utile vers les copies
  actives. Cette seconde règle est implémentée par s143, pas par cette story-ci.

### Consequences
- Good, because aucun fichier de la personne ne devient méthode active, par aucun canal, et
  `remove --global` n'en emporte aucun.
- Good, because une charge utile synchronisée avec sa signature s'installe sans dépôt.
- Bad, because une charge utile posée avant ce correctif demande un run depuis un dépôt.
- Neutral: la personne déplace elle-même un fichier étranger ; Polype ne le range nulle part.
