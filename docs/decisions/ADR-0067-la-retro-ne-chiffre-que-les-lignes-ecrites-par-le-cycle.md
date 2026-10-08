---
adr: 0067
title: La rétro ne chiffre que les lignes écrites par le cycle
status: accepted
date: 2026-10-08
scope: story s89-po-retro
supersedes: []
superseded-by: []
---

# ADR-0067 — La rétro ne chiffre que les lignes écrites par le cycle

## Context and Problem Statement
s89 crée `/po-retro`, qui résume « un jalon ou une plage de stories » depuis les revues, les relevés et les rapports QA. Mais la méthode ne connaît pas de jalon (le gabarit de stories met chaque story en `## <id>`), aucun fichier ne referme un majeur, et un fichier de revue empile plusieurs revues dont les lignes ne suivent pas toujours le gabarit. Il faut décider ce qu'est un jalon, ce qui compte comme un chiffre, et où va le résultat, sans quoi chaque exécution le devinerait autrement.

## Considered Options
- **Jalon lu dans les titres, chiffres tirés des seules lignes du cycle, sortie à l'écran** — un jalon est un titre de `docs/stories.md` d'un niveau au-dessus des titres de stories, et couvre les stories jusqu'au prochain titre de son niveau ; chaque chiffre vient d'une ligne que le cycle écrit (`Review status:`, `Fix loop:`, `Failure cause:`, sévérité d'un constat, `Max severity:`, `Ship allowed:`, `QA status:`, colonne `Exit` de `## Runs`) et cite son `chemin:ligne` ; une ligne illisible est dite illisible ; un majeur est ouvert quand il figure dans la dernière revue de sa story ; rien n'est écrit.
- **Une ligne `Milestone:` par story dans le gabarit de stories** — explicite, mais hors du périmètre de s89, et chaque projet devrait réécrire ses stories pour obtenir sa première rétro.
- **Un script `bin/po-retro` qui analyse les fichiers** — reproductible, mais hors de l'`Owns` de s89, et les revues réelles écrivent leurs lignes en élément de liste ou en gras (`docs/reviews/s78-platform-setting.md`) : un analyseur strict les ignorerait sans le dire.
- **Écrire la rétro dans `docs/retro/<jalon>.md`** — elle resterait dans git, mais la commande aurait besoin de Write, que la story lui refuse, et ce fichier n'ouvrirait aucune gate.
- **Compter commits, lignes de code ou durées dans git** — facile à obtenir, mais ce sont les métriques de vanité que la story écarte : elles ne disent pas où le cycle a coûté.
- **Lire les majeurs ouverts dans le tracker d'issues** — le réglage `Issue tracker` vaut souvent `—`, et ce ne serait plus un fait enregistré par le cycle.

## Decision Outcome
Chosen option: **Jalon lu dans les titres, chiffres tirés des seules lignes du cycle, sortie à l'écran**, parce que c'est la seule qui marche sur les `docs/stories.md` existants sans les réécrire, qui garde chaque chiffre vérifiable par sa ligne, et qui tient sans Write ni Edit.

### Consequences
- Good, because chaque chiffre se vérifie en ouvrant la ligne citée, et une donnée absente se lit « absent », jamais zéro.
- Good, because un projet qui suit le gabarit (stories en `##`) obtient quand même sa rétro, par une plage `<premier id>..<dernier id>`.
- Bad, because un majeur corrigé par une story ultérieure sans lien écrit reste affiché ouvert : la sortie le dit « ouvert selon la dernière revue », pas « non corrigé ».
- Neutral: si un jour une story ajoute un champ de clôture des majeurs ou une ligne `Milestone:`, une nouvelle ADR remplacera la partie concernée de celle-ci.
