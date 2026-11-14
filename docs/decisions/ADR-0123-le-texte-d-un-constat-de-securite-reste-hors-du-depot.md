---
adr: 0123
title: Le texte d'un constat de sécurité reste hors du dépôt, dans le dossier que nomme Private folder
status: accepted
date: 2026-11-14
scope: story s178-security-findings-stay-private
supersedes: [ADR-0090]
superseded-by: []
---

# ADR-0123 — Le texte d'un constat de sécurité reste hors du dépôt

## Context and Problem Statement
`po record review` écrit la réponse du relecteur entière dans `docs/reviews/<id>.md`, qui part dans git avec la story : un constat de sécurité y est public avant sa correction, la limite que l'ADR-0090 note à son option D. Le porteur a décidé (D7 b, 2026-11-14) qu'un tel constat reste sur sa machine, dans la boîte de décisions, la revue n'en gardant qu'un compte et l'identifiant de la décision. `po inbox add` exige pour une décision `sensitive` un `context` absolu hors du dépôt, `.git` et les worktrees compris ; aucun réglage ne nomme un lieu privé. Il faut choisir où vit ce texte et qui l'efface.

Ce qui ne dépend pas du choix : `po record review` reconnaît un constat de sécurité à sa marque (`- <sévérité> — [security] — …`), refuse une marque mal placée avant d'écrire quoi que ce soit, écrit le texte en fichier `0600` dans un dossier `0700`, pose une décision `sensitive` de motif `security` dont `context` désigne ce fichier, et met à la place des constats la ligne `Security findings: <n> — decision <d-NNNN>`. `Max severity:` et `Ship allowed:` restent ceux du relecteur. Le fix run et la revue suivante lisent le texte par `po inbox <id>`.

## Considered Options
Classées par les critères du porteur : open source ou auto-hébergeable, sobre, passant à l'échelle, facile à manier pour un agent, apte à la production et au suivi. Toutes sont des fichiers locaux : les deux premiers critères ne les départagent pas.

- **A. Le dossier d'état de l'utilisateur, effacé par la personne.** `${XDG_STATE_HOME:-$HOME/.local/state}/polype/private/<nom du projet>/<id de story>-<horodatage>-<pid>.md`, ce que le chef de projet a fait à la main le 2026-11-14. `po` ne l'efface jamais.
  - Pour : aucun réglage, chemin déterministe qu'un agent retrouve par `po inbox <id>` ; le texte survit aux redémarrages ; `XDG_STATE_HOME` suffit à le déplacer (volume chiffré) sans toucher au projet.
  - Contre : les textes s'accumulent tant que la personne ne les efface pas, et rien ne le lui rappelle ; supprimer le clone laisse le texte orphelin.
  - Seconde machine ou collaborateur : le texte reste sur la machine qui a consigné la revue, comme la boîte (`Decision inbox`, locale) ; ailleurs, la revue montre un compte et un identifiant qui ne s'ouvrent pas, et l'on demande à la personne.
  - Session reprise des jours plus tard : le texte et la décision sont là.
  - Fix run et revue suivante : `po inbox <id>` rend `context`, le fichier se lit ; rien ne change entre la consignation et la consommation.
  - Nettoyage : la personne, une fois la faiblesse corrigée et publiée.
  - Réglage nouveau : aucun.
- **B. Un réglage `Private folder:` nommant un chemin absolu.** `po` y écrit, refuse un chemin dans le dépôt. Effacement par la personne.
  - Pour : la personne choisit le lieu, un dossier chiffré ou synchronisé entre ses machines ; c'est la seule option qui peut suivre la personne sur une seconde machine.
  - Contre : un réglage de plus pour chaque projet ; un projet existant qui ne l'a pas refuse tout constat de sécurité jusqu'à ce qu'il le pose ; tant que la boîte reste locale, la décision ne voyage pas, le texte seul ne sert à rien ailleurs.
  - Seconde machine : possible si le dossier est synchronisé ; la décision, elle, n'y est pas.
  - Session reprise, fix run, revue suivante : comme A.
  - Nettoyage : la personne.
  - Réglage nouveau : oui. `method/commands/po-setup.md`, le `AGENTS.local.md` de chaque projet et les tests des réglages sortent du `Owns` de s178 : il faudrait corriger la story avant de l'exécuter.
- **C. Le dossier d'administration git du worktree, effacé avec lui.** `<git-common-dir>/worktrees/<id>/polype-private/`, que `git worktree remove` supprime au nettoyage du ship.
  - Pour : nettoyage automatique, lié à la vie de la story ; aucun chemin personnel ; git ne suit jamais ce qui est sous `.git`.
  - Contre : `po inbox add` doit accepter un `context` sous `.git`, ce qu'il refuse aujourd'hui pour toute la racine ; un constat majeur laissé ouvert au ship perd son texte avant que la personne l'ait traité ; une copie du dépôt (`cp -r`, sauvegarde) l'emporte ; un worktree retiré à la main l'efface aussi.
  - Seconde machine : non. Session reprise : oui tant que le worktree existe.
  - Fix run et revue suivante : oui, le worktree vit encore.
  - Nettoyage : git, au retrait du worktree.
  - Réglage nouveau : aucun.
- **D. Le dossier d'état, effacé par `po inbox consume`.** Lieu de A ; `po` efface le texte quand le chef de projet consomme la décision.
  - Pour : rien ne s'accumule, sans geste de la personne.
  - Contre : le chef de projet consomme une décision dès qu'il a écrit ce que la réponse produit (`method/AGENTS.md`, `## The project lead`), donc avant le fix run qui doit lire le texte ; il faudrait changer cette règle, hors `Owns`, chez s179.
  - Seconde machine, session reprise : comme A jusqu'à la consommation.
  - Fix run et revue suivante : texte perdu si la décision est consommée avant.
  - Nettoyage : `po`, à la consommation. Réglage nouveau : aucun.
- **E. Un dossier temporaire du système**, créé en `umask 077` comme le fait `po-intake.sh` pour un contrôle `--sensitive`.
  - Pour : un précédent dans le dépôt ; le système nettoie.
  - Contre : effacé au redémarrage ou par le nettoyeur de `/tmp` ; une session reprise des jours plus tard trouve un `context` qui ne mène à rien.
  - Seconde machine : non. Fix run le jour même : oui. Réglage nouveau : aucun.

Écartée d'emblée : le texte dans le fichier de la décision. `po inbox` rendrait alors le texte à tout agent extérieur, un front de discussion compris, quand l'interface ne rend que des chemins (`docs/interface-agent.md`, `## Ce que l'interface ne fait pas`).

## Decision Outcome
Option choisie : **B**, par le porteur le 2026-11-14 (décision d-0020 de la boîte), contre l'option A que cette ADR proposait. Il n'a pas donné d'autre raison que le texte de l'option : c'est lui qui choisit le lieu, chiffré ou synchronisé entre ses machines. Le nettoyage reste à la personne : `po` n'efface jamais un texte qu'il a écrit.

Le réglage, tel que `po` le lit :
- `Private folder:` est commité dans `AGENTS.local.md`, souvent dans un dépôt public et lu sur plusieurs machines : sa valeur ne doit nommer ni un utilisateur ni un dossier personnel. Elle est donc un chemin absolu ou un chemin qui commence par `~/`, que `po` développe avec la variable `HOME` de la machine qui consigne la revue. `$HOME` ni aucune autre variable n'est développé : `po` ne passe jamais par un shell, et `$HOME/…` se lit comme un chemin relatif, donc refusé. Le gabarit porte `~/.local/state/polype/private/`.
- Le chemin obtenu doit être absolu et hors du dépôt : ni sous la racine du projet, `.git` compris, ni dans un worktree du même dépôt, par la même règle que le `context` d'une décision `sensitive`. Sinon, refus `private-folder-unusable` (sortie 1).
- `po` écrit sous `<Private folder>/<nom du projet>/`, crée en `0700` les dossiers qui manquent, laisse tel quel un dossier qui existe (un volume chiffré monté par la personne), et écrit chaque texte dans un fichier neuf en `0600`, jamais par-dessus un autre.
- Réglage absent ou `—` : une réponse sans constat de sécurité se consigne comme avant, le réglage n'est pas lu. Une réponse qui en porte est refusée `no-private-folder-setting` (sortie 2, `"written": false`) : ni revue, ni texte, ni décision, rien écrit nulle part dans le dépôt ni hors de lui. Le message nomme le réglage. `polype update` et `polype check` nomment déjà un réglage du gabarit qui manque au projet.

La décision posée par `po record review` propose trois options : `fix-here` (corriger dans cette story ; recommandée), `hold` (la story attend, la personne règle la faiblesse elle-même), `ship-later` (livrer si la revue le permet, traiter plus tard ; un constat critique bloque le ship quoi qu'il arrive). Sa question ne décrit pas la faiblesse. Elle porte `blocks: [<id>]`, et la lane attend la réponse de la personne, seulement quand les constats de sécurité de la réponse comptent au moins un critique ou un majeur ; quand ils sont tous mineurs, `blocks` est vide et la story continue (décision d-0021 du porteur, 2026-11-14).

L'ADR-0123 remplace l'ADR-0090 sur un seul point : le texte d'un constat de sécurité n'est plus dans la revue publique. Le reste de l'ADR-0090 tient, dont « un constat de sécurité n'est jamais déposé seul ».

### Consequences
- Good, because aucun dépôt public ne décrit une faiblesse avant sa correction, le fix run comme la revue suivante la lisent toujours, et la personne place ce texte où elle veut, chiffré ou synchronisé.
- Bad, because chaque projet porte un réglage de plus, un projet qui ne l'a pas refuse tout constat de sécurité jusqu'à ce qu'il le pose, et les textes s'accumulent jusqu'à ce que la personne les efface ; un constat critique ou majeur arrête la lane jusqu'à sa réponse.
- Neutral: la décision, elle, reste dans la boîte locale (`Decision inbox`) : sur une seconde machine, le texte peut être là sans la décision qui le désigne, tant que la boîte ne voyage pas (#216). La correction elle-même reste publique dans la pull request ; cette ADR ne cache que la description.
