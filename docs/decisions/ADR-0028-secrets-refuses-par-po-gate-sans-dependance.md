---
adr: 0028
title: Le pre-commit refuse les secrets avec une courte table de motifs dans po-gate, sans scanner externe
status: accepted
date: 2026-10-08
tags: [adr, polype, gates, secrets]
scope: story s49-secret-scan
supersedes: []
superseded-by: []
---

# ADR-0028 — Le pre-commit refuse les secrets avec une courte table de motifs dans po-gate, sans scanner externe

## Context and Problem Statement
s49 fait refuser par le pre-commit un fichier `.env*` indexé et une ligne ajoutée qui porte une clé privée PEM ou un jeton AWS, GitHub, Stripe ou Anthropic. Trois choix restent ouverts : quel moteur détecte les jetons, ce que le contrôle lit, et comment il se comporte quand il ne peut pas lire.

## Considered Options
- **gitleaks, trufflehog ou detect-secrets** — des centaines de règles maintenues, mais une dépendance que `po-gate` n'a pas aujourd'hui (ADR-0025) ; absente sur la machine, le hook devrait soit tout refuser, soit tout laisser passer.
- **Table `<règle>|<longueur minimale>|<ERE>` dans `po-gate.sh`, lue par awk** — même forme que la table du garde de plancher ; un format de jeton de plus = une ligne.
- **Scanner les fichiers indexés en entier** — trouve aussi un secret déjà présent avant le commit, mais bloque un commit qui ne l'a pas introduit et relit des fichiers entiers à chaque commit.
- **Scanner seulement les lignes ajoutées de `git diff --cached -U0`** — ne juge que ce que le commit introduit.
- **Échec de lecture → laisser passer** — un hook muet sur une panne ne protège rien.
- **Échec de lecture → refuser le commit** — la règle déjà suivie par `pre_commit` quand il ne peut pas lister les fichiers indexés (`po-gate.sh:67-68`).

## Decision Outcome
Chosen options: **table de motifs dans `po-gate.sh`**, **lignes ajoutées seulement**, **échec de lecture → refus**, because la story vise les secrets évidents et non un audit, l'`Owns` borne la story à `po-gate.sh`, et un contrôle qui s'efface sur une panne ne retire rien à la vigilance de l'agent qu'il doit remplacer.

### Consequences
- Good, because aucun outil à installer : un projet qui active les hooks a le contrôle tel quel.
- Good, because le message nomme le fichier, la ligne et la règle sans jamais reprendre la valeur.
- Bad, because un format de jeton absent de la table (Slack, Google, OpenAI, mots de passe dans une URL) passe ; le contrôle n'est pas un audit de secrets.
- Bad, because une clé factice de test au format réel est refusée ; les tests la construisent à l'exécution.
- Neutral: un projet qui veut un audit complet branche gitleaks dans sa CI ou chaîne son propre hook ; la table s'étend quand un format revient en revue.
