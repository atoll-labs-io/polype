---
adr: 0121
title: Les plateformes publiées de po et l'endroit où l'installeur lit la somme attendue
status: accepted
date: 2026-11-14
scope: story s171-po-prebuilt-and-verified
supersedes: []
superseded-by: []
---

# ADR-0121 — Les plateformes publiées de `po` et l'endroit où l'installeur lit la somme attendue

## Context and Problem Statement
L'ADR-0115 retient un `po` précompilé par plateforme, vérifié par sa somme, compilé depuis les sources en repli, et laisse deux choix au porteur : la liste des plateformes publiées, et l'endroit où l'installeur lit la somme attendue. Elle note qu'une somme publiée seulement à côté du binaire ne détecte qu'un téléchargement abîmé, et ne prouve l'origine que si l'installeur versionné porte la somme attendue. s171 écrit l'installeur et le workflow de release : il faut trancher les deux avant d'exécuter son plan.

## Considered Options
Classées par les critères du porteur : libre ou auto-hébergeable, sobre en matériel, capable de grandir, facile à manier pour une IA (`## Ranking the options` de la skill `capability-bricks`).

**Où l'installeur lit la somme attendue**

1. **Dans l'installeur versionné, `bin/polype`** (bloc `PO_SUMS`, une ligne `<sha256>  po-<version>-<plateforme>` par binaire publié), ajoutée par un commit qui suit la publication et passe par une pull request comme tout changement. Aucun service, aucune clé, aucun outil de plus qu'un `sha256sum` ou un `shasum` ; marche pareil sur Forgejo. Prouve que le binaire téléchargé est celui dont le dépôt revu a écrit la somme : un binaire remplacé après coup sur la page de release est refusé. Ne prouve pas que ce binaire a été compilé depuis ces sources (pas de compilation reproductible) : le runner qui l'a construit reste de confiance. Coût : une release se fait en deux temps, et le commit étiqueté ne porte pas encore ses sommes, donc l'installeur de ce commit-là compile depuis les sources.
2. **Dans un fichier de sommes publié avec le binaire, téléchargé au même endroit** — une seule étape de release. Ne détecte qu'un téléchargement abîmé : qui peut remplacer le binaire peut remplacer la somme à côté (la réserve de l'ADR-0115).
3. **Une signature détachée (minisign, ou signify)** — prouve qui a signé, indépendamment du lieu de téléchargement. Demande une clé privée à garder hors du dépôt, accessible au workflow, et un outil que la machine qui installe n'a pas par défaut : l'installation cesse de ne demander « que de quoi télécharger et vérifier une somme » (ADR-0115).
4. **Attestation de provenance de la forge (`gh attestation verify`, Sigstore)** — prouve que le binaire vient de tel workflow sur tel commit. Liée à GitHub et à un service tiers, ni libre de bout en bout ni auto-hébergeable, et demande `gh` sur la machine qui installe.

**Plateformes publiées** (toutes les autres compilent depuis les sources, ADR-0115)

1. **`linux-x86_64`, `linux-aarch64`, `macos-aarch64`** — les machines de développement courantes et les serveurs ARM (auto-hébergement, Raspberry Pi), trois runners hébergés gratuits pour un dépôt public (`ubuntu-latest`, `ubuntu-24.04-arm`, `macos-latest`). Un Mac Intel compile depuis les sources.
2. **Les mêmes et `macos-x86_64`** — un runner de plus (`macos-13`), pour un parc de Mac Intel qui décroît et dont GitHub retire les runners.
3. **`linux-x86_64` seul** — un seul runner ; un Mac et toute machine ARM compilent depuis les sources, ce qui demande Rust à la plupart des postes de développement.

Windows n'est dans aucune option : Polype est en bash, et WSL est une machine Linux.

## Decision Outcome
Chosen option: **la somme dans l'installeur versionné (option 1) et les trois plateformes `linux-x86_64`, `linux-aarch64`, `macos-aarch64` (option 1)**, tranchées par le porteur le 2026-11-14 par la boîte de décisions (d-0013, d-0014). Sa raison pour la somme : c'est la seule voie où la somme attendue vient d'ailleurs que du téléchargement, sans clé ni service à tenir. Les trois plateformes servent les machines de développement courantes et les serveurs ARM sur trois runners hébergés gratuits ; un Mac Intel compile depuis les sources (ADR-0115).

### Consequences
- Good, because un binaire remplacé sur la page de release, ou servi par un miroir, est refusé par l'installeur, qui garde le `po` en place.
- Good, because rien ne change pour une forge Forgejo : seule l'étape de publication du workflow dépend de la forge.
- Bad, because une release demande un second commit, celui des sommes ; tant qu'il n'a pas atterri, les installeurs compilent depuis les sources.
- Bad, because la somme ne prouve pas la compilation depuis les sources : le runner hébergé qui construit le binaire reste de confiance.
- Neutral: un binaire Linux compilé sur `ubuntu-latest` demande une glibc au moins aussi récente que celle des symboles qu'il lie ; une machine plus ancienne échoue à le lancer et doit forcer la compilation depuis les sources.
